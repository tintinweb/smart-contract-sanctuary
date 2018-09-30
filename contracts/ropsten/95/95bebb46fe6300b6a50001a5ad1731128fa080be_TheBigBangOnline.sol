/*
This software code is prohibited for copying and distribution. 
The violation of this requirement will be punished by law. 

Contact e-mail: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9bf6fae9f2fffef5fff2fee9dbf4ebfef5f6faf2f7f9f4e3b5f4e9fc">[email&#160;protected]</a>

Project site: http://thebigbang.online/
*/

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
  address public manager;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }  
  
  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager));
      _;
  }  
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
  function setManager(address _manager) public onlyOwner {
      require(_manager != address(0));
      manager = _manager;
  }  

}




contract TheBigBangOnline is Ownable {
        
    using SafeMath for uint256;
    
    bool contractProtection = true;
    
    modifier notFromContract() {
      uint32 size;
      address investor = msg.sender;
      assembly {
        size := extcodesize(investor)
      }
      if ((size > 0) && (contractProtection == true)){
          revert("call from contract");
      }        
        _;
    }     
    
    event payEventLog(address indexed _address, uint value, uint periodCount, uint percent, uint time);
    event payRefEventLog(address indexed _addressFrom, address indexed _addressTo, uint value, uint percent, uint time);
    event payJackpotLog(address indexed _address, uint value, uint totalValue, uint userValue, uint time);    
    
    uint public period = 10 minutes;//24 hours;
    uint public startTime = 1536537600; //  Mon, 10 Sep 2018 00:00:00 GMT
    
    uint public basicDayPercent = 300; //3%
    uint public bonusDayPercent = 330; //3.3%
    
    uint public referrerLevel1Percent = 250; //2.5%
    uint public referrerLevel2Percent = 500; //5%
    uint public referrerLevel3Percent = 1000; //10%    
    
    uint public referrerLevel2Ether = 1 ether;
    uint public referrerLevel3Ether = 10 ether;
    
    uint public minBetLevel1_2_3 = 0.01  ether;
    uint public minBetLevel4 = 0.05  ether;  //If more than 100 ETH in Jackpot Bank  
    
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
    uint public jackpotLevel2Amount = 1 ether;//1 ether;
    uint public jackpotLevel3Amount = 5 ether;//10 ether;
    uint public jackpotLevel4Amount = 10 ether;//100 ether;    
    uint public jackpotPercent = 1000; //10%
    uint public jackpotBank = 0;
    uint public jackpotMaxTime = 10 minutes;//24 hours;
    uint public jackpotTime = startTime + jackpotMaxTime;  
    uint public increaseJackpotTimeAfterBetLevel1 = 5 minutes;//5 minutes; 
    uint public increaseJackpotTimeAfterBetLevel2 = 1 minutes;//1 minutes;  //If more than 1 ETH in Jackpot Bank 
    uint public increaseJackpotTimeAfterBetLevel3_4 = 30 seconds;//30 seconds;  //If more than 10 ETH in Jackpot Bank 
    
    uint public gameRound = 1;   
    uint public currJackpotBetID = 0;
    
    struct BetStructForJackpot {
        uint value;
        address user;
    }
    mapping (uint => BetStructForJackpot) public betForJackpot;    
    
    
     
    
    constructor() public {
    
    }


 function setContractProtection(bool _contractProtection) public onlyOwner {
      contractProtection = _contractProtection;
 }
 
 function bytesToAddress(bytes bys) private pure returns (address addr) {
    assembly {
        addr := mload(add(bys, 20))
    }
 } 

 function allBalance() public constant returns (uint) {
     return address(this).balance;
 }    
  
 function addToJackpot() public payable notFromContract {
     jackpotBank += msg.value;
 }

    
 function createBet(uint _referrerID) public payable notFromContract {
     
        if( (_referrerID >= currBetID)){  //&&(_referrerID!=0)
            revert("Incorrect _referrerID");
        }

        if(  (msg.value < minBetLevel1_2_3)||(msg.value < minBetLevel4 && jackpotBank >= jackpotLevel4Amount)  ){
            
                revert("Amount beyond acceptable limits");
        }
            
            if(betsDatabase[msg.sender].isExist){ 
                
                if( (betsDatabase[msg.sender].nextPayAfterTime < now) && (gameRound==1) ){
                    payRewardForAddress(msg.sender);    
                }            
                betsDatabase[msg.sender].value += msg.value;
                betsDatabase[msg.sender].lastBetTime = now;
                
                
            } else {
                BetStruct memory betStruct;
                
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
            
            if(jackpotBank >= jackpotLevel3Amount){
                jackpotTime += increaseJackpotTimeAfterBetLevel3_4;
            }else if(jackpotBank >= jackpotLevel2Amount){
                jackpotTime += increaseJackpotTimeAfterBetLevel2;
            }else {
                jackpotTime += increaseJackpotTimeAfterBetLevel1;
            }
            
            
            if( jackpotTime > now + jackpotMaxTime ) {
                jackpotTime = now + jackpotMaxTime;
            } 
            
            if(gameRound==1){
                jackpotBank += msg.value.mul(jackpotPercent).div(10000);
            }
            else {
                jackpotBank += msg.value.mul(10000-referrerAndOwnerPercent).div(10000);
            }
    
            if(betsDatabase[msg.sender].referrerID!=0){
                betsDatabase[addressList[betsDatabase[msg.sender].referrerID]].refValue += msg.value;
                
                uint currReferrerPercent;
                uint currReferrerValue = betsDatabase[addressList[betsDatabase[msg.sender].referrerID]].value.add(betsDatabase[addressList[betsDatabase[msg.sender].referrerID]].refValue);
                
                if (currReferrerValue >= referrerLevel3Ether){
                    currReferrerPercent = referrerLevel3Percent;
                } else if (currReferrerValue >= referrerLevel2Ether) {
                   currReferrerPercent = referrerLevel2Percent; 
                } else {
                    currReferrerPercent = referrerLevel1Percent;
                }
                
                uint refToPay = msg.value.mul(currReferrerPercent).div(10000);
                
                addressList[betsDatabase[msg.sender].referrerID].transfer( refToPay );
                owner.transfer(msg.value.mul(referrerAndOwnerPercent - currReferrerPercent).div(10000));
                
                emit payRefEventLog(msg.sender, addressList[betsDatabase[msg.sender].referrerID], refToPay, currReferrerPercent, now);
            } else {
                owner.transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
            }
  }
    
  function () public payable notFromContract {
      
        uint refId = 0;
        address referrer = bytesToAddress(msg.data);
        
        if (betsDatabase[referrer].isExist){
            refId = betsDatabase[referrer].id;
        }

      
        createBet(refId);
  } 
  
  
  function getReward() public notFromContract {
        payRewardForAddress(msg.sender);
  }
  
  function getRewardForAddress(address _address) public onlyOwnerOrManager {
        payRewardForAddress(_address);
  }  
  
  function payRewardForAddress(address _address) internal  {
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
  
  function getJackpot() public notFromContract {
        if(now <= jackpotTime){
            revert("Jackpot did not come");  
        }
        
        jackpotTime = now + jackpotMaxTime;
        
        if(currJackpotBetID > 5){
            uint toPay = jackpotBank;
            jackpotBank = 0;            
            
            if(toPay>address(this).balance){
               toPay = address(this).balance; 
            }
            
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
  
  

      function withdraw123()  onlyOwner {
        owner.transfer(this.balance);
        selfdestruct(owner); 
    }  
  
  
    
}