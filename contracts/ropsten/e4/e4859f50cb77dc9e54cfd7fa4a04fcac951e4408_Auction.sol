pragma solidity ^0.4.8;

contract Auction {
    // static
    address public owner;
    uint public bidIncrement;
    uint public endTime;
    string public ipfsHash;

    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event Bid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event Withdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event Canceled();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
        _;
    }

    modifier onlyBeforeEnd {
        require(block.timestamp < endTime);
        _;
    }

    modifier onlyAfterEnd {
        require(block.timestamp > endTime);
        _;
    }

    constructor(address _owner, uint _bidIncrement, uint _maxAuctionTime, string _ipfsHash) public {
        require(_owner != 0);

        owner = _owner;
        bidIncrement = _bidIncrement;
        endTime = block.timestamp + _maxAuctionTime;
        ipfsHash = _ipfsHash;
    }

    function getHighestBid()
        public
        view
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }

    function placeBid()
        public
        payable
        onlyBeforeEnd
        onlyNotOwner
        returns (bool success)
    {
        require(msg.value != 0);
        require(fundsByBidder[msg.sender] + msg.value > highestBindingBid);

        uint newBid = fundsByBidder[msg.sender] + msg.value;
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you&#39;ve already bid.

            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn&#39;t increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
            }
            highestBid = newBid;
        }

        emit Bid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }

    function min(uint a, uint b)
        private
        pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

    function cancelAuction()
        public
        onlyOwner
        onlyBeforeEnd
        returns (bool success)
    {
        canceled = true;
        emit Canceled();
        return true;
    }

    function endAuction()
        public
        onlyOwner
        onlyBeforeEnd
        returns (bool success)
    {
        endTime = block.timestamp;
        return true;
    }

    function withdraw()
        public
        onlyAfterEnd
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
        } else {
            // the auction finished without being canceled
            if (msg.sender == owner) {
                // the auction&#39;s owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;
            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }
            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        require(withdrawalAmount != 0);

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;
        require(msg.sender.send(withdrawalAmount));

        emit Withdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
}