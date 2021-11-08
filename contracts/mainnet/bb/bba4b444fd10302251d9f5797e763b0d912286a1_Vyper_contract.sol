# @version 0.2.16
"""
@title "Zap" Depositer for permissionless ibBTC metapools
@author [email protected]
"""

interface ERC20:
    def transfer(_receiver: address, _amount: uint256): nonpayable
    def transferFrom(_sender: address, _receiver: address, _amount: uint256): nonpayable
    def approve(_spender: address, _amount: uint256): nonpayable
    def decimals() -> uint256: view
    def balanceOf(_owner: address) -> uint256: view

interface CurveMeta:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256, _receiver: address) -> uint256: nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]) -> uint256[N_COINS]: nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256, _receiver: address) -> uint256: nonpayable
    def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256) -> uint256: nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256: view
    def exchange_underlying(i: int128, j: int128, _dx: uint256, _min_dy: uint256, _receiver: address) -> uint256: nonpayable
    def coins(i: uint256) -> address: view

interface CurveBase:
    def add_liquidity(amounts: uint256[BASE_N_COINS], min_mint_amount: uint256): nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[BASE_N_COINS]): nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256): nonpayable
    def remove_liquidity_imbalance(amounts: uint256[BASE_N_COINS], max_burn_amount: uint256): nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[BASE_N_COINS], deposit: bool) -> uint256: view
    def coins(i: int128) -> address: view
    def fee() -> uint256: view

interface WrappedIbbtcEth:
    def mint(_shares: uint256): nonpayable
    def burn(_shares: uint256): nonpayable
    def balanceOf(_user: address) -> uint256: view
    def sharesOf(_user: address) -> uint256: view
    def balanceToShares(_balance: uint256) -> uint256: view
    def sharesToBalance(_balance: uint256) -> uint256: view


N_COINS: constant(int128) = 2 # wibbtc, crvRenWSBTC
MAX_COIN: constant(int128) = N_COINS-1
BASE_N_COINS: constant(int128) = 3 # renBTC, wBTC, sBTC
N_ALL_COINS: constant(int128) = N_COINS + BASE_N_COINS - 1

BASE_POOL: constant(address) = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714
BASE_LP_TOKEN: constant(address) = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3
BASE_COINS: constant(address[3]) = [
    0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D,  # renBTC
    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,  # wBTC
    0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6,  # sBTC
]

FEE_DENOMINATOR: constant(uint256) = 10 ** 10
FEE_IMPRECISION: constant(uint256) = 100 * 10 ** 8  # % of the fee

IBBTC_WRAPPER_PROXY: constant(address) = 0x8751D4196027d4e6DA63716fA7786B5174F04C15
WIBBTC_TOKEN: constant(address) = 0x8751D4196027d4e6DA63716fA7786B5174F04C15
IBBTC_TOKEN: constant(address) = 0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F

# coin -> pool -> is approved to transfer?
is_approved: HashMap[address, HashMap[address, bool]]


@external
def __init__():
    """
    @notice Contract constructor
    """
    base_coins: address[3] = BASE_COINS
    for coin in base_coins:
        ERC20(coin).approve(BASE_POOL, MAX_UINT256)

    ERC20(IBBTC_TOKEN).approve(IBBTC_WRAPPER_PROXY, MAX_UINT256)

@external
def add_liquidity(
    _pool: address,
    _deposit_amounts: uint256[N_ALL_COINS],
    _min_mint_amount: uint256,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Wrap underlying coins and deposit them into `_pool`
    @param _pool Address of the pool to deposit into
    @param _deposit_amounts List of amounts of underlying coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _receiver Address that receives the LP tokens
    @return Amount of LP tokens received by depositing
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    deposit_base: bool = False
    base_coins: address[3] = BASE_COINS

    # for ibbtc deposit
    if _deposit_amounts[0] != 0:
        coin: address = IBBTC_TOKEN

        ERC20(coin).transferFrom(msg.sender, self, _deposit_amounts[0])
        
        before_balance_wibbtc: uint256 = WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceOf(self)
        WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).mint(_deposit_amounts[0])
        after_balance_wibbtc: uint256 = WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceOf(self)
        
        meta_amounts[0] = after_balance_wibbtc - before_balance_wibbtc

        # approve wibbtc for _pool to use
        if not self.is_approved[WIBBTC_TOKEN][_pool]:
            ERC20(WIBBTC_TOKEN).approve(_pool, MAX_UINT256)
            self.is_approved[WIBBTC_TOKEN][_pool] = True

    # for all coins(other than ibbtc)
    for i in range(1, N_ALL_COINS):
        amount: uint256 = _deposit_amounts[i]
        if amount == 0:
            continue
        deposit_base = True
        base_idx: uint256 = i - 1
        coin: address = base_coins[base_idx]

        ERC20(coin).transferFrom(msg.sender, self, amount)
        # Handle potential Tether fees
        if i == N_ALL_COINS - 1:
            base_amounts[base_idx] = ERC20(coin).balanceOf(self)
        else:
            base_amounts[base_idx] = amount

    # Deposit to the base pool
    if deposit_base:
        coin: address = BASE_LP_TOKEN
        CurveBase(BASE_POOL).add_liquidity(base_amounts, 0)
        meta_amounts[MAX_COIN] = ERC20(coin).balanceOf(self)
        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, MAX_UINT256)
            self.is_approved[coin][_pool] = True

    # Deposit to the meta pool
    return CurveMeta(_pool).add_liquidity(meta_amounts, _min_mint_amount, _receiver)


