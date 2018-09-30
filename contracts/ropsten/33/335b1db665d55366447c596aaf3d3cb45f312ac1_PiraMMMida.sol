pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    owner = newOwner;
  }

}


contract PiraMMMida is Ownable {
    
    event payEventLog(address _address, uint value, uint periodCount, uint percent);
    
    using SafeMath for uint256;
    
    //mapping (uint => uint) InPeriod;
    uint public period = 10*60;//1 days; // 1 day
    uint public startTime = now; 
    
    uint public basicDayPercent = 300; //3%
    uint public bonusDayPercent = 330; //3.3%
    
    uint public referrerLevel1Percent = 250; //2.5%
    uint public referrerLevel2Percent = 500; //5%
    uint public referrerLevel3Percent = 1000; //10%    
    
    uint public referrerLevel2Ether = 0.1 ether;
    uint public referrerLevel3Ether = 1 ether;
    
    uint public minBet = 0.01  ether;
    
    uint public referrerAndOwnerPercent = 2000; //20%    
    
    uint public currBetID = 0;
    
    
    struct BetStruct {
        //address user;
        uint value;
        uint firstBetTime;
        uint lastBetTime;
        uint lastPaymentTime;
        uint nextPayAfterTime;
        bool isExist;
        uint id;
        uint referrerID;
    }
    
    mapping (address => BetStruct) public betsDatabase;
    mapping (uint => address) public addressList;
    //address[] public addressList;
    


    
    constructor() public {
    
    }

    
 function createBet(uint _referrerID) public payable {
     
        //проверяем, правильность _referrerID
        if( (_referrerID >= currBetID)&&(_referrerID!=0)){
            revert("Incorrect _referrerID");
        }

        //проверяем - удовлетворяет ли присланная сумма условиям минимальной и максимальной ставки
        if( msg.value < minBet){
            revert("Amount beyond acceptable limits");
        }
        
        BetStruct memory betStruct;
        
        //Проверяем, делалась ли ставка данным инвестором ранее
        if(betsDatabase[msg.sender].isExist){
            betStruct = betsDatabase[msg.sender];
            
            // Выплачиваем, то что должны на данный момент, если не выплачивали ранее
            if(betStruct.nextPayAfterTime < now){
                getRewardForAddress(msg.sender);    
            }            
            
            betStruct.value += msg.value;
            betStruct.lastBetTime = now;
            
            betsDatabase[msg.sender] = betStruct;
            
        } else {
            
            uint nextPayAfterTime = startTime+((now.sub(startTime)).div(period)).mul(period)+period;

            betStruct = BetStruct({ 
                value : msg.value,
                firstBetTime : now,
                lastBetTime : now,
                lastPaymentTime : 0,
                nextPayAfterTime: nextPayAfterTime,
                isExist : true,
                id : currBetID,
                referrerID : _referrerID
            });
        
            betsDatabase[msg.sender] = betStruct;
            addressList[currBetID] = msg.sender;
            
            currBetID++;
        }

        if(betStruct.referrerID!=0){
            uint currReferrerPercent;
            uint currReferrerValue = betsDatabase[addressList[_referrerID]].value;
            
            if (currReferrerValue >= referrerLevel3Ether){
                currReferrerPercent = referrerLevel3Percent;
            } else if (currReferrerValue >= referrerLevel2Ether) {
               currReferrerPercent = referrerLevel2Percent; 
            } else {
                currReferrerPercent = referrerLevel1Percent;
            }
            
            addressList[_referrerID].transfer(msg.value.mul(currReferrerPercent).div(10000));
            owner.transfer(msg.value.mul(referrerAndOwnerPercent - currReferrerPercent).div(10000));
        } else {
            owner.transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
        }
        
  }
    
  function () public payable {
        createBet(0);
  } 
  
  
  function getReward() public {
        getRewardForAddress(msg.sender);
  }
  
  function getRewardForAddress(address _address) public {
        //проверяем - существует ли инвестор
        if(!betsDatabase[_address].isExist){
             revert("Address are not an investor");    
        }
        
        //проверяем - настало ли время выплаты 
        if(betsDatabase[_address].nextPayAfterTime >= now){
             revert("The payout time has not yet come");    
        }
        
        
        //BetStruct memory betStruct = betsDatabase[_address];
        
        //считаем - за сколько периодов нужно заплатить 
        uint periodCount = now.sub(betsDatabase[_address].nextPayAfterTime).div(period).add(1);
        uint percent = basicDayPercent;
        
        if(betsDatabase[_address].referrerID>0){
            percent = bonusDayPercent;
        }
        
        uint toPay = periodCount.mul(betsDatabase[_address].value).div(10000).mul(percent);
        
        betsDatabase[_address].lastPaymentTime = now;
        betsDatabase[_address].nextPayAfterTime += periodCount.mul(period); 
        
        _address.transfer(toPay);
        
        emit payEventLog(_address, toPay, periodCount, percent);
  }
  

    
}