// File: contracts/Seller.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

contract SellersAuthorization {
  mapping(address => bool) internal sellers;

  /**
   * @dev Returns true if @param _seller is true.
   */
  function isSeller(address _seller) public view returns (bool) {
    return sellers[_seller];
  }

  /**
   * @dev Enables a seller.
   * @param _newSeller The new seller address.
   */
  function _addSeller(address _newSeller) internal returns (bool) {
    require(_newSeller != address(0), 'Address 0x0 not valid');
    sellers[_newSeller] = true;
    return sellers[_newSeller];
  }

  /**
   * @dev Removes a seller.
   * @param _seller The address of the seller to remove.
   */

  function _removeSeller(address _seller) internal returns (bool) {
    sellers[_seller] = false;
    return sellers[_seller];
  }

  /**
   * @dev Push the amount earned to the seller as soon as the tx is completed.
   */
  function _pushPayment(address payable _seller, uint256 _amount) internal {
    require(_seller != address(0));
    _seller.transfer(_amount);
  }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

pragma solidity ^0.6.2;

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
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );

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
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

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
  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

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
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

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
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
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
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
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
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
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
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
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
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/Marketplace.sol

pragma solidity 0.6.10;

contract Marketplace is Ownable, SellersAuthorization {
  using SafeMath for uint256;

  uint256 public offerIdCounter = 0;
  bool public paused = false;

  event OfferCreated(
    address indexed _tokenAddress,
    address indexed _seller,
    uint256 _tokenId,
    uint256 _tokenAmount,
    uint256 _price,
    uint256 _offerIdCounter
  );
  event OfferCancelled(
    address indexed _tokenAddress,
    uint256 _tokenId,
    uint256 _offerId
  );
  event OfferSuccess(
    address indexed _tokenAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _offerIdCounter,
    address _newOwner
  );

  modifier isNotPaused() {
    require(!paused, 'Contract paused');
    _;
  }

  /*
   * @dev hasTokens Makes sure the seller has enough tokens.
   */
  modifier hasTokens(
    address _token,
    address _seller,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) {
    require(
      IERC1155(_token).balanceOf(_seller, _tokenId) >= _tokenAmount,
      'Seller does not own enough tokens'
    );
    _;
  }

  struct Offer {
    address tokenAddress;
    address payable seller;
    uint256 tokenId;
    uint256 tokenAmount;
    uint256 price; // The price for 1 (one) token.
  }

  mapping(uint256 => Offer) private offers;

  /**
   * @dev Creates an offer for the give tokenId.
   * @dev Needs to approve this contract first
   * @param _tokenAddress The token contract address
   * @param _tokenId The token Id on sale.
   * @param _tokenAmount Amount of tokens to sell
   * @param _price The price of the token Id on sale.
   */
  function createOffer(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _tokenAmount,
    uint256 _price
  )
    public
    hasTokens(_tokenAddress, msg.sender, _tokenId, _tokenAmount)
    isNotPaused
  {
    require(isSeller(msg.sender));
    require(
      IERC1155(_tokenAddress).isApprovedForAll(msg.sender, address(this)),
      'Missing approval'
    );
    require(_price > 0);

    offers[offerIdCounter].tokenAddress = _tokenAddress;
    offers[offerIdCounter].tokenId = _tokenId;
    offers[offerIdCounter].seller = msg.sender;
    offers[offerIdCounter].tokenAmount = _tokenAmount;
    offers[offerIdCounter].price = _price;

    emit OfferCreated(
      _tokenAddress,
      msg.sender,
      _tokenId,
      _tokenAmount,
      _price,
      offerIdCounter
    );

    offerIdCounter = offerIdCounter.add(1);
  }

  /**
   * @dev Removed an offer.
   * @param _offerId The offer Id that has to be removed.
   * @notice Require msg.sender equals to the offer seller.
   */
  function deleteOffer(uint256 _offerId) public isNotPaused {
    require(
      offers[_offerId].seller == msg.sender,
      'Msg.sender is not the seller'
    );
    emit OfferCancelled(
      offers[_offerId].tokenAddress,
      offers[_offerId].tokenId,
      _offerId
    );
    delete (offers[_offerId]);
  }

  /**
   * @dev Allows user to buy token.
   * @param _offerId The offer Id the user wants to buy.
   * @param _tokenAmount The amount of tokens the user wants to buy.
   * @notice Pushes the payment to seller.
   */
  function buyToken(uint256 _offerId, uint256 _tokenAmount)
    public
    payable
    isNotPaused
    hasTokens(
      offers[_offerId].tokenAddress,
      offers[_offerId].seller,
      offers[_offerId].tokenId,
      _tokenAmount
    )
  {
    require(_tokenAmount > 0, 'Token amount cannot be 0');
    require(
      msg.value == offers[_offerId].price.mul(_tokenAmount),
      'Invalid amount'
    );
    require(
      IERC1155(offers[_offerId].tokenAddress).isApprovedForAll(
        offers[_offerId].seller,
        address(this)
      ),
      'Missing approval'
    );

    offers[_offerId].tokenAmount = offers[_offerId].tokenAmount.sub(
      _tokenAmount
    );

    IERC1155(offers[_offerId].tokenAddress).safeTransferFrom(
      offers[_offerId].seller,
      msg.sender,
      offers[_offerId].tokenId,
      _tokenAmount,
      '0x0'
    );

    _pushPayment(offers[_offerId].seller, msg.value);

    emit OfferSuccess(
      offers[_offerId].tokenAddress,
      offers[_offerId].tokenId,
      msg.value,
      _offerId,
      msg.sender
    );
  }

  /**
   * @dev A wrapper for _addSeller ().
   * @param _newSeller The address of the new seller enabled.
   * @notice Function restricted to the contract owner.
   */
  function addSeller(address _newSeller) public onlyOwner {
    require(_addSeller(_newSeller));
  }

  /**
   * @dev A wrapper for _removeSeller ().
   * @param _seller The address of the seller to remove.
   * @notice Function restricted to the contract owner.
   */
  function removeSeller(address _seller) public onlyOwner {
    require(!_removeSeller(_seller));
  }

  /**
   * @dev Returns offer details for given offer id.
   * @param _offerId The offer id.
   * @notice If seller balanceOf is lower than the amount of tokens on sale
   * returns the balanceOf (_seller).
   */
  function getOffer(uint256 _offerId) public view returns (Offer memory) {
    Offer memory _offer = offers[_offerId];
    uint256 balanceOf = IERC1155(_offer.tokenAddress).balanceOf(
      _offer.seller,
      _offer.tokenId
    );
    if (_offer.tokenAmount > balanceOf) {
      _offer.tokenAmount = balanceOf;
    }
    return _offer;
  }

  /**
   * @dev Pause the contract.
   * @param _paused True if should pause.
   */
  function pauseContract(bool _paused) public onlyOwner {
    paused = _paused;
  }

  /**
   * @dev Safe.
   */
  function withdrawAll() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}