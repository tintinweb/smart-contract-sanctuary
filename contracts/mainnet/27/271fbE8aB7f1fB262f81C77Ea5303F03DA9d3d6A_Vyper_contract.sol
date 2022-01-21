# @version ^0.3.0
# A "zap" to add liquidity and deposit into gauge in one transaction
# (c) Curve.Fi, 2022

MAX_COINS: constant(uint256) = 5
ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

# External Contracts
interface ERC20:
    def transfer(_receiver: address, _amount: uint256): nonpayable
    def transferFrom(_sender: address, _receiver: address, _amount: uint256): nonpayable
    def approve(_spender: address, _amount: uint256): nonpayable
    def decimals() -> uint256: view
    def balanceOf(_owner: address) -> uint256: view
    def allowance(_owner : address, _spender : address) -> uint256: view

interface Pool2:
    def add_liquidity(amounts: uint256[2], min_mint_amount: uint256): payable

interface Pool3:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256): payable

interface Pool4:
    def add_liquidity(amounts: uint256[4], min_mint_amount: uint256): payable

interface Pool5:
    def add_liquidity(amounts: uint256[5], min_mint_amount: uint256): payable

interface PoolUseUnderlying2:
    def add_liquidity(amounts: uint256[2], min_mint_amount: uint256, use_underlying: bool): payable

interface PoolUseUnderlying3:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256, use_underlying: bool): payable

interface PoolUseUnderlying4:
    def add_liquidity(amounts: uint256[4], min_mint_amount: uint256, use_underlying: bool): payable

interface PoolUseUnderlying5:
    def add_liquidity(amounts: uint256[5], min_mint_amount: uint256, use_underlying: bool): payable

interface PoolFactory2:
    def add_liquidity(pool: address, amounts: uint256[2], min_mint_amount: uint256): payable

interface PoolFactory3:
    def add_liquidity(pool: address, amounts: uint256[3], min_mint_amount: uint256): payable

interface PoolFactory4:
    def add_liquidity(pool: address, amounts: uint256[4], min_mint_amount: uint256): payable

interface PoolFactory5:
    def add_liquidity(pool: address, amounts: uint256[5], min_mint_amount: uint256): payable

interface Gauge:
    def deposit(lp_token_amount: uint256, addr: address): payable


allowance: public(HashMap[address, HashMap[address, bool]])
gauge_allowance: HashMap[address, bool]


@internal
def _add_liquidity(
        deposit: address,
        n_coins: uint256,
        amounts: uint256[MAX_COINS],
        min_mint_amount: uint256,
        eth_value: uint256,
        use_underlying: bool,
        pool: address
):
    if pool != ZERO_ADDRESS:
        if n_coins == 2:
            PoolFactory2(deposit).add_liquidity(pool, [amounts[0], amounts[1]], min_mint_amount, value=eth_value)
        elif n_coins == 3:
            PoolFactory3(deposit).add_liquidity(pool, [amounts[0], amounts[1], amounts[2]], min_mint_amount, value=eth_value)
        elif n_coins == 4:
            PoolFactory4(deposit).add_liquidity(pool, [amounts[0], amounts[1], amounts[2], amounts[3]], min_mint_amount, value=eth_value)
        elif n_coins == 5:
            PoolFactory5(deposit).add_liquidity(pool, [amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]], min_mint_amount, value=eth_value)
    elif use_underlying:
        if n_coins == 2:
            PoolUseUnderlying2(deposit).add_liquidity([amounts[0], amounts[1]], min_mint_amount, True, value=eth_value)
        elif n_coins == 3:
            PoolUseUnderlying3(deposit).add_liquidity([amounts[0], amounts[1], amounts[2]], min_mint_amount, True, value=eth_value)
        elif n_coins == 4:
            PoolUseUnderlying4(deposit).add_liquidity([amounts[0], amounts[1], amounts[2], amounts[3]], min_mint_amount, True, value=eth_value)
        elif n_coins == 5:
            PoolUseUnderlying5(deposit).add_liquidity([amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]], min_mint_amount, True, value=eth_value)
    else:
        if n_coins == 2:
            Pool2(deposit).add_liquidity([amounts[0], amounts[1]], min_mint_amount, value=eth_value)
        elif n_coins == 3:
            Pool3(deposit).add_liquidity([amounts[0], amounts[1], amounts[2]], min_mint_amount, value=eth_value)
        elif n_coins == 4:
            Pool4(deposit).add_liquidity([amounts[0], amounts[1], amounts[2], amounts[3]], min_mint_amount, value=eth_value)
        elif n_coins == 5:
            Pool5(deposit).add_liquidity([amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]], min_mint_amount, value=eth_value)


@payable
@external
@nonreentrant('lock')
def deposit_and_stake(
        deposit: address,
        lp_token: address,
        gauge: address,
        n_coins: uint256,
        coins: address[MAX_COINS],
        amounts: uint256[MAX_COINS],
        min_mint_amount: uint256,
        use_underlying: bool, # for aave, saave, ib (use_underlying) and crveth, cvxeth (use_eth)
        pool: address = ZERO_ADDRESS, # for factory
):
    assert n_coins >= 2, 'n_coins must be >=2'
    assert n_coins <= MAX_COINS, 'n_coins must be <=MAX_COINS'

    # Ensure allowance for swap or zap
    for i in range(MAX_COINS):
        if i >= n_coins:
            break

        if coins[i] == ETH_ADDRESS or amounts[i] == 0 or self.allowance[deposit][coins[i]]:
            continue

        self.allowance[deposit][coins[i]] = True
        ERC20(coins[i]).approve(deposit, MAX_UINT256)

    # Ensure allowance for gauge
    if not self.gauge_allowance[gauge]:
        self.gauge_allowance[gauge] = True
        ERC20(lp_token).approve(gauge, MAX_UINT256)

    # Transfer coins from owner
    has_eth: bool = False
    for i in range(MAX_COINS):
        if i >= n_coins:
            break

        if coins[i] == ETH_ADDRESS:
            assert msg.value == amounts[i]
            has_eth = True
            continue

        if amounts[i] > 0:
            # "safeTransferFrom" which works for ERC20s which return bool or not
            _response: Bytes[32] = raw_call(
                coins[i],
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(amounts[i], bytes32),
                ),
                max_outsize=32,
            )  # dev: failed transfer
            if len(_response) > 0:
                assert convert(_response, bool)  # dev: failed transfer

    if not has_eth:
        assert msg.value == 0

    # Reverts if n_coins is wrong
    self._add_liquidity(deposit, n_coins, amounts, min_mint_amount, msg.value, use_underlying, pool)

    lp_token_amount: uint256 = ERC20(lp_token).balanceOf(self)
    assert lp_token_amount > 0 # dev: swap-token mismatch

    Gauge(gauge).deposit(lp_token_amount, msg.sender)


@payable
@external
def __default__():
    pass