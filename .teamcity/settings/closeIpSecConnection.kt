package settings

import jetbrains.buildServer.configs.kotlin.v2019_2.BuildStep
import jetbrains.buildServer.configs.kotlin.v2019_2.BuildSteps
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.ScriptBuildStep
import shared.common.build_steps.script_file

fun BuildSteps.closeIpSecConnection(scriptPath: String): ScriptBuildStep {
    val step = script_file(
        name = "Close IPSec connection",
        script_paths = listOf(
            "settings/close_ikev2_connection.sh",
            "$scriptPath/vpn/scripts/restore_hosts_file.sh",
        ),
    )

    step.executionMode = BuildStep.ExecutionMode.ALWAYS

    return step
}