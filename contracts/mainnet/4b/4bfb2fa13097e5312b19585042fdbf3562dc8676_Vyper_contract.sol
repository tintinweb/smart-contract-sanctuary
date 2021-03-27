# @version 0.2.11
"""
@title Tokenized Gauge Wrapper: Unit Protocol Edition
@author Curve Finance
@license MIT
@notice Tokenizes gauge deposits to allow claiming of CRV when
        deposited as a collateral within the unit.xyz Vault
"""

from vyper.interfaces import ERC20

implements: ERC20


interface LiquidityGauge:
    def lp_token() -> address: view
    def minter() -> address: view
    def crv_token() -> address: view
    def deposit(_value: uint256): nonpayable
    def withdraw(_value: uint256): nonpayable
    def claimable_tokens(addr: address) -> uint256: nonpayable

interface Minter:
    def mint(gauge_addr: address): nonpayable

interface UnitVault:
    def collaterals(asset: address, user: address) -> uint256: nonpayable


event Deposit:
    provider: indexed(address)
    value: uint256

event Withdraw:
    provider: indexed(address)
    value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256


minter: public(address)
crv_token: public(address)
lp_token: public(address)
gauge: public(address)

balanceOf: public(HashMap[address, uint256])
depositedBalanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
allowances: HashMap[address, HashMap[address, uint256]]

name: public(String[64])
symbol: public(String[32])

# caller -> recipient -> can deposit?
approved_to_deposit: public(HashMap[address, HashMap[address, bool]])

crv_integral: uint256
crv_integral_for: HashMap[address, uint256]
claimable_crv: public(HashMap[address, uint256])

# [uint216 claimable balance][uint40 timestamp]
last_claim_data: uint256

# https://github.com/unitprotocol/core/blob/master/contracts/Vault.sol
UNIT_VAULT: constant(address) = 0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19


@external
def __init__(
    _name: String[64],
    _symbol: String[32],
    _gauge: address,
):
    """
    @notice Contract constructor
    @param _name Token full name
    @param _symbol Token symbol
    @param _gauge Liquidity gauge contract address
    """

    self.name = _name
    self.symbol = _symbol

    lp_token: address = LiquidityGauge(_gauge).lp_token()
    ERC20(lp_token).approve(_gauge, MAX_UINT256)

    self.minter = LiquidityGauge(_gauge).minter()
    self.crv_token = LiquidityGauge(_gauge).crv_token()
    self.lp_token = lp_token
    self.gauge = _gauge


@external
def decimals() -> uint256:
    return 18


@internal
def _checkpoint(_user_addresses: address[2]):
    claim_data: uint256 = self.last_claim_data
    I: uint256 = self.crv_integral

    if block.timestamp != claim_data % 2**40:
        last_claimable: uint256 = shift(claim_data, -40)
        claimable: uint256 = LiquidityGauge(self.gauge).claimable_tokens(self)
        d_reward: uint256 = claimable - last_claimable
        total_balance: uint256 = self.totalSupply
        if total_balance > 0:
            I += 10 ** 18 * d_reward / total_balance
            self.crv_integral = I
        self.last_claim_data = block.timestamp + shift(claimable, 40)

    for addr in _user_addresses:
        if addr in [ZERO_ADDRESS, UNIT_VAULT]:
            # do not calculate an integral for the vault to ensure it cannot ever claim
            continue
        user_integral: uint256 = self.crv_integral_for[addr]
        if user_integral < I:
            user_balance: uint256 = self.balanceOf[addr] + self.depositedBalanceOf[addr]
            self.claimable_crv[addr] += user_balance * (I - user_integral) / 10 ** 18
            self.crv_integral_for[addr] = I


@external
def user_checkpoint(addr: address) -> bool:
    """
    @notice Record a checkpoint for `addr`
    @param addr User address
    @return bool success
    """
    self._checkpoint([addr, ZERO_ADDRESS])
    return True


@external
def claimable_tokens(addr: address) -> uint256:
    """
    @notice Get the number of claimable tokens per user
    @dev This function should be manually changed to "view" in the ABI
    @return uint256 number of claimable tokens per user
    """
    self._checkpoint([addr, ZERO_ADDRESS])

    return self.claimable_crv[addr]


