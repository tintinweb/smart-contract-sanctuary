# @version 0.2.4
# (c) Curve.Fi, 2020
# Pool for DAI/USDC/USDT

from vyper.interfaces import ERC20

interface CurveToken:
    def totalSupply() -> uint256: view
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burnFrom(_to: address, _value: uint256) -> bool: nonpayable


N_COINS: constant(int128) = 3  # <- change

FEE_DENOMINATOR: constant(uint256) = 10 ** 10 



@pure
@internal
def get_D(xp: uint256[N_COINS], amp: uint256) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = amp * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D



@view
@internal
def get_y_D(A_: uint256, i: int128, xp: uint256[N_COINS], D: uint256) -> uint256:
    
    assert i >= 0  # dev: i below zero
    assert i < N_COINS  # dev: i above N_COINS

    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = A_ * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i != i:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D / (Ann * N_COINS)
    b: uint256 = S_ + D / Ann
    y_prev: uint256 = 0
    y: uint256 = D
    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                break
        else:
            if y_prev - y <= 1:
                break
    return y



@view
@external
def calc_token_amount(token_amount: uint256, amp: uint256, amounts: uint256[N_COINS],balances: uint256[3], deposit: bool) -> uint256:
   # amounts n balances dono 18 me hone chahiye
    _balances: uint256[3] = balances
    D0: uint256 = self.get_D(_balances, amp)
    for i in range(N_COINS):
        if deposit:
            _balances[i] += amounts[i]
        else:
            _balances[i] -= amounts[i]
    D1: uint256 = self.get_D(_balances, amp)
    diff: uint256 = 0
    if deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * token_amount / D0

@view
@external
def add_liquidity(old_balances:uint256[3], token_supply:uint256, amp:uint256, amounts: uint256[3], min_mint_amount: uint256) -> (uint256,uint256[3]):
    # old balance 18 me h
    # amounts bhi 18 me
    fees: uint256[3] = empty(uint256[3])
    _fee: uint256 = 20000000 * 3 / (4 * (3 - 1))
    _admin_fee: uint256 = 5000000000
  
    D0: uint256 = 0
    if token_supply > 0:
        D0 = self.get_D(old_balances, amp)
    new_balances: uint256[3] = old_balances

    for i in range(3):
        in_amount: uint256 = amounts[i]
        if token_supply == 0:
            assert in_amount > 0  # dev: initial deposit requires all coins
       
        new_balances[i] = old_balances[i] + in_amount

    # Invariant after change
    D1: uint256 = self.get_D(new_balances, amp)
    assert D1 > D0

    D2: uint256 = D1
    if token_supply > 0:
        # Only account for fees if we are not the first to deposit
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            if ideal_balance > new_balances[i]:
                difference = ideal_balance - new_balances[i]
            else:
                difference = new_balances[i] - ideal_balance
            fees[i] = _fee * difference / FEE_DENOMINATOR
            new_balances[i] -= fees[i]
        D2 = self.get_D(new_balances, amp)
   
    # Calculate, how much pool tokens to mint
    mint_amount: uint256 = 0
    if token_supply == 0:
        mint_amount = D1  # Take the dust if there was any
    else:
        mint_amount = token_supply * (D2 - D0) / D0

    assert mint_amount >= min_mint_amount, "Slippage screwed you"

    return mint_amount,new_balances

@view
@external
def remove_liquidity(balances: uint256[3], total_supply: uint256, _amount: uint256, min_amounts: uint256[3]) -> uint256[3]:
    amounts: uint256[3] = empty(uint256[3])
    fees: uint256[N_COINS] = empty(uint256[N_COINS])  # Fees are unused but we've got them historically in event
    valuetosend: uint256[3] = empty(uint256[3])
    for i in range(N_COINS):
        value: uint256 = balances[i] * _amount / total_supply
        assert value >= min_amounts[i], "Withdrawal resulted in fewer coins than expected"
        amounts[i] = value
        valuetosend[i] = value
    
    return valuetosend

@view
@external
def remove_liquidity_imbalance(balances: uint256[3], amp: uint256, token_supply: uint256, amounts: uint256[N_COINS], max_burn_amount: uint256) -> (uint256, uint256,uint256,uint256):
        # 18 precision
    _fee: uint256 = 20000000 * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = 5000000000
  
    old_balances: uint256[N_COINS] = balances
    new_balances: uint256[N_COINS] = old_balances
    D0: uint256 = self.get_D(old_balances, amp)
    for i in range(N_COINS):
        new_balances[i] -= amounts[i]
    D1: uint256 = self.get_D(new_balances, amp)
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        difference: uint256 = 0
        if ideal_balance > new_balances[i]:
            difference = ideal_balance - new_balances[i]
        else:
            difference = new_balances[i] - ideal_balance
        fees[i] = _fee * difference / FEE_DENOMINATOR
        new_balances[i] -= fees[i]
    D2: uint256 = self.get_D(new_balances, amp)

    token_amount: uint256 = (D0 - D2) * token_supply / D0
    assert token_amount != 0  # dev: zero tokens burned
    token_amount += 1  # In case of rounding errors - make it unfavorable for the "attacker"
    assert token_amount <= max_burn_amount, "Slippage screwed you"

    return token_amount, D0,D1,D2



@view
@internal
def _calc_withdraw_one_coin(xp: uint256[3], total_supply: uint256, amp:uint256, _token_amount: uint256, i: int128) -> (uint256, uint256):
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    _fee: uint256 = 20000000 * N_COINS / (4 * (N_COINS - 1))

    D0: uint256 = self.get_D(xp, amp)
    D1: uint256 = D0 - _token_amount * D0 / total_supply
    xp_reduced: uint256[N_COINS] = xp

    new_y: uint256 = self.get_y_D(amp, i, xp, D1)
    dy_0: uint256 = (xp[i] - new_y) 

    for j in range(N_COINS):
        dx_expected: uint256 = 0
        if j == i:
            dx_expected = xp[j] * D1 / D0 - new_y
        else:
            dx_expected = xp[j] - xp[j] * D1 / D0
        xp_reduced[j] -= _fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y_D(amp, i, xp_reduced, D1)
    dy = (dy - 1)  # Withdraw less to account for rounding errors

    return dy, dy_0 - dy


@view
@external
def remove_liquidity_one_coin(balances: uint256[3],total_supply:uint256,amp:uint256, _token_amount: uint256, i: int128, min_amount: uint256) -> uint256:
    """
    Remove _amount of liquidity all in a form of coin i
    """
   
    dy: uint256 = 0
    dy_fee: uint256 = 0
    dy, dy_fee = self._calc_withdraw_one_coin(balances,total_supply,amp,_token_amount, i)
    assert dy >= min_amount, "Not enough coins removed"
    return dy