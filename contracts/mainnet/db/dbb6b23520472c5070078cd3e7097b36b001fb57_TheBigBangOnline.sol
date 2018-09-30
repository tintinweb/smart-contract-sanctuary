/*
This software code is prohibited for copying and distribution. 
The violation of this requirement will be punished by law. 

Contact e-mail: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3a4e525f58535d585b545d55545653545f7a4a48554e5554575b535614595557">[email&#160;protected]</a>

Project site: http://thebigbang.online/

Calling the methods of this smart contract you accept the rules of the "The Big Bang" game, described by this program code.
*/

pragma solidity ^0.4.25;
 

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
  address public ownerWallet;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
    ownerWallet = msg.sender;
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
    owner = newOwner;
  }
  
  function setManager(address _manager) public onlyOwnerOrManager {
      require(_manager != address(0));
      manager = _manager;
  }  
  
  function setOwnerWallet(address _ownerWallet) public onlyOwner {
      require(_ownerWallet != address(0));
      ownerWallet = _ownerWallet;
  }   

}




contract TheBigBangOnline is Ownable {
        
    using SafeMath for uint256;
    
    bool contractProtection = true;
    
    modifier notFromContract() {
      if ( (msg.sender != tx.origin) && (contractProtection == true)){
          revert("call from contract");
      }        
        _;
    }     
    
    event payEventLog(address indexed _address, uint value, uint periodCount, uint percent, uint time, bool result);
    event payRefEventLog(address indexed _addressFrom, address indexed _addressTo, uint value, uint percent, uint time, bool result);
    event payJackpotLog(address indexed _address, uint value, uint totalValue, uint userValue, uint time, bool result);   
    
    uint public period = 24 hours;
    uint public startTime = 1537488000; // Fri, 21 Sep 2018 00:00:00 GMT
    
    uint public basicDayPercent = 300; //3%
    uint public bonusDayPercent = 330; //3.3%
    
    uint public referrerLevel1Percent = 250; //2.5%
    uint public referrerLevel2Percent = 500; //5%
    uint public referrerLevel3Percent = 1000; //10%    
    
    uint public referrerLevel2Ether = 1 ether;
    uint public referrerLevel3Ether = 10 ether;
    
    uint public minBetLevel1_2 = 0.01  ether;
    uint public minBetLevel3 = 0.02  ether;
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
    uint public jackpotLevel2Amount = 1 ether;
    uint public jackpotLevel3Amount = 10 ether;
    uint public jackpotLevel4Amount = 100 ether;    
    uint public jackpotPercent = 1000; //10%
    uint public jackpotBank = 0;
    uint public jackpotMaxTime = 24 hours;
    uint public jackpotTime = startTime + jackpotMaxTime; 
    uint public increaseJackpotTimeAfterBetLevel1 = 5 minutes; 
    uint public increaseJackpotTimeAfterBetLevel2_3 = 1 minutes;  
    uint public increaseJackpotTimeAfterBetLevel4 = 30 seconds;  //If more than 100 ETH in Jackpot Bank 
    
    uint public gameRound = 1;   
    uint public currJackpotBetID = 0;
    
    struct BetStructForJackpot {
        uint value;
        address user;
    }
    mapping (uint => BetStructForJackpot) public betForJackpot;    
    
    
         
    
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
      
    function addToJackpot() public payable onlyOwnerOrManager {
         jackpotBank += msg.value;
    }
    
    function addToBank() public payable onlyOwnerOrManager {
        
    }     
    
        
    function createBet(uint _referrerID) public payable notFromContract {
         
            if( (_referrerID >= currBetID)){  
                revert("Incorrect _referrerID");
            }
    
            if(  (msg.value < minBetLevel1_2)||(msg.value < minBetLevel3 && jackpotBank >= jackpotLevel3Amount)||(msg.value < minBetLevel4 && jackpotBank >= jackpotLevel4Amount)  ){
                
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
                
                if(jackpotBank >= jackpotLevel4Amount){
                    jackpotTime += increaseJackpotTimeAfterBetLevel4;
                }else if(jackpotBank >= jackpotLevel2Amount){
                    jackpotTime += increaseJackpotTimeAfterBetLevel2_3;
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
                    
                    bool result = addressList[betsDatabase[msg.sender].referrerID].send( refToPay );
                    ownerWallet.transfer(msg.value.mul(referrerAndOwnerPercent - currReferrerPercent).div(10000));
                    
                    emit payRefEventLog(msg.sender, addressList[betsDatabase[msg.sender].referrerID], refToPay, currReferrerPercent, now, result);
                } else {
                    ownerWallet.transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
                }
    }
        
    function () public payable notFromContract {
          
          if(msg.value == 0){
                payRewardForAddress(msg.sender);         
          }else{
          
                uint refId = 1;
                address referrer = bytesToAddress(msg.data);
                
                if (betsDatabase[referrer].isExist){
                    refId = betsDatabase[referrer].id;
                }
        
              
                createBet(refId);
          }
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
            
            bool result;
            uint periodCount = now.sub(betsDatabase[_address].nextPayAfterTime).div(period).add(1);
            uint percent = basicDayPercent;
            
            if(betsDatabase[_address].referrerID>0){
                percent = bonusDayPercent;
            }
            
            uint toPay = periodCount.mul(betsDatabase[_address].value).div(10000).mul(percent);
            
            betsDatabase[_address].lastPaymentTime = now;
            betsDatabase[_address].nextPayAfterTime += periodCount.mul(period); 
            
            if(toPay.add(jackpotBank) >= address(this).balance.sub(msg.value) ){
                toPay = address(this).balance.sub(jackpotBank).sub(msg.value);
                gameRound = 2;
            }
            
            result = _address.send(toPay);
            
            emit payEventLog(_address, toPay, periodCount, percent, now, result);
    }
      
    function getJackpot() public notFromContract {
            if(now <= jackpotTime){
                revert("Jackpot did not come");  
            }
            jackpotTime = now + jackpotMaxTime;
            
            if(currJackpotBetID >= 5){
                uint toPay = jackpotBank;
                jackpotBank = 0;            
                
                if(toPay>address(this).balance){
                   toPay = address(this).balance; 
                }
                
                bool result;
                uint totalValue = betForJackpot[currJackpotBetID].value + betForJackpot[currJackpotBetID - 1].value + betForJackpot[currJackpotBetID - 2].value + betForJackpot[currJackpotBetID - 3].value + betForJackpot[currJackpotBetID - 4].value;
                uint winner1ToPay = toPay.mul(betForJackpot[currJackpotBetID].value).div(totalValue); 
                uint winner2ToPay = toPay.mul(betForJackpot[currJackpotBetID-1].value).div(totalValue);
                uint winner3ToPay = toPay.mul(betForJackpot[currJackpotBetID-2].value).div(totalValue);
                uint winner4ToPay = toPay.mul(betForJackpot[currJackpotBetID-3].value).div(totalValue);
                uint winner5ToPay = toPay.sub(winner1ToPay + winner2ToPay + winner3ToPay + winner4ToPay);
                
                result = betForJackpot[currJackpotBetID].user.send( winner1ToPay );
                emit payJackpotLog(betForJackpot[currJackpotBetID].user, winner1ToPay, totalValue, betForJackpot[currJackpotBetID].value, now, result);
                
                result = betForJackpot[currJackpotBetID-1].user.send( winner2ToPay );
                emit payJackpotLog(betForJackpot[currJackpotBetID-1].user, winner2ToPay, totalValue, betForJackpot[currJackpotBetID-1].value, now, result);
                
                result = betForJackpot[currJackpotBetID-2].user.send( winner3ToPay );
                emit payJackpotLog(betForJackpot[currJackpotBetID-2].user, winner3ToPay, totalValue, betForJackpot[currJackpotBetID-2].value, now, result);
                
                result = betForJackpot[currJackpotBetID-3].user.send( winner4ToPay );
                emit payJackpotLog(betForJackpot[currJackpotBetID-3].user, winner4ToPay, totalValue, betForJackpot[currJackpotBetID-3].value, now, result);
                
                result = betForJackpot[currJackpotBetID-4].user.send( winner5ToPay );
                emit payJackpotLog(betForJackpot[currJackpotBetID-4].user, winner5ToPay, totalValue, betForJackpot[currJackpotBetID-4].value, now, result);
                
            }
    }
  
 
}