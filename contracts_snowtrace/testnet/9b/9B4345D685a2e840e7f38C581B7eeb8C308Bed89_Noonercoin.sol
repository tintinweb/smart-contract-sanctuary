/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-17
*/

pragma solidity ^0.5.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20  {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }
}

contract Noonercoin is ERC20{
   using SafeMath for uint256;
   uint256 startTime;
   uint256 mintingRateNoonerCoin;
   uint256 mintingRateNoonerWei;
   uint256 lastMintingTime;
   address adminAddress;
   bool isNewCycleStart = false;
   uint8[] __randomVariable = [150, 175, 200, 225, 250];
   uint8[] __remainingRandomVariable = [150, 175, 200, 225, 250];
   uint8[] tempRemainingRandomVariable;
   mapping (uint256 => uint256) occurenceOfRandomNumber;
   uint256 weekStartTime = now; 
   mapping (address => uint256)  noonercoin;
   mapping (address => uint256)  noonerwei;
   uint256 totalWeiBurned = 0;
   uint256 public totalCycleLeft = 19;  
   uint256 private _totalSupply;
   string private _name;
   string private _symbol;
   uint256 private _decimal;
   uint256 private _frequency;
   uint256 private _cycleTime = 86400; //given one day sec
   uint256 private _fundersAmount;
   uint256 _randomValue;
   uint256 randomNumber;
   int private count = 0; 
   uint256 previousCyclesTotalTokens = 0;
   uint256 previousCyclesTotalWei = 0;
   uint256 indexs = 1;
   uint256[] randomVariableArray;
   uint256[] previousCyclesBalance;
   uint256[] previousCyclesWeiBalance;
   uint256 public weiAmountAdded = 0;
   uint256 public weiAmountAddedAtBurn = 0;
   uint256 signmaValueWei = 0;
   uint256 currentMintingRateTotalTokens = 0;
   uint256 totalMintedTokens = 0;
   uint256 weiToBurned = 0;
   uint256 totalWeiInAdminAcc = 0;
   uint256[] previousSigmaValues;
   uint256[] previousBurnValues;
   bool stopTheMinting =  false;

   constructor(uint256 totalSupply_, string memory tokenName_, string memory tokenSymbol_,uint256 decimal_, uint256 mintingRateNoonerCoin_, uint256 frequency_, uint256 fundersAmount_) public ERC20("XDC","XDC"){
       _totalSupply = totalSupply_;
       _name = tokenName_;
       _symbol = tokenSymbol_;
       _decimal = decimal_;
       mintingRateNoonerCoin = mintingRateNoonerCoin_;
       _frequency = frequency_;
       adminAddress = msg.sender;
       _fundersAmount = fundersAmount_;       
       mintingRateNoonerWei = 0;
       startTime = now;
       noonercoin[adminAddress] = _fundersAmount;
   }

    function incrementCounter() public {
        count += 1;
    }
    
    function _transfer(address recipient, uint256 amount) public {
        address sender = msg.sender;
        uint256 senderBalance = noonercoin[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        noonercoin[sender] = senderBalance - amount;
        noonercoin[recipient] += amount;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return noonercoin[account];
    }

    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function decimals() public view  returns (uint256) {
        return _decimal;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

   function getStartTime() public view returns(uint256){
       return startTime;
   }
    
   function mintToken(address add, uint256 currentTime) public returns (bool) {  //admin only
       require(msg.sender == adminAddress, "Only owner can do this");
      //burn the tokens before minting 
      if(isNewCycleStart) {
          uint256 randomValue = _randomValue;
          if(randomValue == 150){
              isNewCycleStart = false;
              noonerwei[add] = 0;
              for(indexs=1;indexs<=1;indexs++) {
                  previousCyclesTotalTokens = noonercoin[add];
                  previousCyclesTotalWei = noonerwei[add];
                  previousCyclesBalance.push(previousCyclesTotalTokens);
                  previousSigmaValues.push(0);
                  previousBurnValues.push(0); 
              }
          }
          else {
              if(randomValue==175 && totalCycleLeft == 18) {
                  isNewCycleStart = false;
                  noonerwei[add] = 0;
                  for(indexs=1;indexs<=1;indexs++) {
                      previousCyclesTotalTokens = noonercoin[add];
                      previousCyclesTotalWei = noonerwei[add];
                      previousCyclesBalance.push(previousCyclesTotalTokens);
                      previousSigmaValues.push(0); 
                      previousBurnValues.push(0); 
                  }
               }
              else {
                  burnToken();
                  isNewCycleStart = false;
              }
           } 
      } 
       
       if(stopTheMinting) {
           return false;
       } 
       else {
           uint256 weiAfterMint = noonerwei[add] + mintingRateNoonerWei;
           uint256 noonerCoinExtractedFromWei = 0;

            //logic to add wei in noonercoin, if wei value is greater than or equal to 10**18
            if(weiAfterMint >= 10**18){
                weiAfterMint = weiAfterMint - 10**18;
                noonerCoinExtractedFromWei = 1;
            }
            //condition to call a popRandomVariable
            uint256 nowTime = now;
            uint256 totalOccurences = getTotalPresentOcuurences();
            if(totalOccurences != 120) {
                if(nowTime-weekStartTime >= 720){
                    popRandomVariable();
                    weekStartTime=now;
                }
            }
            
            //adding the minting tokens into the admin account
            noonercoin[add] = noonercoin[add] + mintingRateNoonerCoin + noonerCoinExtractedFromWei;
            noonerwei[add] = weiAfterMint;
            lastMintingTime = currentTime;
            
            //changing the mintingrate with above condition
            uint256 timeDiff = lastMintingTime - startTime; 
            if(timeDiff >= _cycleTime){      
                //wei amount of >.5 to be added in adminAccount
                if(noonerwei[add] >= (10**18/2)) {
                    noonercoin[add] += 1;
                    weiAmountAdded += 1;
                }

                if(totalCycleLeft == 0) {
                    stopTheMinting = true;
                }
                else {
                    totalCycleLeft = totalCycleLeft - 1;
                    _randomValue = randomVariablePicker();
                    randomVariableArray.push(_randomValue);
                    isNewCycleStart = true;
                
                    //fetch random number from outside
                    uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei; 
                    mintingRateNoonerCoin =  getIntegerValue(flag, _randomValue, 1);
                    mintingRateNoonerWei  =  getDecimalValue(flag, _randomValue, 1);
                    startTime = startTime + _cycleTime;
            
                    //reset random variable logic, occurenceOfRandomNumber for each cycle 
                    __remainingRandomVariable = __randomVariable;
                    delete tempRemainingRandomVariable;
                    delete occurenceOfRandomNumber[__randomVariable[0]];
                    delete occurenceOfRandomNumber[__randomVariable[1]];
                    delete occurenceOfRandomNumber[__randomVariable[2]];
                    delete occurenceOfRandomNumber[__randomVariable[3]];
                    delete occurenceOfRandomNumber[__randomVariable[4]];
                    count = 0;
                    lastMintingTime = 0;
                    weekStartTime = now;
                    randomNumber = 0;
                    indexs = 1;
                }
            }
            //2nd check for popRandomVaribale
            uint256 totalPicks = occurenceOfRandomNumber[__randomVariable[0]] + occurenceOfRandomNumber[__randomVariable[1]] + occurenceOfRandomNumber[__randomVariable[2]] + occurenceOfRandomNumber[__randomVariable[3]] + occurenceOfRandomNumber[__randomVariable[4]];
            uint256 diff = 0;
            uint256 estimatePicks = 0;
            uint256 picks = 0;
            if(totalPicks != 120 && lastMintingTime != 0) {
                diff = lastMintingTime - startTime;
                if(diff > _frequency) {
                    estimatePicks = (diff-_frequency)/720;
                    if(totalPicks >= estimatePicks){
                        picks = 0;
                    }
                    else {
                        picks = estimatePicks - totalPicks;
                        for(uint256 i = 0; i < picks; i++){
                            popRandomVariable();
                        }
                    }
                } 
            }    
            return true; 
       }  
    }
    
    function popRandomVariable() public  returns(bool){
        randomNumber = randomVariablePicker();
        if(occurenceOfRandomNumber[randomNumber]>=24){
            //remove variable
            uint256 _index;
            for(uint256 index=0;index<=__remainingRandomVariable.length;index++){
                if(__remainingRandomVariable[index]==randomNumber){
                    _index = index;
                    break;
                }
            }
            delete __remainingRandomVariable[_index];
            __remainingRandomVariable[_index] = __remainingRandomVariable[__remainingRandomVariable.length-1];
            if(__remainingRandomVariable.length > 0) {
                 __remainingRandomVariable.length--;
            }
        }

        if(occurenceOfRandomNumber[randomNumber]<24){
            occurenceOfRandomNumber[randomNumber] = occurenceOfRandomNumber[randomNumber]+1;
        }

        //2nd time calling randomNumber from randomVariablePicker
        randomNumber = randomVariablePicker();  

        //2nd time occurenceOfRandomNumber >= 24   
        if(occurenceOfRandomNumber[randomNumber] >= 24) {
            if(count < 4) {
                incrementCounter();
                uint256 _index;
                //remove variable
                for(uint256 index=0;index<=__remainingRandomVariable.length;index++){
                    if(__remainingRandomVariable[index]==randomNumber){
                        _index = index;
                        break;
                    }
                }
                delete __remainingRandomVariable[_index];
                __remainingRandomVariable[_index] = __remainingRandomVariable[__remainingRandomVariable.length-1];
                if(__remainingRandomVariable.length > 0) {
                    __remainingRandomVariable.length--;
                }
            }
        }     
        return true;
    }
    
    function burnToken() internal returns(bool){
        uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei;
        uint256 signmaValueCoin = 0;
        signmaValueWei = 0;
        for(uint256 index=1;index<=totalCycleLeft;index++){
            uint256 intValue = getIntegerValue(flag*720, 150**index, index);//720
            uint256 intDecimalValue = getDecimalValue(flag*720, 150**index, index);//720
            signmaValueCoin = signmaValueCoin + intValue;
            signmaValueWei = signmaValueWei + intDecimalValue;
        }
        signmaValueWei = signmaValueWei + signmaValueCoin * 10**18;
        uint256 adminBalance = noonercoin[adminAddress];      
        uint256 iterationsInOneCycle = _cycleTime/_frequency;//720
        currentMintingRateTotalTokens = iterationsInOneCycle * mintingRateNoonerCoin * 10**18 + iterationsInOneCycle*mintingRateNoonerWei;
        totalMintedTokens =  (adminBalance-_fundersAmount - weiAmountAdded)*10**18 + noonerwei[adminAddress] + totalWeiBurned; //before adding totalWeiBurned.
        weiToBurned = _totalSupply*10**18 - signmaValueWei - totalMintedTokens - currentMintingRateTotalTokens - totalWeiBurned;
        totalWeiInAdminAcc = (adminBalance-_fundersAmount - weiAmountAdded) * 10**18 + noonerwei[adminAddress];

        if(totalWeiInAdminAcc <= weiToBurned) {            
            return false;
        }
        uint256 remainingWei;
        if(totalWeiInAdminAcc > weiToBurned) {
            remainingWei = totalWeiInAdminAcc - weiToBurned;
            noonercoin[adminAddress] =  _fundersAmount + weiAmountAdded + (remainingWei/10**18);
            uint256 weiAddedInAdminAccount  = remainingWei -  (noonercoin[adminAddress] - _fundersAmount - weiAmountAdded) * 10**18;
            
            //add +1 token to adminAccount when remain wei is >.5
            if(weiAddedInAdminAccount >= (10**18/2)) {
                noonercoin[adminAddress] += 1;
                weiToBurned = (weiToBurned/10**18)* 10**18;
                weiAmountAddedAtBurn += 1;
            }

            noonerwei[adminAddress] = 0;
            totalWeiBurned = totalWeiBurned + weiToBurned;
            for(indexs=1;indexs<=1;indexs++) {
                previousCyclesTotalTokens = noonercoin[adminAddress];
                previousCyclesTotalWei = remainingWei -  (noonercoin[adminAddress] - _fundersAmount - weiAmountAdded - weiAmountAddedAtBurn) * 10**18;
                previousCyclesBalance.push(previousCyclesTotalTokens);
                previousSigmaValues.push(signmaValueWei);
                previousBurnValues.push(weiToBurned); 
            }
            return true;
        }
    }
    
    function getUserBalance(address add) public view returns (uint256){
        return noonercoin[add];
    }
    
    function getAfterDecimalValue(address add) public view returns (uint256){
        return noonerwei[add];
    }
      
    function getIntegerValue(uint256 a, uint256 b, uint256 expoHundred) internal pure returns (uint256 q){
       //b is already multiplied by 100
       q = a*100**expoHundred/b;
       q=q/10**18;
       return q;
    }

    function getDecimalValue(uint256 a, uint256 b, uint256 expoHundred) internal pure returns (uint256 p){
       //b is already multiplied by 100
       uint256 q = a*100**expoHundred/b;
       q=q/10**18;
       uint256 r = (a*100**expoHundred) - (b*10**18) * q;
       p = r/b;
       return p;
    }

    function randomVariablePicker() internal view returns (uint256) {
        uint256 getRandomNumber = __remainingRandomVariable[
        uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender))) % __remainingRandomVariable.length];
        return getRandomNumber;
    }
  
  //for error handing in scheduler
  function mintTokenAsPerCurrentRate(address add, uint256 missedToken, uint256 missedWei) public returns (bool) {  
       require(msg.sender == adminAddress, "Only owner can do this");
       if(isNewCycleStart){
           uint256 randomValue = _randomValue;
           if(randomValue == 150){
               isNewCycleStart = false;
               noonerwei[add] = 0;
               for(indexs=1;indexs<=1;indexs++) {
                   previousCyclesTotalTokens = noonercoin[add];
                   previousCyclesTotalWei = noonerwei[add];
                   previousCyclesBalance.push(previousCyclesTotalTokens);
                   previousSigmaValues.push(0);
                   previousBurnValues.push(0);           
               }
           }
           if(randomValue != 150){
               if(randomValue==175 && totalCycleLeft == 18) {
                   isNewCycleStart = false;
                   noonerwei[add] = 0;
                   for(indexs=1;indexs<=1;indexs++) {
                       previousCyclesTotalTokens = noonercoin[add];
                       previousCyclesTotalWei = noonerwei[add];
                       previousCyclesBalance.push(previousCyclesTotalTokens);
                       previousBurnValues.push(0);
                       previousSigmaValues.push(0);
                    }
                }
                else {
                    burnToken();
                    isNewCycleStart = false;
                }
            } 
        }  
        if(stopTheMinting) {
            return false;
        }
        else {
            uint256 weiAfterMint = missedWei;
            noonercoin[add] = noonercoin[add] + missedToken;
            noonerwei[add] = weiAfterMint;
            return true;
        }
  }
  
  function changeConfigVariable() public returns (bool){
      require(msg.sender == adminAddress, "Only owner can do this");
       //wei amount of >.5 to be added in adminAccount
      if(noonerwei[adminAddress] >= (10**18/2)) {
            noonercoin[adminAddress] += 1;
            weiAmountAdded += 1;
       } 

      if(stopTheMinting) {
          return false;
      }
      else {
        _randomValue = randomVariablePicker();
        randomVariableArray.push(_randomValue);
        isNewCycleStart = true;
        totalCycleLeft = totalCycleLeft - 1;
        uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei; 
        mintingRateNoonerCoin =  getIntegerValue(flag, _randomValue, 1);
        mintingRateNoonerWei  =  getDecimalValue(flag, _randomValue, 1);
        startTime = startTime + _cycleTime;
        
        //reset random variable logic, occurenceOfRandomNumber for each cycle 
        __remainingRandomVariable = __randomVariable;
        delete tempRemainingRandomVariable;
        delete occurenceOfRandomNumber[__randomVariable[0]];
        delete occurenceOfRandomNumber[__randomVariable[1]];
        delete occurenceOfRandomNumber[__randomVariable[2]];
        delete occurenceOfRandomNumber[__randomVariable[3]];
        delete occurenceOfRandomNumber[__randomVariable[4]];
        count = 0;
        lastMintingTime = 0;
        weekStartTime = now;
        randomNumber = 0;
        indexs = 1;    
        return true;
    }
  }
  
  function getLastMintingTime() public view returns (uint256){
    //   require(msg.sender != adminAddress);
      return lastMintingTime;
  }
  
  function getLastMintingRate() public view returns (uint256){
      return mintingRateNoonerCoin;
  }

  function getLastMintingTimeAndStartTimeDifference() public view returns (uint256) {
      uint256 lastMintingTimeAndStartTimeDifference = 0; 
      if(lastMintingTime != 0) {
          lastMintingTimeAndStartTimeDifference = lastMintingTime - startTime;
      }   
      return lastMintingTimeAndStartTimeDifference;
  }
  
    function checkMissingTokens(address add) public view returns (uint256, uint256, uint256, uint256) {
      uint256 adminBalance = 0;//noonercoin[add]; //admin bal 
      uint256 adminBalanceinWei = 0;//noonerwei[add]; //admin bal wei
     
      if (lastMintingTime == 0) {
          return (0,0, 0, totalCycleLeft);
      }
      if (lastMintingTime != 0) {
        uint256  estimatedMintedToken = 0;
        uint256 estimatedMintedTokenWei = 0;
        uint256 timeDifference = lastMintingTime - startTime;
        uint256 valueForEach = timeDifference.div(_frequency); 
        if(totalCycleLeft != 19) {
            adminBalance = noonercoin[add] - weiAmountAdded - weiAmountAddedAtBurn; //admin bal 
            adminBalanceinWei = noonerwei[add]; //admin bal wei
            estimatedMintedToken = (previousCyclesTotalTokens - weiAmountAdded - weiAmountAddedAtBurn) + valueForEach * mintingRateNoonerCoin;
            estimatedMintedTokenWei = valueForEach *  mintingRateNoonerWei;
        }
        if(totalCycleLeft == 19) {
            adminBalance = noonercoin[add]; //admin bal 
            adminBalanceinWei = noonerwei[add]; //admin bal wei  
            estimatedMintedToken = _fundersAmount + valueForEach * mintingRateNoonerCoin;  
        }
        uint256 temp = estimatedMintedTokenWei / 10**18;
        estimatedMintedToken += temp;
        uint256 weiVariance = estimatedMintedTokenWei - (temp * 10**18);      
        uint256 checkDifference = 0;
        if(estimatedMintedToken != adminBalance) {
            if(adminBalance >= estimatedMintedToken) {
                checkDifference = 0;
            } else {
                checkDifference = estimatedMintedToken - adminBalance;
            }
        }
        if(weiVariance == adminBalanceinWei) {
            weiVariance = 0;
        }
        return (checkDifference, weiVariance, weekStartTime, totalCycleLeft); 
       }
    }

    function currentDenominatorAndRemainingRandomVariables() public view returns(uint256, uint8[] memory) {
      return (_randomValue, __remainingRandomVariable);
    } 

    function getOccurenceOfRandomNumber() public view returns(uint256, uint256, uint256, uint256, uint256, uint256){
      return (randomNumber, occurenceOfRandomNumber[__randomVariable[0]],occurenceOfRandomNumber[__randomVariable[1]],occurenceOfRandomNumber[__randomVariable[2]],occurenceOfRandomNumber[__randomVariable[3]], occurenceOfRandomNumber[__randomVariable[4]]);
    }

    function getOccurenceOfPreferredRandomNumber(uint256 number) public view returns(uint256){
      return occurenceOfRandomNumber[number];
    }

    function getTotalPresentOcuurences() public view returns(uint256){
      uint256 total = occurenceOfRandomNumber[__randomVariable[0]] + occurenceOfRandomNumber[__randomVariable[1]] + occurenceOfRandomNumber[__randomVariable[2]] + occurenceOfRandomNumber[__randomVariable[3]] + occurenceOfRandomNumber[__randomVariable[4]];
      return total;
    }

    function getRandomVariablesArray() public view returns(uint256[] memory) {
      return(randomVariableArray);
    }

    function previousCyclesBalances() public view returns(uint256[] memory) {
      return(previousCyclesBalance);
    }

    function getLastMintingRateWei() public view returns(uint256) {
        return(mintingRateNoonerWei);
    }

    function getBurnValues(address add) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return(signmaValueWei, currentMintingRateTotalTokens, totalMintedTokens, weiToBurned, totalWeiInAdminAcc, weiAmountAdded);
    }

    function previousCyclesBurn() public view returns(uint256[] memory) {
      return(previousBurnValues);
    }

    function previousCyclesSigmaValue() public view returns(uint256[] memory) {
        return(previousSigmaValues);
    }

}