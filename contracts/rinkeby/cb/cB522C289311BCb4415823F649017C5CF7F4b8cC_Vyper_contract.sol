# @version 0.3.0
"""
@title Pollen Token
@license MIT
@notice Pollen collected by bees
"""


interface Bee:
    def balanceOf(_owner: address) -> uint256: view


event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event Burn:
    _from: indexed(address)
    _value: uint256


# Timestamp adjustment needed for halving
struct Adjustment:
    ts: uint256
    adjusted: uint256


BASE: constant(uint256) = 10 ** 18

HALVING_PERIOD: constant(uint256) = 6 * 4 * 7 * 86400  # 6 months
MINT_PERIODS: constant(uint256) = 4 * 2  # 4 years
COLLECT_PERIOD: constant(uint256) = 2 * 3600  # 2 hours
mint_start: uint256
adjusted_ts: Adjustment[MINT_PERIODS]
last_ts: Adjustment

INITIAL_SUPPLY: constant(uint256) = 1023912500 * BASE

balanceOf: public(HashMap[address, uint256])
last_settlement_of: HashMap[address, uint256]

allowance: public(HashMap[address, HashMap[address, uint256]])

totalSupply: public(uint256)

bee: public(address)


@external
def __init__(_bee: address):
    self.bee = _bee

    ts: uint256 = block.timestamp
    adjusted: uint256 = ts
    self.adjusted_ts[0].ts = ts
    self.adjusted_ts[0].adjusted = ts
    power: uint256 = 1
    for i in range(1, MINT_PERIODS):
        ts += HALVING_PERIOD
        adjusted += HALVING_PERIOD / power
        power *= 2
        self.adjusted_ts[i].ts = ts
        self.adjusted_ts[i].adjusted = adjusted
    self.last_ts.ts = ts + HALVING_PERIOD
    self.last_ts.adjusted = adjusted + HALVING_PERIOD / power

    # Provide initial supply
    self.balanceOf[msg.sender] = INITIAL_SUPPLY
    self.totalSupply = INITIAL_SUPPLY
    log Transfer(ZERO_ADDRESS, msg.sender, INITIAL_SUPPLY)


@external
@view
def name() -> String[64]:
    """
    @return The name of this token
    """
    return "Pollen"


@external
@view
def symbol() -> String[32]:
    """
    @return An abbreviated name for this token
    """
    return "POLLEN"


@external
@view
def decimals() -> uint256:
    """
    @return The number of decimals this token uses
    """
    return 18


@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @param _spender Address to be approved for `_value` of tokens
    @param _value Amount of tokens to approve
    @return True if approve was successful
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def increaseAllowance(_spender: address, _value: uint256) -> bool:
    """
    @param _spender Address to be approved for more `_value` of tokens
    @param _value Amount of tokens to add to approved
    @return True if increaseAllowance was successful
    """
    self.allowance[msg.sender][_spender] += _value
    log Approval(msg.sender, _spender, self.allowance[msg.sender][_spender])
    return True


@external
def decreaseAllowance(_spender: address, _value: uint256) -> bool:
    """
    @param _spender Address to be approved for less `_value` of tokens
    @param _value Amount of tokens to remove from approved
    @return True if decreaseAllowance was successful
    """
    self.allowance[msg.sender][_spender] -= _value
    log Approval(msg.sender, _spender, self.allowance[msg.sender][_spender])
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    log Transfer(_from, _to, _value)
    return True


@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @param _to Address of the new owner
    @param _value Amount of tokens to transfer
    @return True if transfer was successful
    """
    return self._transfer(msg.sender, _to, _value)


@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @dev Throws unless `msg.sender` is the approved address `_value` of token
    @param _from Address of current owner
    @param _to Address of the new owner
    @param _value Amount of tokens to be transferred
    @return True if transfer was successful
    """
    self.allowance[_from][msg.sender] -= _value
    return self._transfer(_from, _to, _value)


@internal
def _burn(_from: address, _value: uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.totalSupply -= _value
    log Transfer(_from, ZERO_ADDRESS, _value)
    return True


@external
def burn(_value: uint256) -> bool:
    """
    @param _value Amount of tokens to burn
    @return True if burn was successful
    """
    return self._burn(msg.sender, _value)


@external
def burnFrom(_from: address, _value: uint256) -> bool:
    """
    @dev Throws unless `msg.sender` is the approved address `_value` of token
    @param _from Address of current owner
    @param _value Amount of tokens to burn
    @return True if burn was successful
    """
    self.allowance[_from][msg.sender] -= _value
    return self._burn(_from, _value)


@internal
@view
def _adjusted_ts(_ts: uint256) -> uint256:
    last_ts: Adjustment = self.last_ts
    if _ts >= last_ts.ts:
        return last_ts.adjusted
    adjusted_ts: Adjustment[MINT_PERIODS] = self.adjusted_ts
    power: uint256 = 1
    for i in range(MINT_PERIODS):
        if adjusted_ts[i].ts + HALVING_PERIOD > _ts:
            return adjusted_ts[i].adjusted + (_ts - adjusted_ts[i].ts) / power
        power *= 2
    return 0  # unreachable


@internal
@view
def _to_settle(_owner: address, settlement_ts: uint256) -> uint256:
    last_settlement_ts: uint256 = self.last_settlement_of[_owner]
    if last_settlement_ts == 0 or last_settlement_ts >= self.last_ts.ts:
        # Initial settle or mint finished
        return 0

    n: uint256 = Bee(self.bee).balanceOf(_owner)
    rate: uint256 = 50 * n + min(n * (n - 1), 2500)

    period: uint256 = self._adjusted_ts(settlement_ts) - self._adjusted_ts(last_settlement_ts)

    return rate * BASE * period / COLLECT_PERIOD


@external
@view
def to_settle(_owner: address, settlement_ts: uint256 = block.timestamp) -> uint256:
    """
    @notice Amount of token `_owner` will farm by specific time
    @param _owner Address of owner of settling tokens
    @param settlement_ts Timestamp at which the settle will be maintained
    @return Amount of token
    """
    return self._to_settle(_owner, settlement_ts)


@external
@nonpayable
def settle(_owner: address = msg.sender) -> uint256:
    """
    @notice Settle all collected tokens
    @param _owner Address of the collected tokens
    """
    settlement_ts: uint256 = block.timestamp
    to_settle: uint256 = self._to_settle(_owner, settlement_ts)
    self.last_settlement_of[_owner] = settlement_ts
    self.balanceOf[_owner] += to_settle

    self.totalSupply += to_settle
    log Transfer(ZERO_ADDRESS, _owner, to_settle)
    return to_settle