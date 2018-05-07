These samples expect you to run Python 2.7 with the Azure Python SDK for Python. Hopefully the SDK becomes more stable with Python 3.x.

When working in the Azure Cloud Shell, run the following commands to install the appropriate packages required by these samples:

```
pip2 install --user azurerm azure-cosmosdb-table
```

To then run each sample in the Azure Cloud Shell, make sure you use the Python 2.7 binary. As an example:

```
python2.7 storage_table_demo.py
```