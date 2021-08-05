# @version ^0.2.0

# @dev Implementation of ERC-20 token standard.
# @author Takayuki Jimba (@yudetamago)
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

from vyper.interfaces import ERC20

implements: ERC20

interface PaymentTokenGovernorProxy:
	def payment_token_governor_address() -> address: view

	def get_payment_token_acceptance(
		_paymentTokenAddress: address
	) -> bool: view

	def get_accepted_payment_tokens(
		_index: uint256
	) -> address: view

interface FeeGovernorProxy:
	def get_fee_denominator() -> uint256: view

	def get_admin_fee() -> uint256: view

	def get_beneficiary() -> address: view

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event FundsDeposited:
    sender: indexed(address)
    paymentToken: indexed(address)
    value: uint256

event FundsDistributed:
    receiver: indexed(address)
    paymentToken: indexed(address)
    value: uint256

event FundsWithdrawn:
    receiver: indexed(address)
    paymentToken: indexed(address)
    value: uint256

event AdminFeeWithdrawn:
	beneficiary: indexed(address)
	paymentToken: indexed(address)
	value: uint256

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

# @dev Mapping of payment token address to pointsPerShare
pointsPerShare: HashMap[address, uint256]

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
balanceOf: public(HashMap[address, uint256])


allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256

# @dev PaymentTokenGovernorProxy instance
payment_token_governor_proxy: PaymentTokenGovernorProxy

# @dev Mapping of payment token address to contract balance of that payment token
payment_token_to_balance: HashMap[address, uint256]

# @dev Mapping of payment token address to mapping of wallet address to withdrawn funds
withdrawnFunds: HashMap[address, HashMap[address, uint256]]

# @dev Mapping of payment token address to mapping of wallet address to points correction
pointsCorrection: HashMap[address, HashMap[address, int128]]

# @dev Mapping of payment token address to balance of admin fee of that payment token
payment_token_to_admin_fee_balance: public(HashMap[address, uint256])

# @dev Mapping of payment token address to cumulative balance of admin fees withdrawn for that payment token
payment_token_to_cumulative_withdrawn_admin_fee: HashMap[address, uint256]

# @dev FeeGovernorProxy instance
fee_governor_proxy: FeeGovernorProxy

# ERC20 functions

@external
def __init__():

	pass

@external
@nonreentrant('lock')
def initialize(
	_name: String[64],
	_symbol: String[32],
	_decimals: uint256,
	_supply: uint256,
	_ownerAddress: address,
	_payment_token_governor_proxy_address: address,
	_fee_governor_proxy_address: address
) -> bool:
	"""
	@notice Initialize the contract
	@dev Separate from '__init__' method to facilitate factory pattern in 'FundsDistributionTokenFactory'
	@param _name Name of the funds distribution token
	@param _symbol Symbol of the funds distribution token
	@param _decimals Number of decimals for the funds distribution token
	@param _supply Total supply of the funds distribution token
	@param _ownerAddress Address to mint initial supply to
	"""
	self.name = _name
	self.symbol = _symbol
	self.decimals = _decimals
	self.balanceOf[_ownerAddress] = _supply
	self.total_supply = _supply
	self.payment_token_governor_proxy = PaymentTokenGovernorProxy(_payment_token_governor_proxy_address)
	self.fee_governor_proxy = FeeGovernorProxy(_fee_governor_proxy_address)
	log Transfer(ZERO_ADDRESS, _ownerAddress, _supply)

	return True


