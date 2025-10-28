# pragma version 0.4.3 
"""
@license MIT 
@title Buy Me A Coffee!
@author Jund
@notice This contract is for creating a sample funding contract
"""
from interfaces import AggregatorV3Interface
import get_price_module

# Constants & Immutables
MINIMUM_USD: public(constant(uint256)) = as_wei_value(5, "ether")
PRICE_FEED: public(immutable(AggregatorV3Interface)) 
OWNER: public(immutable(address)) 

# Storage
funders: public(DynArray[address, 1000])
funder_to_amount_funded: public(HashMap[address, uint256])

@deploy
def __init__(price_feed: address):
    PRICE_FEED = AggregatorV3Interface(price_feed)
    OWNER = msg.sender

@external
@payable
def fund():
    self._fund()

@internal
@payable
def _fund():
    usd_value_of_eth: uint256 = get_price_module._get_eth_to_usd_rate(PRICE_FEED, msg.value)
    assert usd_value_of_eth >= MINIMUM_USD, "You must spend more ETH!"
    self.funders.append(msg.sender)
    self.funder_to_amount_funded[msg.sender] += msg.value

@external
def withdraw():
    assert msg.sender == OWNER, "Not the contract owner!"
    raw_call(OWNER, b"", value = self.balance)
    for funder: address in self.funders:
        self.funder_to_amount_funded[funder] = 0
    self.funders = []

@external 
@view 
def get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    return get_price_module._get_eth_to_usd_rate(PRICE_FEED, eth_amount)

@external 
@payable 
def __default__():
    self._fund()
