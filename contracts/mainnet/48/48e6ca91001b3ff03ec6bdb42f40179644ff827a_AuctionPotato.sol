// loosely based on Bryn Bellomy code
// https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
//
// updated to 0.4.25 standard, replaced blocks with time, converted to hot potato style by Chibi Fighters
// https://chibifighters.io
//

pragma solidity ^0.4.25;

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



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract AuctionPotato is Ownable {
    using SafeMath for uint256; 

    string name;
    uint public startTime;
    uint public endTime;
    uint auctionDuration;

    // pototo
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    
    // used to immidiately block placeBids
    bool blockerPay;
    bool blockerWithdraw;
    
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    // couple events
    event LogBid(address bidder, address highestBidder, uint oldHighestBindingBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    event Withdraw(address owner, uint amount);
    
    
    constructor() public {
        
        blockerWithdraw = false;
        blockerPay = false;
        
        // 0.003 ETH
        highestBindingBid = 3000000000000000;
        potato = 0;
        
        // set to 3 hours
        auctionDuration = 3 hours;

        // 12/31/2018 @ 5:00pm (UTC) 1546275600 Glen Weyl
        // 01/03/2019 @ 5:00pm (UTC) 1546534800 Glen Weyl 2
        // 01/06/2019 @ 5:00pm (UTC) 1546794000 Glen Weyl 3
        
        // 12/31/2018 @ 6:00pm (UTC) 1546279200 Brenna Sparks
        // 01/03/2019 @ 6:00pm (UTC) 1546538400 Brenna Sparks 2
        // 01/06/2019 @ 6:00pm (UTC) 1546797600 Brenna Sparks 3

        startTime = 1546279200;
        endTime = startTime + auctionDuration;

        name = "Brenna Sparks";

    }
    
    
    function setStartTime(uint _time) onlyOwner public 
    {
        require(now < startTime);
        startTime = _time;
        endTime = startTime + auctionDuration;
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
    
    
    function queryAuction() public view returns (string, uint, address, uint, uint, uint)
    {
        
        return (name, nextBid(), highestBidder, highestBindingBid, startTime, endTime);
        
    }


    function placeBid() public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
    {   
        // we are only allowing to increase in bidIncrements to make for true hot potato style
        require(msg.value == highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(now > startTime);
        require(blockerPay == false);
        blockerPay = true;
        
        // calculate the user&#39;s total bid based on the current amount they&#39;ve sent to the contract
        // plus whatever has been sent with this transaction

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);

        highestBidder.transfer(fundsByBidder[highestBidder]);
        fundsByBidder[highestBidder] = 0;
        
        oldHighestBindingBid = highestBindingBid;
        
        // set new highest bidder
        highestBidder = msg.sender;
        highestBindingBid = highestBindingBid.add(potato);

        oldPotato = potato;
        potato = highestBindingBid.mul(4).div(9);
        
        emit LogBid(msg.sender, highestBidder, oldHighestBindingBid, highestBindingBid);
        
        blockerPay = false;
    }


    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
    {
        canceled = true;
        emit LogCanceled();
        
        emit Withdraw(highestBidder, address(this).balance);
        highestBidder.transfer(address(this).balance);
        
    }


    function withdraw() public onlyOwner {
        require(now > endTime);
        
        emit Withdraw(msg.sender, address(this).balance);
        msg.sender.transfer(address(this).balance);
    }


    function balance() public view returns (uint _balance) {
        return address(this).balance;
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