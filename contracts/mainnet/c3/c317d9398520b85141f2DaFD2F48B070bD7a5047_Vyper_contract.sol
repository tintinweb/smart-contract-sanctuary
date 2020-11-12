# Created by interfinex.io
# - The Greeks

interface ERC20:
    def approve(_spender : address, _value : uint256) -> bool: nonpayable
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable    
    def allowance(_owner: address, _spender: address) -> uint256: view

@internal
def safeTransferFrom(_token: address, _from: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token transferFrom failed!"

    return True

@internal
def safeApprove(_token: address, _spender: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("approve(address,uint256)"),
            convert(_spender, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token approval failed!"

    return True

interface Exchange:
    def initialize_exchange(
        _base_token: address, 
        _asset_token: address, 
        _fee_rate: uint256, 
        _erc20_dividend_template: address, 
        _factory_contract: address,
        _ifex_token_contract: address
    ): nonpayable
    def mint_liquidity(
        base_token_amount: uint256, 
        min_asset_token_amount: uint256, 
        max_asset_token_amount: uint256, 
        recipient: address, 
        deadline: uint256
    ): nonpayable

event NewExchange:
    creator: address
    exchange_contract: indexed(address)
    base_token: indexed(address)
    asset_token: indexed(address)

exchange_template: public(address)
erc20_dividend_template: public(address)

ifex_token_contract: public(address)

pair_to_exchange: public(HashMap[address, HashMap[address, address]])
exchange_to_pair: public(HashMap[address, address[2]])
exchange_count: public(uint256)
id_to_exchange: public(HashMap[uint256, address])

fee_rate: public(uint256)

@external
def initialize_factory(_fee_rate: uint256, _exchange_template: address, _erc20_dividend_template: address, _ifex_token_contract: address,):
    assert self.exchange_template == ZERO_ADDRESS and self.erc20_dividend_template == ZERO_ADDRESS
    assert _exchange_template != ZERO_ADDRESS and _erc20_dividend_template != ZERO_ADDRESS

    self.exchange_template = _exchange_template
    self.ifex_token_contract = _ifex_token_contract
    self.erc20_dividend_template = _erc20_dividend_template
    self.fee_rate = _fee_rate

@internal
def _create_exchange(_token0: address, _token1: address, _token0_amount: uint256, _token1_amount: uint256, creator: address) -> address:
    assert _token0 != ZERO_ADDRESS and _token1 != ZERO_ADDRESS, "asset_token and base_token must be valid addresses"
    assert self.exchange_template != ZERO_ADDRESS, "exchange_template must have been initialized"
    assert self.pair_to_exchange[_token0][_token1] == ZERO_ADDRESS and self.pair_to_exchange[_token1][_token0] == ZERO_ADDRESS, "Exchange contract cannot already exist for pair"
    assert _token0_amount > 0 and _token1_amount > 0, "Must deposit at least some liquidity"

    uint256_token0: uint256 = convert(_token0, uint256)
    uint256_token1: uint256 = convert(_token1, uint256)
    token0: address = _token0
    token1: address = _token1
    token0_amount: uint256 = _token0_amount
    token1_amount: uint256 = _token1_amount
    if (uint256_token0 > uint256_token1):
        token0 = _token1
        token1 = _token0
        token0_amount = _token1_amount
        token1_amount = _token0_amount

    exchange: address = create_forwarder_to(self.exchange_template)
    
    self.safeApprove(token0, exchange, MAX_UINT256)
    self.safeApprove(token1, exchange, MAX_UINT256)

    self.pair_to_exchange[token0][token1] = exchange
    self.pair_to_exchange[token1][token0] = exchange
    self.exchange_to_pair[exchange] = [token0, token1]

    self.id_to_exchange[self.exchange_count] = exchange
    self.exchange_count += 1

    Exchange(exchange).initialize_exchange(
        token0, 
        token1, 
        self.fee_rate, 
        self.erc20_dividend_template,
        self,
        self.ifex_token_contract
    )

    Exchange(exchange).mint_liquidity(
        token0_amount, 
        token1_amount, 
        token1_amount, 
        creator,
        0,
    )

    log NewExchange(creator, exchange, token0, token1)
    return exchange
    
@external
def create_exchange(base_token: address, asset_token: address, base_token_amount: uint256, asset_token_amount: uint256, ifex_token_amount: uint256):
    self.safeTransferFrom(base_token, msg.sender, self, base_token_amount)
    self.safeTransferFrom(asset_token, msg.sender, self, asset_token_amount)
    self.safeTransferFrom(self.ifex_token_contract, msg.sender, self, ifex_token_amount)
    
    # Create the ifex exchange so that ifex tokens can be bought and paid out in dividends
    if base_token != self.ifex_token_contract and asset_token != self.ifex_token_contract:
        if self.pair_to_exchange[base_token][self.ifex_token_contract] == ZERO_ADDRESS:
            self._create_exchange(base_token, self.ifex_token_contract, base_token_amount * 10 / 100, ifex_token_amount * 50 / 100, msg.sender)
        
        if self.pair_to_exchange[asset_token][self.ifex_token_contract] == ZERO_ADDRESS:
            self._create_exchange(asset_token, self.ifex_token_contract, asset_token_amount * 10 / 100, ifex_token_amount * 50 / 100, msg.sender) 

    deposit_percentage: uint256 = 90
    if base_token == self.ifex_token_contract or asset_token == self.ifex_token_contract: 
        deposit_percentage = 100

    self._create_exchange(base_token, asset_token, base_token_amount * deposit_percentage / 100, asset_token_amount * deposit_percentage / 100, msg.sender)