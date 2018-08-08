// based on Bryn Bellomy code
// https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
//
// updated to 0.4.21 standard, replaced blocks with time, converted to hot potato style by Chibi Fighters
// added custom start command for owner so they don&#39;t take off immidiately
//

pragma solidity ^0.4.21;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, returns 0 if it would go into minus range.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AuctionPotato {
    using SafeMath for uint256; 
    // static
    address public owner;
    uint public bidIncrement;
    uint public startTime;
    uint public endTime;
    string public infoUrl;
    string name;
    
    // start auction manually at given time
    bool started;

    // pototo
    uint public potato;
    
    // state
    bool public canceled;
    
    uint public highestBindingBid;
    address public highestBidder;
    
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    
    // initial settings on contract creation
    constructor() public {

        owner = msg.sender;
        // 0.01 ETH
        bidIncrement = 10000000000000000;
        
        started = false;
        
        name = "Lizard People";
        infoUrl = "https://chibifighters.io";
        
    }

    function getHighestBid() internal
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    function timeLeft() public view returns (uint time) {
        if (now >= endTime) return 0;
        return endTime - now;
    }
    
    function auctionName() public view returns (string _name) {
        return name;
    }
    
    function nextBid() public view returns (uint _nextBid) {
        return bidIncrement.add(highestBindingBid).add(potato);
    }
    
    function startAuction(string _name, uint _duration_secs) public onlyOwner returns (bool success){
        require(started == false);
        
        started = true;
        startTime = now;
        endTime = now + _duration_secs;
        name = _name;
        
        return true;
        
    }
    
    function isStarted() public view returns (bool success) {
        return started;
    }

    function placeBid() public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {   
        // we are only allowing to increase in bidIncrements to make for true hot potato style
        require(msg.value == highestBindingBid.add(bidIncrement).add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        
        // calculate the user&#39;s total bid based on the current amount they&#39;ve sent to the contract
        // plus whatever has been sent with this transaction
        uint newBid = highestBindingBid.add(bidIncrement);

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(newBid);
        
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);
        
        // set new highest bidder
        highestBidder = msg.sender;
        highestBindingBid = newBid;
        
        // set new increment size
        bidIncrement = bidIncrement.mul(5).div(4);
        
        // 10% potato
        potato = highestBindingBid.div(100).mul(20);
        
        emit LogBid(msg.sender, newBid, highestBidder, highestBindingBid);
        return true;
    }

    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }

    function withdraw() public
    // can withdraw once overbid
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            // set funds to 0
            fundsByBidder[withdrawalAccount] = 0;
        }
        
        // owner can withdraw once auction is cancelled or ended
        //if (ownerHasWithdrawn == false && msg.sender == owner && (canceled == true || now > endTime)) {
        if (msg.sender == owner) {
            withdrawalAccount = owner;
            withdrawalAmount = highestBindingBid;
            ownerHasWithdrawn = true;
            
            // set funds to 0
            fundsByBidder[withdrawalAccount] = 0;
        }
        
        // overbid people can withdraw their bid + profit
        // exclude owner because he is set above
        if (!canceled && (msg.sender != highestBidder && msg.sender != owner)) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            fundsByBidder[withdrawalAccount] = 0;
        }

        // highest bidder can withdraw leftovers if he didn&#39;t before
        if (msg.sender == highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount].sub(highestBindingBid);
            fundsByBidder[withdrawalAccount] = fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        }

        if (withdrawalAmount == 0) revert();
    
        // send the funds
        if (!msg.sender.send(withdrawalAmount)) revert();

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
    
    // just in case the contract is bust and can&#39;t pay
    function fuelContract() public onlyOwner payable {
        
    }
    
    function balance() public view returns (uint _balance) {
        return address(this).balance;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    modifier onlyNotOwner {
        if (msg.sender == owner) revert();
        _;
    }

    modifier onlyAfterStart {
        if (now < startTime) revert();
        _;
    }

    modifier onlyBeforeEnd {
        if (now > endTime) revert();
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) revert();
        _;
    }
}