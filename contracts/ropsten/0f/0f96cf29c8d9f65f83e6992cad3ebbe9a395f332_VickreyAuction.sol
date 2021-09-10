// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import './IERC20.sol';

// TODO Review all usage of `public`
// TODO Optimize storage writes with memory

contract VickreyAuction {

    IERC20 public token;

    // TODO Pack the following struct
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
        address jobPoster;
        uint auctionId;
    }

    /* uint public minimumPayout;
    uint public biddingDeadline;
    uint public revealDeadline;

    address public endUser;
    address public highestBidder;
    uint public highestBid;
    uint public secondHighestBid; */

    struct Auction {
        uint minimumPayout;
        uint reward;
        uint biddingDeadline;
        uint revealDeadline;
        uint highestBid;
        uint secondHighestBid;
        address highestBidder;
        bool ended;
    }

    mapping(address => Auction[]) public auctions;
    mapping(address => Bid[]) bids;
    mapping(address => uint) staleBids;

    event AuctionEnded(
        address indexed endUser,
        uint auctionId,
        address winner, 
        uint secondHighestBid
    );
    /* event BidPlaced(
        address bidder,
        uint amount
    ); */

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();

    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

    // TODO 2 Use `initialize` instead of constructor to make the contract upgradable
    constructor(
        IERC20 _token
    ) {
        token = _token;
    }

    // FIXME 1 Right now, `reward` is just parameterized and there is no check,
    //         in place; to make sure that the `endUser` is good for the funds
    uint reward;

    // FIXME 1 (continued)
    // Have end-user actually transfer the funds and then check that the reward amount is equal to it
    function start(
        uint _minimumPayout,
        uint _biddingDeadline,
        uint _revealDeadline,
        uint _reward,
        address _endUser
    )
        public
    {
        auctions[_endUser].push(Auction({
            minimumPayout: _minimumPayout,
            reward: _reward,
            biddingDeadline: _biddingDeadline,
            revealDeadline: _revealDeadline,
            highestBid: 0,
            secondHighestBid: 0,
            highestBidder: address(0),
            ended: false
        }));
    }

    function bid(
        address _endUser,
        uint _auctionId,
        bytes32 _blindedBid,
        uint _amount
    )
        public
        onlyBefore(auctions[_endUser][_auctionId].biddingDeadline)
    {
        require(_amount > auctions[_endUser][_auctionId].minimumPayout,'_amount must be greater than minimumPayout');
        uint allowedAmount = token.allowance(msg.sender,address(this));
        require(allowedAmount >= _amount,'allowedAmount must be greater than or equal to _amount');
        // TODO  1.5 Re-factor `transferFrom` to eliminate gas costs?
        token.transferFrom(msg.sender,address(this),_amount);
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: _amount,
            jobPoster: _endUser,
            auctionId: _auctionId
        }));
    }

    function reveal(
        address _endUser,
        uint _auctionId,
        uint[] memory _amounts,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(auctions[_endUser][_auctionId].biddingDeadline)
        onlyBefore(auctions[_endUser][_auctionId].revealDeadline)
    {
        uint numberOfBids = bids[msg.sender].length;
        // TODO Uncomment the follow checks:
        // require(_amounts.length == numberOfBids,'_amounts.length must be equal to numberOfBids');
        // require(_fake.length == numberOfBids,'_fake.length must be equal to numberOfBids');
        // require(_secret.length == numberOfBids,'_secret.length must be equal to numberOfBids');
        uint refund;
        for (uint i = 0; i < numberOfBids; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            if (bidToCheck.jobPoster == _endUser && bidToCheck.auctionId == _auctionId) {
                (uint amount, bool fake, bytes32 secret) = (_amounts[i], _fake[i], _secret[i]);
                if (bidToCheck.blindedBid != keccak256(abi.encodePacked(amount, fake, secret))) {
                    continue;
                }
                refund += bidToCheck.deposit;
                if (!fake && bidToCheck.deposit >= amount) {
                    if (placeBid(_endUser, _auctionId, msg.sender, amount)) {
                        refund -= amount;
                    }
                }
                bidToCheck.blindedBid = bytes32(0);
            }
        }
        // TODO 1 Replace the `transfer` invocation with a safer alternative
        token.transfer(msg.sender,refund);
    }

    function withdraw() public {
        uint amount = staleBids[msg.sender];
        if (amount > 0) {
            staleBids[msg.sender] = 0;
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            token.transfer(msg.sender,amount);
        }
    }

    function auctionEnd(
        address _endUser,
        uint _auctionId
    )
        public
        onlyAfter(auctions[_endUser][_auctionId].revealDeadline)
    {
        if (auctions[_endUser][_auctionId].ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(
            _endUser,
            _auctionId,
            auctions[_endUser][_auctionId].highestBidder,
            auctions[_endUser][_auctionId].secondHighestBid);
        auctions[_endUser][_auctionId].ended = true;
    }

    /// @dev This should be called by `_endUser`
    function payout(
        address _endUser,
        uint _auctionId
    )
        public
    {
        require(auctions[_endUser][_auctionId].ended, 'VickreyAuction has not ended');
        // TODO 1 Replace the `transfer` invocation with a safer alternative

        //FIXME
        token.transfer(_endUser, auctions[_endUser][_auctionId].secondHighestBid);
        uint leftover = auctions[_endUser][_auctionId].highestBid - auctions[_endUser][_auctionId].secondHighestBid;
        // TODO n Does `auctions[_endUser][_auctionId].reward` need to be set to `0`, like `amount` is in other places?
        uint workerPay = leftover + auctions[_endUser][_auctionId].reward;
        // TODO 4 Optimize the `transfer` of `leftover` to `highestBidder`
        // TODO 1 Replace the `transfer` invocation with a safer alternative
        token.transfer(auctions[_endUser][_auctionId].highestBidder, workerPay);
    }

    function placeBid(
        address _endUser,
        uint _auctionId,
        address _bidder,
        uint _amount
    )
        internal
        returns (bool success)
    {
        if (_amount <= auctions[_endUser][_auctionId].highestBid) {
            return false;
        }
        if (auctions[_endUser][_auctionId].highestBidder != address(0)) {
            staleBids[auctions[_endUser][_auctionId].highestBidder] += auctions[_endUser][_auctionId].highestBid;
        }
        auctions[_endUser][_auctionId].secondHighestBid = auctions[_endUser][_auctionId].highestBid;
        auctions[_endUser][_auctionId].highestBid = _amount;
        auctions[_endUser][_auctionId].highestBidder = _bidder;
        // TODO Possible cruft below
        /* emit BidPlaced(
            auctions[_endUser][_auctionId].highestBidder,
            auctions[_endUser][_auctionId].highestBid); */
        return true;
    }
}