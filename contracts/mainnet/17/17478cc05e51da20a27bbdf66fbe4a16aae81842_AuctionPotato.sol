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
    uint public startTime;
    uint public endTime;
    string public infoUrl;
    string name;
    
    // start auction manually at given time
    bool started;

    // pototo
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
    // transfer ownership
    address creatureOwner;
    address creature_newOwner;
    event CreatureOwnershipTransferred(address indexed _from, address indexed _to);
    
    
    // state
    bool public canceled;
    
    uint public highestBindingBid;
    address public highestBidder;
    
    // used to immidiately block placeBids
    bool blockerPay;
    bool blockerWithdraw;
    
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, address highestBidder, uint oldHighestBindingBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    
    // initial settings on contract creation
    constructor() public {
        
        blockerWithdraw = false;
        blockerPay = false;
        
        owner = msg.sender;
        creatureOwner = owner;
        
        // 0.002 ETH
        highestBindingBid = 2000000000000000;
        potato = 0;
        
        started = false;
        
        name = "Minotaur";
        infoUrl = "https://chibifighters.io";
        
    }

    function getHighestBid() internal
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    // query remaining time
    // this should not be used, query endTime once and then calculate it in your frontend
    // it&#39;s helpful when you want to debug in remix
    function timeLeft() public view returns (uint time) {
        if (now >= endTime) return 0;
        return endTime - now;
    }
    
    function auctionName() public view returns (string _name) {
        return name;
    }
    
    // calculates the next bid amount to you can have a oneclick buy button
    function nextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato);
    }
    
    // calculates the bid after the current bid so nifty hackers can skip the queue
    // this is not in our frontend and no one knows if it actually works
    function nextNextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato).add((highestBindingBid.add(potato)).mul(4).div(9));
    }
    
    // command to start the auction
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
        require(msg.value == highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        require(blockerPay == false);
        blockerPay = true;
        
        // calculate the user&#39;s total bid based on the current amount they&#39;ve sent to the contract
        // plus whatever has been sent with this transaction

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);
        
        oldHighestBindingBid = highestBindingBid;
        
        // set new highest bidder
        highestBidder = msg.sender;
        highestBindingBid = highestBindingBid.add(potato);
        
        // 40% potato results in ~6% 2/7
        // 44% potato results in ? 13% 4/9 
        // 50% potato results in ~16% /2
        oldPotato = potato;
        potato = highestBindingBid.mul(4).div(9);
        
        emit LogBid(msg.sender, highestBidder, oldHighestBindingBid, highestBindingBid);
        blockerPay = false;
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
        require(blockerWithdraw == false);
        blockerWithdraw = true;
        
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
        if (ownerHasWithdrawn == false && msg.sender == owner && (canceled == true || now > endTime)) {
            withdrawalAccount = owner;
            withdrawalAmount = highestBindingBid.sub(oldPotato);
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
        if (!canceled && msg.sender == highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount].sub(oldHighestBindingBid);
            fundsByBidder[withdrawalAccount] = fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        }

        if (withdrawalAmount == 0) revert();
    
        // send the funds
        msg.sender.transfer(withdrawalAmount);

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        blockerWithdraw = false;
        return true;
    }
    
    // amount owner can withdraw after auction ended
    // that way you can easily compare the contract balance with your amount
    // if there is more in the contract than your balance someone didn&#39;t withdraw
    // let them know that :)
    function ownerCanWithdraw() public view returns (uint amount) {
        return highestBindingBid.sub(oldPotato);
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

    modifier onlyBeforeEnd {
        if (now > endTime) revert();
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) revert();
        _;
    }
    
    // who owns the creature (not necessarily auction winner)
    function queryCreatureOwner() public view returns (address _creatureOwner) {
        return creatureOwner;
    }
    
    // transfer ownership for auction winners in case they want to trade the creature before release
    function transferCreatureOwnership(address _newOwner) public {
        require(msg.sender == creatureOwner);
        creature_newOwner = _newOwner;
    }
    
    // buyer needs to confirm the transfer
    function acceptCreatureOwnership() public {
        require(msg.sender == creature_newOwner);
        emit CreatureOwnershipTransferred(creatureOwner, creature_newOwner);
        creatureOwner = creature_newOwner;
        creature_newOwner = address(0);
    }
    
}