@view
@external
def totalSupply() -> uint256:
    """
    @dev Total number of tokens in existence.
    """
    return self.total_supply


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
def _transfer(_to: address, _from: address, _value: uint256):
	"""
	@dev Internal function to transfer token and keep track of amount withdrawable
	@param _to The address to transfer to.
	@param _from The address to transfer from.
	@param _value The amount to transfer.
	"""

	for i in range(1, 11):

		_currentPaymentTokenAddress: address = self.payment_token_governor_proxy.get_accepted_payment_tokens(i)

		if _currentPaymentTokenAddress == ZERO_ADDRESS:
			break

		_correction: uint256 = self.pointsPerShare[_currentPaymentTokenAddress] * _value
		_senderWithdrawnFunds: uint256 = self.withdrawnFunds[_currentPaymentTokenAddress][_from]

		if _senderWithdrawnFunds > 0:
			self.pointsCorrection[_currentPaymentTokenAddress][_from] = self.pointsCorrection[_currentPaymentTokenAddress][_from] + convert(_correction, int128)
			self.pointsCorrection[_currentPaymentTokenAddress][_to] = self.pointsCorrection[_currentPaymentTokenAddress][_to] - convert(_correction, int128)

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    self._transfer(_to, msg.sender, _value)

    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    self._transfer(_to, msg.sender, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != ZERO_ADDRESS
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowances[_to][msg.sender] -= _value
    self._burn(_to, _value)

# FDT functions

@view
@internal
def _accumulativeFundsOf(_receiver: address, _paymentTokenAddress: address) -> int128:
    return convert((self.pointsPerShare[_paymentTokenAddress] * self.balanceOf[_receiver]), int128) + self.pointsCorrection[_paymentTokenAddress][_receiver]

@view
@internal
def _withdrawableFundsOf(_receiver: address, _paymentTokenAddress: address) -> uint256:
    return convert(self._accumulativeFundsOf(_receiver, _paymentTokenAddress), uint256) - self.withdrawnFunds[_paymentTokenAddress][_receiver]

@internal
def _distributeFunds(_triggerer: address, _paymentTokenAddress: address, _value: uint256):
	"""
	@dev Distribute funds which have not been distributed
	@param _value The amount that will be distributed
	"""
	assert self.total_supply > 0

	if _value > 0:
		_fee_denominator: uint256 = self.fee_governor_proxy.get_fee_denominator()
		_admin_fee: uint256 = self.fee_governor_proxy.get_admin_fee()
		_current_admin_fee: uint256 = _value * _admin_fee / _fee_denominator
		self.payment_token_to_admin_fee_balance[_paymentTokenAddress] += _current_admin_fee
		self.pointsPerShare[_paymentTokenAddress] += (_value - _current_admin_fee) / self.total_supply
		log FundsDistributed(_triggerer, _paymentTokenAddress, _value)

@internal
def _updateFundsTokenBalance(_paymentTokenAddress: address) -> uint256:

    _prevfundsTokenBalance: uint256 = self.payment_token_to_balance[_paymentTokenAddress]

    self.payment_token_to_balance[_paymentTokenAddress] = ERC20(_paymentTokenAddress).balanceOf(self)

    if _prevfundsTokenBalance > self.payment_token_to_balance[_paymentTokenAddress]:
        return _prevfundsTokenBalance - self.payment_token_to_balance[_paymentTokenAddress]
    elif self.payment_token_to_balance[_paymentTokenAddress] > _prevfundsTokenBalance:
        return self.payment_token_to_balance[_paymentTokenAddress] - _prevfundsTokenBalance
    else:
        return 0


@internal
def _prepareWithdraw(_receiver: address, _paymentTokenAddress: address) -> uint256:

    _withdrawableDividend: uint256 = self._withdrawableFundsOf(_receiver, _paymentTokenAddress)

    self.withdrawnFunds[_paymentTokenAddress][_receiver] = self.withdrawnFunds[_paymentTokenAddress][_receiver] + _withdrawableDividend

    log FundsWithdrawn(_receiver, _paymentTokenAddress, _withdrawableDividend)

    return _withdrawableDividend

@internal
def _withdrawFunds(_to: address):
	"""
	@dev Helper function to withdraw funds for a given account
	@param _to The address to withdraw to
	"""

	for i in range(1, 11):

		_currentPaymentTokenAddress: address = self.payment_token_governor_proxy.get_accepted_payment_tokens(i)

		if _currentPaymentTokenAddress == ZERO_ADDRESS:
			break

		_newFunds: uint256 = self._updateFundsTokenBalance(_currentPaymentTokenAddress)

		if _newFunds > 0:
	        self._distributeFunds(_to, _currentPaymentTokenAddress, _newFunds)

		_withdrawableFunds: uint256 = self._prepareWithdraw(_to, _currentPaymentTokenAddress)
		ERC20(_currentPaymentTokenAddress).transfer(_to, _withdrawableFunds)
		self._updateFundsTokenBalance(_currentPaymentTokenAddress)

@external
def withdrawFunds():
	self._withdrawFunds(msg.sender)

@external
def updateFundsTokenBalance():

	for i in range(1, 11):

		_currentPaymentTokenAddress: address = self.payment_token_governor_proxy.get_accepted_payment_tokens(i)

		if _currentPaymentTokenAddress == ZERO_ADDRESS:
			break

		_newFunds: uint256 = self._updateFundsTokenBalance(_currentPaymentTokenAddress)

		if _newFunds > 0:
			self._distributeFunds(msg.sender, _currentPaymentTokenAddress, _newFunds)

@external
def withdrawAdminFee():
	"""
	@dev Withdraws admin fee to given beneficiary address
	"""
	for i in range(1, 11):

		_currentPaymentTokenAddress: address = self.payment_token_governor_proxy.get_accepted_payment_tokens(i)

		if _currentPaymentTokenAddress == ZERO_ADDRESS:
			break

		_undistributed_admin_fee: uint256 = self.payment_token_to_admin_fee_balance[_currentPaymentTokenAddress]

		if _undistributed_admin_fee == 0:
			continue

		self.payment_token_to_admin_fee_balance[_currentPaymentTokenAddress] = 0
		self.payment_token_to_cumulative_withdrawn_admin_fee[_currentPaymentTokenAddress] += _undistributed_admin_fee

		_beneficiary: address = self.fee_governor_proxy.get_beneficiary()

		ERC20(_currentPaymentTokenAddress).transfer(_beneficiary, _undistributed_admin_fee)
		log AdminFeeWithdrawn(_beneficiary, _currentPaymentTokenAddress, _undistributed_admin_fee)

@view
@external
def withdrawableFundsOf(_receiver: address, _paymentTokenAddress: address) -> uint256:

    return self._withdrawableFundsOf(_receiver, _paymentTokenAddress)

@view
@external
def withdrawnFundsOf(_receiver: address, _paymentTokenAddress: address) -> uint256:
    return self.withdrawnFunds[_paymentTokenAddress][_receiver]

@external
@payable
def payToContract(_amount: uint256, _paymentTokenAddress: address) -> bool:

	assert self.payment_token_governor_proxy.get_payment_token_acceptance(_paymentTokenAddress) == True, "Token not accepted for payment"

	assert ERC20(_paymentTokenAddress).allowance(msg.sender, self) >= _amount
	ERC20(_paymentTokenAddress).transferFrom(msg.sender, self, _amount)
	log FundsDeposited(msg.sender, _paymentTokenAddress, _amount)

	return True

@external
@payable
def __default__():
    pass

@external
@view
def getPointsPerShare(_paymentTokenAddress: address) -> uint256:
    return self.pointsPerShare[_paymentTokenAddress]