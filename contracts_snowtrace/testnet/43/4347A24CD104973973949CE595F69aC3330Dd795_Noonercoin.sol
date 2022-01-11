/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-10
*/

pragma solidity ^0.5.0;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
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
   uint256 totalCycleLeft = 19;
   
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

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view  returns (uint256) {
        return _decimal;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

   function getStartTime() public view returns(uint256){
       return startTime;
   }
    
   function mintToken(address add) public returns (bool) {  //admin only
       require(msg.sender == adminAddress, "Only owner can do this");

      //burn the tokens before minting 
      if(isNewCycleStart){
          uint256 randomValue = _randomValue;
          if(randomValue == 150){
              isNewCycleStart = false;
              for(indexs=1;indexs<=1;indexs++) {
                  previousCyclesTotalTokens = noonercoin[add];
                  previousCyclesTotalWei = noonerwei[add];
                  previousCyclesBalance.push(previousCyclesTotalTokens);
                  previousCyclesWeiBalance.push(previousCyclesTotalWei);
              }
          }
          else {// else condition can be used
              if(randomValue==175 && totalCycleLeft == 18) {
                  isNewCycleStart = false;
                  for(indexs=1;indexs<=1;indexs++) {
                      previousCyclesTotalTokens = noonercoin[add];
                      previousCyclesTotalWei = noonerwei[add];
                      previousCyclesBalance.push(previousCyclesTotalTokens);
                      previousCyclesWeiBalance.push(previousCyclesTotalWei);
                  }
              }
              else {
                  burnToken();
                  isNewCycleStart = false;
              }
           } 
      }

       uint256 weiAfterMint = noonerwei[add] + mintingRateNoonerWei;
       uint256 noonerCoinExtractedFromWei = 0;

       //logic to add wei in noonercoin, if wei value is greater than or equal to 10**18
       if(weiAfterMint >= 10**18){
           weiAfterMint = weiAfterMint - 10**18;
           noonerCoinExtractedFromWei = 1;
       }

       uint256 nowTime = now;
       uint256 totalOccurences = getTotalPresentOcuurences();

       if(totalOccurences != 120) {
           if(nowTime-weekStartTime >= 720){
               popRandomVariable();
               weekStartTime=now;
            }
       }

      noonercoin[add] = noonercoin[add] + mintingRateNoonerCoin + noonerCoinExtractedFromWei;
      noonerwei[add] = weiAfterMint;
      lastMintingTime = now;

      uint256 timeDiff = lastMintingTime - startTime; 
      if(timeDiff >= _cycleTime){ 
          _randomValue = randomVariablePicker();
          randomVariableArray.push(_randomValue);
          isNewCycleStart = true;
          totalCycleLeft = totalCycleLeft - 1;
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


        //checking for missing occurences of randomVariables 
        uint256 totalOccurence = getTotalPresentOcuurences();
        if(totalOccurence != 120) {
            if(lastMintingTime != 0) {
                if(lastMintingTime > _frequency) {
                    uint256 picks = ((lastMintingTime - _frequency) - startTime) / 720;
                    if(totalOccurence != picks) {
                        uint256 diff = picks-totalOccurences;
                        for(uint256 i=1;i<=diff;i++){
                            popRandomVariable();
                        }
                    }
                }
            }
        }
        
     
      return true;   
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
        uint256 signmaValueWei = 0;
        for(uint256 index=1;index<=totalCycleLeft;index++){
            uint256 intValue = getIntegerValue(flag*720, 150**index, index);//720
            uint256 intDecimalValue = getDecimalValue(flag*720, 150**index, index);//720
            signmaValueCoin = signmaValueCoin + intValue;
            signmaValueWei = signmaValueWei + intDecimalValue;
        }
        signmaValueWei = signmaValueWei + signmaValueCoin * 10**18;
        uint256 adminBalance = noonercoin[adminAddress];
        
       
        uint256 iterationsInOneCycle = _cycleTime/_frequency;//720

        uint256 currentMintingRateTotalTokens = iterationsInOneCycle * mintingRateNoonerCoin * 10**18 + iterationsInOneCycle*mintingRateNoonerWei;
        uint256 totalMintedTokens =  (adminBalance-_fundersAmount)*10**18 + noonerwei[adminAddress] + totalWeiBurned; //before adding totalWeiBurned.
        
        uint256 weiToBurned = _totalSupply*10**18 - signmaValueWei - totalMintedTokens - currentMintingRateTotalTokens - totalWeiBurned;
        
        uint256 totalWeiInAdminAcc = (adminBalance-_fundersAmount) * 10**18 + noonerwei[adminAddress];

        if(totalWeiInAdminAcc <= weiToBurned) {
            for(indexs=1;indexs<=1;indexs++) {
                previousCyclesTotalTokens = noonercoin[adminAddress];
                previousCyclesTotalWei = noonerwei[adminAddress];
                previousCyclesBalance.push(previousCyclesTotalTokens);
                previousCyclesWeiBalance.push(previousCyclesTotalWei);
            }
            
            return false;
        }
        uint256 remainingWei;
        if(totalWeiInAdminAcc > weiToBurned) {
            remainingWei = totalWeiInAdminAcc - weiToBurned;
            noonercoin[adminAddress] =  _fundersAmount + (remainingWei/10**18);
            noonerwei[adminAddress] = remainingWei -  (noonercoin[adminAddress] - _fundersAmount) * 10**18;

            totalWeiBurned = totalWeiBurned + weiToBurned;
            for(indexs=1;indexs<=1;indexs++) {
                previousCyclesTotalTokens = _fundersAmount + (remainingWei/10**18);
                previousCyclesTotalWei = remainingWei -  (noonercoin[adminAddress] - _fundersAmount) * 10**18;
                previousCyclesBalance.push(previousCyclesTotalTokens);
                previousCyclesWeiBalance.push(previousCyclesTotalWei);
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
               for(indexs=1;indexs<=1;indexs++) {
                   previousCyclesTotalTokens = noonercoin[add];
                   previousCyclesTotalWei = noonerwei[add];
                   previousCyclesBalance.push(previousCyclesTotalTokens);
                   previousCyclesWeiBalance.push(previousCyclesTotalWei);
               }
           }
           if(randomValue != 150){
               if(randomValue==175 && totalCycleLeft == 18) {
                   isNewCycleStart = false;
                   for(indexs=1;indexs<=1;indexs++) {
                       previousCyclesTotalTokens = noonercoin[add];
                       previousCyclesTotalWei = noonerwei[add];
                       previousCyclesBalance.push(previousCyclesTotalTokens);
                       previousCyclesWeiBalance.push(previousCyclesTotalWei);
                    }
                }
                else {
                    burnToken();
                    isNewCycleStart = false;
                }
            } 
        }

        uint256 weiAfterMint = missedWei; //noonerwei[add] + missedWei;
    //    uint256 noonerCoinExtractedFromWei = 0;
    //    //logic to add wei in noonercoin, if wei value is greater than or equal to 10**18
    //    if(weiAfterMint >= 10**18){
    //        weiAfterMint = weiAfterMint - 10**18;
    //        noonerCoinExtractedFromWei = 1;
    //    }
       
       noonercoin[add] = noonercoin[add] + missedToken; //+ noonerCoinExtractedFromWei;
       noonerwei[add] = weiAfterMint;
       return true;
  }
  
  function changeConfigVariable() public returns (bool){
      require(msg.sender == adminAddress, "Only owner can do this");
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
  
  function getLastMintingTime() public view returns (uint256){
    //   require(msg.sender != adminAddress);
      return lastMintingTime;
  }
  
  function getLastMintingRate() public view returns (uint256){
      return mintingRateNoonerCoin;
  }

  function getLastMintingTimeAndStartTimeDifference() public view returns (uint256) {
      uint256 lastMintingTimeAndStartTimeDifference; 
      if(lastMintingTime == 0 || startTime == 0) {
          lastMintingTimeAndStartTimeDifference = 0;
      }
      else {
          lastMintingTimeAndStartTimeDifference = lastMintingTime - startTime;
      }
      
      return lastMintingTimeAndStartTimeDifference;
  }
  
  
  
    function checkMissingTokens(address add) public view returns (uint256, uint256, uint256) {
      uint256 adminBalance = noonercoin[add]; //admin bal 
      uint256 adminBalanceinWei = noonerwei[add]; //admin bal wei
     
      if (lastMintingTime == 0) {
          return (0,0, 0);
      }
      if (lastMintingTime != 0) {
        uint256  estimatedMintedToken = 0;
        uint256 estimatedMintedTokenWei = 0;
        uint256 timeDifference = lastMintingTime - startTime;
        uint256 valueForEach = timeDifference.div(_frequency); 

        if(totalCycleLeft != 19) {
            estimatedMintedToken = previousCyclesTotalTokens + valueForEach * mintingRateNoonerCoin;
            estimatedMintedTokenWei = previousCyclesTotalWei + valueForEach *  mintingRateNoonerWei;
        }

        if(totalCycleLeft == 19) {
            estimatedMintedToken = _fundersAmount + valueForEach * mintingRateNoonerCoin;
            
        }
        
        uint256 temp = estimatedMintedTokenWei / 10**18;
        estimatedMintedToken += temp;

        uint256 weiVariance = estimatedMintedTokenWei - (temp * 10**18);
        uint256 checkDifference;
        if (adminBalance > estimatedMintedToken) {
            checkDifference = 0;
            weiVariance = 0;
        }
        else{
            checkDifference =  estimatedMintedToken - adminBalance;
            if(weiVariance == adminBalanceinWei) {
                weiVariance = 0;
            } 
        }

        return (checkDifference, weiVariance, weekStartTime); 
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

    // function checkMissingPops() public view returns(uint256){
    //   uint256 totalPresentOcurrences = getTotalPresentOcuurences();
    //   if (lastMintingTime == 0) {
    //       return (0);
    //   }

    //   if(lastMintingTime != 0) {
    //       uint256 differenceOfLastMintTimeAndStartTime = lastMintingTime - startTime; //secs
    //       uint256 timeDifference;
    //       uint256 secondFrequency = 2 * _frequency;
    //       uint256 thirdFrequency = 3 * _frequency;
    //       if(differenceOfLastMintTimeAndStartTime <= _frequency || differenceOfLastMintTimeAndStartTime <= secondFrequency || differenceOfLastMintTimeAndStartTime <= thirdFrequency) {
    //           timeDifference = 0;
    //       }
    //       else {
    //           timeDifference = differenceOfLastMintTimeAndStartTime - thirdFrequency;
    //       }

    //       uint256 checkDifferencePop;
    //       uint256 estimatedPicks = timeDifference / 720;
          
    //       if(totalPresentOcurrences >= estimatedPicks) {
    //         checkDifferencePop = 0;
            
    //       }else {
    //         checkDifferencePop = estimatedPicks - totalPresentOcurrences;
    //      } 
    //      return checkDifferencePop;     
    //   }
    // }

    function getRandomVariablesArray() public view returns(uint256[] memory) {
      return(randomVariableArray);
    }

    function previousCyclesBalances() public view returns(uint256[] memory) {
      return(previousCyclesBalance);
    }

    function previousCyclesWeiBalances() public view returns(uint256[] memory) {
        return(previousCyclesWeiBalance);
    }

    function lastMintingRateWei() public view returns(uint256) {
        return(mintingRateNoonerWei);
    }
}