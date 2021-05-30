# @version ^0.2.0

"""
@title Conditional NFT Factory
@author Gary Tse
@notice Factory to deploy `ConditionalNFT` contracts
"""

interface ConditionalNFT:
	def initialize(
		_name: String[64],
		_symbol: String[32],
		_tokenURI: String[128],
		_maxSupply: uint256,
		_minPrice: uint256,
		_lockAddress: address,
		_minter: address,
		_beneficiary: address
	) -> bool: nonpayable

event ConditionalNFTCreated:
	token: address
	name: String[64]
	symbol: String[32]

# @dev Target address of the ConditionalNFT contract
target: public(address)

# @dev Coutn of cNFT instances
totalCount: public(uint256)

# @dev Mapping of index to cNFT address
indexToCNFT: HashMap[uint256, address]

# @dev Mapping of cNFT to Lock address
indexToCNFTToLock: HashMap[uint256, HashMap[address, address]]

@external
def __init__(_target: address):
	self.target = _target
	self.totalCount = 0

@external
def deploy_cnft_contract(
	_name: String[64],
	_symbol: String[32],
	_tokenURI: String[128],
	_maxSupply: uint256,
	_minPrice: uint256,
	_lockAddress: address
) -> address:
	"""
	@notice Deploy a cNFT contract
	@param _name Name of the token
	@param _symbol Symbol of the token
	@param _tokenURI URI of the token metadata
	@param _maxSupply Maximum supply of the token
	@param _minPrice Minimum price of the token
	@param _lockAddress Address of the Lock contract that is condition for holding, transferring and receiving token
	@return address Address of deployed cNFT
	"""
	_contract: address = create_forwarder_to(self.target)
	ConditionalNFT(_contract).initialize(
		_name,
		_symbol,
		_tokenURI,
		_maxSupply,
		_minPrice,
		_lockAddress,
		msg.sender,
		msg.sender
	)
	log ConditionalNFTCreated(_contract, _name, _symbol)
	self.totalCount += 1
	current_index: uint256 = self.totalCount
	self.indexToCNFT[current_index] = _contract
	self.indexToCNFTToLock[current_index][_contract] = _lockAddress
	return _contract

@view
@external
def get_cnft_by_index(
	_index: uint256
) -> address:
	"""
	@notice Get cNFT address by index
	@param _index Index of cNFT
	@return address Address of cNFT at index
	"""
	return self.indexToCNFT[_index]

@view
@external
def get_lock_by_index_and_cnft(
	_index: uint256,
	_cnft: address
) -> address:
	"""
	@notice Get lock address by index and cNFT
	@param _index Index of cNFT
	@param _cnft Address of cNFT
	@return address Address of lock for given index and cNFT
	"""
	return self.indexToCNFTToLock[_index][_cnft]