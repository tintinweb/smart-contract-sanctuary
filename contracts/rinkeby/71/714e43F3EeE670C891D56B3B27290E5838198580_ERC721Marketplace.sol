//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./utils/Operator.sol";
import "./interfaces/IAztecNFT.sol";
import "./interfaces/IAztecToken.sol";

struct ListingItem {
    uint256 id;
    uint256 priceInWei;
    address token;
    uint256 tokenId;
    address seller;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
}

contract ERC721Marketplace is Operator, ERC721Holder {
    address public constant BURN_ADDRESS =
        0x687a48eba6b3A7A060D89eA63232f20D83aCBDF8;
    uint256 public _listingIdCounter;
    mapping(uint256 => ListingItem) public _listings;

    address public _colosseum;
    address public _fund;
    IAztecToken public _aztecToken;
    uint256 public _burnFeeRate;
    uint256 public _colosseumFeeRate; // 10000 = 100%
    uint256 public _fundFeeRate;
    uint256 public _minerFeeRate;

    address public _aztecNFT;

    mapping(address => uint256) private _swapAztBalances;
    mapping(address => uint256) private _swapAztWithdrews;

    event AddListing(
        uint256 indexed listingId,
        address indexed seller,
        address token,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 time
    );
    event CancelListing(uint256 indexed listingId, uint256 time);
    event PurchaseListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address token,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 time
    );

    constructor(
        address aztecToken,
        address colosseum,
        address fund,
        address operator
    ) {
        _aztecToken = IAztecToken(aztecToken);
        _colosseum = colosseum;
        _fund = fund;
        _colosseumFeeRate = 200;
        _burnFeeRate = 200;
        _fundFeeRate = 100;
        _minerFeeRate = 200;

        setOperator(operator, true);
    }

    function addListing(
        address token,
        uint256 tokenId,
        uint256 priceInWei
    ) public {
        IERC721 erc721Token = IERC721(token);
        address owner = _msgSender();
        require(
            erc721Token.ownerOf(tokenId) == owner,
            "ERC721Marketplace: Not owner of ERC721 token"
        );
        require(
            erc721Token.isApprovedForAll(owner, address(this)) ||
                erc721Token.getApproved(tokenId) == address(this),
            "ERC721Marketplace: Not approved for transfer"
        );
        require(
            priceInWei >= 1 ether,
            "ERC721Marketplace: Price must be greater than 1 BUSD"
        );

        erc721Token.transferFrom(owner, address(this), tokenId);

        _listingIdCounter++;
        uint256 listingId = _listingIdCounter;
        _listings[listingId] = ListingItem({
            id: listingId,
            priceInWei: priceInWei,
            token: token,
            tokenId: tokenId,
            seller: owner,
            timeCreated: block.timestamp,
            timePurchased: 0,
            cancelled: false
        });

        emit AddListing(
            listingId,
            owner,
            token,
            tokenId,
            priceInWei,
            block.timestamp
        );
    }

    function cancelListing(uint256 listingId) public {
        ListingItem storage listingItem = _listings[listingId];
        if (listingItem.id == 0) {
            return;
        }
        require(
            listingItem.seller == _msgSender(),
            "ERC721Marketplace: caller not seller"
        );

        if (listingItem.cancelled == true || listingItem.timePurchased != 0) {
            return;
        }
        listingItem.cancelled = true;

        IERC721(listingItem.token).transferFrom(
            address(this),
            _msgSender(),
            listingItem.tokenId
        );
        emit CancelListing(listingId, block.timestamp);
    }

    function purchaseListing(uint256 listingId) public {
        ListingItem storage listingItem = _listings[listingId];
        if (listingItem.id == 0) {
            return;
        }
        require(
            listingItem.timePurchased == 0 && listingItem.cancelled == false,
            "ERC721Marketplace: order is closed"
        );
        listingItem.timePurchased = block.timestamp;
        uint256 amount = listingItem.priceInWei;

        address buyer = _msgSender();
        // burn
        uint256 burnShare = (amount * _burnFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, BURN_ADDRESS, burnShare);
        // colosseum
        uint256 colosseumShare = (amount * _colosseumFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, _colosseum, colosseumShare);
        // fund
        uint256 fundShare = (amount * _fundFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, _fund, colosseumShare);

        uint256 minerShare;
        if (listingItem.token == _aztecNFT) {
            // to miner
            minerShare = (amount * _minerFeeRate) / 10000;
            _swapAztBalances[
                IAztecNFT(listingItem.token).miners(listingItem.tokenId)
            ] += minerShare;
        }
        // deposit this address
        uint256 depositThis = amount - burnShare - colosseumShare - fundShare;
        _aztecToken.transferFrom(buyer, address(this), depositThis);

        // to seller
        _swapAztBalances[listingItem.seller] += depositThis - minerShare;
        IERC721(listingItem.token).transferFrom(
            address(this),
            _msgSender(),
            listingItem.tokenId
        );

        emit PurchaseListing(
            listingId,
            listingItem.seller,
            _msgSender(),
            listingItem.token,
            listingItem.tokenId,
            listingItem.priceInWei,
            block.timestamp
        );
    }

    function batchCancelListing(uint256[] memory listingIds) external {
        for (uint256 index; index < listingIds.length; index++) {
            cancelListing(listingIds[index]);
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _swapAztBalances[owner];
    }

    function withdrew(address owner) public view returns (uint256) {
        return _swapAztWithdrews[owner];
    }

    function withdraw() public {
        address owner = _msgSender();
        uint256 balance = _swapAztBalances[owner];
        _swapAztBalances[owner] = 0;
        _swapAztWithdrews[owner] += balance;
        _aztecToken.transfer(owner, balance);
    }

    function setRecipient(address colosseum, address fund)
        external
        onlyOperator
    {
        require(colosseum != address(0), "Zero address");
        require(fund != address(0), "Zero address");
        _colosseum = colosseum;
        _fund = fund;
    }

    function setFeeRate(
        uint256 colosseumRate,
        uint256 burnFeeRate,
        uint256 fundFeeRate
    ) external onlyOperator {
        _colosseumFeeRate = colosseumRate;
        _burnFeeRate = burnFeeRate;
        _fundFeeRate = fundFeeRate;
    }

    function setMinerFeeRate(uint256 rate) external onlyOperator {
        _minerFeeRate = rate;
    }

    function setAztecToken(address aztecToken) external onlyOperator {
        _aztecToken = IAztecToken(aztecToken);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    mapping(address => bool) private _operators;

    event OperatorSetted(address account, bool allow);

    modifier onlyOperator() {
        require(_operators[_msgSender()], "Forbidden");
        _;
    }

    constructor() {
        setOperator(_msgSender(), true);
    }

    function operator(address account) public view returns (bool) {
        return _operators[account];
    }

    function setOperator(address account, bool allow) public onlyOwner {
        _operators[account] = allow;
        emit OperatorSetted(account, allow);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IAztecNFT is IERC721 {
    function mint(address to, uint256 numericTrait)
        external
        returns (uint256 tokenId);

    function numericTraits(uint256 tokenId)
        external
        view
        returns (uint256 numericTrait);

    function setNumericTraits(uint256 tokenId, uint256 numericTrait) external;

    function burn(uint256 tokenId) external;

    function miners(uint256 tokenId) external returns (address miner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IAztecToken is IERC20 {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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