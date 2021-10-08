// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOwnable.sol";

/// @title A fixed price ERC721 Purchase Contract
/// @author jierlich
/// @notice Users can list NFTs, purchase listed NFTs, and delist NFTs
/// @notice Collection owners can set fees
/// @dev The collection owner fee is dependent on the existence of an `owner` function on the ERC721 contract
contract ERC721FixedPricePurchase is Ownable {
    /// @dev mapping from ERC721 address -> token id -> listing price
    mapping(address => mapping(uint256 => uint256)) public listing;

    /// @dev mapping from collection owner to collection fee
    mapping(address => uint256) public collectionFee;

    /// @dev mapping from collection owner to fees accrued
    mapping(address => uint256) public collectionFeesAccrued;

    /// @dev fee for the protocol
    uint256 public protocolFee;

    /// @dev protocol fees accrued
    uint256 public protocolFeesAccrued;

    /// @dev used to calculate the basis point fee
    uint constant FEE_BASE = 10000;

    event Listed(address indexed erc721, uint256 indexed tokenId, address indexed owner, uint256 price);

    event Purchased(address indexed erc721, uint256 indexed tokenId, address indexed buyer);

    modifier onlyErc721Owner(address erc721, uint256 tokenId) {
        require(IERC721(erc721).ownerOf(tokenId) == msg.sender, "ERC721FixedPricePurchase: Only ERC721 owner can call this function");
        _;
    }

    modifier onlyCollectionOwner(address erc721) {
        require(IOwnable(erc721).owner() == msg.sender, "ERC721FixedPricePurchase: Only collection owner can call this function");
        _;
    }

    /// @notice list an ERC721 token for sale
    /// @dev the owner must approve the tokenId on the ERC721 in a separate transaction to fully list
    /// @dev delisting is done externally by revoking approval on the ERC721
    /// @param erc721 token contract
    /// @param tokenId id of the ERC721 token being listed
    /// @param price amount buyer must pay to purchase
    function list(address erc721, uint256 tokenId, uint256 price) onlyErc721Owner(erc721, tokenId) public {
        listing[erc721][tokenId] = price;
        emit Listed(erc721, tokenId, msg.sender, price);
    }

    /// @notice purchase an ERC721 token that is on sale
    /// @dev basis point fees are calculated using the fee base constant
    /// @param erc721 token contract
    /// @param tokenId id of the ERC721 token being listed
    function purchase(address erc721, uint256 tokenId) public payable {
        require(msg.value >= listing[erc721][tokenId], "ERC721FixedPricePurchase: Buyer didn't send enough ether");
        require(listing[erc721][tokenId] > 0, "ERC721FixedPricePurchase: Token is not listed");
        listing[erc721][tokenId] = 0;
        address from = IERC721(erc721).ownerOf(tokenId);

        uint256 collectionFeeAmount = msg.value * collectionFee[erc721] / FEE_BASE;
        uint256 protocolFeeAmount = msg.value * protocolFee / FEE_BASE;
        uint256 sellerFeeAmount = msg.value - protocolFeeAmount - collectionFeeAmount;

        collectionFeesAccrued[erc721] += collectionFeeAmount;
        protocolFeesAccrued += protocolFeeAmount;

        (bool sent,) = from.call{value: sellerFeeAmount}("");
        require(sent, "ERC721FixedPricePurchase: Failed to send Ether");

        IERC721(erc721).safeTransferFrom(from, msg.sender, tokenId);
        /// @dev price is set to 0 to protect future owners
        listing[erc721][tokenId] = 0;
        emit Purchased(erc721, tokenId, msg.sender);
    }

    /// @notice set the basis point fee of the collection owner
    /// @param erc721 token contract
    /// @param fee basis point amount of the transaction
    function setCollectionFee(address erc721, uint256 fee) onlyCollectionOwner(erc721) public {
        collectionFee[erc721] = fee;
    }

    /// @notice set the basis point fee of the protocol owner
    /// @param fee basis point amount of the transaction
    function setProtocolFee(uint256 fee) onlyOwner() public {
        protocolFee = fee;
    }

    /// @notice allows collection owner to withdraw collected fees
    /// @param erc721 token contract
    function collectionWithdraw(address erc721) public {
        require(collectionFeesAccrued[erc721] > 0, 'ERC721FixedPricePurchase: No funds to withdraw for this collection');
        address payable collectionOwner = payable(IOwnable(erc721).owner());
        uint256 amount = collectionFeesAccrued[erc721];
        collectionFeesAccrued[erc721] = 0;
        (bool sent,) = collectionOwner.call{value: amount}("");
        require(sent, "ERC721FixedPricePurchase: Failed to send Ether");
    }

    /// @notice allows protocol owner to withdraw collected fees
    function protocolWithdraw() public {
        require(protocolFeesAccrued > 0, 'ERC721FixedPricePurchase: No protocol funds to withdraw');
        uint256 amount = protocolFeesAccrued;
        protocolFeesAccrued = 0;
        (bool sent,) = owner().call{value: amount}("");
        require(sent, "ERC721FixedPricePurchase: Failed to send Ether");
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

pragma solidity =0.8.4;

interface IOwnable {
    function owner() external view returns (address);
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