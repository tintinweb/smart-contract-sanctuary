//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './FlameCoin.sol';

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);
}

contract FlameCoinCrowdsale {
    
        using SafeMath for uint256;
        IStdReference internal ref;
        
        /**
       * Event for FlameCoins purchase logging
       * @param purchaser who paid for the tokens
       * @param beneficiary who got the tokens
       * @param value bnbs paid for purchase
       * @param FlameCoinAmount amount of Flame Coins purchased
       */
        event TokenPurchase(
            address indexed purchaser,
            address indexed beneficiary,
            uint256 value,
            uint256 FlameCoinAmount
        );
    
       bool public isEnded = false;
    
       event Ended(uint256 totalBNBRaisedInCrowdsale,uint256 unsoldTokensTransferredToOwner);
       
       uint256 public currentFlameCoinUSDPrice;     //FlameCoins in $USD 
       
       FlameCoin public FLM;
       
       uint8 public currentCrowdsaleStage;

      // Flame Coin Distribution
      // =============================
      uint256 public totalFlameCoinsForSale = 30000000*(1e18); // 30,000,000 FLM will be sold during the whole Crowdsale
      // ==============================
      
      // Amount of bnb raised in Crowdsale
      // ==================
      uint256 public totalBNBRaised;
      // ===================
    
      // Crowdsale Stages Details
      // ==================
       mapping (uint256 => uint256) public remainingFLMInStage;
       mapping (uint256 => uint256) public FLMUSDPriceInStages;
      // ===================
    
      // Events
      event BNBTransferred(string text);
      
      //Modifier
        address payable public owner;    
        modifier onlyOwner() {
            require (msg.sender == owner);
            _;
        }
    
      // Constructor
      // ============
      constructor() public       
      {   
          owner = msg.sender;
          currentCrowdsaleStage = 1;
          
          remainingFLMInStage[1] = 10000000*1e18;   // 10,000,000 FLM will be sold during the Stage 1
          remainingFLMInStage[2] = 5000000*1e18;  // 5,000,000 FLM will be sold during the Stage 2
          remainingFLMInStage[3] = 10000000*1e18;  // 10,000,000 FLM will be sold during the Stage 3
          remainingFLMInStage[4] = 5000000*1e18;  // 5,000,000 FLM will be sold during the Stage 4
          
          FLMUSDPriceInStages[1] = 15000000000000000;    //$0.015
          FLMUSDPriceInStages[2] = 30000000000000000;    //$0.03
          FLMUSDPriceInStages[3] = 45000000000000000;   //$0.045
          FLMUSDPriceInStages[4] = 60000000000000000;   //$0.06
        
          currentFlameCoinUSDPrice = FLMUSDPriceInStages[1];       
          
          ref = IStdReference(0xDA7a001b254CD22e46d3eAB04d937489c93174C3);
          FLM = new FlameCoin(owner); // Flame Coin Deployment
      }
      // =============

      // Change Crowdsale Stage. 
      function switchToNextStage() public onlyOwner {
          currentCrowdsaleStage = currentCrowdsaleStage + 1;
          if((currentCrowdsaleStage == 5) || (currentCrowdsaleStage == 0)){
              endCrowdsale();
          }
          currentFlameCoinUSDPrice = FLMUSDPriceInStages[currentCrowdsaleStage]; 
      }
      
       /**
       * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
       * @param _beneficiary Address performing the FlameCoin purchase
       */
      function _preValidatePurchase(
        address _beneficiary
      )
        internal pure
      {
        require(_beneficiary != address(0));
      }
    
      /**
       * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
       * @param _beneficiary Address performing the FlameCoins purchase
       * @param _tokenAmount Number of Flame Coins to be purchased
       */
      function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
      )
        internal
      {
        FLM.transfer(_beneficiary, _tokenAmount);
      }
    
      /**
       * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
       * @param _beneficiary Address receiving the tokens
       * @param _tokenAmount Number of Flame Coins to be purchased
       */
      function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
      )
        internal
      {
        _deliverTokens(_beneficiary, _tokenAmount);
      }
    
      /**
       * @dev Override to extend the way in which bnb is converted to tokens.
       * @param _bnbAmount Value in bnb to be converted into tokens
       * @return Number of tokens that can be purchased with the specified _bnbAmount
       */
      function _getTokenAmount(uint256 _bnbAmount)
        internal view returns (uint256)
      {
        return _bnbAmount.mul(getLatestBNBPrice()).div(currentFlameCoinUSDPrice);
      }
      
      
      // FlameCoins Purchase
      // =========================
      receive() external payable {
          if(isEnded){
              revert(); //Block Incoming BNB Deposits if Crowdsale has ended
          }
          buyFlameCoins(msg.sender);
      }
      
      function buyFlameCoins(address _beneficiary) public payable {
          uint256 bnbAmount = msg.value;
          require(bnbAmount > 0,"Please Send some BNB");
          if(isEnded){
            revert();
          }
          
          _preValidatePurchase(_beneficiary);
          uint256 FlameCoinsToBePurchased = _getTokenAmount(bnbAmount);
          if (FlameCoinsToBePurchased > remainingFLMInStage[currentCrowdsaleStage]) {
             revert();  //Block Incoming BNB Deposits if tokens to be purchased, exceeds remaining tokens for sale in the current stage
          }
            _processPurchase(_beneficiary, FlameCoinsToBePurchased);
            emit TokenPurchase(
              msg.sender,
              _beneficiary,
              bnbAmount,
              FlameCoinsToBePurchased
            );
            
          totalBNBRaised = totalBNBRaised.add(bnbAmount);
          remainingFLMInStage[currentCrowdsaleStage] = remainingFLMInStage[currentCrowdsaleStage].sub(FlameCoinsToBePurchased);
          
          if(remainingFLMInStage[currentCrowdsaleStage] == 0){
              switchToNextStage();      // Switch to Next Crowdsale Stage when all tokens allocated for current stage are being sold out
          }
          
      }
      
      // Finish: Finalizing the Crowdsale.
      // ====================================================================
    
      function endCrowdsale() public onlyOwner {
          require(!isEnded,"Crowdsale already finalized");   
          uint256 unsoldTokens = FLM.balanceOf(address(this));
		  FLM.transfer(owner, unsoldTokens);
                                                              
         for(uint8 i = 1; i<=5; i++){
             remainingFLMInStage[i] = 0;   
          }

          currentCrowdsaleStage = 0;
          emit Ended(totalBNBRaised,unsoldTokens);
          isEnded = true;
      }
      // ===============================
        
      function FlameCoinBalance(address tokenHolder) external view returns(uint256 balance){
          return FLM.balanceOf(tokenHolder);
      }

    /**
     * Returns the latest BNB-USD price
     */
    function getLatestBNBPrice() public view returns (uint256){
        IStdReference.ReferenceData memory data = ref.getReferenceData("BNB","USD");
        return data.rate;
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance,"Insufficient Funds");
        owner.transfer(amount);
        emit BNBTransferred("Funds Withdrawn to Owner Account");
    }
      
    function transferFLMOwnership(address _newOwner) public onlyOwner{
        return FLM.transferOwnership(_newOwner);
    }
    }