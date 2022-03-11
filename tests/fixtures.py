import pytest
import brownie

@pytest.fixture(scope="module")
def vault(MultiSigVault, accounts):
    return MultiSigVault.deploy({'from': accounts[0]})