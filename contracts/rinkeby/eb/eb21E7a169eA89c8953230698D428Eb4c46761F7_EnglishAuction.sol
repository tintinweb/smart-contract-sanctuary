// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC1155 {
    function transfer(address, uint) external;

    function safeTransferFrom(
        address,
        address,
        uint,
        uint,
        bytes calldata
    ) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC1155 public nft;
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid
    ) {
        nft = IERC1155(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() public {
        require(!started, "started");
       // require(msg.sender == seller, "not seller");

        nft.safeTransferFrom(msg.sender, address(this), nftId, 1, '');
        started = true;
        endAt = block.timestamp + 7 days;

        emit Start();
    }

    function bid() public payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() public {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() public {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId, 1, '');
            seller.transfer(highestBid);
        } else {
            nft.transfer(seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}