# @version 0.2.15
"""
@title Yearn Vault Swapper
@license GNU AGPLv3
@author yearn.finance
@notice
  Yearn vault swapper should be used to swap from one crv vault to an other.
"""

from vyper.interfaces import ERC20
N_ALL_COINS: constant(int128) = 2


interface Vault:
    def token() -> address: view
    def apiVersion() -> String[28]: view
    def governance() -> address: view
    def withdraw(
    maxShares: uint256,
    recipient: address
    ) -> uint256: nonpayable
    def deposit(amount: uint256, recipient: address) -> uint256: nonpayable
    def pricePerShare() -> uint256: view
    def transferFrom(f: address, to: address, amount: uint256) -> uint256: nonpayable
    def decimals() -> uint256: view

interface StableSwap:
    def remove_liquidity_one_coin(amount: uint256, i: int128, min_amount: uint256): nonpayable
    def coins(i: uint256) -> address: view
    def add_liquidity(amounts: uint256[N_ALL_COINS], min_mint_amount: uint256): nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[N_ALL_COINS], is_deposit: bool) -> uint256: view

interface Token:
    def minter() -> address: view

interface Registry:
    def get_pool_from_lp_token(lp: address) -> address: view

registry: public(Registry)

@external
def __init__():
    self.registry = Registry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5)

@external
def swap(from_vault: address, to_vault: address, amount: uint256, min_amount_out: uint256):
    """
    @notice swap tokens from one vault to an other
    @dev Remove funds from a vault, move one side of 
    the asset from one curve pool to an other and 
    deposit into the new vault.
    @param from_vault The vault tokens should be taken from
    @param to_vault The vault tokens should be deposited to
    @param amount The amount of tokens you whish to use from the from_vault
    @param min_amount_out The minimal amount of tokens you would expect from the to_vault
    """
    underlying: address = Vault(from_vault).token()
    target: address = Vault(to_vault).token()

    underlying_pool:address = self.registry.get_pool_from_lp_token(underlying)

    target_pool: address = self.registry.get_pool_from_lp_token(target)

    Vault(from_vault).transferFrom(msg.sender, self, amount)

    underlying_amount: uint256 = Vault(from_vault).withdraw(amount, self)
    
    StableSwap(underlying_pool).remove_liquidity_one_coin(underlying_amount, 1, 1)
    
    liquidity_amount: uint256 = ERC20(StableSwap(underlying_pool).coins(1)).balanceOf(self)
    ERC20(StableSwap(underlying_pool).coins(1)).approve(target_pool, liquidity_amount)

    StableSwap(target_pool).add_liquidity([0, liquidity_amount], 1)

    target_amount: uint256 = ERC20(target).balanceOf(self)
    if ERC20(target).allowance(self, to_vault) < target_amount:
        ERC20(target).approve(to_vault, 0)
        ERC20(target).approve(to_vault, MAX_UINT256) 

    out:uint256 = Vault(to_vault).deposit(target_amount, msg.sender)
    assert(out >= min_amount_out)

@view
@external
def estimate_out(from_vault: address, to_vault: address, amount: uint256) -> uint256:
    """
    @notice estimate the amount of tokens out
    @param from_vault The vault tokens should be taken from
    @param to_vault The vault tokens should be deposited to
    @param amount The amount of tokens you whish to use from the from_vault
    @return the amount of token shared expected in the to_vault
    """
    underlying: address = Vault(from_vault).token()
    target: address = Vault(to_vault).token()

    underlying_pool:address = self.registry.get_pool_from_lp_token(underlying)

    target_pool: address = self.registry.get_pool_from_lp_token(target)

    pricePerShareFrom: uint256 = Vault(from_vault).pricePerShare()
    pricePerShareTo: uint256 = Vault(to_vault).pricePerShare()

    amount_out: uint256 = pricePerShareFrom * amount / (10 ** Vault(from_vault).decimals())
    amount_out = StableSwap(underlying_pool).calc_withdraw_one_coin(amount_out, 1)
    amount_out = StableSwap(target_pool).calc_token_amount([0, amount_out], True)
    
    return amount_out * (10 ** Vault(to_vault).decimals()) / pricePerShareTo