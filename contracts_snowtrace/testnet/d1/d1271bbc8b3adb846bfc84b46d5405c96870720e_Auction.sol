/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-22
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IERC721Lite {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Auction {
    address public owner;

    IERC721Lite public tokenInterface;
    uint256 public tokenId;
    uint256 public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint256 public highestBid;

    // Allows withdrawals of beaten bids
    mapping(address => uint256) private pendingReturns;
    uint256 private totalPendingReturns = 0;

    bool public ended;

    // Errors
    error AuctionSlotUsed();
    error AuctionHasNotStarted();
    error AuctionAlreadyEnded();
    error BidNotHighEnough();
    error AuctionNotYetEnded();
    error TransferFailed();
    error Unauthorized();

    // Events
    event OwnerUpdated(address indexed owner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(owner);
    }

    function auctionStart(
        uint256 biddingTime,
        address _tokenAddress,
        uint256 _tokenId
    ) external onlyOwner {
        // one time only
        if (auctionEndTime != 0) revert AuctionSlotUsed();

        unchecked {
            auctionEndTime = block.timestamp + biddingTime; // solhint-disable-line
        }
        tokenInterface = IERC721Lite(_tokenAddress);
        tokenId = _tokenId;

        tokenInterface.transferFrom(msg.sender, address(this), _tokenId);
    }

    function bid() external payable {
        uint256 endTime = auctionEndTime;
        uint256 prevBid = highestBid;

        if (endTime == 0) revert AuctionHasNotStarted();
        if (block.timestamp >= endTime) revert AuctionAlreadyEnded(); // solhint-disable-line
        if (msg.value <= prevBid) revert BidNotHighEnough();

        if (prevBid != 0) {
            unchecked {
                pendingReturns[highestBidder] += prevBid;
                totalPendingReturns += prevBid;
            }
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        // withdraw previous msg.sender bid, if it exists
        uint256 amount = pendingReturns[msg.sender];

        if (amount != 0) {
            pendingReturns[msg.sender] = 0;

            unchecked {
                totalPendingReturns -= amount;
            }
            //slither-disable-next-line low-level-calls
            (bool success, ) = msg.sender.call{value: amount}(""); // solhint-disable-line
            if (!success) revert TransferFailed();
        }
    }

    function hasBid() external view returns (bool) {
        return pendingReturns[msg.sender] != 0;
    }

    function withdraw() external {
        if (auctionEndTime == 0) revert AuctionHasNotStarted();

        uint256 amount = pendingReturns[msg.sender];
        if (amount != 0) {
            pendingReturns[msg.sender] = 0;
            unchecked {
                totalPendingReturns -= amount;
            }
            //slither-disable-next-line low-level-calls
            (bool success, ) = msg.sender.call{value: amount}(""); // solhint-disable-line
            if (!success) revert TransferFailed();
        }
    }

    function auctionEnd() external {
        uint256 endTime = auctionEndTime;

        if (endTime == 0) revert AuctionHasNotStarted();
        if (block.timestamp <= endTime) revert AuctionNotYetEnded(); // solhint-disable-line
        if (ended) revert AuctionAlreadyEnded();

        ended = true;

        tokenInterface.transferFrom(address(this), highestBidder, tokenId);
    }

    function withdrawHighestBid() external onlyOwner {
        if (!ended) revert AuctionNotYetEnded();

        //slither-disable-next-line low-level-calls
        (bool success, ) = msg.sender.call{value: highestBid}(""); // solhint-disable-line
        if (!success) revert TransferFailed();
    }

    function withdrawEmergency() external onlyOwner {
        //slither-disable-next-line low-level-calls
        (bool success, ) = msg.sender.call{value: address(this).balance}(""); // solhint-disable-line
        if (!success) revert TransferFailed();

        tokenInterface.transferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {} // solhint-disable-line

    fallback() external payable {} // solhint-disable-line
}