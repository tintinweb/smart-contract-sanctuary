# Created by interfinex.io
# - The Greeks

interface ERC20:
    def approve(_spender : address, _value : uint256) -> bool: nonpayable
    def allowance(_owner: address, _spender: address) -> uint256: view
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable
    def initializeERC20(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256, _mintable: bool): nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def totalSupply() -> uint256: view
    def mint(_to: address, _value: uint256): nonpayable
    def transfer(_to : address, _value : uint256) -> bool: nonpayable

interface DividendERC20:
    def initializeERC20(
        _name: String[64], 
        _symbol: String[32], 
        _decimals: uint256, 
        _supply: uint256, 
        _dividend_token: address,
        _mintable: bool
    ): nonpayable
    def burnFrom(_to: address, _value: uint256): nonpayable
    def distributeDividends(_value: uint256): nonpayable

interface Exchange:
    def swap(
        input_token: address,
        input_token_amount: uint256,
        recipient: address,
        min_output_token_amount: uint256,
        max_output_token_amount: uint256,
        deadline: uint256,
        referral: address
    ) -> uint256: nonpayable

interface Factory:
    def pair_to_exchange(token0: address, token1: address) -> address: view

base_token: public(address)
asset_token: public(address)
liquidity_token: public(address)
ifex_token_contract: public(address)

factory_contract: public(address)

fee_rate: public(uint256) # fee * 10**18
MIN_LIQUIDITY: constant(uint256) = 10 ** 3
MULTIPLIER: constant(uint256) = 10 ** 18

event MintLiquidity:
    base_token_amount: uint256
    asset_token_amount: uint256
    liquidity_tokens_minted: uint256
    user: indexed(address)

event BurnLiquidity:
    base_token_amount: uint256
    asset_token_amount: uint256
    liquidity_tokens_burned: uint256
    user: indexed(address)

event Swap:
    base_token_amount: uint256
    asset_token_amount: uint256
    is_buy: indexed(bool)
    user: indexed(address)

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
def safeTransfer(_token: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32),
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token transfer failed!"

    return True

@external
def initialize_exchange(
    _base_token: address, 
    _asset_token: address, 
    _fee_rate: uint256, 
    _erc20_dividend_template: address, 
    _factory_contract: address,
    _ifex_token_contract: address
):
    assert _base_token != ZERO_ADDRESS and _asset_token != ZERO_ADDRESS, "_base_token and _asset_token must be valid addresses"
    assert self.base_token == ZERO_ADDRESS and self.asset_token == ZERO_ADDRESS, "base_token and asset_token can only be initialised once"
    self.base_token = _base_token
    self.asset_token = _asset_token
    self.fee_rate = _fee_rate
    self.liquidity_token = create_forwarder_to(_erc20_dividend_template)
    self.ifex_token_contract = _ifex_token_contract
    self.factory_contract = _factory_contract

    asset_token_ifex_token_exchange: address = Factory(self.factory_contract).pair_to_exchange(_asset_token, _ifex_token_contract)
    base_token_ifex_token_exchange: address = Factory(self.factory_contract).pair_to_exchange(_base_token, _ifex_token_contract)
    self.safeApprove(self.asset_token, asset_token_ifex_token_exchange, MAX_UINT256)
    self.safeApprove(self.base_token, base_token_ifex_token_exchange, MAX_UINT256)

    self.safeApprove(self.ifex_token_contract, self.ifex_token_contract, MAX_UINT256)
    self.safeApprove(self.ifex_token_contract, self.liquidity_token, MAX_UINT256)
    DividendERC20(self.liquidity_token).initializeERC20("LiquidityToken", "LT", 18, 0, self.ifex_token_contract, True)
    return

@external
def mint_liquidity(base_token_amount: uint256, min_asset_token_amount: uint256, max_asset_token_amount: uint256, recipient: address, deadline: uint256):
    assert base_token_amount > 0
    assert block.timestamp <= deadline or deadline == 0

    base_token_balance: uint256 = ERC20(self.base_token).balanceOf(self)
    asset_token_balance: uint256 = ERC20(self.asset_token).balanceOf(self)
    total_liquidity_token_balance: uint256 = ERC20(self.liquidity_token).totalSupply()

    # Initialisation case
    if total_liquidity_token_balance == 0:
        assert base_token_amount > MIN_LIQUIDITY * 2
        liquidity_tokens_minted: uint256 = base_token_amount
        asset_token_amount: uint256 = min_asset_token_amount
        self.safeTransferFrom(self.asset_token, msg.sender, self, asset_token_amount)
        self.safeTransferFrom(self.base_token, msg.sender, self, base_token_amount)
        ERC20(self.liquidity_token).mint(self, liquidity_tokens_minted)
        ERC20(self.liquidity_token).transfer(recipient, liquidity_tokens_minted - MIN_LIQUIDITY)
        log MintLiquidity(base_token_amount, asset_token_amount, liquidity_tokens_minted, msg.sender)
        return

    liquidity_tokens_minted: uint256 = total_liquidity_token_balance * base_token_amount / base_token_balance 
    asset_token_amount: uint256 = base_token_amount * asset_token_balance / base_token_balance
    assert asset_token_amount >= min_asset_token_amount and asset_token_amount <= max_asset_token_amount
    self.safeTransferFrom(self.asset_token, msg.sender, self, asset_token_amount)
    self.safeTransferFrom(self.base_token, msg.sender, self, base_token_amount)
    ERC20(self.liquidity_token).mint(recipient, liquidity_tokens_minted)
    log MintLiquidity(base_token_amount, asset_token_amount, liquidity_tokens_minted, msg.sender)

