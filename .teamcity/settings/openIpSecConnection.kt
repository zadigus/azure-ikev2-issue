package settings

import jetbrains.buildServer.configs.kotlin.v2019_2.BuildSteps
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.ScriptBuildStep
import shared.common.build_steps.script_file

fun BuildSteps.openIpSecConnection(scriptPath: String, workingDir: String): ScriptBuildStep {
    return script_file(
        name = "Open IPSec Connection",
        script_paths = listOf(
            "$scriptPath/vpn/scripts/backup_hosts_file.sh",
            "$scriptPath/vpn/scripts/add_amazon_hosts.sh",
            "settings/open_ikev2_connection.sh",
        ),
        working_directory = workingDir,
    )
}