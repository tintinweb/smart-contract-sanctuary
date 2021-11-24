/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-23
*/

pragma solidity ^0.5.0;

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
    
   uint256 startTime;
   uint256 mintingRateNoonerCoin;
   uint256 mintingRateNoonerWei;
   uint256 lastMintingTime;
   address adminAddress;
   bool isNewCycleStart = false;
   uint8[] __randomVariable = [150, 175, 200, 225, 250];
   uint8[] __remainingRandomVariable = [150, 175, 200, 225, 250];
   uint8[] tempRemainingRandomVariable;
   mapping (uint256 => uint256) occuranceOfRandonNumber;
   uint256 weekStartTime = 0;
   
   mapping (address => uint256)  noonercoin;
   mapping (address => uint256)  noonerwei;
   
   uint256 totalWeiBurned = 0;
   uint256 totalCycleLeft = 20;
   
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimal;
    
    uint256 private _frequency;
    uint256 private _cycleTime = 72576000;
   
   constructor(uint256 totalSupply_, string memory tokenName_, string memory tokenSymbol_,uint256 decimal_, uint256 mintingRateNoonerCoin_, uint256 frequency_) public ERC20("XDC","XDC"){
       _totalSupply = totalSupply_;
       _name = tokenName_;
       _symbol = tokenSymbol_;
       _decimal = decimal_;
       mintingRateNoonerCoin = mintingRateNoonerCoin_;
       _frequency = frequency_;
       adminAddress = msg.sender;
       
       mintingRateNoonerWei = 0;
       startTime = now;
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
       uint256 weiAfterMint = noonerwei[add] + mintingRateNoonerWei;
       uint256 noonerCoinExtractedFromWei = 0;
       //logic to add wei in noonercoin, if wei value is greater than or equal to 10**18
       if(weiAfterMint >= 10**18){
           weiAfterMint = weiAfterMint - 10**18;
           noonerCoinExtractedFromWei = 1;
       }
       
       if(now-weekStartTime>604800){
           popRandomVariable();
           weekStartTime=0;
       }
      //burn the tokens before minting 
      if(isNewCycleStart){
          uint256 randomValue = randomVariablePicker();
          if(randomValue != 150){
              burnToken();
              isNewCycleStart = false;
         } 
      }
      noonercoin[add] = noonercoin[add] + mintingRateNoonerCoin + noonerCoinExtractedFromWei;
      noonerwei[add] = weiAfterMint;
      lastMintingTime = now;
      
      
    
     uint256 timeDiff = now - startTime;
     uint256 fromTime = _cycleTime - _frequency; //72576000
    
     if(timeDiff > fromTime){    //120weeks - 120seconds
         if(timeDiff < _cycleTime){//120 weeks 
           uint256 _randomValue = randomVariablePicker();
           isNewCycleStart = true;
           totalCycleLeft = totalCycleLeft - 1;
           //fetch random number from outside
           uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei; 
           mintingRateNoonerCoin =  getIntegerVaue(flag, _randomValue, 1);
           mintingRateNoonerWei  =  getDecimalVaue(flag, _randomValue, 1);
           startTime = startTime + _cycleTime;
           
           //reset random variable logic
           __remainingRandomVariable = __randomVariable;
           delete tempRemainingRandomVariable;
         }
      }
      return true;   
    }
    
    
    function popRandomVariable() public  returns(bool){
        uint256 randomNumber = randomVariablePicker();
        if(occuranceOfRandonNumber[randomNumber]>=24){
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
            for(uint256 index=0;index<__remainingRandomVariable.length-1;index++){
                tempRemainingRandomVariable[index]= __remainingRandomVariable[index];
            }
          __remainingRandomVariable = tempRemainingRandomVariable;
         }
         if(occuranceOfRandonNumber[randomNumber]<24){
            occuranceOfRandonNumber[randomNumber] = occuranceOfRandonNumber[randomNumber]+1;
         }
        return true;
    }
    
    function burnToken() internal returns(bool){
        uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei;
        uint256 signmaValueCoin = 0;
        uint256 signmaValueWei = 0;
        for(uint256 index=1;index<=totalCycleLeft;index++){
            uint256 intValue = getIntegerVaue(flag * 604800,  150 ** index, index);
            uint256 intDecimalValue = getDecimalVaue(flag * 604800,  150 ** index, index);
            signmaValueCoin = signmaValueCoin + intValue;
            signmaValueWei = signmaValueWei + intDecimalValue;
        }
    
        signmaValueWei = signmaValueWei + signmaValueCoin * 10**18;
        
        uint256 iterationsInOneCycle = _cycleTime/_frequency;
        uint256 totalMintedTokens = noonercoin[adminAddress]*10**18 + noonerwei[adminAddress] + totalWeiBurned + 
        iterationsInOneCycle * mintingRateNoonerCoin * 10**18 + iterationsInOneCycle*mintingRateNoonerWei;
        
        uint256 weiToBurned = 23000000*10**18 - (totalMintedTokens +  signmaValueWei) - totalWeiBurned;
        
        uint256 totalWeiInAdminAcc = noonercoin[adminAddress] * 10**18 + noonerwei[adminAddress];
        if(totalWeiInAdminAcc < weiToBurned)
          return false;
        uint256 remainingWei = totalWeiInAdminAcc - weiToBurned;
        
        noonercoin[adminAddress] =  remainingWei/10**18;
        noonerwei[adminAddress] =   remainingWei -  noonercoin[adminAddress] * 10**18;
        
        totalWeiBurned = totalWeiBurned + weiToBurned;
        return true;
    }
    
    function getUserBalance(address add) public view returns (uint256){
        return noonercoin[add];
    }
    
    function getAfterDecimalValue(address add) internal view returns (uint256){
        return noonerwei[add];
    }
    
    function getIntegerVaue(uint256 a, uint256 b, uint256 expoHundred) internal pure returns (uint256 q){
       //b is already multiplied by 100
       q = a*100**expoHundred/b;
       q=q/10**18;
       return q;
  }
  
  function getDecimalVaue(uint256 a, uint256 b, uint256 expoHundred) internal pure returns (uint256 p){
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
    //    uint256 randomValue = randomVariablePicker();
    //   if(randomValue != 150){
    //    if(isNewCycleStart){
    //           burnToken();
    //           isNewCycleStart = false;
    //    } 
    //   }
       uint256 weiAfterMint = noonerwei[add] + missedWei;
       uint256 noonerCoinExtractedFromWei = 0;
       //logic to add wei in noonercoin, if wei value is greater than or equal to 10**18
       if(weiAfterMint >= 10**18){
           weiAfterMint = weiAfterMint - 10**18;
           noonerCoinExtractedFromWei = 1;
       }
       
       noonercoin[add] = noonercoin[add] + missedToken + noonerCoinExtractedFromWei;
       noonerwei[add] = weiAfterMint;
       return true;
  }
  
  function changeConfigVariable() public returns (bool){
           require(msg.sender == adminAddress, "Only owner can do this");
           uint256 randomValue = randomVariablePicker();
           isNewCycleStart = true;
           totalCycleLeft = totalCycleLeft - 1;
           uint256 flag = mintingRateNoonerCoin * 10**18 + mintingRateNoonerWei; 
           mintingRateNoonerCoin =  getIntegerVaue(flag, randomValue, 1);
           mintingRateNoonerWei  =  getDecimalVaue(flag, randomValue, 1);
           startTime = startTime + _cycleTime;
           
           //reset random variable logic
           __remainingRandomVariable = __randomVariable;
           delete tempRemainingRandomVariable;
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
      uint256 lastMintingTimeAndStartTimeDifference = lastMintingTime - startTime;
      return lastMintingTimeAndStartTimeDifference;
  }
  
  function getCurrentTimeAndStartTimeDifference() public view returns (uint256) {
      uint256 currentTimeAndStartTimeDifference = now - startTime;
      return currentTimeAndStartTimeDifference;
  }

  function checkFailedTransactions(address add) public view returns (uint256) {
      uint256 adminBalance = noonercoin[add]; //admin balance 
      uint256 currMintingRate = getLastMintingRate(); 
      uint256 timeDifference = uint256(lastMintingTime - startTime) / 3600; //checking time from start time to current time and changing to hrs format.

      //lets say we got value from timeDifference and we can also get token amount ie.., if value = 24 then divide 24/24 = 1
      uint256 valueForEach = timeDifference/_frequency; // we will get 1,2,3....
      uint256 estimatedMintedToken = valueForEach * currMintingRate;// gets the total coins for that total hours
      uint256 checkDifference = estimatedMintedToken - adminBalance;// checking diff from the estimate total and also from admin bal
      uint256 missedTokens = checkDifference / mintingRateNoonerCoin; //finding missing tokens.
      return missedTokens; 
  }
  
  
  function checkMissingTokens(address add) public view returns (uint256, uint256) {
      uint256 adminBalance = noonercoin[add]; //admin bal 
      uint256 adminBalanceinWei = noonerwei[add]; //admin bal wei
      if (lastMintingTime == 0) {
          return (0, 0);
      }
      if (lastMintingTime != 0) {
      uint256 timeDifference = uint256(lastMintingTime - startTime) / 3600; //checking time from start time to current time and changing to hrs format.
      uint256 valueForEach = timeDifference/_frequency; // we will get 1,2,3....
      uint256 estimatedMintedToken = valueForEach * mintingRateNoonerCoin;// gets the total coins for that total hours
      uint256 estimatedMintedTokenWei = valueForEach *  mintingRateNoonerWei;
      uint256 temp = estimatedMintedTokenWei / 10**18;
      estimatedMintedTokenWei -= temp;
      estimatedMintedToken += temp;
      uint256 checkDifferenceWei = estimatedMintedTokenWei - (adminBalanceinWei);// checking diff from the estimate total and also from admin bal
      uint256 checkDifference = estimatedMintedToken - adminBalance;
      return (checkDifference,checkDifferenceWei); 
    }
  }

  function currentMintRate() public view returns (uint256){
    uint256 currMintingRate = getLastMintingRate();
    return currMintingRate;
  }
}