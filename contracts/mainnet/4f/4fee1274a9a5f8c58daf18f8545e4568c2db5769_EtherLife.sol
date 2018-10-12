pragma solidity ^0.4.24;

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
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

contract EtherLife is Ownable
{   
    using SafeMath for uint;
    
    struct deposit {
        uint time;
        uint value;
        uint timeOfLastWithdraw;
    }
    
    mapping(address => deposit) public deposits;
    mapping(address => address) public parents;
    address[] public investors;
    
    uint public constant withdrawPeriod = 1 days;
    
    uint public constant minDepositSum = 100 finney; // 0.1 ether;
    
    event Deposit(address indexed from, uint256 value);
    event Withdraw(address indexed from, uint256 value);
    event ReferrerBonus(address indexed from, address indexed to, uint8 level, uint256 value);
    
    
    modifier checkSender() 
    {
        require(msg.sender != address(0));
        _;
    }

    
    function bytesToAddress(bytes source) internal pure returns(address parsedAddress) 
    {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

    function () checkSender public payable 
    {
        if(msg.value == 0)
        {
            withdraw();
            return;
        }
        
        require(msg.value >= minDepositSum);
        
        checkReferrer(msg.sender);
        
        payFee(msg.value);
        addDeposit(msg.sender, msg.value);
        
        emit Deposit(msg.sender, msg.value);
        
        payRewards(msg.sender, msg.value);
    }
    
    function getInvestorsLength() public view returns (uint)
    {
        return investors.length;
    }
    
    function getParents(address investorAddress) public view returns (address[])
    {
        address[] memory refLevels = new address[](5);
        address current = investorAddress;
        
        for(uint8 i = 0; i < 5; i++)
        {
             current = parents[current];
             if(current == address(0)) break;
             refLevels[i] = current;
        }
        
        return refLevels;
    }
    
    function calculateRewardForLevel(uint8 level, uint value) public pure returns (uint)
    {
        if(level == 1) return value.div(50);           // 2%
        if(level == 2) return value.div(100);          // 1%
        if(level == 3) return value.div(200);          // 0.5%
        if(level == 4) return value.div(400);          // 0.25%
        if(level == 5) return value.div(400);          // 0.25%
        
        return 0;
    }
    
    function calculatWithdrawForPeriod(uint8 period, uint depositValue, uint periodsCount) public pure returns (uint)
    {
        if(period == 1)
        {
            return depositValue.div(25).mul(periodsCount);          // 4%
        }
        else if(period == 2)
        {
            return depositValue.mul(3).div(100).mul(periodsCount);  // 3%
        }
        else if(period == 3)
        {
            return depositValue.div(50).mul(periodsCount);          // 2%
        }
        else if(period == 4)
        {
            return depositValue.div(100).mul(periodsCount);         // 1%
        }
        else if(period == 5)
        {
            return depositValue.div(200).mul(periodsCount);         // 0.5%
        }
        
        return 0;
    }
    
    function calculateWithdraw(uint currentTime, uint depositTime, uint depositValue, uint timeOfLastWithdraw) public pure returns (uint)
    {
        if(currentTime - timeOfLastWithdraw < withdrawPeriod)
        {
            return 0;
        }
        
        uint timeEndOfPeriod1 = depositTime + 30 days;
        uint timeEndOfPeriod2 = depositTime + 60 days;
        uint timeEndOfPeriod3 = depositTime + 90 days;
        uint timeEndOfPeriod4 = depositTime + 120 days;
        

        uint sum = 0;
        uint timeEnd = 0;
        uint periodsCount = 0;
            
        if(timeOfLastWithdraw < timeEndOfPeriod1)
        {
            timeEnd = currentTime > timeEndOfPeriod1 ? timeEndOfPeriod1 : currentTime;
            (periodsCount, timeOfLastWithdraw) = calculatePeriodsCountAndNewTime(timeOfLastWithdraw, timeEnd);
            sum = calculatWithdrawForPeriod(1, depositValue, periodsCount);
        }
        
        if(timeOfLastWithdraw < timeEndOfPeriod2)
        {
            timeEnd = currentTime > timeEndOfPeriod2 ? timeEndOfPeriod2 : currentTime;
            (periodsCount, timeOfLastWithdraw) = calculatePeriodsCountAndNewTime(timeOfLastWithdraw, timeEnd);
            sum = sum.add(calculatWithdrawForPeriod(2, depositValue, periodsCount));
        }
        
        if(timeOfLastWithdraw < timeEndOfPeriod3)
        {
            timeEnd = currentTime > timeEndOfPeriod3 ? timeEndOfPeriod3 : currentTime;
            (periodsCount, timeOfLastWithdraw) = calculatePeriodsCountAndNewTime(timeOfLastWithdraw, timeEnd);
            sum = sum.add(calculatWithdrawForPeriod(3, depositValue, periodsCount));
        }
        
        if(timeOfLastWithdraw < timeEndOfPeriod4)
        {
            timeEnd = currentTime > timeEndOfPeriod4 ? timeEndOfPeriod4 : currentTime;
            (periodsCount, timeOfLastWithdraw) = calculatePeriodsCountAndNewTime(timeOfLastWithdraw, timeEnd);
            sum = sum.add(calculatWithdrawForPeriod(4, depositValue, periodsCount));
        }
        
        if(timeOfLastWithdraw >= timeEndOfPeriod4)
        {
            timeEnd = currentTime;
            (periodsCount, timeOfLastWithdraw) = calculatePeriodsCountAndNewTime(timeOfLastWithdraw, timeEnd);
            sum = sum.add(calculatWithdrawForPeriod(5, depositValue, periodsCount));
        }
         
        return sum;
    }
    
    function checkReferrer(address investorAddress) internal
    {
        if(deposits[investorAddress].value == 0 && msg.data.length == 20)
        {
            address referrerAddress = bytesToAddress(bytes(msg.data));
            require(referrerAddress != investorAddress);     
            require(deposits[referrerAddress].value > 0);        
            
            parents[investorAddress] = referrerAddress;
            investors.push(investorAddress);
        }
    }
    
    function payRewards(address investorAddress, uint depositValue) internal
    {   
        address[] memory parentAddresses = getParents(investorAddress);
        for(uint8 i = 0; i < parentAddresses.length; i++)
        {
            address parent = parentAddresses[i];
            if(parent == address(0)) break;
            
            uint rewardValue = calculateRewardForLevel(i + 1, depositValue);
            parent.transfer(rewardValue);
            
            emit ReferrerBonus(investorAddress, parent, i + 1, rewardValue);
        }
    }
    
    function addDeposit(address investorAddress, uint weiAmount) internal
    {   
        if(deposits[investorAddress].value == 0)
        {
            deposits[investorAddress].time = now;
            deposits[investorAddress].timeOfLastWithdraw = now;
            deposits[investorAddress].value = weiAmount;
        }
        else
        {
            if(now - deposits[investorAddress].timeOfLastWithdraw >= withdrawPeriod)
            {
                payWithdraw(investorAddress);
            }
            
            deposits[investorAddress].value = deposits[investorAddress].value.add(weiAmount);
            deposits[investorAddress].timeOfLastWithdraw = now;
        }
    }
    
    function payFee(uint weiAmount) internal
    {
        uint fee = weiAmount.mul(16).div(100); // 16%
        owner.transfer(fee);
    }
    
    function calculateNewTime(uint startTime, uint endTime) public pure returns (uint) 
    {
        uint periodsCount = endTime.sub(startTime).div(withdrawPeriod);
        return startTime.add(withdrawPeriod.mul(periodsCount));
    }
    
    function calculatePeriodsCountAndNewTime(uint startTime, uint endTime) public pure returns (uint, uint) 
    {
        uint periodsCount = endTime.sub(startTime).div(withdrawPeriod);
        uint newTime = startTime.add(withdrawPeriod.mul(periodsCount));
        return (periodsCount, newTime);
    }
    
    function payWithdraw(address to) internal
    {
        require(deposits[to].value > 0);
        
        uint sum = calculateWithdraw(now, deposits[to].time, deposits[to].value, deposits[to].timeOfLastWithdraw);
        require(sum > 0);
        
        deposits[to].timeOfLastWithdraw = calculateNewTime(deposits[to].time, now);
        
        to.transfer(sum);
        emit Withdraw(to, sum);
    }
    
    
    function withdraw() checkSender public returns (bool)
    {
        payWithdraw(msg.sender);
        return true;
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
}