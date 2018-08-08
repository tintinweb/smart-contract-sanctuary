// loosely based on Bryn Bellomy code
// https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
//
// 
// Our Aetherian #0 ownership is now handled by this contract instead of our core. This contract "owns" 
// the monster and players can bid to get their hands on this mystical creature until someone else outbids them.
// Every following sale increases the price by x1.5 until no one is willing to outbid the current owner.
// Once a player has lost ownership, they will get a full refund of their bid + 50% of the revenue created by the sale.
// The other 50% go to the dev team to fund development. 
// This "hot potato" style auction technically never ends and enables some very interesting scenarios
// for our in-game world
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
    uint public startTime;
    
    string name;
    
    // start auction manually at given time
    bool started;

    // pototo
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
    // transfer ownership
    address creatureOwner;
    
    event CreatureOwnershipTransferred(address indexed _from, address indexed _to);
    
    
   
    
    uint public highestBindingBid;
    address public highestBidder;
    
    // used to immidiately block placeBids
    bool blockerPay;
    bool blockerWithdraw;
    
    mapping(address => uint256) public fundsByBidder;
  

    event LogBid(address bidder, address highestBidder, uint oldHighestBindingBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    
    
    
    // initial settings on contract creation
    constructor() public {
    
        
        blockerWithdraw = false;
        blockerPay = false;
        
        owner = msg.sender;
        creatureOwner = owner;
        
        // 1 ETH starting price
        highestBindingBid = 1000000000000000000;
        potato = 0;
        
        started = false;
        
        name = "Aetherian";
        
    }

    function getHighestBid() internal
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    
    
    function auctionName() public view returns (string _name) {
        return name;
    }
    
    // calculates the next bid amount so that you can have a one-click buy button
    function nextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato);
    }
    
    
    // command to start the auction
    function startAuction() public onlyOwner returns (bool success){
        require(started == false);
        
        started = true;
        startTime = now;
        
        
        return true;
        
    }
    
    function isStarted() public view returns (bool success) {
        return started;
    }

    function placeBid() public
        payable
        onlyAfterStart
        onlyNotOwner
        returns (bool success)
    {   
        // we are only allowing to increase in bidIncrements to make for true hot potato style
        // while still allowing overbid to happen in case some parties are trying to 
        require(msg.value >= highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        require(blockerPay == false);
        blockerPay = true;

        // if someone overbids, return their
        if (msg.value > highestBindingBid.add(potato))
        {
            uint overbid = msg.value - highestBindingBid.add(potato);
            msg.sender.transfer(overbid);
        }
        
        // calculate the user&#39;s total bid based on the current amount they&#39;ve sent to the contract
        // plus whatever has been sent with this transaction

        
        
        oldHighestBindingBid = highestBindingBid;
        
        // set new highest bidder
        highestBidder = msg.sender;
        highestBindingBid = highestBindingBid.add(potato);
        
        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        
        
        oldPotato = potato;
        
        uint potatoShare;
        
        potatoShare = potato.div(2);
        potato = highestBindingBid.mul(5).div(10);
            
        // special case at start of auction
        if (creatureOwner == owner) {
            fundsByBidder[owner] = fundsByBidder[owner].add(highestBindingBid);
        }
        else {
            fundsByBidder[owner] = fundsByBidder[owner].add(potatoShare);
            
            fundsByBidder[creatureOwner] = fundsByBidder[creatureOwner].add(potatoShare);
        }
        
        
        
        
        emit LogBid(msg.sender, highestBidder, oldHighestBindingBid, highestBindingBid);
        
        
        emit CreatureOwnershipTransferred(creatureOwner, msg.sender);
        creatureOwner = msg.sender;
        
        
        blockerPay = false;
        return true;
    }

    

    function withdraw() public
    // can withdraw once overbid
        returns (bool success)
    {
        require(blockerWithdraw == false);
        blockerWithdraw = true;
        
        address withdrawalAccount;
        uint withdrawalAmount;
        
        if (msg.sender == owner) {
            withdrawalAccount = owner;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            
            
            // set funds to 0
            fundsByBidder[withdrawalAccount] = 0;
        }
       
        // overbid people can withdraw their bid + profit
        // exclude owner because he is set above
        if (msg.sender != highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            fundsByBidder[withdrawalAccount] = 0;
        }
        
        if (withdrawalAmount == 0) revert();
    
        // send the funds
        msg.sender.transfer(withdrawalAmount);

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        blockerWithdraw = false;
        return true;
    }
    
    // amount owner can withdraw
    // that way you can easily compare the contract balance with your amount
    // if there is more in the contract than your balance someone didn&#39;t withdraw
    // let them know that :)
    function ownerCanWithdraw() public view returns (uint amount) {
        return fundsByBidder[owner];
    }
    
    // just in case the contract is bust and can&#39;t pay
    // should never be needed but who knows
    function fuelContract() public onlyOwner payable {
        
    }
    
    function balance() public view returns (uint _balance) {
        return address(this).balance;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
        _;
    }

    modifier onlyAfterStart {
        if (now < startTime) revert();
        _;
    }

    
    
    
    // who owns the creature (not necessarily auction winner)
    function queryCreatureOwner() public view returns (address _creatureOwner) {
        return creatureOwner;
    }
    
    
    
   
    
}