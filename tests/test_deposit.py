import pytest
from brownie import chain, accounts

accountNr = 1
depositVal = 10**18


@pytest.fixture(scope="module")
def vault(MultiSigVault, accounts):
    return MultiSigVault.deploy({"from": accounts[0]})


@pytest.fixture(scope="module")
def deposited(vault, accounts):
    return vault.deposit({"from": accounts[accountNr], "value": depositVal})


def test_init_default_admin_role(vault, accounts):
    assert vault.hasRole(vault.DEFAULT_ADMIN_ROLE(), accounts[0]) == 1


def test_init_signer_role(vault, accounts):
    assert vault.hasRole(vault.SIGNER(), accounts[0]) == 1


def test_deposit(vault, deposited):
    assert vault.balance() == 10**18


def test_roles(vault, accounts):
    vault.grantRole(vault.SIGNER(), accounts[accountNr])
    assert vault.hasRole(vault.SIGNER(), accounts[accountNr]) == 1


"""How to check require functions 
def test_roles(vault, accounts):
    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), accounts[accountNr])
    assert vault.hasRole(vault.DEFAULT_ADMIN_ROLE(), accounts[accountNr]) == 0"""


def test_adding_transactions(vault, accounts):
    vault.addTransaction(accounts[3], 5 * 10**17, {"from": accounts[accountNr]})
    assert vault.transactionLog().length == 1


def test_daily_withdrawal(vault, deposited):
    final_time = chain.time() + 40
    balance = vault.balance()
    # 60 * 60 * 24
    vault.withdrawWithTimeConstraints(1 * (10**16))
    chain.mine(timestamp=final_time)
    vault.withdrawWithTimeConstraints(1 * (10**16))
    assert vault.balance() == int((balance) - (2 * (10**16)))
