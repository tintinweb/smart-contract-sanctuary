pragma solidity ^0.4.0;

contract TwentyDollars {
    /*
     * Storage
     */

    struct Bid {
        address owner;
        uint256 amount;
    }

    address owner;
    uint256 public gameValue;
    uint256 public gameEndBlock;
    
    Bid public highestBid;
    Bid public secondHighestBid;
    mapping (address => uint256) public balances;

    
    /*
     * Modifiers
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBiddingOpen() {
        require(block.number < gameEndBlock);
        _;
    }

    modifier onlyBiddingClosed() {
        require(biddingClosed());
        _;
    }

    modifier onlyHighestBidder() {
        require(msg.sender == highestBid.owner);
        _;
    }
    
    
    /*
     * Constructor
     */
    
    constructor() public payable {
        owner = msg.sender;
        gameValue = msg.value;
        gameEndBlock = block.number + 40000;
    }


    /*
     * Public functions
     */

    function bid() public payable onlyBiddingOpen {
        // Must bid higher than current highest bid.
        require(msg.value > highestBid.amount);

        // Push out second highest bid and set new highest bid.
        balances[secondHighestBid.owner] += secondHighestBid.amount;
        secondHighestBid = highestBid;
        highestBid.owner = msg.sender;
        highestBid.amount = msg.value;
        
        // Extend the game by ten blocks.
        gameEndBlock += 10;
    }
    
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

    function winnerWithdraw() public onlyBiddingClosed onlyHighestBidder {
        address highestBidder = highestBid.owner;
        require(highestBidder != address(0));
        delete highestBid.owner;
        highestBidder.transfer(gameValue);
    }

    function ownerWithdraw() public onlyOwner onlyBiddingClosed {
        // Withdraw the value of the contract minus allocation for the winner. 
        uint256 winnerAllocation = (highestBid.owner == address(0)) ? 0 : gameValue;
        owner.transfer(getContractBalance() - winnerAllocation);
    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function biddingClosed() public view returns (bool) {
        return block.number >= gameEndBlock;
    }
    
    
    /*
     * Fallback
     */

    function () public payable {
        bid();
    }
}