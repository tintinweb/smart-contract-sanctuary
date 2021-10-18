// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

contract SimpleAuction {

    // Address of the creator of the auction.
    address payable public creator;

    // Address of the beneficiary of the auction.
    address public beneficiary;

    // Unix timestamps (seconds since 1970-01-01) or time periods in seconds.
    // Use https://www.unixtimestamp.com/ to convert between timestamps and DD-MMM-YYY.
    uint256 public endTime;

    address public highestBidder;
    uint256 public highestBid;

    // Ledger of bids, to allow for withdrawal by non-winners after auction ends.
    mapping(address => uint256) public pendingReturns;

    // Set to true when auction ends, to allow for withdrawals.
    bool public ended = false;

    event BeneficiaryUpdated(address beneficiary);
    event EndTimeUpdated(uint256 endTime);

    event HighestBidIncrease(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    /// Create a simple auction that will end after `_secsToEnd` seconds
    /// with `_beneficiary` as the beneficiary of the winning bid.
    constructor(uint256 _secsToEnd, address payable _beneficiary) {
        beneficiary = _beneficiary;
        endTime = block.timestamp + _secsToEnd;
        creator = payable(msg.sender);
    }

    /// Updates the beneficiary address of the auction.  
    /// In production the `onlyCreator` modifier should be applied.
    function updateBeneficiary(address _beneficiary) public {
        beneficiary = _beneficiary;

        emit BeneficiaryUpdated(_beneficiary);
    }

    /// Updates the `endTime` of the auction.  
    /// In production the `onlyCreator` modifier should be applied.
    function updateEndTime(uint256 _endTime) public {
        endTime = _endTime;

        emit EndTimeUpdated(_endTime);
    }

    // Modifier to check that the caller is the creator of the contract.
    modifier onlyCreator() {
        require(msg.sender == creator, "Not creator.");
        _;
    }

    /// Bid on the auction with the value sent together with this transaction.
    function bid() public payable {
        // Check is auction has ended
        if (block.timestamp > endTime) {
            revert("Auction already ended.");
        }

        // Check that incoming bid is the highest bid
        if (msg.value < highestBid) {
            revert("A higher bid already exist.");
        }

        // Update the ledger of pending returns to facilitate withdrawal by non-winning bidders after auction ends
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncrease(msg.sender, msg.value);
    }

    /// Withdraw funds from contract by non-winning bidders after auction ends.
    function withdraw() public returns (bool) {

        // Check withdrawal amount from ledger of pending returns.
        uint256 amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            // If  withdrawal is not successful, reinstate amount in ledger of pending returns.
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    /// Flag the auction as ended
    function endAuction() public onlyCreator {

        // Check if auction is still in progress
        if (block.timestamp < endTime) {
            revert("Auction still in progress.");
        }

        // Check if auction has ended
        if (ended) {
            revert("Auction ended already");
        }

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (highestBid > 0) {
            // Transfer the winning bid to the auction beneficiary
            payable(beneficiary).transfer(highestBid);
        }
    }
}