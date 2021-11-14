//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
		* @dev Initializes the contract setting the deployer as the initial owner.
		*/
	constructor() {
		_setOwner(_msgSender());
	}

	/**
		* @dev Returns the address of the current owner.
		*/
	function owner() public view virtual returns (address) {
		return _owner;
	}

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner.");
			_;
	}

	/**
		* @dev Leaves the contract without owner. It will not be possible to call
		* `onlyOwner` functions anymore. Can only be called by the current owner.
		*
		* NOTE: Renouncing ownership will leave the contract without an owner,
		* thereby removing any functionality that is only available to the owner.
		*/
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

	/**
		* @dev Transfers ownership of the contract to a new account (`newOwner`).
		* Can only be called by the current owner.
		*/
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address.");
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

library SafeMath {
	/**
	* @dev Returns the addition of two unsigned integers, with an overflow flag.
	*
	* _Available since v3.4._
	*/
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
		* @dev Returns the substraction of two unsigned integers, with an overflow flag.
		*
		* _Available since v3.4._
		*/
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	/**
		* @dev Returns the multiplication of two unsigned integers, with an overflow flag.
		*
		* _Available since v3.4._
		*/
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
		* @dev Returns the division of two unsigned integers, with a division by zero flag.
		*
		* _Available since v3.4._
		*/
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	/**
		* @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
		*
		* _Available since v3.4._
		*/
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

	/**
		* @dev Returns the addition of two unsigned integers, reverting on
		* overflow.
		*
		* Counterpart to Solidity's `+` operator.
		*
		* Requirements:
		*
		* - Addition cannot overflow.
		*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		return a + b;
	}

	/**
		* @dev Returns the subtraction of two unsigned integers, reverting on
		* overflow (when the result is negative).
		*
		* Counterpart to Solidity's `-` operator.
		*
		* Requirements:
		*
		* - Subtraction cannot overflow.
		*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}

	/**
		* @dev Returns the multiplication of two unsigned integers, reverting on
		* overflow.
		*
		* Counterpart to Solidity's `*` operator.
		*
		* Requirements:
		*
		* - Multiplication cannot overflow.
		*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}

	/**
		* @dev Returns the integer division of two unsigned integers, reverting on
		* division by zero. The result is rounded towards zero.
		*
		* Counterpart to Solidity's `/` operator.
		*
		* Requirements:
		*
		* - The divisor cannot be zero.
		*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	/**
		* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
		* reverting when dividing by zero.
		*
		* Counterpart to Solidity's `%` operator. This function uses a `revert`
		* opcode (which leaves remaining gas untouched) while Solidity uses an
		* invalid opcode to revert (consuming all remaining gas).
		*
		* Requirements:
		*
		* - The divisor cannot be zero.
		*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return a % b;
	}

	/**
		* @dev Returns the subtraction of two unsigned integers, reverting with custom message on
		* overflow (when the result is negative).
		*
		* CAUTION: This function is deprecated because it requires allocating memory for the error
		* message unnecessarily. For custom revert reasons use {trySub}.
		*
		* Counterpart to Solidity's `-` operator.
		*
		* Requirements:
		*
		* - Subtraction cannot overflow.
		*/
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	/**
		* @dev Returns the integer division of two unsigned integers, reverting with custom message on
		* division by zero. The result is rounded towards zero.
		*
		* Counterpart to Solidity's `/` operator. Note: this function uses a
		* `revert` opcode (which leaves remaining gas untouched) while Solidity
		* uses an invalid opcode to revert (consuming all remaining gas).
		*
		* Requirements:
		*
		* - The divisor cannot be zero.
		*/
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}

	/**
		* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
		* reverting with custom message when dividing by zero.
		*
		* CAUTION: This function is deprecated because it requires allocating memory for the error
		* message unnecessarily. For custom revert reasons use {tryMod}.
		*
		* Counterpart to Solidity's `%` operator. This function uses a `revert`
		* opcode (which leaves remaining gas untouched) while Solidity uses an
		* invalid opcode to revert (consuming all remaining gas).
		*
		* Requirements:
		*
		* - The divisor cannot be zero.
		*/
	function mod(
			uint256 a,
			uint256 b,
			string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

library Address {
 
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance.");

		(bool success, ) = recipient.call{value: amount}("");
		require(success, "Address: unable to send value, recipient may have reverted.");
	}

	
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed.");
	}


	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}


	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call.");
		require(isContract(target), "Address: call to non-contract.");

		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed.");
	}

	
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract.");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed.");
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract.");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
				// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

