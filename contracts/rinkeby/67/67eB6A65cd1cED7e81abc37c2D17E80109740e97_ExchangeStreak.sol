// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../openzepplin-contracts/token/ERC20/IERC20.sol";
import "../openzepplin-contracts/token/ERC721/IERC721.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155.sol";


contract ExchangeStreak {
	struct ERC1155Offer {
		uint tokenId;
		uint quantity;
		uint price;
		address seller;
	}

	event TokenPriceListed (uint indexed _tokenId, address indexed _owner, uint _price);
	event TokenPriceDeleted (uint indexed _tokenId);
	event TokenPriceUnlisted (uint indexed _tokenId);
	event TokenSold (uint indexed _tokenId, uint _price, bool _soldForERC20);
	event TokenOwned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner);
	event TokenBought (uint indexed _tokenId, uint _price, address indexed _previousOwner, address indexed _newOwner, bool _soldForERC20);
	event Token1155OfferListed (uint indexed _tokenId, uint indexed _offerId, address indexed _owner, uint _quantity, uint _price);
	event Token1155OfferDeleted (uint indexed _tokenId, uint indexed _offerId);
	event Token1155PriceUnlisted (uint indexed _tokenId, uint indexed _offerId);
	event Token1155Sold(uint indexed _tokenId, uint indexed _offerId, uint _quantity, uint _price, bool _soldForERC20);
	event Token1155Owned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner, uint _quantity);
	event Token1155Bought (uint _tokenId, uint indexed _offerId, uint _quantity, uint _price, address indexed _previousOwner, address indexed _newOwner, bool _soldForERC20);

	address public signerAddress;
	address owner;

	bytes32 public name = "ExchangeStreak";

	uint public offerIdCounter;
	uint public safeVolatilityPeriod;

	IERC20 public erc20Contract;
	IERC721 public erc721Contract;
	IERC1155 public erc1155Contract;

	mapping(address => uint) public nonces;
	mapping(uint => uint) public ERC721Prices;
	mapping(uint => ERC1155Offer) public ERC1155Offers;
	mapping(address => mapping(uint => uint)) public tokensListed;

	constructor (
		address _signerAddress,
		address _erc721Address,
		address _erc1155Address,
		address _erc20Address
	)
	{
		require (_signerAddress != address(0));
		require (_erc721Address != address(0));
		require (_erc1155Address != address(0));
		require (_erc20Address != address(0));

		owner = msg.sender;
		signerAddress = _signerAddress;
		erc721Contract = IERC721(_erc721Address);
		erc1155Contract = IERC1155(_erc1155Address);
		erc20Contract = IERC20(_erc20Address);

		safeVolatilityPeriod = 4 hours;
	}

	function listToken(
		uint _tokenId,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(erc721Contract.ownerOf(_tokenId) == msg.sender);
		require(ERC721Prices[_tokenId] == 0);
		ERC721Prices[_tokenId] = _price;
		emit TokenPriceListed(_tokenId, msg.sender, _price);
	}

	function listToken1155(
		uint _tokenId,
		uint _quantity,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(erc1155Contract.balanceOf(msg.sender, _tokenId) >= tokensListed[msg.sender][_tokenId] + _quantity);

		uint offerId = offerIdCounter++;
		ERC1155Offers[offerId] = ERC1155Offer({
			tokenId: _tokenId,
			quantity: _quantity,
			price: _price,
			seller: msg.sender
		});

		tokensListed[msg.sender][_tokenId] += _quantity;
		emit Token1155OfferListed(_tokenId, offerId, msg.sender, _quantity, _price);
	}

	function removeListToken(
		uint _tokenId
	)
	external
	{
		require(erc721Contract.ownerOf(_tokenId) == msg.sender);
		deleteTokenPrice(_tokenId);

		emit TokenPriceUnlisted(_tokenId);
	}

	function removeListToken1155(
		uint _offerId
	)
	external
	{
		require(ERC1155Offers[_offerId].seller == msg.sender);
		ERC1155Offer memory offer = ERC1155Offers[_offerId];
		deleteToken1155Offer(_offerId);

		emit Token1155PriceUnlisted(offer.tokenId, _offerId);
	}

	function deleteTokenPrice(
		uint _tokenId
	)
	internal
	{
		delete ERC721Prices[_tokenId];
		emit TokenPriceDeleted(_tokenId);
	}

	function deleteToken1155Offer(
		uint _offerId
	)
	internal
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];
		tokensListed[offer.seller][offer.tokenId] -= offer.quantity;

		delete ERC1155Offers[_offerId];
		emit Token1155OfferDeleted(offer.tokenId, _offerId);
	}

	function buyToken(
		uint _tokenId
	)
	external
	payable
	{
		require(ERC721Prices[_tokenId] > 0, "token is not for sale");
		require(ERC721Prices[_tokenId] <= msg.value);

		address tokenOwner = erc721Contract.ownerOf(_tokenId);

		address payable payableTokenOwner = payable(tokenOwner);
		(bool sent, ) = payableTokenOwner.call{value: msg.value}("");
		require(sent);

		erc721Contract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

		emit TokenSold(_tokenId, msg.value, false);
		emit TokenOwned(_tokenId, tokenOwner, msg.sender);

		emit TokenBought(_tokenId, msg.value, tokenOwner, msg.sender, false);

		deleteTokenPrice(_tokenId);
	}

	function buyToken1155(
		uint _offerId,
		uint _quantity
	)
	external
	payable
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);
		require(offer.price * _quantity <= msg.value);

		address payable payableSeller = payable(offer.seller);
		(bool sent, ) = payableSeller.call{value: msg.value}("");
		require(sent);

		erc1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, offer.price, false);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		emit Token1155Bought(offer.tokenId, _offerId, _quantity, offer.price, offer.seller, msg.sender, false);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function buyTokenForERC20(
		uint _tokenId,
		uint _priceInERC20,
		uint _nonce,
		bytes calldata _signature,
		uint _timestamp
	)
	external
	{
		bytes32 hash = keccak256(abi.encodePacked(_tokenId, _priceInERC20, _nonce, _timestamp));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signerAddress, "invalid secret signer");

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		if (safeVolatilityPeriod > 0) {
			require(_timestamp + safeVolatilityPeriod >= block.timestamp, "safe volatility period exceeded");
		}
		require(ERC721Prices[_tokenId] > 0, "token is not for sale");

		nonces[msg.sender] = _nonce;

		address tokenOwner = erc721Contract.ownerOf(_tokenId);

		bool sent = erc20Contract.transferFrom(msg.sender, tokenOwner, _priceInERC20);
		require(sent);

		erc721Contract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

		emit TokenSold(_tokenId, _priceInERC20, true);
		emit TokenOwned(_tokenId, tokenOwner, msg.sender);

		deleteTokenPrice(_tokenId);
	}

	function buyToken1155ForERC20(
		uint _offerId,
		uint _quantity,
		uint _priceInERC20,
		uint _nonce,
		bytes calldata _signature,
		uint _timestamp
	)
	external
	{
		bytes32 hash = keccak256(abi.encodePacked(_offerId, _quantity, _priceInERC20, _nonce, _timestamp));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signerAddress, "invalid secret signer");

		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		if (safeVolatilityPeriod > 0) {
			require(_timestamp + safeVolatilityPeriod >= block.timestamp, "safe volatility period exceeded");
		}
		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);

		nonces[msg.sender] = _nonce;

		erc20Contract.transferFrom(msg.sender, offer.seller, _priceInERC20 * _quantity);
		erc1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, _priceInERC20, true);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function setSigner(
		address _newSignerAddress
	)
	external
	{
		require(msg.sender == owner);
		signerAddress = _newSignerAddress;
	}

	function setSafeVolatilityPeriod(
		uint _newSafeVolatilityPeriod
	)
	external
	{
		require(msg.sender == owner);
		safeVolatilityPeriod = _newSafeVolatilityPeriod;
	}

	function recoverSignerAddress(
		bytes32 _hash,
		bytes memory _signature
	)
	internal
	pure
	returns (address)
	{
		require(_signature.length == 65, "invalid signature length");

		bytes32 r;
		bytes32 s;
		uint8 v;

		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := and(mload(add(_signature, 65)), 255)
		}

		if (v < 27) {
			v += 27;
		}

		if (v != 27 && v != 28) {
			return address(0);
		}

		return ecrecover(_hash, v, r, s);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