@external
def remove_liquidity(
    _pool: address,
    _burn_amount: uint256,
    _min_amounts: uint256[N_ALL_COINS],
    _receiver: address = msg.sender
) -> uint256[N_ALL_COINS]:
    """
    @notice Withdraw and unwrap coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _pool Address of the pool to deposit into
    @param _burn_amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _receiver Address that receives the LP tokens
    @return List of amounts of underlying coins that were withdrawn
    """
    ERC20(_pool).transferFrom(msg.sender, self, _burn_amount)

    min_amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts: uint256[N_ALL_COINS] = empty(uint256[N_ALL_COINS])

    # Withdraw from meta
    meta_received: uint256[N_COINS] = CurveMeta(_pool).remove_liquidity(
        _burn_amount,
        [_min_amounts[0], convert(0, uint256)]
    )

    # convert wibbtc to ibbtc
    coin: address = CurveMeta(_pool).coins(0)
    
    before_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
    WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).burn(WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceToShares(meta_received[0]))
    after_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
    
    amounts[0] = after_ibbtc_balance - before_ibbtc_balance
    ERC20(IBBTC_TOKEN).transfer(_receiver, amounts[0])
    
    # Withdraw from base
    for i in range(BASE_N_COINS):
        min_amounts_base[i] = _min_amounts[MAX_COIN+i]
    CurveBase(BASE_POOL).remove_liquidity(meta_received[1], min_amounts_base)

    base_coins: address[BASE_N_COINS] = BASE_COINS
    for i in range(1, N_ALL_COINS):
        coin = base_coins[i-1]
        amounts[i] = ERC20(coin).balanceOf(self)
        ERC20(coin).transfer(_receiver, amounts[i])

    return amounts


@external
def remove_liquidity_one_coin(
    _pool: address,
    _burn_amount: uint256,
    i: int128,
    _min_amount: uint256,
    _receiver: address=msg.sender
) -> uint256:
    """
    @notice Withdraw and unwrap a single coin from the pool
    @param _pool Address of the pool to deposit into
    @param _burn_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of underlying coin to receive
    @param _receiver Address that receives the LP tokens
    @return Amount of underlying coin received
    """
    ERC20(_pool).transferFrom(msg.sender, self, _burn_amount)
    coin_amount: uint256 = 0

    if i == 0:
        coin_amount = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, i, _min_amount, self)
        
        before_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
        WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).burn(WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceToShares(coin_amount))
        after_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
        
        coin_amount = after_ibbtc_balance - before_ibbtc_balance
        ERC20(IBBTC_TOKEN).transfer(_receiver, coin_amount)
    else:
        base_coins: address[BASE_N_COINS] = BASE_COINS
        coin: address = base_coins[i - MAX_COIN]
        # Withdraw a base pool coin
        coin_amount = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, MAX_COIN, 0, self)
        CurveBase(BASE_POOL).remove_liquidity_one_coin(coin_amount, i-MAX_COIN, _min_amount)
        coin_amount = ERC20(coin).balanceOf(self)
        ERC20(coin).transfer(_receiver, coin_amount)

    return coin_amount

