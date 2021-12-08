from brownie import Lottery, accounts, config, network
from scripts.deploy_lottery import deploy_lottery
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS
from web3 import Web3
import pytest

def test_get_entrance_fee():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip()
    # Arrange
    lottery = deploy_lottery()
    # Act
    expected_fee = Web3.toWei(0.0125, "ether")
    entrance_fee = lottery.getEntranceFee()
    # Assert
    assert expected_fee == entrance_fee # 7:54

