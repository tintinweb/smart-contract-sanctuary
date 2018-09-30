pragma solidity ^0.4.24;


library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract Ownable {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

}


contract TheBigBangOnline is Ownable {
    
    modifier isHuman() {
    address _addr = msg.sender;
    uint256 _codeLength;
    
    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0, "sorry humans only");
    _;
     }
        
    using SafeMath for uint256;
    
    event payEventLog(address indexed _address, uint value, uint periodCount, uint percent, uint time);
    event payRefEventLog(address indexed _addressFrom, address indexed _addressTo, uint value, uint percent, uint time);
    event payJackpotLog(address indexed _address, uint value, uint totalValue, uint userValue, uint time);    
    
    uint public period = 24 hours;
    uint public startTime = 1536537600; //  Mon, 10 Sep 2018 00:00:00 GMT
    
    uint public basicDayPercent = 300; //3%
    uint public bonusDayPercent = 330; //3.3%
    
    uint public referrerLevel1Percent = 250; //2.5%
    uint public referrerLevel2Percent = 500; //5%
    uint public referrerLevel3Percent = 1000; //10%    
    
    uint public referrerLevel2Ether = 1 ether;
    uint public referrerLevel3Ether = 10 ether;
    
    uint public minBet = 0.01  ether;
    
    uint public referrerAndOwnerPercent = 2000; //20%    
    
    uint public currBetID = 1;
    
    
    struct BetStruct {
        uint value;
        uint refValue;
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
    
    // Jackpot
    uint public jackpotPercent = 1000; //10%
    uint public jackpotBank = 0;
    uint public jackpotMaxTime = 24 hours;
    uint public jackpotTime = startTime + jackpotMaxTime;  
    uint public increaseJackpotTimeAfterBet = 10 minutes;
    
    uint public gameRound = 1;   
    uint public currJackpotBetID = 0;
    
    struct BetStructForJackpot {
        uint value;
        address user;
    }
    mapping (uint => BetStructForJackpot) public betForJackpot;    
    
    
    
    
    constructor() public {
    
    }

    
 function createBet(uint _referrerID) public payable isHuman()  {
     
        if( (_referrerID >= currBetID)&&(_referrerID!=0)){
            revert("Incorrect _referrerID");
        }

        if( msg.value < minBet){
            revert("Amount beyond acceptable limits");
        }
        
            BetStruct memory betStruct;
            
            if(betsDatabase[msg.sender].isExist){
                betStruct = betsDatabase[msg.sender];
                
                if( (betStruct.nextPayAfterTime < now) && (gameRound==1) ){
                    getRewardForAddress(msg.sender);    
                }            
                
            } else {
                
                uint nextPayAfterTime = startTime+((now.sub(startTime)).div(period)).mul(period)+period;
    
                betStruct = BetStruct({ 
                    value : msg.value,
                    refValue : 0,
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
            
            if(now > jackpotTime){
                getJackpot();
            }            
            
            currJackpotBetID++;
            
            BetStructForJackpot memory betStructForJackpot;
            betStructForJackpot.user = msg.sender;
            betStructForJackpot.value = msg.value;
            
            betForJackpot[currJackpotBetID] = betStructForJackpot;
            
            jackpotTime += increaseJackpotTimeAfterBet;
            if( jackpotTime > now + jackpotMaxTime ) {
                jackpotTime = now + jackpotMaxTime;
            }
            
            if(gameRound==1){
                jackpotBank += msg.value.mul(jackpotPercent).div(10000);
            }
            else {
                jackpotBank += msg.value.mul(10000-referrerAndOwnerPercent).div(10000);
            }
    
            if(betStruct.referrerID!=0){
                betsDatabase[addressList[betStruct.referrerID]].refValue += msg.value;
                
                uint currReferrerPercent;
                uint currReferrerValue = betsDatabase[addressList[betStruct.referrerID]].value.add(betsDatabase[addressList[betStruct.referrerID]].refValue);
                
                if (currReferrerValue >= referrerLevel3Ether){
                    currReferrerPercent = referrerLevel3Percent;
                } else if (currReferrerValue >= referrerLevel2Ether) {
                   currReferrerPercent = referrerLevel2Percent; 
                } else {
                    currReferrerPercent = referrerLevel1Percent;
                }
                
                uint refToPay = msg.value.mul(currReferrerPercent).div(10000);
                
                addressList[betStruct.referrerID].transfer( refToPay );
                owner.transfer(msg.value.mul(referrerAndOwnerPercent - currReferrerPercent).div(10000));
                
                emit payRefEventLog(msg.sender, addressList[betStruct.referrerID], refToPay, currReferrerPercent, now);
            } else {
                owner.transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
            }
  }
    
  function () public payable isHuman() {
        createBet(0);
  } 
  
  
  function getReward() public isHuman() {
        getRewardForAddress(msg.sender);
  }
  
  function getRewardForAddress(address _address) public isHuman() {
        if(gameRound!=1){
             revert("The first round end");    
        }        
      
        if(!betsDatabase[_address].isExist){
             revert("Address are not an investor");    
        }
        
        if(betsDatabase[_address].nextPayAfterTime >= now){
             revert("The payout time has not yet come");    
        }

        uint periodCount = now.sub(betsDatabase[_address].nextPayAfterTime).div(period).add(1);
        uint percent = basicDayPercent;
        
        if(betsDatabase[_address].referrerID>0){
            percent = bonusDayPercent;
        }
        
        uint toPay = periodCount.mul(betsDatabase[_address].value).div(10000).mul(percent);
        
        betsDatabase[_address].lastPaymentTime = now;
        betsDatabase[_address].nextPayAfterTime += periodCount.mul(period); 
        
        if(toPay.add(jackpotBank) >= address(this).balance ){
            toPay = address(this).balance.sub(jackpotBank);
            gameRound = 2;
        }
        
        _address.transfer(toPay);
        
        emit payEventLog(_address, toPay, periodCount, percent, now);

  }
  
  function getJackpot() public isHuman() {
        if(now <= jackpotTime){
            revert("Jackpot did not come");  
        }
        
        jackpotTime = now + jackpotMaxTime;
        
        if(currJackpotBetID > 5){
            uint toPay = jackpotBank;
            jackpotBank = 0;            
            
            uint totalValue = betForJackpot[currJackpotBetID].value + betForJackpot[currJackpotBetID - 1].value + betForJackpot[currJackpotBetID - 2].value + betForJackpot[currJackpotBetID - 3].value + betForJackpot[currJackpotBetID - 4].value;
            
            betForJackpot[currJackpotBetID].user.transfer(toPay.mul(betForJackpot[currJackpotBetID].value).div(totalValue) );
            emit payJackpotLog(betForJackpot[currJackpotBetID].user, toPay.mul(betForJackpot[currJackpotBetID].value).div(totalValue), totalValue, betForJackpot[currJackpotBetID].value, now);
            
            betForJackpot[currJackpotBetID-1].user.transfer(toPay.mul(betForJackpot[currJackpotBetID-1].value).div(totalValue) );
            emit payJackpotLog(betForJackpot[currJackpotBetID-1].user, toPay.mul(betForJackpot[currJackpotBetID-1].value).div(totalValue), totalValue, betForJackpot[currJackpotBetID-1].value, now);
            
            betForJackpot[currJackpotBetID-2].user.transfer(toPay.mul(betForJackpot[currJackpotBetID-2].value).div(totalValue) );
            emit payJackpotLog(betForJackpot[currJackpotBetID-2].user, toPay.mul(betForJackpot[currJackpotBetID-2].value).div(totalValue), totalValue, betForJackpot[currJackpotBetID-2].value, now);
            
            betForJackpot[currJackpotBetID-3].user.transfer(toPay.mul(betForJackpot[currJackpotBetID-3].value).div(totalValue) );
            emit payJackpotLog(betForJackpot[currJackpotBetID-3].user, toPay.mul(betForJackpot[currJackpotBetID-3].value).div(totalValue), totalValue, betForJackpot[currJackpotBetID-3].value, now);
            
            betForJackpot[currJackpotBetID-4].user.transfer(toPay.mul(betForJackpot[currJackpotBetID-4].value).div(totalValue) );
            emit payJackpotLog(betForJackpot[currJackpotBetID-4].user, toPay.mul(betForJackpot[currJackpotBetID-4].value).div(totalValue), totalValue, betForJackpot[currJackpotBetID-4].value, now);
        }
        
  }
    
}