package settings

import jetbrains.buildServer.configs.kotlin.v2019_2.BuildStep
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

    val azureDockerImage = DockerImage(
        name = "kubernetes-configuration-x86_64-ubuntu22.04",
        tag = dockerImageTag,
        run_parameters = "-v /var/run/docker.sock:/var/run/docker.sock --network host"
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
                
                az login --service-principal -u ${'$'}ARM_CLIENT_ID -p ${'$'}ARM_CLIENT_SECRET --tenant ${'$'}ARM_TENANT_ID
                
                credential=${'$'}(az acr credential show --name ${'$'}ACR_NAME --resource-group ${'$'}HUB_RESOURCE_GROUP_NAME)
                username=${'$'}(echo ${'$'}credential | jq -r '.username')
                echo ${'$'}credential | jq -r '.passwords[] | select(.name == "password") | .value' | docker login ${'$'}ACR_URL --username ${'$'}username --password-stdin
            """.trimIndent()
            this.dockerImage = azureDockerImage.toString()
            dockerImagePlatform = azureDockerImage.Platform
            dockerRunParameters = azureDockerImage.run_parameters
            dockerPull = true
        }
        closeVpnConnection(scriptPath)
        openIpSecConnection(scriptPath=scriptPath, workingDir="./")
        script {
            name = "Debug IPSec"
            scriptContent = """
                #! /bin/sh
                
                ################################################################
                # JOURNAL CTL
                ################################################################
                journalctl -u ipsec
                
                ################################################################
                # SYSLOGS
                ################################################################
                tail -f /var/log/syslog
                
            """.trimIndent()
            executionMode = BuildStep.ExecutionMode.ALWAYS
        }
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
                
                az login --service-principal -u ${'$'}ARM_CLIENT_ID -p ${'$'}ARM_CLIENT_SECRET --tenant ${'$'}ARM_TENANT_ID
                
                credential=${'$'}(az acr credential show --name ${'$'}ACR_NAME --resource-group ${'$'}HUB_RESOURCE_GROUP_NAME)
                username=${'$'}(echo ${'$'}credential | jq -r '.username')
                echo ${'$'}credential | jq -r '.passwords[] | select(.name == "password") | .value' | docker login ${'$'}ACR_URL --username ${'$'}username --password-stdin
            """.trimIndent()
            this.dockerImage = azureDockerImage.toString()
            dockerImagePlatform = azureDockerImage.Platform
            dockerRunParameters = azureDockerImage.run_parameters
            dockerPull = true
        }
        closeIpSecConnection(scriptPath=scriptPath)
    }

    artifactRules += """
        vpnconfig.ovpn, 
        vpn-config => vpn-config.zip, 
        /etc/ipsec.d => ipsec.d.zip, 
        /etc/ipsec.conf, 
        /etc/ipsec.secrets,
    """.trimIndent()

    agent.add_to_requirements(this)

    params {
        param("terraform.state.key", "$projectName/%teamcity.build.branch%")
    }
})
