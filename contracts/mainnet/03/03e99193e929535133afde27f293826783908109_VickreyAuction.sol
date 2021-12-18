// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import './IERC20.sol';


contract VickreyAuction {

    event AuctionEnded(
        address indexed endUser,
        uint auctionId,
        address winner, 
        uint secondHighestBid
    );

    event BidPlaced(
        address indexed endUser,
        uint indexed auctionId,
        address indexed bidder
    );

    event PaidOut(
        address indexed endUser,
        uint indexed auctionId,
        uint amount
    );

    enum Status {
        isActive,
        isEndedButNotPaid,
        isEndedAndPaid
    }

    struct Bid {
        bytes32 blindedBid;
        address jobPoster;
        uint auctionId;
        uint deposit;
    }

    struct Auction {
        uint minimumPayout;
        uint reward;
        uint biddingDeadline;
        uint revealDeadline;
        uint bidsPlaced;
        uint highestBid;
        uint secondHighestBid;
        address highestBidder;
        Status status;
    }

    mapping(address => Auction[]) public auctions;
    mapping(bytes32 => Bid) private bids;
    mapping(address => uint) private staleBids;

    IERC20 public token;

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();
    error DoesNotMatchBlindedBid();

    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

    constructor(
        IERC20 _token
    ) {
        token = _token;
    }

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
            bidsPlaced: 0,
            highestBid: 0,
            secondHighestBid: 0,
            highestBidder: _endUser,
            status: Status.isActive
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
        require(_amount < auctions[_endUser][_auctionId].reward,'_amount must be less than reward');
        require(_amount > auctions[_endUser][_auctionId].minimumPayout,'_amount must be greater than minimumPayout');
        uint allowedAmount = token.allowance(msg.sender,address(this));
        require(allowedAmount >= _amount,'allowedAmount must be greater than or equal to _amount');
        token.transferFrom(msg.sender,address(this),_amount);
        bids[keccak256(abi.encodePacked(_endUser,_auctionId,msg.sender))] = Bid({
            blindedBid: _blindedBid,
            deposit: _amount,
            jobPoster: _endUser,
            auctionId: _auctionId
        });
        emit BidPlaced(
            _endUser,
            _auctionId,
            msg.sender);
    }

    function reveal(
        address _endUser,
        uint _auctionId,
        uint _amount,
        bool _fake,
        bytes32 _secret
    )
        public
        onlyAfter(auctions[_endUser][_auctionId].biddingDeadline)
        onlyBefore(auctions[_endUser][_auctionId].revealDeadline)
    {
        Bid storage bidToCheck = bids[keccak256(abi.encodePacked(_endUser,_auctionId,msg.sender))];
        if (bidToCheck.jobPoster == _endUser && bidToCheck.auctionId == _auctionId) {
            uint refund;
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(_amount, _fake, _secret))) {
                revert DoesNotMatchBlindedBid();
            }
            refund += bidToCheck.deposit;
            if (!_fake && bidToCheck.deposit >= _amount) {
                if (placeBid(_endUser, _auctionId, msg.sender, _amount)) {
                    refund -= _amount;
                }
            }
            bidToCheck.blindedBid = bytes32(0);
            if (refund > 0) token.transfer(msg.sender,refund);
        }
    }

    function withdraw() public {
        uint amount = staleBids[msg.sender];
        if (amount > 0) {
            staleBids[msg.sender] = 0;
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
        if (auctions[_endUser][_auctionId].status == Status.isActive) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(
            _endUser,
            _auctionId,
            auctions[_endUser][_auctionId].highestBidder,
            auctions[_endUser][_auctionId].secondHighestBid);
        auctions[_endUser][_auctionId].status = Status.isEndedButNotPaid;
    }

    function payout(
        address _endUser,
        uint _auctionId
    )
        public
    {
        require(auctions[_endUser][_auctionId].status != Status.isActive, 'VickreyAuction has not ended');
        require(auctions[_endUser][_auctionId].status != Status.isEndedAndPaid, 'VickreyAuction has been paid-out');
        if (auctions[_endUser][_auctionId].bidsPlaced == 0) {
            token.transfer(_endUser, auctions[_endUser][_auctionId].reward);
        } else {
            uint leftover = auctions[_endUser][_auctionId].highestBid - auctions[_endUser][_auctionId].secondHighestBid;
            uint workerPay = leftover + auctions[_endUser][_auctionId].reward;
            token.transfer(auctions[_endUser][_auctionId].highestBidder, workerPay);
            emit PaidOut(
                _endUser,
                _auctionId,
                workerPay);
        }
        auctions[_endUser][_auctionId].status = Status.isEndedAndPaid;
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
            address hb = auctions[_endUser][_auctionId].highestBidder;
            staleBids[hb] += auctions[_endUser][_auctionId].highestBid;
        }
        auctions[_endUser][_auctionId].secondHighestBid = auctions[_endUser][_auctionId].highestBid;
        auctions[_endUser][_auctionId].highestBid = _amount;
        auctions[_endUser][_auctionId].highestBidder = _bidder;
        auctions[_endUser][_auctionId].bidsPlaced += 1;
        return true;
    }
}