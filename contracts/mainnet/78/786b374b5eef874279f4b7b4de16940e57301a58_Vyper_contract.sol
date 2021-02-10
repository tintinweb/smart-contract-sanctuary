# @version 0.2.8
"""
@title Underlying Burner
@notice Converts underlying coins to USDC, adds liquidity to 3pool
        and transfers to fee distributor
"""


from vyper.interfaces import ERC20


interface StableSwap:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256): nonpayable

interface RegistrySwap:
    def exchange_with_best_rate(
        _from: address,
        _to: address,
        _amount: uint256,
        _expected: uint256,
    ) -> uint256: payable

interface AddressProvider:
    def get_address(_id: uint256) -> address: view

interface Synthetix:
    def exchangeWithTracking(
        sourceCurrencyKey: bytes32,
        sourceAmount: uint256,
        destinationCurrencyKey: bytes32,
        originator: address,
        trackingCode: bytes32,
    ): nonpayable
    def settle(currencyKey: bytes32) -> uint256[3]: nonpayable


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

TRIPOOL: constant(address) = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
TRIPOOL_LP: constant(address) = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
TRIPOOL_COINS: constant(address[3]) = [
    0x6B175474E89094C44Da98b954EedeAC495271d0F,
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    0xdAC17F958D2ee523a2206206994597C13D831ec7,
]
USDC: constant(address) = TRIPOOL_COINS[1]

SNX: constant(address) = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
SUSD: constant(address) = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51
SUSD_CURRENCY_KEY: constant(bytes32) = 0x7355534400000000000000000000000000000000000000000000000000000000
TRACKING_CODE: constant(bytes32) = 0x4355525645000000000000000000000000000000000000000000000000000000

is_approved: HashMap[address, HashMap[address, bool]]

receiver: public(address)
recovery: public(address)
is_killed: public(bool)

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
                     Should be set to an `UnderlyingBurner` deployment.
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

    # infinite approval for all 3pool coins
    for coin in TRIPOOL_COINS:
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(TRIPOOL, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)


@payable
@external
def burn(_coin: address) -> bool:
    """
    @notice Receive `_coin` and swap for USDC if not a 3pool asset
    @param _coin Address of the coin being received
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        response: Bytes[32] = raw_call(
            _coin,
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(msg.sender, bytes32),
                convert(self, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)

    # if coin is not in 3pool, swap it for USDC
    if not _coin in TRIPOOL_COINS:
        registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)

        if not self.is_approved[registry_swap][_coin]:
            response: Bytes[32] = raw_call(
                _coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(registry_swap, bytes32),
                    convert(MAX_UINT256, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)
            self.is_approved[registry_swap][_coin] = True

        if _coin == SUSD:
            # if the coin is sUSD, settle prior to exchanging
            Synthetix(SNX).settle(SUSD_CURRENCY_KEY)

        # get actual balance in case of transfer fee or pre-existing balance
        amount = ERC20(_coin).balanceOf(self)
        if amount != 0:
            RegistrySwap(registry_swap).exchange_with_best_rate(_coin, USDC, amount, 0)

    return True


@external
def convert_synth(_currency_key: bytes32, _amount: uint256) -> bool:
    """
    @notice Convert a synth to sUSD
    @dev Synth burners transfer synths to this contract and then conver them
         via this method. In this way we reduce the number of calls to settle.
    @param _currency_key Currency key of the synth to convert
    @param _amount Amount of the synth to convert
    @return bool success
    """
    Synthetix(SNX).exchangeWithTracking(_currency_key, _amount, SUSD_CURRENCY_KEY, self, TRACKING_CODE)
    return True


@external
def execute() -> bool:
    """
    @notice Add liquidity to 3pool and transfer 3CRV to the fee distributor
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    amounts: uint256[3] = [
        ERC20(TRIPOOL_COINS[0]).balanceOf(self),
        ERC20(TRIPOOL_COINS[1]).balanceOf(self),
        ERC20(TRIPOOL_COINS[2]).balanceOf(self),
    ]
    if amounts[0] != 0 and amounts[1] != 0 and amounts[2] != 0:
        StableSwap(TRIPOOL).add_liquidity(amounts, 0)

    amount: uint256 = ERC20(TRIPOOL_LP).balanceOf(self)
    if amount != 0:
        ERC20(TRIPOOL_LP).transfer(self.receiver, amount)

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