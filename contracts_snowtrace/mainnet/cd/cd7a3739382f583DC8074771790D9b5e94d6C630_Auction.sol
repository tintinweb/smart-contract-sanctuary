/**
 *Submitted for verification at snowtrace.io on 2021-12-07
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Auction.sol
// SPDX-License-Identifier: MIT AND Unlicense
pragma solidity =0.8.10 >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC721Receiver.sol"; */

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

////// src/Auction.sol
/* pragma solidity 0.8.10; */

/* import "@openzeppelin/contracts/access/Ownable.sol"; */
/* import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; */

interface IERC721Lite {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Auction is Ownable, ERC721Holder {

    IERC721Lite public tokenInterface;
    uint256 public tokenId;
    uint256 public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint256 public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint256) pendingReturns;
    uint256 totalPendingReturns = 0;

    bool ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    function auctionStart(uint256 biddingTime, address _tokenAddress, uint256 _tokenId) external onlyOwner {
        // one time only
        require(auctionEndTime == 0);

        auctionEndTime = block.timestamp + biddingTime;

        tokenInterface = IERC721Lite(_tokenAddress);
        tokenId = _tokenId;

        tokenInterface.safeTransferFrom(_msgSender(), address(this), _tokenId);
    }

    function bid() external payable {

        require(auctionEndTime != 0, "AuctionHasNotStarted");
        require(block.timestamp < auctionEndTime, "AuctionAlreadyEnded");
        require(msg.value > highestBid, "BidNotHighEnough");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
            totalPendingReturns += highestBid;
        }

        highestBidder = _msgSender();
        highestBid = msg.value;

        // withdraw previous bid
        uint256 amount = pendingReturns[_msgSender()];
        if(amount > 0) {
            pendingReturns[_msgSender()] = 0;

            if (!payable(_msgSender()).send(amount)) {
                pendingReturns[_msgSender()] = amount;
            }
            else {
                totalPendingReturns -= amount;
            }
        }

        emit HighestBidIncreased(_msgSender(), msg.value);
    }

    function hasBid() external view returns (bool) {
        return pendingReturns[_msgSender()] > 0;
    }

    function withdraw() external {
        require(auctionEndTime != 0, "AuctionHasNotStarted");

        uint256 amount = pendingReturns[_msgSender()];
        if (amount > 0) {
            pendingReturns[_msgSender()] = 0;

            if (!payable(_msgSender()).send(amount)) {
                pendingReturns[_msgSender()] = amount;
            }
            else {
                totalPendingReturns -= amount;
            }
        }
    }

    function auctionEnd() external {

        require(auctionEndTime != 0, "AuctionHasNotStarted");
        require(block.timestamp > auctionEndTime, "AuctionNotYetEnded");
        require(!ended, "AuctionEndAlreadyCalled");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        tokenInterface.safeTransferFrom(address(this), highestBidder, tokenId);
    }

    function withdrawHighestBid() external onlyOwner {
        require(ended, "AuctionNotYetEnded");

        payable(_msgSender()).transfer(highestBid);
    }

    function withdrawEmergency() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}