import jetbrains.buildServer.configs.kotlin.v2019_2.project
import jetbrains.buildServer.configs.kotlin.v2019_2.version
import settings.TerraformDeployBuild
import settings.TerraformDestroyBuild
import shared.common.Agent
import shared.common.Architecture
import shared.common.CPU
import shared.common.DockerImage
import shared.templates.ArtifactoryDockerLogin
import shared.templates.EnvironmentSetup


/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the


    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2022.04"

project {
    params {
        param("teamcity.ui.settings.readOnly", "true")
        param("env.JIRA_PROJECT_ID", "master")
        param("env.PROJECT_NAME", "ikev2-issue")
        param("env.ARTIFACTORY_URL", "%system.artifactory.registry.url%")
        param("env.TF_VAR_ARM_CLIENT_ID", "%env.ARM_CLIENT_ID%")
        param("env.TF_VAR_ARM_CLIENT_SECRET", "%env.ARM_CLIENT_SECRET%")
        param("env.TF_VAR_ARM_CLIENT_SECRET_ID", "%env.ARM_CLIENT_SECRET_ID%")
        param("env.TF_VAR_ARM_SUBSCRIPTION_ID", "%env.ARM_SUBSCRIPTION_ID%")
        param("env.TF_VAR_ARM_TENANT_ID", "%env.ARM_TENANT_ID%")
        param("env.TF_VAR_ARM_AUTH_CLIENT_ID", "%env.ARM_AUTH_CLIENT_ID%")
        param("env.TF_VAR_ARM_AUTH_CLIENT_SECRET", "%env.ARM_AUTH_CLIENT_SECRET%")
        param("env.TF_VAR_location", "eastus")
        param("env.TF_VAR_hub_vnet", "10.60.32.0/20")
        param("env.TF_VAR_vpn_client_address_pools", "10.60.56.0/24")
        param("env.PIP_EXTRA_INDEX_URL", "%system.pypi-public.server.address.login%")
    }

    template(ArtifactoryDockerLogin)
    template(EnvironmentSetup)

    val pathToScripts = "shared/"
    val dockerImageTag = "2b2587c3ec345c3c9f00f337918accacf65c745d"
    val projectName = "%env.PROJECT_NAME%"

    val terraformDockerImage =
        DockerImage(name = "terraform-x86_64-ubuntu22.04", tag = dockerImageTag)

    val agent = Agent(
        cpu = CPU.LOW,
        architecture = Architecture.AMD64,
        killAfterFirstBuild = true,
    )

    val deployBuild = TerraformDeployBuild(
        dockerImage = terraformDockerImage,
        dockerImageTag = dockerImageTag,
        agent = agent,
        scriptPath = pathToScripts,
        projectName = projectName,
    )
    buildType(deployBuild)

    val destroyBuild = TerraformDestroyBuild(
        dockerImage = terraformDockerImage,
        agent = agent,
        scriptPath = pathToScripts,
        projectName = projectName,
    )
    buildType(destroyBuild)
}