@external
@nonreentrant('lock')
def claim_tokens(addr: address = msg.sender):
    """
    @notice Claim mintable CRV
    @param addr Address to claim for
    """
    self._checkpoint([addr, ZERO_ADDRESS])

    crv_token: address = self.crv_token
    claimable: uint256 = self.claimable_crv[addr]
    self.claimable_crv[addr] = 0

    if ERC20(crv_token).balanceOf(self) < claimable:
        Minter(self.minter).mint(self.gauge)
        self.last_claim_data = block.timestamp

    ERC20(crv_token).transfer(addr, claimable)


@external
def set_approve_deposit(addr: address, can_deposit: bool):
    """
    @notice Set whether `addr` can deposit tokens for `msg.sender`
    @param addr Address to set approval on
    @param can_deposit bool - can this account deposit for `msg.sender`?
    """
    self.approved_to_deposit[addr][msg.sender] = can_deposit


@external
@nonreentrant('lock')
def deposit(_value: uint256, addr: address = msg.sender):
    """
    @notice Deposit `_value` LP tokens
    @param _value Number of tokens to deposit
    @param addr Address to deposit for
    """
    if addr != msg.sender:
        assert self.approved_to_deposit[msg.sender][addr], "Not approved"

    self._checkpoint([addr, ZERO_ADDRESS])

    if _value != 0:
        self.balanceOf[addr] += _value
        self.totalSupply += _value

        ERC20(self.lp_token).transferFrom(msg.sender, self, _value)
        LiquidityGauge(self.gauge).deposit(_value)

    log Deposit(addr, _value)
    log Transfer(ZERO_ADDRESS, addr, _value)


@external
@nonreentrant('lock')
def withdraw(_value: uint256):
    """
    @notice Withdraw `_value` LP tokens
    @param _value Number of tokens to withdraw
    """
    self._checkpoint([msg.sender, ZERO_ADDRESS])

    if _value != 0:
        self.balanceOf[msg.sender] -= _value
        self.totalSupply -= _value

        LiquidityGauge(self.gauge).withdraw(_value)
        ERC20(self.lp_token).transfer(msg.sender, _value)

    log Withdraw(msg.sender, _value)
    log Transfer(msg.sender, ZERO_ADDRESS, _value)


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner The address which owns the funds.
    @param _spender The address which will spend the funds.
    @return An uint256 specifying the amount of tokens still available for the spender.
    """
    return self.allowances[_owner][_spender]


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    self._checkpoint([_from, _to])

    if _value != 0:
        self.balanceOf[_from] -= _value
        self.balanceOf[_to] += _value

    log Transfer(_from, _to, _value)


@external
@nonreentrant('lock')
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self._transfer(msg.sender, _to, _value)

    if msg.sender == UNIT_VAULT:
        # when the transfer originates from the vault, consider it a withdrawal
        # and adjust `depositedBalance` accordingly
        self.depositedBalanceOf[_to] = UnitVault(UNIT_VAULT).collaterals(self, _to)

    return True


@external
@nonreentrant('lock')
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    _allowance: uint256 = self.allowances[_from][msg.sender]
    if _allowance != MAX_UINT256:
        self.allowances[_from][msg.sender] = _allowance - _value

    self._transfer(_from, _to, _value)

    if _to == UNIT_VAULT:
        # when a `transferFrom` directs into the vault, consider it a deposited
        # balance so that the recipient may still claim CRV from it
        self.depositedBalanceOf[_from] += _value

    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
    @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {increaseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will transfer the funds
    @param _value The amount of tokens that may be transferred
    @return bool success
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)

    return True


@external
def increaseAllowance(_spender: address, _added_value: uint256) -> bool:
    """
    @notice Increase the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _added_value The amount of to increase the allowance
    @return bool success
    """
    allowance: uint256 = self.allowances[msg.sender][_spender] + _added_value
    self.allowances[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True


@external
def decreaseAllowance(_spender: address, _subtracted_value: uint256) -> bool:
    """
    @notice Decrease the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _subtracted_value The amount of to decrease the allowance
    @return bool success
    """
    allowance: uint256 = self.allowances[msg.sender][_spender] - _subtracted_value
    self.allowances[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True