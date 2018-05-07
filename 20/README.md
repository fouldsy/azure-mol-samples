This sample script creates an Azure Iot Hub, device identity, and consumer group. This Hub can be used for a simulated, or real, Azure IoT Device.

The script also then creates an Azure Web App, and configures some application settings to populate the IoT Hub connection string and consumer group. These settings allow the Web App to receive information from the IoT device.

Websockets are also enabled for the Web App to automatically update with real-time information from the IoT device.