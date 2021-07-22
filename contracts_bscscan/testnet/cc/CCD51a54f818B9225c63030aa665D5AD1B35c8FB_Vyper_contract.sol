from vyper.interfaces import ERC20

contract bERC20:
    def totalSupply() -> uint256: constant
    def allowance(_owner: address, _spender: address) -> uint256: constant
    def transfer(_to: address, _value: uint256) -> bool: modifying
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
    def approve(_spender: address, _value: uint256) -> bool: modifying
    def name() -> string[64]: constant
    def symbol() -> string[32]: constant
    def decimals() -> uint256: constant
    def balanceOf(arg0: address) -> uint256: constant
    def deposit(depositAmount: uint256): modifying
    def withdraw(withdrawTokens: uint256): modifying
    def getPricePerFullShare() -> uint256: constant

contract IxfiLP:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256,fees: uint256[N_COINS]): modifying
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]): modifying
    def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256): modifying
    def balances(i: int128) -> uint256: constant
    def A() -> uint256: constant
    def fee() -> uint256: constant
    def owner() -> address: constant

contract IWETH:
    def deposit():modifying
    def transfer(to:address,value:uint256) -> bool:modifying
    def withdraw(amount:uint256):modifying


Payment: event({_amount: uint256, _from: address})

N_COINS: constant(int128) = 3
ZERO256: constant(uint256) = 0 
ZEROS: constant(uint256[N_COINS]) = [ ZERO256, ZERO256, ZERO256]
LENDING_PRECISION: constant(uint256) = 10 ** 18
PRECISION: constant(uint256) = 10 ** 18
PRECISION_MUL: constant(uint256[N_COINS]) = [convert(1, uint256), convert(1, uint256), convert(1, uint256)]
FEE_DENOMINATOR: constant(uint256) = 10 ** 10
FEE_IMPRECISION: constant(uint256) = 25 * 10 ** 8 

coins: public(address[N_COINS])
underlying_coins: public(address[N_COINS])
ixfiLP: public(address)
token: public(address)
entrance_fee: public(uint256)
fee_claimer:public(address)

@public
def __init__(_coins: address[N_COINS], _underlying_coins: address[N_COINS],
             _ixfiLP: address, _token: address, _enterance_fee:uint256, _fee_claimer:address):
    self.coins = _coins
    self.underlying_coins = _underlying_coins
    self.ixfiLP = _ixfiLP
    self.token = _token
    self.entrance_fee = _enterance_fee
    self.fee_claimer = _fee_claimer


@public
@payable
@nonreentrant('lock')
def add_liquidity(uamounts: uint256[N_COINS], min_mint_amount: uint256):
    amounts: uint256[N_COINS] = ZEROS
    IWETH(self.underlying_coins[0]).deposit(value=msg.value)
    fees: uint256[N_COINS] = ZEROS
    _fee: uint256 = self.entrance_fee/3

    for i in range(N_COINS):
      
        uamount:uint256 = uamounts[i]
        if i==0:
            uamount = ERC20(self.underlying_coins[i]).balanceOf(self)
        if uamount > 0:
            if i>0:
                assert_modifiable(ERC20(self.underlying_coins[i])\
                    .transferFrom(msg.sender, self, uamount))

            

            # fee transfer
            fees[i] = uamount*_fee/FEE_DENOMINATOR
            uamount = uamount-fees[i]
            assert_modifiable(ERC20(self.underlying_coins[i]).transfer(self, fees[i]))
            ERC20(self.underlying_coins[i]).approve(self.coins[i], uamount)
            # bERC20(self.coins[i]).deposit(uamount)
            amounts[i] = bERC20(self.coins[i]).balanceOf(self)
            ERC20(self.coins[i]).approve(self.ixfiLP, amounts[i])

    IxfiLP(self.ixfiLP).add_liquidity(amounts, min_mint_amount, fees)

    tokens: uint256 = ERC20(self.token).balanceOf(self)
    assert_modifiable(ERC20(self.token).transfer(msg.sender, tokens))


@private
def _send_all(_addr: address, min_uamounts: uint256[N_COINS], one: int128):

    for i in range(N_COINS):
        if (one < 0) or (i == one):
            _coin: address = self.coins[i]
            _balance: uint256 = bERC20(_coin).balanceOf(self)
            if _balance == 0:
                continue
            bERC20(_coin).withdraw(_balance)

            _ucoin: address = self.underlying_coins[i]
            _uamount: uint256 = ERC20(_ucoin).balanceOf(self)
            assert _uamount >= min_uamounts[i], "Not enough coins withdrawn"
            if i==0:
                if ERC20(self.underlying_coins[0]).balanceOf(self)<_uamount:
                    _uamount = ERC20(self.underlying_coins[0]).balanceOf(self)
                    assert _uamount>0 , "Amount is less than 0"
                IWETH(self.underlying_coins[0]).withdraw(_uamount)
                send(_addr,self.balance)
                # assert_modifiable(ERC20(_ucoin).transfer(_addr, _uamount))
            else:
                assert_modifiable(ERC20(_ucoin).transfer(_addr, _uamount))

