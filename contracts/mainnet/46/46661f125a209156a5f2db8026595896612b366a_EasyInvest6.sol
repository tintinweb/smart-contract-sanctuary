pragma solidity ^0.4.23;

/**
 * EasyInvest 6 Contract
 *  - GAIN 6% PER 24 HOURS
 *  - STRONG MARKETING SUPPORT  
 *  - NEW BETTER IMPROVEMENTS
 * How to use:
 *  1. Send any amount of ether to make an investment;
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS);
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time;
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract is reviewed and approved by professionals!
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract EasyInvest6 is Ownable
{   
    using SafeMath for uint;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public lastInvest;
    address[] public investors;
    
    address private m1;
    address private m2;
    
    
    function getInvestorsCount() public view returns(uint) 
    {   
        return investors.length;
    }
    
    function () external payable 
    {   
        if(msg.value > 0) 
        {   
            require(msg.value >= 10 finney, "require minimum 0.01 ETH"); // min 0.01 ETH
            
            uint fee = msg.value.mul(7).div(100).add(msg.value.div(200)); // 7.5%;            
            if(m1 != address(0)) m1.transfer(fee);
            if(m2 != address(0)) m2.transfer(fee);
        }
    
        payWithdraw(msg.sender);
        
        if (invested[msg.sender] == 0) 
        {
            investors.push(msg.sender);
        }
        
        lastInvest[msg.sender] = now;
        invested[msg.sender] += msg.value;
    }
    
    function getNumberOfPeriods(uint startTime, uint endTime) public pure returns (uint)
    {
        return endTime.sub(startTime).div(1 days);
    }
    
    function getWithdrawAmount(uint investedSum, uint numberOfPeriods) public pure returns (uint)
    {
        return investedSum.mul(6).div(100).mul(numberOfPeriods);
    }
    
    function payWithdraw(address to) internal
    {
        if (invested[to] != 0) 
        {
            uint numberOfPeriods = getNumberOfPeriods(lastInvest[to], now);
            uint amount = getWithdrawAmount(invested[to], numberOfPeriods);
            to.transfer(amount);
        }
    }
    
    function batchWithdraw(address[] to) onlyOwner public 
    {
        for(uint i = 0; i < to.length; i++)
        {
            payWithdraw(to[i]);
        }
    }
    
    function batchWithdraw(uint startIndex, uint length) onlyOwner public 
    {
        for(uint i = startIndex; i < length; i++)
        {
            payWithdraw(investors[i]);
        }
    }
    
    function setM1(address addr) onlyOwner public 
    {
        m1 = addr;
    }
    
    function setM2(address addr) onlyOwner public 
    {
        m2 = addr;
    }
}