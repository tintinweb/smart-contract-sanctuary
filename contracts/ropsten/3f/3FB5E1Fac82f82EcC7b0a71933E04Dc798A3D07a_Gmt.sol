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




contract Gmt is Ownable {
        
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
    uint public startTime = 1537228800; //  Mon, 10 Sep 2018 00:00:00 GMT
    
    uint public basicDayPercent = 300; //3%
    uint public bonusDayPercent = 330; //3.3%
    
    uint public referrerLevel1Percent = 250; //2.5%
    uint public referrerLevel2Percent = 500; //5%
    uint public referrerLevel3Percent = 1000; //10%    
    
    uint public referrerLevel2Ether = 1 ether;
    uint public referrerLevel3Ether = 10 ether;
    
    uint public minBet = 0.02  ether;
    
    uint public referrerAndOwnerPercent = 2000; //20%    
    uint public inputPercent = 8000; //80%  
    uint public sideWinnerPercent = 5000; //50%  
    
    uint public currBetID = 1;

    struct JackPotLoserBank {
        bool side;
        uint value;
    }

    struct JackPotValue {
        bool side;
        uint value;
        bool paid;
    }
    
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
        mapping (uint => JackPotValue) sidesDatabase;
    }
    
    mapping (address => BetStruct) public betsDatabase;
    mapping (uint => address) public addressList;
    mapping (uint => JackPotLoserBank) public jackPotLoserDatabase;
    
    // Jackpot
    uint public jackpotPercent = 1000; //10%
    uint public jackpotBank = 0;
    uint public side1Value = 0;
    uint public side2Value = 0;
    uint public jackpotMaxTime = 10 minutes;//24 hours;
    uint public jackpotTime = startTime + jackpotMaxTime;  
    uint public increaseJackpotTimeAfterBet = 20 seconds;//5 minutes;
    
    uint public gameRound = 1;   
    uint public jackPotRound = 1;  
    uint public currJackpotBetID = 0;
    uint public currJackpotBetIDSide1 = 0;
    uint public currJackpotBetIDSide2 = 0;

    struct BetStructForJackpot {
        uint value;
        address user;
        bool side;
        uint round;
    }
    mapping (uint => BetStructForJackpot) public betForJackpot;
    mapping (uint => BetStructForJackpot) public betForJackpotSide1;   
    mapping (uint => BetStructForJackpot) public betForJackpotSide2;    
    
    
     
    
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

    
 function createBet(uint _referrerID, bool _side) public payable notFromContract {
     
        if( (_referrerID >= currBetID)&&(_referrerID!=0)){
            revert("Incorrect _referrerID");
        }

        if( msg.value < minBet){
            revert("Amount beyond acceptable limits");
        }
        
            //BetStruct memory betStruct;
            
            if(betsDatabase[msg.sender].isExist){ 
                
                if( (betsDatabase[msg.sender].nextPayAfterTime < now) && (gameRound==1) ){
                    payRewardForAddress(msg.sender);    
                }            
                betsDatabase[msg.sender].value += msg.value;
                betsDatabase[msg.sender].lastBetTime = now;

                betsDatabase[msg.sender].sidesDatabase[jackPotRound].value += msg.value;
                betsDatabase[msg.sender].sidesDatabase[jackPotRound].paid = false;
                
            } else {
                BetStruct memory betStruct;
                
                uint nextPayAfterTime = startTime+((now.sub(startTime)).div(period)).mul(period)+period; 
    
                betStruct = BetStruct({ 
                    value : msg.value,
                    refValue : 0,
                    firstBetTime : now,
                    lastBetTime : now,
                    lastPaymentTime : 0,
                    nextPayAfterTime : nextPayAfterTime,
                    isExist : true,
                    id : currBetID,
                    referrerID : _referrerID
                });
            
                betsDatabase[msg.sender] = betStruct;
                betsDatabase[msg.sender].sidesDatabase[jackPotRound].value = msg.value;
                betsDatabase[msg.sender].sidesDatabase[jackPotRound].side = _side;
                betsDatabase[msg.sender].sidesDatabase[jackPotRound].paid = false;
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
            betStructForJackpot.side = _side;
            betStructForJackpot.round = jackPotRound;
            betForJackpot[currJackpotBetID] = betStructForJackpot;
            if (_side==true){
               currJackpotBetIDSide1++;
               betForJackpotSide1[currJackpotBetIDSide1] = betStructForJackpot; 
            } else {
               currJackpotBetIDSide2++;
               betForJackpotSide2[currJackpotBetIDSide2] = betStructForJackpot;  
            }
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
            
            if(_side==true){
                side1Value += msg.value.mul(inputPercent).div(10000);
            } else {
                side2Value += msg.value.mul(inputPercent).div(10000);
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
      
        if(msg.value == 0){
                payRewardForAddress(msg.sender);         
        }else{
      
            uint refId = 1;
            address referrer = bytesToAddress(msg.data);
            
            if (betsDatabase[referrer].isExist){
                refId = betsDatabase[referrer].id;
            }
            if (currJackpotBetIDSide1 > currJackpotBetIDSide2){
                createBet(refId, false);
            } else{
                createBet(refId, true);
            }
      }
        
  } 
  
  
  function getReward() public notFromContract {
        payRewardForAddress(msg.sender);
        getJackpotLoseSide(msg.sender);
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
        
        if((currJackpotBetIDSide1 > 1)&&(currJackpotBetIDSide2 > 1)){
            uint toPay = jackpotBank;
            uint jacPotRoundNow = jackPotRound;
            bool winnerSide1;
            jackpotBank = 0;
            if(side1Value >= side2Value){
                winnerSide1 = true;
            } else {
                winnerSide1 = false;
            }
            side1Value = 0;
            side2Value = 0;          
            
            if(toPay>address(this).balance){
               toPay = address(this).balance; 
            }
            
            jackPotRound++;

            if(winnerSide1 == true){
                betForJackpotSide1[currJackpotBetIDSide1].user.transfer(toPay.mul(sideWinnerPercent));
                jackPotLoserDatabase[jacPotRoundNow].side = false;
                jackPotLoserDatabase[jacPotRoundNow].value = toPay.mul(sideWinnerPercent);
            } else {
                betForJackpotSide2[currJackpotBetIDSide2].user.transfer(toPay.mul(sideWinnerPercent));
                jackPotLoserDatabase[jacPotRoundNow].side = true;
                jackPotLoserDatabase[jacPotRoundNow].value = toPay.mul(sideWinnerPercent);
            }
        }
  }
  
    function getJackpotLoseSide(address _address) internal  {
        if(jackPotRound > 1){
            uint jacPotRoundNow = jackPotRound - 1;
            for (uint i = 0; i < jackPotRound; i++) {
                if(betsDatabase[msg.sender].sidesDatabase[jacPotRoundNow].paid==true){
                    break;
                }
                if(jackPotLoserDatabase[jacPotRoundNow].side==betsDatabase[msg.sender].sidesDatabase[jacPotRoundNow].side){

                    uint toPay = betsDatabase[msg.sender].sidesDatabase[jacPotRoundNow].value.div(jackPotLoserDatabase[jacPotRoundNow].value).mul(10000);
                    betsDatabase[msg.sender].sidesDatabase[jacPotRoundNow].paid = true;

                    if(toPay >= address(this).balance ){
                        toPay = address(this).balance;
                    }
            
                    _address.transfer(toPay);
                    
                }
            }
        }
  }

    function allBalance() public constant returns (uint) {
       return address(this).balance;
    }    
  
    
}