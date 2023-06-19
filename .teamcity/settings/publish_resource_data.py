import argparse
import json

from azure.mgmt.containerregistry import ContainerRegistryManagementClient
from azure.storage.blob import BlobClient
from mdl_azure_shared import AzureConfiguration, AzureClientFactory, AzureStateFile


class ResourceDataReader:
    def __init__(self, state_blob_client: BlobClient):
        state = self._read_data_from_blob(state_blob_client)
        self._resources = state["resources"]

    @property
    def resource_group_name(self):
        return self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_resource_group", attribute_name="name"
        )

    @property
    def hub_vnet_name(self):
        return self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_virtual_network",
            resource_name="vnet_hub",
            attribute_name="name",
        )

    @property
    def hub_vnet_id(self):
        return self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_virtual_network",
            resource_name="vnet_hub",
            attribute_name="id",
        )

    @property
    def container_registry_name(self):
        return self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_container_registry", attribute_name="name"
        )

    @property
    def vnet_gateway_name(self):
        return self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_virtual_network_gateway", attribute_name="name"
        )

    @property
    def vpn_address_space(self):
        client_configuration = self._get_attribute_value_from_resource_or_none(
            resource_type="azurerm_virtual_network_gateway",
            attribute_name="vpn_client_configuration",
        )
        return (
            client_configuration[0]["address_space"][0]
            if client_configuration
            else None
        )

    @property
    def dns_resolver_inbound_endpoint_ip(self):
        try:
            ip_configurations = self._get_attribute_value_from_resource_or_none(
                resource_type="azurerm_private_dns_resolver_inbound_endpoint",
                attribute_name="ip_configurations",
            )
            return ip_configurations[0]["private_ip_address"]
        except:
            return None

    def _get_attribute_value_from_resource_or_none(
        self, resource_type, attribute_name, resource_name=None, instance_index=0
    ):
        try:
            resource = self._get_resource(
                resource_type=resource_type, resource_name=resource_name
            )
            return resource["instances"][instance_index]["attributes"][attribute_name]
        except:
            return None

    def _get_resource(self, resource_type, resource_name=None):
        if resource_name is None:
            resource = next(
                filter(lambda r: r["type"] == resource_type, self._resources)
            )
            return resource
        resource = next(
            filter(
                lambda r: r["type"] == resource_type and r["name"] == resource_name,
                self._resources,
            )
        )
        return resource

    @staticmethod
    def _read_data_from_blob(client) -> dict:
        blob_data = client.download_blob()
        data = blob_data.readall()
        json_data = data.decode("utf8").replace("'", '"')
        json_data = json.loads(json_data)
        return json_data


class ResourceDataPublisher:
    def __init__(
        self,
        container_registry_mgmt_client: ContainerRegistryManagementClient,
        resource_data_reader: ResourceDataReader,
    ):
        self._resource_values = {}
        self._container_registry_mgmt_client = container_registry_mgmt_client
        self._state = resource_data_reader

    def acquire_values(self):
        self._resource_values[
            "HUB_RESOURCE_GROUP_NAME"
        ] = self._state.resource_group_name
        self._resource_values["HUB_VNET_NAME"] = self._state.hub_vnet_name
        self._resource_values["HUB_VNET_ID"] = self._state.hub_vnet_id
        self._resource_values["ACR_NAME"] = self._state.container_registry_name
        self._resource_values["VNET_GATEWAY_NAME"] = self._state.vnet_gateway_name
        self._resource_values["VPN_ADDR_SPACE"] = self._state.vpn_address_space
        self._resource_values[
            "PRIVATE_DNS_RESOLVER_IP"
        ] = self._state.dns_resolver_inbound_endpoint_ip

        self._acquire_acr_url()

    def _acquire_acr_url(self):
        if (
            self._resource_values["ACR_NAME"] is not None
            and self._resource_values["HUB_RESOURCE_GROUP_NAME"] is not None
        ):
            container_registries_operations = (
                self._container_registry_mgmt_client.registries
            )
            container_registry = container_registries_operations.get(
                resource_group_name=self._resource_values["HUB_RESOURCE_GROUP_NAME"],
                registry_name=self._resource_values["ACR_NAME"],
            )
            self._resource_values["ACR_URL"] = container_registry.login_server
            self._resource_values[
                "HELM_REPO_WITH_TRAILING_SLASH"
            ] = f"oci://{container_registry.login_server}/helm/"

    def publish_resource_values(self):
        filtered_values = {
            k: v for k, v in self._resource_values.items() if v is not None
        }
        for key in filtered_values:
            print(
                f"##teamcity[setParameter name='env.{key}' value='{self._resource_values[key]}']"
            )


def parse_command_line_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--state-storage-account-name",
        action="store",
        default="%terraform.state.storage.account.name%",
    )
    parser.add_argument(
        "--state-key",
        action="store",
        required=True,
    )
    parser.add_argument(
        "--state-storage-container-name",
        action="store",
        default="%terraform.state.storage.container.name%",
    )
    parser.add_argument(
        "--state-resource-group-name",
        action="store",
        default="%terraform.state.resource.group.name%",
    )
    args = parser.parse_args()
    state_file = AzureStateFile(
        storage_account_name=args.state_storage_account_name,
        state_key=args.state_key,
        storage_container_name=args.state_storage_container_name,
        resource_group_name=args.state_resource_group_name,
    )
    return state_file


if __name__ == "__main__":
    azure_configuration = AzureConfiguration()
    azure_client_factory = AzureClientFactory(azure_configuration)
    state_file = parse_command_line_args()
    state_blob_client = azure_client_factory.create_state_blob_client(state_file)
    container_registry_mgmt_client = ContainerRegistryManagementClient(
        azure_configuration.azure_credential(),
        azure_configuration.data("AZURE_SUBSCRIPTION_ID"),
    )
    state_reader = ResourceDataReader(state_blob_client)
    publisher = ResourceDataPublisher(container_registry_mgmt_client, state_reader)

    publisher.acquire_values()
    publisher.publish_resource_values()
