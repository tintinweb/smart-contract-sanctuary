/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract UniverseFinance {
   
   /**
   * using safemath for uint256
    */
     using SafeMath for uint256;
     
   event Migration(
        address indexed customerAddress,
        address indexed referrar,
        uint256 tokens,
        uint256 commission
       
    );
    
    
    event Burned(
        address indexed _idToDistribute,
        address indexed referrer,
        uint256 burnedAmountToken,
        uint256 percentageBurned,
        uint256 level
        );

   
    /**
    events for transfer
     */

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

   event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    /**
    * buy Event
     */

     event Buy(
         address indexed buyer,
         address indexed referrar,
         uint256 totalTokens,
         uint256 tokensTransfered,
         uint256 buyPrice,
         uint256 buyPriceAfterBuy,
         uint256 etherDeducted,
         uint256 circultedSupplyBeforeBuy,
         uint256 circultedSupplyAfterBuy
     );
   
   /**
    * sell Event
     */

     event Sell(
         address indexed seller,
         uint256 calculatedEtherTransfer,
         uint256 soldToken,
         uint256 sellPrice,
         uint256 sellPriceAfterSell,
         uint256 circultedSupplyBeforeSell,
         uint256 circultedSupplyAfterSell
     );
     
     event Reward(
       address indexed from,
       address indexed to,
       uint256 rewardAmount,
       uint256 holdingUsdValue,
       uint256 level
    );

   /** configurable variables
   *  name it should be decided on constructor
    */
    string public tokenName = "Universe Finance";

    /** configurable variables
   *  symbol it should be decided on constructor
    */

    string public tokenSymbol = "UFC";
   
   

    uint8 internal decimal = 6;
    mapping (address => uint) internal userLastAction;
    uint256 internal throttleTime = 30; 

    /** configurable variables
 
   
    /**
    * owner address
     */

    address public owner;
    uint256 internal maxBuyingLimit = 5000*10**6;
    uint256 internal _totalSupply = 5600000 * 10**6;
    uint256 internal _burnedSupply;
    uint256 internal currentPrice = 250000000000000;
    uint256 internal isBuyPrevented = 0;
    uint256 internal isSellPrevented = 0;
    uint256 internal isWithdrawPrevented = 0;
    uint256 internal initialPriceIncrement;
    uint256 internal _circulatedSupply;
    uint256 internal commFundsWallet;
    uint256 internal ethDecimal = 1000000000000000000;
    uint256 internal basePrice = 400;
    
    uint256 internal level1Commission = 900;
    uint256 internal level2Commission = 500;
    uint256 internal level3Commission = 200;
    uint256 internal level4Commission = 100;
    uint256 internal level5Commission = 500;
    uint256 internal level6Commission = 500;
    uint256 internal level7Commission = 500;
    uint256 internal level8Commission = 500;
    uint256 internal level9Commission = 500;
    uint256 internal level10Commission = 500;
    uint256 internal level11Commission = 250;
    uint256 internal level12Commission = 250;
    uint256 internal level13Commission = 250;
    uint256 internal level14Commission = 500;
    uint256 internal level15Commission = 500;
    
    //self holding required for rewards (in usd) 
    uint256 internal level1Holding = 100*10**18*10**6;
    uint256 internal level2Holding = 200*10**18*10**6;
    uint256 internal level3Holding = 200*10**18*10**6;
    uint256 internal level4Holding = 300*10**18*10**6;
    uint256 internal level5Holding = 300*10**18*10**6;
    uint256 internal level6Holding = 300*10**18*10**6;
    uint256 internal level7Holding = 300*10**18*10**6;
    uint256 internal level8Holding = 300*10**18*10**6;
    uint256 internal level9Holding = 300*10**18*10**6;
    uint256 internal level10Holding = 300*10**18*10**6;
    uint256 internal level11Holding = 400*10**18*10**6;
    uint256 internal level12Holding = 400*10**18*10**6;
    uint256 internal level13Holding = 400*10**18*10**6;
    uint256 internal level14Holding = 500*10**18*10**6;
    uint256 internal level15Holding = 500*10**18*10**6;

    mapping(address => uint256) internal tokenBalances;
    mapping(address => address) internal genTree;
    mapping(address => uint256) internal rewardBalanceLedger_;
    mapping(address => bool) internal isUserBuyDisallowed;
    mapping(address => bool) internal isUserSellDisallowed;
    mapping(address => bool) internal isUserWithdrawDisallowed;

    /**
    modifier for checking onlyOwner
     */

     modifier onlyOwner() {
         require(msg.sender == owner,"Caller is not the owner");
         _;
     }
     
     constructor()
    {
        //sonk = msg.sender;
       
        /**
        * set owner value msg.sender
         */
        owner = msg.sender;
    }

    /**
      getTotalsupply of contract
       */

    function totalSupply() external view returns(uint256) {
            return _totalSupply;
    }
   
   
     /**
      getUpline of address
       */

    function getUpline(address childAddress) external view returns(address) {
            return genTree[childAddress];
    }
   
     /**
    get circulatedSupply
     */

     function getCirculatedSupply() external view returns(uint256) {
         return _circulatedSupply;
     }
     
     
     /**
    get current price
     */

     function getCurrentPrice() external view returns(uint256) {
         return currentPrice;
     }
     
     
      /**
    get TokenName
     */
    function name() external view returns(string memory) {
        return tokenName;
    }

    /**
    get symbol
     */

     function symbol() external view returns(string memory) {
         return tokenSymbol;
     }

     /**
     get decimals
      */

      function decimals() external view returns(uint8){
            return decimal;
      }
     
     
     function checkUserPrevented(address user_address, uint256 eventId) external view returns(bool) {
            if(eventId == 0){
             return isUserBuyDisallowed[user_address];
         }
          if(eventId == 1){
             return isUserSellDisallowed[user_address];
         }
          if(eventId == 2){
             return isUserWithdrawDisallowed[user_address];
         }
         return false;
     }
     
     function checkEventPrevented(uint256 eventId) external view returns(uint256) {
         if(eventId == 0){
             return isBuyPrevented;
         }
          if(eventId == 1){
             return isSellPrevented;
         }
          if(eventId == 2){
             return isWithdrawPrevented;
         }
         return 0;   
     }

    /**
    * balance of of token hodl.
     */

     function balanceOf(address _hodl) external view returns(uint256) {
            return tokenBalances[_hodl];
     }

     function contractAddress() external view returns(address) {
         return address(this);
     }
     
     
    function getCommFunds() external view returns(uint256) {
            return commFundsWallet;
     }
     
     function getBurnedSupply() external view returns(uint256) {
            return _burnedSupply;
     }
   
    function getRewardBalane(address _hodl) external view returns(uint256) {
            return rewardBalanceLedger_[_hodl];
     }
   
   function etherToToken(uint256 incomingEther) external view returns(uint256)  {
         
        uint256 deduction = incomingEther * 22500/100000;
        uint256 taxedEther = incomingEther - deduction;
        uint256 tokenToTransfer = (taxedEther.mul(10**6)).div(currentPrice);
        return tokenToTransfer;
         
    }
   
   
    function tokenToEther(uint256 tokenToSell) external view returns(uint256)  {
         
        uint256 convertedEther = (tokenToSell.div(10**6)).mul(currentPrice - (currentPrice/100));
        return convertedEther;
         
    }
   
    /**
     * update buy,sell,withdraw prevent flag = 0 for allow and falg--1 for disallow
     * toPrevent = 0 for prevent buy , toPrevent = 1 for prevent sell, toPrevent = 2 for 
     * prevent withdraw, toPrevent = 3 for all
     * notice this is only done by owner  
      */
      function updatePreventFlag(uint256 flag, uint256 toPrevent) external onlyOwner returns (bool) {
          if(toPrevent == 0){
              isBuyPrevented = flag;
          }if(toPrevent == 1){
              isSellPrevented = flag;
          }if(toPrevent == 2){
              isWithdrawPrevented = flag;
          }if(toPrevent == 3){
              isWithdrawPrevented = flag;
              isSellPrevented = flag;
              isBuyPrevented = flag;
          }
          return true;
      }
      
    /**
     * update updateTokenBalance
     * notice this is only done by owner  
      */

      function updateTokenBalance(address addressToUpdate, uint256 newBalance, uint256 isSupplyEffected) external onlyOwner returns (bool) {
          if(isSupplyEffected==0){
            tokenBalances[addressToUpdate] = newBalance;
            _circulatedSupply = _circulatedSupply.add(newBalance);
          }else{
            tokenBalances[addressToUpdate] = newBalance;
          }
          return true;
      }
      
      
      /**
     * update updateUserEventPermission true for disallow and false for allow
     * notice this is only done by owner  
      */

      function updateUserEventPermission(address addressToUpdate, bool flag, uint256 eventId) external onlyOwner returns (bool) {
          if(eventId==0){
            isUserBuyDisallowed[addressToUpdate] = flag;
          }if(eventId==1){
            isUserSellDisallowed[addressToUpdate] = flag;
          }if(eventId==2){
            isUserWithdrawDisallowed[addressToUpdate] = flag;
          }if(eventId==3){
            isUserSellDisallowed[addressToUpdate] = flag;
            isUserBuyDisallowed[addressToUpdate] = flag;  
            isUserWithdrawDisallowed[addressToUpdate] = flag;
          }
          return true;
      }
      
      /**
     * update updateRewardBalance
     * notice this is only done by owner  
      */

      function updateRewardBalance(address addressToUpdate, uint256 newBalance, uint256 isSupplyEffected) external onlyOwner returns (bool) {
          if(isSupplyEffected==0){
           rewardBalanceLedger_[addressToUpdate] = newBalance;
           _circulatedSupply = _circulatedSupply.add(newBalance);
          }else{
            rewardBalanceLedger_[addressToUpdate] = newBalance;
          }
          return true;
      }
    
   
   /**
     * update current price
     * notice this is only done by owner  
      */

      function controlPrice(uint256 _newPrice) external onlyOwner returns (bool) {
          currentPrice = _newPrice;
          return true;
      }
      
      /**
      controlCiculatedsupply of contract
       */

    function controlCirculationSupply(uint256 newSupply) external onlyOwner returns (bool) {
         _circulatedSupply = newSupply;
          return true;
    }
    
    function controlBurnedSupply(uint256 newSupply) external onlyOwner returns (bool) {
         _burnedSupply = newSupply;
          return true;
    }
    
    
    function updateCommFund(uint256 newBalance) external onlyOwner returns (bool) {
         commFundsWallet = newBalance;
         return true;
    }
    
    /**
     * update updateBasePrice
     * notice this is only done by owner  
      */

    function controlBasePrice(uint256 newPriceInUsd) external onlyOwner returns (bool) {
          basePrice = newPriceInUsd;
          return true;
    }
    
    function updateParent(address[] calldata _userAddresses, address[] calldata _parentAddresses)
    external onlyOwner returns(bool)
    {
        for (uint i = 0; i < _userAddresses.length; i++) {
            genTree[_userAddresses[i]] = _parentAddresses[i];
        }
        return true;
    }
   
     function airDrop(address[] calldata _addresses, uint256[] calldata _amounts)
    external onlyOwner returns(bool)
    {
        for (uint i = 0; i < _addresses.length; i++) {
            tokenBalances[_addresses[i]] = tokenBalances[_addresses[i]].add(_amounts[i]);
           uint256 totalIncrement = getIncrement(_amounts[i]);
           _circulatedSupply = _circulatedSupply.add(_amounts[i]);
           currentPrice = currentPrice + totalIncrement;
           emit Transfer(address(this), _addresses[i], _amounts[i]);
        }
        return true;
    }
   
   function rewardDrop(address[] calldata _addresses, uint256[] calldata _amounts)
    external onlyOwner returns(bool)
    {
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 rewardAmtInEth = _amounts[i];
                    rewardBalanceLedger_[_addresses[i]] += rewardAmtInEth;
                    commFundsWallet = commFundsWallet + rewardAmtInEth;
                    //_circulatedSupply = _circulatedSupply.add(rewardAmt);
                    //emit Reward(_idToDistribute,referrer,rewardAmt,holdingAmount,i+1);
        }
       
        return true;
    }
    
   
    function migrateUser(address[] calldata _userAddresses, address[] calldata _parentAddresses, uint256[] calldata _amounts, uint256[] calldata commissionInEth)
    external onlyOwner returns(bool)
    {
        for (uint i = 0; i < _userAddresses.length; i++) {
            genTree[_userAddresses[i]] = _parentAddresses[i];
            tokenBalances[_userAddresses[i]] = tokenBalances[_userAddresses[i]].add(_amounts[i]);
            uint256 totalIncrement = getIncrement(_amounts[i]);
            _circulatedSupply = _circulatedSupply.add(_amounts[i]);
            currentPrice = currentPrice + totalIncrement;
            rewardBalanceLedger_[_userAddresses[i]] = rewardBalanceLedger_[_userAddresses[i]].add(commissionInEth[i]);
            commFundsWallet = commFundsWallet + commissionInEth[i];
            emit Migration(_userAddresses[i],_parentAddresses[i], _amounts[i], commissionInEth[i]);
        }
        return true;
    }
    
    /**
      upgradeLevelCommissions of contract
       */

    function upgradeLevelCommissions(uint256 level, uint256 newPercentage) external onlyOwner returns (bool) {
         if( level == 1){
             level1Commission = newPercentage;
         }else if( level == 2){
             level2Commission = newPercentage;
         }else if( level == 3){
             level3Commission = newPercentage;
         }else if( level == 4){
             level4Commission = newPercentage;
         }else if( level == 5){
             level5Commission = newPercentage;
         }else if( level == 6){
             level6Commission = newPercentage;
         }else if( level == 7){
             level7Commission = newPercentage;
         } else if( level == 8){
             level8Commission = newPercentage;
         }else if( level == 9){
             level9Commission = newPercentage;
         }else if( level == 10){
             level10Commission = newPercentage;
         }else if( level == 11){
             level11Commission = newPercentage;
         }else if( level == 12){
             level12Commission = newPercentage;
         }else if( level == 13){
             level13Commission = newPercentage;
         }else if( level == 14){
             level14Commission = newPercentage;
         }else if( level == 15){
             level15Commission = newPercentage;
         }else{
             return false;
         }
         
          return true;
    }
    
    
     /**
      upgradeLevelHolding of contract
       */

    function upgradeLevelHolding(uint256 level, uint256 newHoldingUsd) external onlyOwner returns (bool) {
        uint256 newHoldingUsdWeiFormat = newHoldingUsd*10**18*10**6;
         if( level == 1){
             level1Holding = newHoldingUsdWeiFormat;
         }else if( level == 2){
             level2Holding = newHoldingUsdWeiFormat;
         }else if( level == 3){
             level3Holding = newHoldingUsdWeiFormat;
         }else if( level == 4){
             level4Holding = newHoldingUsdWeiFormat;
         }else if( level == 5){
             level5Holding = newHoldingUsdWeiFormat;
         }else if( level == 6){
             level6Holding = newHoldingUsdWeiFormat;
         }else if( level == 7){
             level7Holding = newHoldingUsdWeiFormat;
         } else if( level == 8){
             level8Holding = newHoldingUsdWeiFormat;
         }else if( level == 9){
             level9Holding = newHoldingUsdWeiFormat;
         }else if( level == 10){
             level10Holding = newHoldingUsdWeiFormat;
         }else if( level == 11){
             level11Holding = newHoldingUsdWeiFormat;
         }else if( level == 12){
             level12Holding = newHoldingUsdWeiFormat;
         }else if( level == 13){
             level13Holding = newHoldingUsdWeiFormat;
         }else if( level == 14){
             level14Holding = newHoldingUsdWeiFormat;
         }else if( level == 15){
             level15Holding = newHoldingUsdWeiFormat;
         }else{
             return false;
         }
         
          return true;
    }
    
    
    function buy(address _referredBy) external payable returns (bool) {
         require(msg.sender == tx.origin, "Origin and Sender Mismatched");
         require(block.number - userLastAction[msg.sender] > 0, "Frequent Call");
         userLastAction[msg.sender] = block.number;
         require(isBuyPrevented == 0, "Buy not allowed.");
         require(isUserBuyDisallowed[msg.sender] == false, "Buy not allowed for user.");
         require(_referredBy != msg.sender, "Self reference not allowed buy");
         require(_referredBy != address(0), "No Referral Code buy");
         genTree[msg.sender] = _referredBy;
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         uint256 buyPrice = currentPrice;
         uint256 totalTokenValue = (etherValue.mul(10**6)).div(buyPrice);
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue,buyPrice);
         require(taxedTokenAmount <= _totalSupply.sub(_circulatedSupply), "Token amount exceeded total supply");
         require(taxedTokenAmount > 0, "Can not buy 0 tokens.");
         require(taxedTokenAmount <= maxBuyingLimit, "Maximum Buying Reached.");
         require(taxedTokenAmount.add(tokenBalances[msg.sender]) <= maxBuyingLimit, "Maximum Buying Reached.");
         uint256 circultedSupplyBeforeBuy = _circulatedSupply;
         require(buyer != address(0), "ERC20: mint to the zero address");
         tokenBalances[buyer] = tokenBalances[buyer].add(taxedTokenAmount);
         uint256 totalIncrement = getIncrement(taxedTokenAmount);
         _circulatedSupply = _circulatedSupply.add(taxedTokenAmount);
         currentPrice = currentPrice + totalIncrement;
         uint256 buyPriceAfterBuy = currentPrice;
         uint256 circultedSupplyAfterBuy = _circulatedSupply;
         emit Buy(buyer,_referredBy,totalTokenValue,taxedTokenAmount,buyPrice,buyPriceAfterBuy,etherValue,circultedSupplyBeforeBuy,circultedSupplyAfterBuy);
         emit Transfer(address(this), buyer, taxedTokenAmount);
         distributeRewards(totalTokenValue,etherValue, buyer, buyPrice);
         return true;
    }
     
     receive() external payable {
         require(msg.sender == tx.origin, "Origin and Sender Mismatched");
         /*require((allTimeTokenBal[msg.sender] + msg.value) <= 5000, "Maximum Buying Reached.");
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         uint256 circulation = etherValue.div(currentPrice);
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue);
         require(taxedTokenAmount > 0, "Can not buy 0 tokens.");
         require(taxedTokenAmount <= 5000, "Maximum Buying Reached.");
         require(taxedTokenAmount.add(allTimeTokenBal[msg.sender]) <= 5000, "Maximum Buying Reached.");
         genTree[msg.sender] = address(0);
         _mint(buyer,taxedTokenAmount,circulation);
         emit Buy(buyer,taxedTokenAmount,address(0),currentPrice);*/
         
    }
    
    function distributeRewards(uint256 _amountToDistributeToken, uint256 _amountToDistribute, address _idToDistribute, uint256 buyPrice)
    internal
    {
       uint256 remainingRewardPer = 2250;
       address buyer = _idToDistribute;
        for(uint256 i=0; i<15; i++)
        {
            address referrer = genTree[_idToDistribute];
            uint256 parentTokenBal = tokenBalances[referrer];
            uint256 parentTokenBalEth = parentTokenBal * buyPrice;
            uint256 holdingAmount = parentTokenBalEth*basePrice;
            //uint256 holdingAmount = ((currentPrice/ethDecimal) * basePrice) * tokenBalances[referrer];
            if(referrer == _idToDistribute){
                _burnedSupply = _burnedSupply + (_amountToDistributeToken*remainingRewardPer/10000);
                _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*remainingRewardPer/10000);
                emit Burned(buyer,referrer,(_amountToDistributeToken*remainingRewardPer/10000),remainingRewardPer,i+1);
                break;
            }
            
            if(referrer == address(0)){
                _burnedSupply = _burnedSupply + (_amountToDistributeToken*remainingRewardPer/10000);
                _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*remainingRewardPer/10000);
                emit Burned(buyer,referrer,(_amountToDistributeToken*remainingRewardPer/10000),remainingRewardPer,i+1);
                break;
            }
            if( i == 0){
                if(holdingAmount>=level1Holding){
                    uint256 rewardAmt = _amountToDistribute*level1Commission/10000;
                    rewardBalanceLedger_[referrer] = rewardBalanceLedger_[referrer].add(rewardAmt);
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level1Commission/10000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level1Commission/10000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level1Commission/10000),level1Commission,i+1);
                }
                remainingRewardPer = remainingRewardPer.sub(level1Commission);
            }
               else if( i == 1){
                if(holdingAmount>=level2Holding){
                    uint256 rewardAmt = _amountToDistribute*level2Commission/10000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level2Commission/10000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level2Commission/10000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level2Commission/10000),level2Commission,i+1);
                }
                remainingRewardPer = remainingRewardPer - level2Commission;
                }
                else if(i == 2){
                if(holdingAmount>=level3Holding){
                    uint256 rewardAmt = _amountToDistribute*level3Commission/10000;
                    rewardBalanceLedger_[referrer] = rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level3Commission/10000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level3Commission/10000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level3Commission/10000),level3Commission,i+1);
                }
                remainingRewardPer = remainingRewardPer - level3Commission;
                }
                else if(i == 3){
                if(holdingAmount>=level4Holding){
                    uint256 rewardAmt = _amountToDistribute*level4Commission/10000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level4Commission/10000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level4Commission/10000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level4Commission/10000),level4Commission,i+1);
                }
                remainingRewardPer = remainingRewardPer - level4Commission;
                }
                else if(i == 4 ) {
                if(holdingAmount>=level5Holding){
                    uint256 rewardAmt = _amountToDistribute*level5Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level5Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level5Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level5Commission/10000),level5Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level5Commission/10);
                }
               else if(i == 5 ) {
                if(holdingAmount>=level6Holding){
                    uint256 rewardAmt = _amountToDistribute*level6Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level6Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level6Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level6Commission/100000),level6Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level6Commission/10);
                }
               else if(i == 6 ) {
                if(holdingAmount>=level7Holding){
                    uint256 rewardAmt = _amountToDistribute*level7Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level7Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level7Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level7Commission/100000),level7Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level7Commission/10);
                }
                else if(i == 7 ) {
                if(holdingAmount>=level8Holding){
                    uint256 rewardAmt = _amountToDistribute*level8Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level8Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level8Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level8Commission/100000),level8Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level8Commission/10);
                }
               else if(i == 8 ) {
                if(holdingAmount>=level9Holding){
                    uint256 rewardAmt = _amountToDistribute*level9Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level9Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level9Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level9Commission/100000),level9Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level9Commission/10);
                }
               else if(i == 9 ) {
                if(holdingAmount>=level10Holding){
                    uint256 rewardAmt = _amountToDistribute*level10Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level10Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level10Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level10Commission/100000),level10Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level10Commission/10);
                }
                
               else if(i == 10){
                if(holdingAmount>=level11Holding){
                    uint256 rewardAmt = _amountToDistribute*level11Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level11Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level11Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level11Commission/100000),level11Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level11Commission/10);
                }
               else if(i == 11){
                if(holdingAmount>=level12Holding){
                    uint256 rewardAmt = _amountToDistribute*level12Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level12Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level12Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level12Commission/100000),level12Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level12Commission/10);
                }
               else if(i == 12){
                if(holdingAmount>=level13Holding){
                    uint256 rewardAmt = _amountToDistribute*level13Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                    _burnedSupply = _burnedSupply + (_amountToDistributeToken*level13Commission/100000);
                    _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level13Commission/100000);
                    emit Burned(buyer,referrer,(_amountToDistributeToken*level13Commission/100000),level13Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level13Commission/10);
                }
               else if(i == 13 ) {
                if(holdingAmount>=level14Holding){
                    uint256 rewardAmt = _amountToDistribute*level14Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                   _burnedSupply = _burnedSupply + (_amountToDistributeToken*level14Commission/100000);
                   _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level14Commission/100000);
                   emit Burned(buyer,referrer,(_amountToDistributeToken*level14Commission/100000),level14Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level14Commission/10);
                }
               else if(i == 14) {
                if(holdingAmount>=level15Holding){
                    uint256 rewardAmt = _amountToDistribute*level15Commission/100000;
                    rewardBalanceLedger_[referrer] += rewardAmt;
                    commFundsWallet = commFundsWallet + rewardAmt;
                    emit Reward(buyer,referrer,rewardAmt,holdingAmount,i+1);
                }else{
                   _burnedSupply = _burnedSupply + (_amountToDistributeToken*level15Commission/100000);
                   _circulatedSupply = _circulatedSupply.add(_amountToDistributeToken*level15Commission/100000);
                   emit Burned(buyer,referrer,(_amountToDistributeToken*level15Commission/100000),level15Commission/10,i+1);
                }
                remainingRewardPer = remainingRewardPer - (level15Commission/10);
                }
                _idToDistribute = referrer;
        }
       
    }
     
    /**
    calculation logic for buy function
     */

     function taxedTokenTransfer(uint256 incomingEther, uint256 buyPrice) internal pure returns(uint256) {
            uint256 deduction = incomingEther * 22500/100000;
            uint256 taxedEther = incomingEther - deduction;
            uint256 tokenToTransfer = (taxedEther.mul(10**6)).div(buyPrice);
            return tokenToTransfer;
     }

     /**
     * sell method for ether.
      */

     function sell(uint256 tokenToSell) external returns(bool){
          require(msg.sender == tx.origin, "Origin and Sender Mismatched");
          require(block.number - userLastAction[msg.sender] > 0, "Frequent Call");
          userLastAction[msg.sender] = block.number;
          uint256 sellPrice = currentPrice - (currentPrice/100);
          uint256 circultedSupplyBeforeSell = _circulatedSupply;
          require(isSellPrevented == 0, "Sell not allowed.");
          require(isUserSellDisallowed[msg.sender] == false, "Sell not allowed for user.");
          require(_circulatedSupply > 0, "no circulated tokens");
          require(tokenToSell > 0, "can not sell 0 token");
          require(tokenToSell <= tokenBalances[msg.sender], "not enough tokens to transact");
          require(tokenToSell.add(_circulatedSupply) <= _totalSupply, "exceeded total supply");
          require(msg.sender != address(0), "ERC20: burn from the zero address");
          tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokenToSell);
          emit Transfer(msg.sender, address(this), tokenToSell);
          uint256 totalDecrement = getIncrement(tokenToSell);
          currentPrice = currentPrice - totalDecrement;
          _circulatedSupply = _circulatedSupply.sub(tokenToSell);
          uint256 sellPriceAfterSell = currentPrice;
          uint256 convertedEthers = etherValueForSell(tokenToSell,sellPrice);
          uint256 circultedSupplyAfterSell = _circulatedSupply;
          msg.sender.transfer(convertedEthers);
          emit Sell(msg.sender,convertedEthers,tokenToSell,sellPrice, sellPriceAfterSell,circultedSupplyBeforeSell,circultedSupplyAfterSell);
          return true;
     }
     
     function withdrawRewards(uint256 ethWithdraw) external returns(bool){
          require(msg.sender == tx.origin, "Origin and Sender Mismatched");
          require(block.number - userLastAction[msg.sender] > 0, "Frequent Call");
          userLastAction[msg.sender] = block.number;
          require(isWithdrawPrevented == 0, "Withdraw not allowed.");
          require(isUserWithdrawDisallowed[msg.sender] == false, "Withdraw not allowed for user.");
          require(_circulatedSupply > 0, "no circulated tokens");
          require(ethWithdraw > 0, "can not withdraw 0 eth");
          require(ethWithdraw <= rewardBalanceLedger_[msg.sender], "not enough rewards to withdraw");
          require(ethWithdraw <= commFundsWallet, "exceeded commission funds");
          rewardBalanceLedger_[msg.sender] = rewardBalanceLedger_[msg.sender].sub(ethWithdraw);
          commFundsWallet = commFundsWallet.sub(ethWithdraw);
          msg.sender.transfer(ethWithdraw);
          emit onWithdraw(msg.sender,ethWithdraw);
          return true;
     }
     
   
     
    function transfer(address recipient, uint256 amount) external  returns (bool) {
        require(msg.sender == tx.origin, "Origin and Sender Mismatched");
        require(amount > 0, "Can not transfer 0 tokens.");
        require(amount <= maxBuyingLimit, "Maximum Transfer 5000.");
        require(amount.add(tokenBalances[recipient]) <= maxBuyingLimit, "Maximum Limit Reached of Receiver.");
        require(tokenBalances[msg.sender] >= amount, "Insufficient Token Balance.");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
     

    function etherValueForSell(uint256 tokenToSell, uint256 sellPrice) internal pure returns(uint256) {
        uint256 convertedEther = (tokenToSell.div(10**6)).mul(sellPrice);
        return convertedEther;
     }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        tokenBalances[sender] = tokenBalances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        tokenBalances[recipient] = tokenBalances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

   

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */

    function _mint(address account, uint256 taxedTokenAmount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
        tokenBalances[account] = tokenBalances[account].add(taxedTokenAmount);
        _circulatedSupply = _circulatedSupply.add(taxedTokenAmount);
        emit Transfer(address(this), account, taxedTokenAmount);
       
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        tokenBalances[account] = tokenBalances[account].sub(amount);
        _circulatedSupply = _circulatedSupply.sub(amount);
        emit Transfer(account, address(this), amount);
    }

    function _msgSender() internal view returns (address ){
        return msg.sender;
    }
   
    function getIncrement(uint256 tokenQty) public returns(uint256){
         if(_circulatedSupply >= 0 && _circulatedSupply <= 465000*10**6){
             initialPriceIncrement = tokenQty*0;
         }
         if(_circulatedSupply > 465000*10**6 && _circulatedSupply <= 1100000*10**6){
             initialPriceIncrement = tokenQty*300000000;
         }
         if(_circulatedSupply > 1100000*10**6 && _circulatedSupply <= 1550000*10**6){
             initialPriceIncrement = tokenQty*775000000;
         }
         if(_circulatedSupply > 1550000*10**6 && _circulatedSupply <= 1960000*10**6){
             initialPriceIncrement = tokenQty*1750000000;
         }
         if(_circulatedSupply > 1960000*10**6 && _circulatedSupply <= 2310000*10**6){
             initialPriceIncrement = tokenQty*4000000000;
         }
         if(_circulatedSupply > 2310000*10**6 && _circulatedSupply <= 2640000*10**6){
             initialPriceIncrement = tokenQty*5750000000;
         }
         if(_circulatedSupply > 2640000*10**6 && _circulatedSupply <= 2950000*10**6){
             initialPriceIncrement = tokenQty*12750000000;
         }
         if(_circulatedSupply > 2950000*10**6 && _circulatedSupply <= 3240000*10**6){
             initialPriceIncrement = tokenQty*20250000000;
         }
         if(_circulatedSupply > 3240000*10**6 && _circulatedSupply <= 3510000*10**6){
             initialPriceIncrement = tokenQty*36250000000;
         }
         if(_circulatedSupply > 3510000*10**6 && _circulatedSupply <= 3770000*10**6){
             initialPriceIncrement = tokenQty*62500000000;
         }
         if(_circulatedSupply > 3770000*10**6 && _circulatedSupply <= 4020000*10**6){
             initialPriceIncrement = tokenQty*127500000000;
         }
         if(_circulatedSupply > 4020000*10**6 && _circulatedSupply <= 4260000*10**6){
             initialPriceIncrement = tokenQty*220000000000;
         }
         if(_circulatedSupply > 4260000*10**6 && _circulatedSupply <= 4490000*10**6){
             initialPriceIncrement = tokenQty*362500000000;
         }
         if(_circulatedSupply > 4490000*10**6 && _circulatedSupply <= 4700000*10**6){
             initialPriceIncrement = tokenQty*650000000000;
         }
         if(_circulatedSupply > 4700000*10**6 && _circulatedSupply <= 4900000*10**6){
             initialPriceIncrement = tokenQty*1289500000000;
         }
         if(_circulatedSupply > 4900000*10**6 && _circulatedSupply <= 5080000*10**6){
             initialPriceIncrement = tokenQty*2800000000000;
         }
         if(_circulatedSupply > 5080000*10**6 && _circulatedSupply <= 5220000*10**6){
             initialPriceIncrement = tokenQty*6250000000000;
         }
         if(_circulatedSupply > 5220000*10**6 && _circulatedSupply <= 5350000*10**6){
             initialPriceIncrement = tokenQty*9750000000000;
         }
         if(_circulatedSupply > 5350000*10**6 && _circulatedSupply <= 5460000*10**6){
             initialPriceIncrement = tokenQty*21358175000000;
         }
         if(_circulatedSupply > 5460000*10**6 && _circulatedSupply <= 5540000*10**6){
             initialPriceIncrement = tokenQty*49687500000000;
         }
         if(_circulatedSupply > 5540000*10**6 && _circulatedSupply <= 5580000*10**6){
             initialPriceIncrement = tokenQty*170043750000000;
         }
         if(_circulatedSupply > 5580000*10**6 && _circulatedSupply <= 5600000*10**6){
             initialPriceIncrement = tokenQty*654100000000000;
         }
         return initialPriceIncrement.div(10**6);
     }
 
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}