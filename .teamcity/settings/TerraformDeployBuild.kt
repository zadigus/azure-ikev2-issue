package settings

import jetbrains.buildServer.configs.kotlin.v2019_2.BuildType
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import shared.common.Agent
import shared.common.Architecture
import shared.common.DockerImage
import shared.common.build_steps.publishJiraProjectId
import shared.infrastructure.build_steps.publishTerraformVariables
import shared.infrastructure.build_steps.terraformConfig
import shared.infrastructure.build_steps.terraformDeploy
import shared.templates.ArtifactoryDockerLogin
import shared.templates.EnvironmentSetup
import shared.vpn.buildSteps.closeVpnConnection
import shared.vpn.buildSteps.generateVpnConfiguration
import shared.vpn.buildSteps.openVpnConnection


class TerraformDeployBuild(
    dockerImage: DockerImage,
    dockerImageTag: String,
    agent: Agent = Agent(architecture = Architecture.AMD64),
    scriptPath: String,
    projectName: String,
    deploymentWorkingDirectory: String = "",
) : BuildType({
    templates(
        EnvironmentSetup,
        ArtifactoryDockerLogin,
    )

    name = "Deploy terraform"

    steps {
        publishJiraProjectId(scriptPath)
        publishTerraformVariables(scriptPath)
        terraformConfig(scriptPath, dockerImage, deploymentWorkingDirectory)
        terraformDeploy(scriptPath, dockerImage, deploymentWorkingDirectory)
        publishResourceData(dockerImage, stateKey = "%terraform.state.key%")
        generateVpnConfiguration(
            scriptPath = scriptPath,
            dockerImageTag = dockerImageTag,
            workingDir = "./",
            stateKey = "%terraform.state.key%"
        )
        openVpnConnection(scriptPath = scriptPath, workingDir = "./")
        script {
            name = "Ping ACR"
            scriptContent = """
                #! /bin/sh
                
                nslookup ${'$'}{ACR_URL}
            """.trimIndent()
        }
        script {
            name = "Log on ACR"
            scriptContent = """
                #! /bin/sh
                
                credential=${'$'}(az acr credential show --name ${'$'}ACR_NAME --resource-group ${'$'}HUB_RESOURCE_GROUP_NAME)
                username=${'$'}(echo ${'$'}credential | jq -r '.username')
                echo ${'$'}credential | jq -r '.passwords[] | select(.name == "password") | .value' | docker login ${'$'}ACR_URL --username ${'$'}username --password-stdin
            """.trimIndent()
        }
        closeVpnConnection(scriptPath)
    }

    agent.add_to_requirements(this)

    params {
        param("terraform.state.key", "$projectName/%teamcity.build.branch%")
    }
})
