# @version 0.2.12
"""
@title Yearn Vault Token Burner
@notice Withdraw from vault and send result to receiver
"""

from vyper.interfaces import ERC20


interface YearnVaultToken:
    def withdraw(amount:uint256): nonpayable
    def token() -> address: view

receiver: public(address)
recovery: public(address)
owner: public(address)
is_killed: public(bool)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)
burnable_coins:public(HashMap[address,address])


event Burn:
    lp_token: address
    amount: uint256
    token0_amount:uint256

@external
def __init__(_receiver:address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver the receiver address to which the resultant tokens will be sent
    @param _recovery Address that tokens are transferred to during an
                     emergency token recovery.
    @param _owner Owner address. Can kill the contract, recover tokens
                  and modify the recovery address.
    @param _emergency_owner Emergency owner address. Can kill the contract
                            and recover tokens.
    """
    self.receiver = _receiver
    self.recovery = _recovery
    self.owner = _owner
    self.emergency_owner = _emergency_owner
    self.burnable_coins[0x986b4AFF588a109c09B50A03f42E4110E29D353F]=0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c # Yearn Vault Curve: sETH -> withdraw and get Curve.fi ETH/sETH LP token
    self.burnable_coins[0xdCD90C7f6324cfa40d7169ef80b12031770B4325]=0x06325440D014e39736583c165C2963BA99fAf14E # Yearn Vault Curve: stETH -> withdraw and get Curve.fi ETH/stETH LP token
    



@external
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` by leaving Sushibar and get Sushi, then send it to receiver
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed
    assert self.burnable_coins[_coin] != ZERO_ADDRESS, "token not burnable"
    
    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)
    result_token:address = self.burnable_coins[_coin]

    if amount != 0:
        YearnVaultToken(_coin).withdraw(amount)
        result_token_amount:uint256 = ERC20(result_token).balanceOf(self)
        assert ERC20(result_token).transfer(self.receiver, result_token_amount)
        log Burn(_coin, amount, result_token_amount)
    return True


@external
def add_burnable_coin(_coin:address) -> bool:
    """
    @notice allow more Yearn Vault CRV LP Tokens to be burned with this burner
    @param _coin Yearn Vault CRV LP Token
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.burnable_coins[_coin] = YearnVaultToken(_coin).token()
    return True
    

@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the recovery address
    @param _coin Token address
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(self.recovery, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_recovery(_recovery: address) -> bool:
    """
    @notice Set the token recovery address
    @param _recovery Token recovery address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.recovery = _recovery

    return True


@external
def set_killed(_is_killed: bool) -> bool:
    """
    @notice Set killed status for this contract
    @dev When killed, the `burn` function cannot be called
    @param _is_killed Killed status
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.is_killed = _is_killed

    return True



@external
def commit_transfer_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.future_owner = _future_owner

    return True


@external
def accept_transfer_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_owner  # dev: only owner
    self.owner = msg.sender

    return True


@external
def commit_transfer_emergency_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.emergency_owner  # dev: only owner
    self.future_emergency_owner = _future_owner

    return True


@external
def accept_transfer_emergency_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_emergency_owner  # dev: only owner
    self.emergency_owner = msg.sender
    return True