@payable
@public
@nonreentrant('lock')
def remove_liquidity(_amount: uint256, min_uamounts: uint256[N_COINS]):
    zeros: uint256[N_COINS] = ZEROS
    assert_modifiable(ERC20(self.token).transferFrom(msg.sender, self, _amount))
    IxfiLP(self.ixfiLP).remove_liquidity(_amount, zeros)
    _addr:address = msg.sender
    one:int128 = -1
    for i in range(N_COINS):
        if (one < 0) or (i == one):
            _coin: address = self.coins[i]
            _balance: uint256 = bERC20(_coin).balanceOf(self)
            if _balance == 0:
                continue
            bERC20(_coin).withdraw(_balance)

            _ucoin: address = self.underlying_coins[i]
            _uamount: uint256 = ERC20(_ucoin).balanceOf(self)
            assert _uamount >= min_uamounts[i], "Not enough coins withdrawn"
            if i==0:
                IWETH(_ucoin).withdraw(_uamount)
                send(_addr,_uamount)
            else:
                assert_modifiable(ERC20(_ucoin).transfer(_addr, _uamount))



@public
@nonreentrant('lock')
def remove_liquidity_imbalance(uamounts: uint256[N_COINS], max_burn_amount: uint256):
    _token: address = self.token

    amounts: uint256[N_COINS] = uamounts
    for i in range(N_COINS):
        if amounts[i] > 0:
            rate: uint256 = bERC20(self.coins[i]).getPricePerFullShare()
            amounts[i] = amounts[i] * LENDING_PRECISION / rate

    _tokens: uint256 = ERC20(_token).balanceOf(msg.sender)
    if _tokens > max_burn_amount:
        _tokens = max_burn_amount
    assert_modifiable(ERC20(_token).transferFrom(msg.sender, self, _tokens))

    IxfiLP(self.ixfiLP).remove_liquidity_imbalance(amounts, max_burn_amount)

    _tokens = ERC20(_token).balanceOf(self)
    assert_modifiable(ERC20(_token).transfer(msg.sender, _tokens))

    self._send_all(msg.sender, ZEROS, -1)


@private
@constant
def _xp_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * _balances[i] / PRECISION
    return result


@private
@constant
def get_D(A: uint256, xp: uint256[N_COINS]) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = A * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS + 1)
        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)
        
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@private
@constant
def get_y(A: uint256, i: int128, _xp: uint256[N_COINS], D: uint256) -> uint256:
    assert (i >= 0) and (i < N_COINS)

    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = A * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i != i:
            _x = _xp[_i]
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

        if y > y_prev:
            if y - y_prev <= 1:
                break
        else:
            if y_prev - y <= 1:
                break
    return y


@private
@constant
def _calc_withdraw_one_coin(_token_amount: uint256, i: int128, rates: uint256[N_COINS]) -> uint256:
    blp: address = self.ixfiLP
    A: uint256 = IxfiLP(blp).A()
    fee: uint256 = IxfiLP(blp).fee() * N_COINS / (3 * (N_COINS - 1))
    fee += fee * FEE_IMPRECISION / FEE_DENOMINATOR 
    precisions: uint256[N_COINS] = PRECISION_MUL
    total_supply: uint256 = ERC20(self.token).totalSupply()

    xp: uint256[N_COINS] = PRECISION_MUL
    S: uint256 = 0
    for j in range(N_COINS):
        xp[j] *= IxfiLP(blp).balances(j)
        xp[j] = xp[j] * rates[j] / LENDING_PRECISION
        S += xp[j]

    D0: uint256 = self.get_D(A, xp)
    D1: uint256 = 0
    
    D1 = D0 - _token_amount * D0 / total_supply
    xp_reduced: uint256[N_COINS] = xp


    for j in range(N_COINS):
        dx_expected: uint256 = 0
        
        b_ideal: uint256 = xp[j] * D1 / D0
        b_expected: uint256 = xp[j]
        if j == i:
            b_expected -= S * (D0 - D1) / D0
        if b_ideal >= b_expected:
            dx_expected += (b_ideal - b_expected)
        else:
            dx_expected += (b_expected - b_ideal)
        xp_reduced[j] -= fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y(A, i, xp_reduced, D1)
    
    dy = dy / precisions[i]

    return dy


@public
@constant
def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    rates: uint256[N_COINS] = ZEROS

    for j in range(N_COINS):
        rates[j] = bERC20(self.coins[j]).getPricePerFullShare()

    return self._calc_withdraw_one_coin(_token_amount, i, rates)


@public
@nonreentrant('lock')
def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_uamount: uint256, donate_dust: bool = False):
    rates: uint256[N_COINS] = ZEROS
    _token: address = self.token

    for j in range(N_COINS):
        rates[j] = bERC20(self.coins[j]).getPricePerFullShare()

    dy: uint256 = self._calc_withdraw_one_coin(_token_amount, i, rates)
    assert dy >= min_uamount, "Not enough coins removed"

    assert_modifiable(
        ERC20(self.token).transferFrom(msg.sender, self, _token_amount))

    amounts: uint256[N_COINS] = ZEROS
    amounts[i] = dy * LENDING_PRECISION / rates[i]
    token_amount_before: uint256 = ERC20(_token).balanceOf(self)
    IxfiLP(self.ixfiLP).remove_liquidity_imbalance(amounts, _token_amount)


    self._send_all(msg.sender, ZEROS, i)

    if not donate_dust:
        token_amount_after: uint256 = ERC20(_token).balanceOf(self)
        if token_amount_after > token_amount_before:
            assert_modifiable(ERC20(_token).transfer(
                msg.sender, token_amount_after - token_amount_before)
            )


@public
@nonreentrant('lock')
def withdraw_donated_dust():
    owner: address = IxfiLP(self.ixfiLP).owner()
    assert msg.sender == owner

    _token: address = self.token
    assert_modifiable(
        ERC20(_token).transfer(owner, ERC20(_token).balanceOf(self)))


@public
@payable
def __default__():
    log.Payment(as_unitless_number(msg.value), msg.sender)