@external
def remove_liquidity_imbalance(
    _pool: address,
    _amounts: uint256[N_ALL_COINS],
    _max_burn_amount: uint256,
    _receiver: address=msg.sender
) -> uint256:
    """
    @notice Withdraw coins from the pool in an imbalanced amount
    @param _pool Address of the pool to deposit into
    @param _amounts List of amounts of underlying coins to withdraw
    @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
    @param _receiver Address that receives the LP tokens
    @return Actual amount of the LP token burned in the withdrawal
    """
    fee: uint256 = CurveBase(BASE_POOL).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
    fee += fee * FEE_IMPRECISION / FEE_DENOMINATOR  # Overcharge to account for imprecision

    # Transfer the LP token in
    ERC20(_pool).transferFrom(msg.sender, self, _max_burn_amount)

    withdraw_base: bool = False
    amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts_meta: uint256[N_COINS] = empty(uint256[N_COINS])

    # determine amounts to withdraw from base pool
    for i in range(BASE_N_COINS):
        amount: uint256 = _amounts[MAX_COIN + i]
        if amount != 0:
            amounts_base[i] = amount
            withdraw_base = True

    # determine amounts to withdraw from metapool
    amounts_meta[0] = _amounts[0]
    if withdraw_base:
        amounts_meta[MAX_COIN] = CurveBase(BASE_POOL).calc_token_amount(amounts_base, False)
        amounts_meta[MAX_COIN] += amounts_meta[MAX_COIN] * fee / FEE_DENOMINATOR + 1

    # withdraw from metapool and return the remaining LP tokens
    burn_amount: uint256 = CurveMeta(_pool).remove_liquidity_imbalance(amounts_meta, _max_burn_amount)
    ERC20(_pool).transfer(msg.sender, _max_burn_amount - burn_amount)

    # withdraw from base pool
    if withdraw_base:
        CurveBase(BASE_POOL).remove_liquidity_imbalance(amounts_base, amounts_meta[MAX_COIN])
        coin: address = BASE_LP_TOKEN
        leftover: uint256 = ERC20(coin).balanceOf(self)

        if leftover > 0:
            # if some base pool LP tokens remain, re-deposit them for the caller
            if not self.is_approved[coin][_pool]:
                ERC20(coin).approve(_pool, MAX_UINT256)
                self.is_approved[coin][_pool] = True
            burn_amount -= CurveMeta(_pool).add_liquidity([convert(0, uint256), leftover], 0, msg.sender)

        # transfer withdrawn base pool tokens to caller
        base_coins: address[BASE_N_COINS] = BASE_COINS
        for i in range(BASE_N_COINS):
            ERC20(base_coins[i]).transfer(_receiver, amounts_base[i])

    # transfer withdrawn metapool tokens to caller
    if _amounts[0] > 0:
        coin: address = CurveMeta(_pool).coins(0)
        
        before_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
        WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).burn(WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceToShares(_amounts[0]))
        after_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
        
        ERC20(coin).transfer(_receiver, after_ibbtc_balance - before_ibbtc_balance)

    return burn_amount


@view
@external
def calc_withdraw_one_coin(_pool: address, _token_amount: uint256, i: int128) -> uint256:
    """
    @notice Calculate the amount received when withdrawing and unwrapping a single coin
    @param _pool Address of the pool to deposit into
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the underlying coin to withdraw
    @return Amount of coin received
    """
    if i < MAX_COIN:
        # we get balance we convert it into ibbtc shares we will receive.
        return WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceToShares(CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, i))
    else:
        _base_tokens: uint256 = CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, MAX_COIN)
        return CurveBase(BASE_POOL).calc_withdraw_one_coin(_base_tokens, i-MAX_COIN)


@view
@external
def calc_token_amount(_pool: address, _amounts: uint256[N_ALL_COINS], _is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _pool Address of the pool to deposit into
    @param _amounts Amount of each underlying coin being deposited
    @param _is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])

    meta_amounts[0] = WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).sharesToBalance(_amounts[0])
    for i in range(BASE_N_COINS):
        base_amounts[i] = _amounts[i + MAX_COIN]

    base_tokens: uint256 = CurveBase(BASE_POOL).calc_token_amount(base_amounts, _is_deposit)
    meta_amounts[MAX_COIN] = base_tokens

    return CurveMeta(_pool).calc_token_amount(meta_amounts, _is_deposit)

@external
def exchange_underlying(_pool: address, i: int128, j: int128, _dx: uint256, _min_dy: uint256, _receiver: address = msg.sender) -> uint256:
    """
    @notice swaps and wrap/unwrap coin
    """
    input_amount: uint256 = _dx

    if i==0:
        ERC20(IBBTC_TOKEN).transferFrom(msg.sender, self, _dx)
 
        before_balance_wibbtc: uint256 = WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceOf(self)
        WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).mint(_dx)
        after_balance_wibbtc: uint256 = WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceOf(self)

        input_amount = after_balance_wibbtc - before_balance_wibbtc
    else:   
        base_coins: address[BASE_N_COINS] = BASE_COINS
        coin: address = base_coins[i - MAX_COIN]
        ERC20(coin).transferFrom(msg.sender, self, _dx)

        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, MAX_UINT256)
            self.is_approved[coin][_pool] = True

    output_amount: uint256 = CurveMeta(_pool).exchange_underlying(i, j, input_amount, _min_dy, self)

    if j==0:
        
        before_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)
        WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).burn(WrappedIbbtcEth(IBBTC_WRAPPER_PROXY).balanceToShares(output_amount))
        after_ibbtc_balance: uint256 = ERC20(IBBTC_TOKEN).balanceOf(self)

        output_amount = after_ibbtc_balance - before_ibbtc_balance

        ERC20(IBBTC_TOKEN).transfer(_receiver, output_amount)
    else:
        base_coins: address[BASE_N_COINS] = BASE_COINS
        coin: address = base_coins[j - MAX_COIN]
        ERC20(coin).transfer(_receiver, output_amount)

    return output_amount