abstract contract Pausable is Context {
	/**
		* @dev Emitted when the pause is triggered by `account`.
		*/
	event Paused(address account);

	/**
		* @dev Emitted when the pause is lifted by `account`.
		*/
	event Unpaused(address account);

	bool private _paused;

	/**
		* @dev Initializes the contract in unpaused state.
		*/
	constructor() {
		_paused = false;
	}

	/**
		* @dev Returns true if the contract is paused, and false otherwise.
		*/
	function paused() public view virtual returns (bool) {
		return _paused;
	}

	modifier whenNotPaused() {
		require(!paused(), "Pausable: paused.");
		_;
	}

	modifier whenPaused() {
		require(paused(), "Pausable: not paused.");
		_;
	}

	function _pause() internal virtual whenNotPaused {
		_paused = true;
		emit Paused(_msgSender());
	}

	function _unpause() internal virtual whenPaused {
		_paused = false;
		emit Unpaused(_msgSender());
	}
}

interface IERC165 {

	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
	/**
		* @dev Emitted when `tokenId` token is transfered from `from` to `to`.
		*/
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	/**
		* @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
		*/
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	/**
		* @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
		*/
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/**
		* @dev Returns the number of tokens in ``owner``'s account.
		*/
	function balanceOf(address owner) external view returns (uint256 balance);