@external
def burn_liquidity(liquidity_token_amount: uint256, deadline: uint256):
    assert liquidity_token_amount > 0
    assert block.timestamp <= deadline or deadline == 0
    
    total_liquidity_token_balance: uint256 = ERC20(self.liquidity_token).totalSupply()
    base_token_amount: uint256 = ERC20(self.base_token).balanceOf(self) * liquidity_token_amount / total_liquidity_token_balance
    asset_token_amount: uint256 = ERC20(self.asset_token).balanceOf(self) * liquidity_token_amount / total_liquidity_token_balance

    DividendERC20(self.liquidity_token).burnFrom(msg.sender, liquidity_token_amount)
    self.safeTransfer(self.base_token, msg.sender, base_token_amount)
    self.safeTransfer(self.asset_token, msg.sender, asset_token_amount)
    log BurnLiquidity(base_token_amount, asset_token_amount, liquidity_token_amount, msg.sender)

@view
@internal
def _getInputToOutputAmount(input_token: address, input_token_amount: uint256, fee: uint256) -> uint256:
    output_token: address = self.asset_token
    if input_token == self.asset_token:
        output_token = self.base_token

    input_token_balance: uint256 = ERC20(input_token).balanceOf(self)
    output_token_balance: uint256 = ERC20(output_token).balanceOf(self)
    return ((input_token_amount - fee) * output_token_balance) / (input_token_balance + input_token_amount - fee)

@view
@external
def getInputToOutputAmount(input_token: address, input_token_amount: uint256) -> uint256:
    assert input_token == self.base_token or input_token == self.asset_token, "input_token is not part of this contract"
    return self._getInputToOutputAmount(input_token, input_token_amount, input_token_amount * self.fee_rate / MULTIPLIER)    

@external
def swap(
    input_token: address,
    input_token_amount: uint256,
    recipient: address,
    min_output_token_amount: uint256,
    max_output_token_amount: uint256,
    deadline: uint256,
    referral: address
) -> uint256:
    assert input_token_amount > 0 and ERC20(self.liquidity_token).totalSupply() != 0, "input_token_amount must be greater than 0"
    assert input_token == self.base_token or input_token == self.asset_token, "input_token is not part of this contract"
    assert deadline == 0 or block.timestamp <= deadline, "Deadline for this transaction has passed"

    output_token: address = self.asset_token
    if input_token == self.asset_token:
        output_token = self.base_token

    input_token_fee: uint256 = input_token_amount * self.fee_rate / MULTIPLIER
    if referral != ZERO_ADDRESS:
        input_token_fee = input_token_fee * 49 / 100
        self.safeTransfer(input_token, referral, input_token_fee * 10 / 100)

    output_token_amount: uint256 = self._getInputToOutputAmount(input_token, input_token_amount, input_token_fee)
    self.safeTransferFrom(input_token, msg.sender, self, input_token_amount)

    assert (output_token_amount >= min_output_token_amount and output_token_amount <= max_output_token_amount) or min_output_token_amount == 0, "Buying output_token amount is greater than slippage"

    if self.base_token != self.ifex_token_contract and self.asset_token != self.ifex_token_contract:
        input_token_ifex_token_exchange: address = Factory(self.factory_contract).pair_to_exchange(input_token, self.ifex_token_contract)
        dividend: uint256 = Exchange(input_token_ifex_token_exchange).swap(input_token, input_token_fee / 10, self, 0, 0, 0, ZERO_ADDRESS)
        DividendERC20(self.liquidity_token).distributeDividends(dividend * 10 / 100)
        DividendERC20(self.ifex_token_contract).distributeDividends(dividend * 90 / 100)

    self.safeTransfer(output_token, recipient, output_token_amount)

    base_token_amount: uint256 = input_token_amount
    asset_token_amount: uint256 = output_token_amount
    is_buy: bool = True
    if input_token != self.base_token:
        base_token_amount = output_token_amount
        asset_token_amount = input_token_amount
        is_buy = False

    log Swap(base_token_amount, asset_token_amount, is_buy, msg.sender)
    return output_token_amount