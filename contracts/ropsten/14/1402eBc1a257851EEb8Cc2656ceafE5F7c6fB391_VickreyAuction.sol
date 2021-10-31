// SPDX-License-Identifier: GPL-3.0
// vim: noai:ts=4:sw=4

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// TODO Review all usage of `public`
// TODO Optimize storage writes with memory

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

    // FIXME 1 (continued)
    // Have end-user actually transfer the funds and then check that the reward amount is equal to it
    // NEED TO FIGURE OUT WHICH CONTRACT WILL HAVE CUSTODY OF DATA SCIENTIST'S FUNDS
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
        // FIXME Later this should be less than the worker-specific reward
        require(_amount < auctions[_endUser][_auctionId].reward,'_amount must be less than reward');
        require(_amount > auctions[_endUser][_auctionId].minimumPayout,'_amount must be greater than minimumPayout');
        uint allowedAmount = token.allowance(msg.sender,address(this));
        require(allowedAmount >= _amount,'allowedAmount must be greater than or equal to _amount');
        // TODO  1.5 Re-factor `transferFrom` to eliminate gas costs?
        // NEED TO FIGURE OUT WHETHER WE WANT TO USE INTERNAL ACCOUNTING AND LET USERS WITHDRAW OR
        // IF WE WANT TO JUST USE TRANSFERFROM
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
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            if (refund > 0) token.transfer(msg.sender,refund);
        }
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
        if (auctions[_endUser][_auctionId].status == Status.isActive) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(
            _endUser,
            _auctionId,
            auctions[_endUser][_auctionId].highestBidder,
            auctions[_endUser][_auctionId].secondHighestBid);
        auctions[_endUser][_auctionId].status = Status.isEndedButNotPaid;
    }

    /// @dev This should be called by `_endUser`
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
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            uint leftover = auctions[_endUser][_auctionId].highestBid - auctions[_endUser][_auctionId].secondHighestBid;
            // TODO n Does `auctions[_endUser][_auctionId].reward` need to be set to `0`, like `amount` is in other places?
            uint workerPay = leftover + auctions[_endUser][_auctionId].reward;
            // TODO 4 Optimize the `transfer` of `leftover` to `highestBidder`
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            token.transfer(auctions[_endUser][_auctionId].highestBidder, workerPay);
            // possible 2nd transfer where 2nd highest bid amount needs to be transferred to the data scientist
            // reward - 2nd highest bid goes to the worker node
            // don't transfer to the data scientist if there's only been one bid
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

// SPDX-License-Identifier: MIT

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