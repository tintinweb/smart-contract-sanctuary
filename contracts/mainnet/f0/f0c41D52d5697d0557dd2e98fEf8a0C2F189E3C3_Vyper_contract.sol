from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
	_from: indexed(address)
	_to: indexed(address)
	_value: uint256

event Approval:
	_owner: indexed(address)
	_spender: indexed(address)
	_value: uint256

event Freeze:
	_account: indexed(address)
	_freeze: bool

name: public(String[10])
symbol: public(String[3])
coinSupply: public(uint256)
maxSupply: public(uint256)
decimals: public(uint256)
balances: public(HashMap[address, uint256])

allowed: HashMap[address, HashMap[address, uint256]]
frozenBalances: public(HashMap[address, bool])
owner: public(address)

ecoMgr: public(address)

@external
def __init__():
	_initialSupply: uint256 = 10000000000
	_decimals: uint256 = 18
	self.coinSupply = _initialSupply * 10 ** _decimals
	self.name = 'SmartrCoin'
	self.symbol = 'SMC'
	self.decimals = _decimals
	self.owner = msg.sender
	self.balances[msg.sender] = self.coinSupply
	self.maxSupply = (_initialSupply * 10 ** _decimals) * 2

	log Transfer(ZERO_ADDRESS, msg.sender, self.coinSupply)

@external
def addMgr(_mgr: address) -> bool:
	assert msg.sender == self.owner
	self.ecoMgr = _mgr
	return True

@external
def freezeBalance(_target: address, _freeze: bool) -> bool:
	assert self.ecoMgr == msg.sender or msg.sender == self.owner
	self.frozenBalances[_target] = _freeze

	log Freeze(_target, _freeze)

	return True

@external
def mintCoin(_value: uint256) -> bool:
	"""
	@dev Mint an amount of coin
	@param _value The amount of coin to be minted.
	"""
	assert self.ecoMgr == msg.sender or self.owner == msg.sender
	assert self.coinSupply + _value <= self.maxSupply
	self.coinSupply += _value
	self.balances[msg.sender] += _value

	log Transfer(ZERO_ADDRESS, msg.sender, _value)

	return True

@external
def burnCoin(_value: uint256) -> bool:
	"""
	@dev Burn an amount of coin
	@param _value The amount of coin to be burned
	"""
	assert self.ecoMgr == msg.sender or self.owner == msg.sender
	assert self.balances[msg.sender] >= _value
	self.coinSupply -= _value
	self.balances[msg.sender] -= _value

	log Transfer(msg.sender, ZERO_ADDRESS, _value)

	return True

@external
def balanceOf(_owner: address) -> uint256:
	return self.balances[_owner]

@external
def transfer(_to: address, _amount: uint256) -> bool:
	assert _to != ZERO_ADDRESS
	assert self.balances[msg.sender] >= _amount
	assert self.frozenBalances[msg.sender] == False
	self.balances[msg.sender] -= _amount
	self.balances[_to] += _amount

	log Transfer(msg.sender, _to, _amount)

	return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
	assert _value <= self.allowed[_from][msg.sender]
	assert _value <= self.balances[_from]
	assert self.frozenBalances[msg.sender] == False

	self.balances[_from] -= _value
	self.allowed[_from][msg.sender] -= _value
	self.balances[_to] += _value

	log Transfer (_from, _to, _value)

	return True

@external
def approve(_spender: address, _amount: uint256) -> bool:
	self.allowed[msg.sender][_spender] = _amount

	log Approval(msg.sender, _spender, _amount)

	return True

@external
def allowance(_owner: address, _spender: address) -> uint256:
	return self.allowed[_owner][_spender]

@external
def totalSupply() -> uint256:
	return self.coinSupply