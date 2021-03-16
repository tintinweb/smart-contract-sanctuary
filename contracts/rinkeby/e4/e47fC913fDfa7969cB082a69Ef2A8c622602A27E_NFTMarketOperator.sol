// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketOperator is Ownable {
    struct ListingItem {
        string id;
        address assetAddress;
        uint256 tokenId;
        address paymentToken;
        uint256 priceInEth;
        uint256 priceInToken;
        uint256 feeInPercent;
        address payTo;
        bool available;
    }

    mapping(string => ListingItem) internal _listingItems;

    function listItemWithEth(
        string memory id,
        address assetAddress,
        uint256 tokenId,
        uint256 priceInEth,
        uint256 feeInPercent,
        address payTo
    ) external onlyOwner returns (bool) {
        require(
            keccak256(abi.encodePacked(_listingItems[id].id)) ==
                keccak256(abi.encodePacked("")),
            "NFTMarketOperator: this item has already listed"
        );

        IERC721 assetOperator = IERC721(assetAddress);
        require(
            assetOperator.getApproved(tokenId) == address(this),
            "NFTMarketOperator: invalid grant"
        );
        require(
            assetOperator.ownerOf(tokenId) == msg.sender,
            "NFTMarketOperator: you are not owner of this item"
        );

        _listingItems[id] = ListingItem({
            id: id,
            assetAddress: assetAddress,
            tokenId: tokenId,
            paymentToken: address(0),
            priceInEth: priceInEth,
            priceInToken: 0,
            feeInPercent: feeInPercent,
            payTo: payTo,
            available: true
        });

        return true;
    }

    function listItemWithErc20Token(
        string memory id,
        address assetAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 priceInToken,
        uint256 feeInPercent,
        address payTo
    ) external onlyOwner returns (bool) {
        require(
            keccak256(abi.encodePacked(_listingItems[id].id)) ==
                keccak256(abi.encodePacked("")),
            "NFTMarketOperator: this item has already listed"
        );

        IERC721 assetOperator = IERC721(assetAddress);
        require(
            assetOperator.getApproved(tokenId) == address(this),
            "NFTMarketOperator: invalid grant"
        );
        require(
            assetOperator.ownerOf(tokenId) == msg.sender,
            "NFTMarketOperator: you are not owner of this item"
        );

        _listingItems[id] = ListingItem({
            id: id,
            assetAddress: assetAddress,
            tokenId: tokenId,
            paymentToken: paymentToken,
            priceInEth: 0,
            priceInToken: priceInToken,
            feeInPercent: feeInPercent,
            payTo: payTo,
            available: true
        });

        return true;
    }

    function buyItemInEth(string memory id) external payable returns (bool) {
        require(
            keccak256(abi.encodePacked(_listingItems[id].id)) ==
                keccak256(abi.encodePacked(id)),
            "NFTMarketOperator: this item has already listed"
        );

        ListingItem storage item = _listingItems[id];
        require(
            item.available == true,
            "NFTMarketOperator: this item has been sold"
        );
        require(
            item.priceInEth <= msg.value,
            "NFTMarketOperator: invalid amount to buy"
        );
        uint256 fee = (item.feeInPercent * item.priceInEth) / 100;
        uint256 paySellerAmount = item.priceInEth - fee;

        payable(item.payTo).transfer(paySellerAmount);
        item.available = false;

        transferAssetItem(
            item.assetAddress,
            item.tokenId,
            item.payTo,
            msg.sender
        );
        return true;
    }

    function buyItemInErc20Token(string memory id)
        external
        payable
        returns (bool)
    {
        require(
            keccak256(abi.encodePacked(_listingItems[id].id)) ==
                keccak256(abi.encodePacked(id)),
            "NFTMarketOperator: this item has already listed"
        );

        ListingItem storage item = _listingItems[id];
        IERC20 token = IERC20(item.paymentToken);

        require(
            item.available == true,
            "NFTMarketOperator: this item has been sold"
        );

        require(
            item.priceInEth <= msg.value,
            "NFTMarketOperator: invalid amount to buy"
        );

        require(
            token.allowance(msg.sender, address(this)) >= item.priceInToken,
            "NFTMarketOperator: you don't have enough money to buy this item"
        );

        uint256 fee = (item.feeInPercent * item.priceInToken) / 100;
        uint256 paySellerAmount = item.priceInToken - fee;

        token.transferFrom(msg.sender, address(this), fee);
        token.transferFrom(msg.sender, item.payTo, paySellerAmount);

        item.available = false;
        transferAssetItem(
            item.assetAddress,
            item.tokenId,
            item.payTo,
            msg.sender
        );

        return true;
    }

    function transferAssetItem(
        address asset,
        uint256 tokenId,
        address from,
        address to
    ) internal returns (bool) {
        IERC721 assetOperator = IERC721(asset);
        assetOperator.safeTransferFrom(from, to, tokenId);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}