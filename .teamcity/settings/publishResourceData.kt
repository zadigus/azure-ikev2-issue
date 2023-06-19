package settings

import jetbrains.buildServer.configs.kotlin.v2019_2.BuildSteps
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.PythonBuildStep
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.python
import shared.common.DockerImage
import shared.common.build_steps.readScript

fun BuildSteps.publishResourceData(dockerImage: DockerImage, stateKey: String) : PythonBuildStep {
    return python {
        name = "Publish Resource Data"

        environment = venv {
            requirementsFile = "ci/azure-requirements/requirements-ci.txt"
        }
        
        command = script {
            content = readScript("settings/cloud/scripts/publish_resource_data.py")
            scriptArguments = """
                --state-storage-account-name=%terraform.state.storage.account.name% 
                --state-key=$stateKey
                --state-storage-container-name=%terraform.state.storage.container.name%
                --state-resource-group-name=%terraform.state.resource.group.name%
            """.trimIndent()
        }

        this.dockerImage = dockerImage.toString()
        dockerImagePlatform = PythonBuildStep.ImagePlatform.Linux
        dockerPull = true
        dockerRunParameters = dockerImage.run_parameters
    }
}