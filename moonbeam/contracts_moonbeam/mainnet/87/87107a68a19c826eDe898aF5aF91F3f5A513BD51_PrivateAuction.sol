//Custom NFT Marketplace Contract. From your favorite beans around - MoonBeans!

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PrivateAuction is IERC721Receiver, ReentrancyGuard, Ownable {

  event BidPlaced(uint256 indexed id, uint256 indexed price, address indexed bidder, uint256 timestamp);
  event BidAccepted(uint256 indexed id, uint256 indexed price, address indexed bidder, uint256 timestamp);
  event BidReturned(uint256 indexed id, uint256 indexed price, address indexed bidder, uint256 timestamp);
  
  struct Offer {
    uint256 price;
    uint256 timestamp;
    bool fundsEscrowed;
    bool accepted;
    address bidder;
  }

  bool public allAuctionsPaused = true;
  mapping(uint256 => bool) public itemAuctionPaused;
  mapping(uint256 => bool) public itemAuctionCompleted;
  mapping(uint256 => Offer[]) public offers;
  mapping(address => bool) public administrators;
  mapping(address => uint256) public escrowed; 
  IERC721 public NFT;

  uint256 private startingBid = 1000 ether;
  uint256 private maxBids = 10;
  address private deadAddress = 0x000000000000000000000000000000000000dEaD;

  modifier onlyAdmins {
    require(administrators[_msgSender()] || owner() == _msgSender(), "Not owner or admin.");
    _;
  }

  // Required in order to receive ERC 721's.
  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  // Required in order to receive MOVR/ETH.
  receive() external payable { }

  function getAuctionDetails(uint256 itemId) external view returns (Offer[] memory) {
    return offers[itemId];
  }

  function highestBid(uint256 itemId) public view returns (Offer memory) {
    if (offers[itemId].length == 0) {
      return Offer(startingBid, 0, false, false, deadAddress);
    }
    return offers[itemId][offers[itemId].length - 1];
  }

  function secondHighestBid(uint256 itemId) internal view returns (Offer memory) {
    return offers[itemId][offers[itemId].length - 2];
  }

  function highestBidAmount(uint256 itemId) public view returns (uint256) {
    return highestBid(itemId).price;
  }
  
  function placeBid(uint256 itemId) public payable nonReentrant{
    require(!allAuctionsPaused, "Auctions Disabled.");
    require(!itemAuctionPaused[itemId], "Auction Paused.");
    require(!itemAuctionCompleted[itemId], "Auction completed");
    require(msg.value > highestBidAmount(itemId), "Bid too low.");

    // add new offer to array
    offers[itemId].push(Offer(msg.value, block.timestamp, true, false, msg.sender));
    emit BidPlaced(itemId, msg.value, msg.sender, block.timestamp);
     
    // we don't want to hold onto too many bids
    if (offers[itemId].length >= maxBids) {
      for (uint i = 0; i < offers[itemId].length - 1;) {
        offers[itemId][i] = offers[itemId][i + 1];
        unchecked {++i;}
      }
      offers[itemId].pop();
    }

    // if there's at least 2 bids now, refund the second highest bid.
    if (offers[itemId].length > 1) {
      Offer memory secondHighestOffer = secondHighestBid(itemId);
      emit BidReturned(itemId, secondHighestOffer.price, secondHighestOffer.bidder, secondHighestOffer.timestamp);
      (bool success, ) = payable(secondHighestOffer.bidder).call{value: secondHighestOffer.price}("");
      require(success, "Escrow return failed.");
    }
  }

  //ADMINS
  function flipAdmin(address user) external onlyOwner {
    administrators[user] = !administrators[user];
  }

  function flipAllBidding() external onlyAdmins {
    allAuctionsPaused = !allAuctionsPaused;
  }

  function setMaxBids(uint256 newMax) external onlyAdmins {
    maxBids = newMax;
  }

  function flipAuction(uint256 itemId) external onlyAdmins {
    require(!itemAuctionCompleted[itemId], "Auction completed.");
    itemAuctionPaused[itemId] = !itemAuctionPaused[itemId];
  }

  function setStartingBid(uint256 _startingBid) external onlyAdmins {
    startingBid = _startingBid;
  }

  function setNFTContract(address ca) external onlyAdmins {
    NFT = IERC721(ca);
  }

  function withdrawAmount(uint256 amount) internal {
    payable(owner()).transfer(amount);
  }

  function end(uint256 itemId) external onlyAdmins {
    require(itemAuctionCompleted[itemId] == false, "Auction already completed.");
    require(offers[itemId].length >= 1, "No bids made.");

    // Get highest bid and emit event
    itemAuctionPaused[itemId] = true;
    itemAuctionCompleted[itemId] = true;
    Offer memory acceptedOffer = highestBid(itemId);
    emit BidAccepted(itemId, acceptedOffer.price, acceptedOffer.bidder, acceptedOffer.timestamp);

    // Mark as accepted and send funds to owner
    acceptedOffer.accepted = true;
    uint256 acceptedOfferIndex = offers[itemId].length - 1;
    offers[itemId][acceptedOfferIndex] = acceptedOffer;
  }

  function finalizeAuctionAndSendOut(uint256 itemId) external onlyAdmins {
    require(itemAuctionCompleted[itemId] == false, "Auction already completed.");
    require(offers[itemId].length >= 1, "No bids made.");

    // Get highest bid and emit event
    itemAuctionPaused[itemId] = true;
    itemAuctionCompleted[itemId] = true;
    Offer memory acceptedOffer = highestBid(itemId);
    emit BidAccepted(itemId, acceptedOffer.price, acceptedOffer.bidder, acceptedOffer.timestamp);

    // Mark as accepted and send funds to owner
    acceptedOffer.accepted = true;
    uint256 acceptedOfferIndex = offers[itemId].length - 1;
    offers[itemId][acceptedOfferIndex] = acceptedOffer;
    withdrawAmount(acceptedOffer.price);

    // Transfer winner NFT to winner
    NFT.transferFrom(address(this), acceptedOffer.bidder, itemId);
  }


  //EMERGENCY ONLY
  function withdrawAll() external onlyAdmins {
    payable(owner()).transfer(address(this).balance);
  }

  function withdrawTokens(address token) external onlyAdmins {
    IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
  }

  function withdrawNFT(address _token, uint256 tokenId) external onlyOwner {
    IERC721(_token).transferFrom(address(this), owner(), tokenId);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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