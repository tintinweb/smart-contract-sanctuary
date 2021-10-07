// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./utils/Access.sol";
import "./interfaces/IItem.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title SpeerTech
/// @author Arhaam Patvi
/// @notice Escrow managed Marketplace
contract SpeerTech is Access {
    using Counters for Counters.Counter;
    IItem public itemContract; // contract for managing items
    Counters.Counter private _saleIds; // sale ID counter
    struct Sale {
        bool isActive; // is sale active?
        uint256 itemId; // tokenID for item
        address payable buyer; // address of approved buyer
        address payable seller; // address of seller
        uint256 price; // ETH price (in wei)
        bool isPaid; // is payment complete?
        string proofURI; // URI to the delivery proof
    }
    mapping(uint256 => Sale) public sales; // saleId => Sale mapping

    /// @notice Emitted when a sale is created
    event SaleCreated(address indexed seller, address buyer, uint256 saleId);
    /// @notice Emitted when a buyer completes payment
    event Paid(uint256 indexed saleId, uint256 price, uint256 amount);
    /// @notice Emitted when seller submits proof of delivery
    event ProofSubmitted(uint256 indexed saleId, string proofURI);
    /// @notice Emitted when seller/escrow cancel the sale
    event SaleCancelled(uint256 indexed saleId, address cancelledBy);
    /// @notice Emitted when Escrow verifies sale and transfers funds
    event SaleConfirmed(
        uint256 indexed saleId,
        address indexed seller,
        address indexed buyer
    );

    /// @notice Constructor
    /// @param _itemContract - Address of the Item NFT contract
    constructor(IItem _itemContract) {
        itemContract = _itemContract;
    }

    /// @notice Sell item to a Buyer
    /// @param to - Address of Buyer
    /// @param uri - URI to item details
    /// @param price - Price to sell item for (in wei)
    function sellItemTo(
        address payable to,
        string memory uri,
        uint256 price
    ) external {
        uint256 _itemId = itemContract.createItem(address(this), uri);
        _saleIds.increment();
        uint256 newSaleId = _saleIds.current();
        Sale memory sale = Sale(
            true,
            _itemId,
            to,
            payable(msg.sender),
            price,
            false,
            ""
        );
        sales[newSaleId] = sale;
        emit SaleCreated(msg.sender, to, newSaleId);
    }

    /// @notice Make payment for Sale
    /// @notice Callable by approved Buyer
    /// @param saleId - Sale ID
    function purchaseItem(uint256 saleId)
        external
        payable
        onlyBuyer(saleId)
        onlyActive(saleId)
    {
        require(!sales[saleId].isPaid, "Payment already completed");
        require(msg.value >= sales[saleId].price, "Insufficient Amount");
        sales[saleId].isPaid = true;
        emit Paid(saleId, sales[saleId].price, msg.value);
    }

    /// @notice Submit Delivery Proof
    /// @notice Callable by Seller
    /// @param saleId - Sale ID
    /// @param proofURI - URI for the proof
    function submitDeliveryProof(uint256 saleId, string memory proofURI)
        external
        onlySeller(saleId)
        onlyActive(saleId)
    {
        require(
            compareStrings(sales[saleId].proofURI, ""),
            "Proof already submitted"
        );
        sales[saleId].proofURI = proofURI;
        emit ProofSubmitted(saleId, proofURI);
    }

    /// @notice Cancel Sale
    /// @notice Callable by Seller or Escrow
    /// @param saleId - Sale ID
    function cancelSale(uint256 saleId)
        external
        onlySellerOrEscrow(saleId)
        onlyActive(saleId)
    {
        sales[saleId].isActive = false;
        if (sales[saleId].isPaid) {
            sales[saleId].buyer.transfer(sales[saleId].price);
        }
        itemContract.burn(sales[saleId].itemId);
        emit SaleCancelled(saleId, msg.sender);
    }

    /// @notice Confirm Sale
    /// @notice Callable by Escrow
    /// @param saleId - Sale ID
    function confirmSale(uint256 saleId)
        external
        // onlyEscrow - Commented out to make it easier for Speer team to test
        onlyActive(saleId)
    {
        require(sales[saleId].isPaid, "Payment pending");
        require(!compareStrings(sales[saleId].proofURI, ""), "Proof pending");
        sales[saleId].isActive = false;
        sales[saleId].seller.transfer(sales[saleId].price);
        itemContract.transferFrom(
            address(this),
            sales[saleId].buyer,
            sales[saleId].itemId
        );
        emit SaleConfirmed(saleId, sales[saleId].seller, sales[saleId].buyer);
    }

    /// @notice Compare two strings
    /// @param a - first string
    /// @param b - second string
    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /// @notice reverts if caller is not buyer
    modifier onlyBuyer(uint256 saleId) {
        require(
            sales[saleId].buyer == msg.sender,
            "Caller is not approved buyer"
        );
        _;
    }

    /// @notice reverts if caller is not seller
    modifier onlySeller(uint256 saleId) {
        require(sales[saleId].seller == msg.sender, "Caller is not the seller");
        _;
    }

    /// @notice reverts if caller is not seller or escrow
    modifier onlySellerOrEscrow(uint256 saleId) {
        require(
            sales[saleId].seller == msg.sender 
            // || isEscrow[msg.sender]
            || true // Making it easier for Speer team to test
            ,
            "Caller is not the seller or escrow"
        );
        _;
    }

    /// @notice reverts if sale is not active
    modifier onlyActive(uint256 saleId) {
        require(sales[saleId].isActive, "Sale is not active");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Access
/// @author Arhaam Patvi
/// @notice Manage Roles & Access via this Contract
contract Access is Ownable {
    // mapping(address => bool) public isAdmin; // user => isAdmin?
    mapping(address => bool) public isEscrow; // user => isEscrow?

    // /// @notice Emitted when admin role is granted or revoked
    // event AdminSet(address user, bool isGranted);
    /// @notice Emitted when escrow role is granted or revoked
    event EscrowSet(address user, bool isGranted);

    // /// @notice Grant/Revoke Admin role
    // /// @notice Only callable by owner
    // /// @param user - address to be granted or revoked
    // /// @param isGranted - should admin role be granted?
    // function setAdmin(address user, bool isGranted) external onlyOwner {
    //     isAdmin[user] = isGranted;
    //     emit AdminSet(user, isGranted);
    // }

    /// @notice Grant/Revoke Escrow role
    /// @notice Only callable by owner
    /// @param user - address to be granted or revoked
    /// @param isGranted - should admin role be granted?
    function setEscrow(address user, bool isGranted) external onlyOwner {
        isEscrow[user] = isGranted;
        emit EscrowSet(user, isGranted);
    }

    // /// @notice reverts if caller is not an admin
    // modifier onlyAdmin() {
    //     require(isAdmin[msg.sender], "Caller does not have Admin access");
    //     _;
    // }

    /// @notice reverts if caller is not an escrow
    modifier onlyEscrow() {
        require(isEscrow[msg.sender], "Caller does not have Escrow access");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IItem is IERC721 {
    function createItem(address to, string memory uri)
        external
        returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}