	/**
		* @dev Returns the owner of the `tokenId` token.
		*
		* Requirements:
		*
		* - `tokenId` must exist.
		*/
	function ownerOf(uint256 tokenId) external view returns (address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns (address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns (bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
	function transferToken(address _address, uint256 _tokenId) external payable;
	function transferCheck(uint256 _tokenId, uint256 _price) external;
}

interface IMarketplace {

	struct Order {
		// Order ID
		bytes32 id;
		// Owner of the NFT
		address seller;
		// NFT registry address
		address nftAddress;
		// Price (in wei) for the published item
		uint256 price;
		// Time when this sale ends
		uint256 expiresAt;
	}

	struct Bid {
		// Bid Id
		bytes32 id;
		// Bidder address
		address bidder;
		// Price for the bid in wei
		uint256 price;
		// Time when this bid ends
		uint256 expiresAt;
	}

	// ORDER EVENTS
	event OrderCreated(
		bytes32 id,
		address indexed seller,
		address indexed nftAddress,
		uint256 indexed assetId,
		uint256 priceInWei,
		uint256 expiresAt
	);

	event OrderUpdated(
		bytes32 id,
		uint256 priceInWei,
		uint256 expiresAt
	);

	event OrderSuccessful(
		bytes32 id,
		address indexed buyer,
		uint256 priceInWei
	);

	event OrderCancelled(bytes32 id);

	// BID EVENTS
	event BidCreated(
		bytes32 id,
		address indexed nftAddress,
		uint256 indexed assetId,
		address indexed bidder,
		uint256 priceInWei,
		uint256 expiresAt
	);

	event BidAccepted(bytes32 id);
	event BidCancelled(bytes32 id);
}

contract Marketplace is Ownable, Pausable, IMarketplace {

	using Address for address;
	using SafeMath for uint256;

	// From ERC721 registry assetId to Order (to avoid asset collision)
	mapping(address => mapping(uint256 => Order)) public orderByAssetId;

	// From ERC721 registry assetId to Bid (to avoid asset collision)
	mapping(address => mapping(uint256 => Bid)) public bidByOrderId;

	// 721 Interfaces
	bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	uint256 private platformFees = 10;

	event Log(string message);
	event LogBytes(bytes data);

	constructor(){
	}


	function updatePlatformFee(uint256 _platformFee) external onlyOwner {
		platformFees= _platformFee;
	}

	function amountAfterFees(uint256 _price) internal view returns(uint256){
		uint256 shareAfterFees = _price.sub(_price.mul(platformFees).div(100));
		return shareAfterFees;
	}

	/**
		* @dev Sets the paused failsafe. Can only be called by owner
		* @param _setPaused - paused state
		*/
	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	/**
		* @dev Creates a new order
		* @param _nftAddress - Non fungible registry address
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Price in Wei for the supported coin
		* @param _expiresAt - Duration of the order (in hours)
		*/
	function createOrder(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth,
		uint256 _expiresAt
	)
		public whenNotPaused payable
	{
		// Check nft registry
		IERC721 nftRegistry = _requireERC721(_nftAddress);

		require(_priceInEth > 0, "Marketplace: Price should be bigger than 0.");

		require(
			_expiresAt > block.timestamp.add(1 minutes),
			"Marketplace: Publication should be more than 1 minute in the future."
		);

		try nftRegistry.transferCheck(_tokenId, msg.value) {
			nftRegistry.transferToken{value: msg.value}(msg.sender, _tokenId);
			_createOrder(_nftAddress, _tokenId, _priceInEth, _expiresAt);
			emit Log("Succefully order created!");
		} catch Error(string memory reason) {
			emit Log(reason);
			payable(msg.sender).transfer(msg.value);
		}
	}


	/**
		* @dev Cancel an already published order
		*  can only be canceled by seller or the contract owner
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		*/
	function cancelOrder(
		address _nftAddress,
		uint256 _tokenId
	)
		public whenNotPaused
	{
		Order memory order = orderByAssetId[_nftAddress][_tokenId];

		require(
			order.seller == msg.sender || msg.sender == owner(),
			"Marketplace: unauthorized sender."
		);

		// Remove pending bid if any
		Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

		if (bid.id != 0) {
			_cancelBid(
				bid.id,
				_nftAddress,
				_tokenId,
				bid.bidder,
				bid.price
			);
		}

		// Cancel order.
		_cancelOrder(
			order.id,
			_nftAddress,
			_tokenId,
			msg.sender
		);
	}


	/**
		* @dev Update an already published order
		*  can only be updated by seller
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		*/
	function updateOrder(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth,
		uint256 _expiresAt
	)
			public whenNotPaused
	{
		Order memory order = orderByAssetId[_nftAddress][_tokenId];

		// Check valid order to update
		require(order.id != 0, "Marketplace: asset not published.");
		require(order.seller == msg.sender, "Marketplace: sender not allowed.");
		require(order.expiresAt >= block.timestamp, "Marketplace: order expired.");

		// check order updated params
		require(_priceInEth > 0, "Marketplace: Price should be bigger than 0.");
		require(
			_expiresAt > block.timestamp.add(1 minutes),
			"Marketplace: Expire time should be more than 1 minute in the future."
		);

		order.price = _priceInEth;
		order.expiresAt = _expiresAt;

		emit OrderUpdated(order.id, _priceInEth, _expiresAt);
	}


	/**
		* @dev Executes the sale for a published NFT and checks for the asset fingerprint
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Order price
		*/
	function safeExecuteOrder(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth
	)
		public whenNotPaused payable
	{
		// Get the current valid order for the asset or fail
		Order memory order = _getValidOrder(
				_nftAddress,
				_tokenId
		);

		/// Check the execution price matches the order price
		require(msg.value >= order.price, "Marketplace: Insufficient price.");
		require(order.seller != msg.sender, "Marketplace: unauthorized sender.");

		// Transfer eth minus market fee to seller
		uint256 _amount = amountAfterFees(order.price);
		payable(order.seller).transfer(_amount);

		// Remove pending bid if any
		Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

		if (bid.id != 0) {
			_cancelBid(
				bid.id,
				_nftAddress,
				_tokenId,
				bid.bidder,
				bid.price
			);
		}

		_executeOrder(
			order.id,
			msg.sender, // buyer
			_nftAddress,
			_tokenId,
			_priceInEth
		);
	}


	/**
		* @dev Places a bid for a published NFT and checks for the asset fingerprint
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Bid price in acceptedToken currency
		* @param _expiresAt - Bid expiration time
		*/
	function safePlaceBid(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth,
		uint256 _expiresAt)
		public whenNotPaused
	{
	
		_createBid(
			_nftAddress,
			_tokenId,
			_priceInEth,
			_expiresAt
		);
	}


	/**
		* @dev Cancel an already published bid
		*  can only be canceled by seller or the contract owner
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		*/
	function cancelBid(
		address _nftAddress,
		uint256 _tokenId
	)
		public whenNotPaused
	{
		Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

		require(
			bid.bidder == msg.sender || msg.sender == owner(),
			"Marketplace: Unauthorized sender."
		);

		_cancelBid(
			bid.id,
			_nftAddress,
			_tokenId,
			bid.bidder,
			bid.price
		);
	}


	/**
		* @dev Executes the sale for a published NFT by accepting a current bid
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Bid price in wei in acceptedTokens currency
		*/
	function acceptBid(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth
	)
		public whenNotPaused
	{
		// check order validity
		Order memory order = _getValidOrder(_nftAddress, _tokenId);

		// item seller is the only allowed to accept a bid
		require(order.seller == msg.sender, "Marketplace: unauthorized sender.");

		Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

		require(bid.price == _priceInEth, "Marketplace: invalid bid price.");
		require(bid.expiresAt >= block.timestamp, "Marketplace: the bid expired.");

		// remove bid
		delete bidByOrderId[_nftAddress][_tokenId];

		emit BidAccepted(bid.id);

		uint256 _amount = amountAfterFees(bid.price);
		payable(order.seller).transfer(_amount);

		_executeOrder(
			order.id,
			bid.bidder,
			_nftAddress,
			_tokenId,
			_priceInEth
		);
	}


	/**
		* @dev Internal function gets Order by nftRegistry and assetId. Checks for the order validity
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		*/
	function _getValidOrder(
		address _nftAddress,
		uint256 _tokenId
	)
			internal view returns (Order memory order)
	{
		order = orderByAssetId[_nftAddress][_tokenId];

		require(order.id != 0, "Marketplace: asset not published.");
		require(order.expiresAt >= block.timestamp, "Marketplace: order expired.");
	}


	/**
		* @dev Executes the sale for a published NFT
		* @param _orderId - Order Id to execute
		* @param _buyer - address
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - NFT id
		* @param _priceInEth - Order price
		*/
	function _executeOrder(
		bytes32 _orderId,
		address _buyer,
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth
	)
		internal
	{
		// remove order
		delete orderByAssetId[_nftAddress][_tokenId];

		// Transfer NFT asset
		IERC721(_nftAddress).safeTransferFrom(
			address(this),
			_buyer,
			_tokenId
		);

		// Notify ..
		emit OrderSuccessful(
			_orderId,
			_buyer,
			_priceInEth
		);
	}


	/**
		* @dev Creates a new order
		* @param _nftAddress - Non fungible registry address
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Price in Wei for the supported coin
		* @param _expiresAt - Expiration time for the order
		*/
	function _createOrder(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth,
		uint256 _expiresAt
	)
		internal
	{
		// Check nft registry
		IERC721 nftRegistry = _requireERC721(_nftAddress);

		// Check order creator is the asset owner
		address assetOwner = nftRegistry.ownerOf(_tokenId);

		// create the orderId
		bytes32 orderId = keccak256(
			abi.encodePacked(
				block.timestamp,
				assetOwner,
				_nftAddress,
				_tokenId,
				_priceInEth
			)
		);

		// save order
		orderByAssetId[_nftAddress][_tokenId] = Order({
			id: orderId,
			seller: assetOwner,
			nftAddress: _nftAddress,
			price: _priceInEth,
			expiresAt: _expiresAt
		});

		emit OrderCreated(
			orderId,
			assetOwner,
			_nftAddress,
			_tokenId,
			_priceInEth,
			_expiresAt
		);
	}


	/**
		* @dev Creates a new bid on a existing order
		* @param _nftAddress - Non fungible registry address
		* @param _tokenId - ID of the published NFT
		* @param _priceInEth - Price in Wei for the supported coin
		* @param _expiresAt - expires time
		*/
	function _createBid(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _priceInEth,
		uint256 _expiresAt
	)
		internal
	{
		// Checks order validity
		Order memory order = _getValidOrder(_nftAddress, _tokenId);

		// check on expire time
		if (_expiresAt > order.expiresAt) {
				_expiresAt = order.expiresAt;
		}

		// Check price if theres previous a bid
		Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

		// if theres no previous bid, just check price > 0
		if (bid.id != 0) {
			if (bid.expiresAt >= block.timestamp) {
				require(
					_priceInEth > bid.price,
					"Marketplace: bid price should be higher than last bid."
				);

			} else {
				require(_priceInEth > 0, "Marketplace: bid should be > 0.");
			}

			_cancelBid(
				bid.id,
				_nftAddress,
				_tokenId,
				bid.bidder,
				bid.price
			);

		} else {
			require(_priceInEth > 0, "Marketplace: bid should be > 0.");
		}

		// Transfer sale amount from bidder to escrow
		// acceptedToken.safeTransferFrom(
		//     msg.sender, // bidder
		//     address(this),
		//     _priceInEth
		// );
		payable(msg.sender).transfer(_priceInEth);

		// Create bid
		bytes32 bidId = keccak256(
			abi.encodePacked(
				block.timestamp,
				msg.sender,
				order.id,
				_priceInEth,
				_expiresAt
			)
		);

		// Save Bid for this order
		bidByOrderId[_nftAddress][_tokenId] = Bid({
			id: bidId,
			bidder: msg.sender,
			price: _priceInEth,
			expiresAt: _expiresAt
		});

		emit BidCreated(
			bidId,
			_nftAddress,
			_tokenId,
			msg.sender, // bidder
			_priceInEth,
			_expiresAt
		);
	}


	/**
		* @dev Cancel an already published order
		*  can only be canceled by seller or the contract owner
		* @param _orderId - Bid identifier
		* @param _nftAddress - Address of the NFT registry
		* @param _tokenId - ID of the published NFT
		* @param _seller - Address
		*/
	function _cancelOrder(
		bytes32 _orderId,
		address _nftAddress,
		uint256 _tokenId,
		address _seller
	)
			internal
	{
		delete orderByAssetId[_nftAddress][_tokenId];

		/// send asset back to seller
		IERC721(_nftAddress).safeTransferFrom(
			address(this),
			_seller,
			_tokenId
		);

		emit OrderCancelled(_orderId);
	}


	/**
		* @dev Cancel bid from an already published order
		*  can only be canceled by seller or the contract owner
		* @param _bidId - Bid identifier
		* @param _nftAddress - registry address
		* @param _tokenId - ID of the published NFT
		* @param _bidder - Address
		* @param _escrowAmount - in acceptenToken currency
		*/
	function _cancelBid(
		bytes32 _bidId,
		address _nftAddress,
		uint256 _tokenId,
		address _bidder,
		uint256 _escrowAmount
	)
			internal
	{
		delete bidByOrderId[_nftAddress][_tokenId];

		// return escrow to canceled bidder
		// acceptedToken.safeTransfer(
		//     _bidder,
		//     _escrowAmount
		// );

		payable(_bidder).transfer(_escrowAmount);


		emit BidCancelled(_bidId);
	}


	function _requireERC721(address _nftAddress) internal view returns (IERC721) {
		require(
			_nftAddress.isContract(),
			"The NFT Address should be a contract."
		);
		require(
			IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
			"The NFT contract has an invalid ERC721 implementation."
		);
		return IERC721(_nftAddress);
	}
}