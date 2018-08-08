pragma solidity 0.4.22;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function decimals()public view returns (uint8);
}

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Funds will be transferred to owner once sale ends
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event withdrawn(address _wallet);
    function Vault(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlyOwner  payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() public onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        Closed();
    }

    function withdrawToWallet() onlyOwner public{
    require(state == State.Closed);
    wallet.transfer(this.balance);
    withdrawn(wallet);
  }
}


contract MIOTCrowdsales is Ownable{
      using SafeMath for uint256;
      
      //Token to be used for this sale
      Token public token;
      
      //All funds will go into this vault
      Vault public vault;
      
      //Total tokens which is on for sale
      uint256 public crowdSaleHardCap;
      
      
      //There can be 5 tiers and it will contain info about each tier
      struct TierInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint256 rate;
          uint8 bonusPercentage;
          uint256 weiRaised;
      }
      
      //info of each tier
      TierInfo[] public tiers;
      
      //Total funding
      uint256 public totalFunding;
      
      uint8 public noOfTiers;
      
      uint256 public tokensSold;
    
      //Keep track whether sales is active or not
      bool public salesActive;
      
      //Keep track of whether the sale has ended or not
      bool public saleEnded;
      
      bool public unspentCreditsWithdrawn;
      
      //to make sure contract is poweredup only once
      bool contractPoweredUp = false;
      
      //Event to trigger Sale stop
      event SaleStopped(address _owner, uint256 time);
      
      //Event to trigger normal flow of sale end
      event Finalized(address _owner, uint256 time);
    
     /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
     event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    //modifiers    
    modifier _saleActive(){
        require(salesActive);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }
    
    modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }
    
    modifier _saleEnded() {
        require(saleEnded);
        _;
    }
    
    modifier tiersEmpty(){
        require(noOfTiers==0);
        _;
    }
    
    function MIOTCrowdsales(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
    }
    
    /**
    *     @dev Check if sale contract has enough tokens on its account balance 
    *     to reward all possible participations within sale period
    */
    function powerUpContract() external onlyOwner {
        
        require(!contractPoweredUp);
        
        // Contract should not be powered up previously
        require(!salesActive);

        // Contract should have enough Parsec credits
        require(token.balanceOf(this) >= crowdSaleHardCap);
        
        //check whether tier information has been entered
        require(noOfTiers>0 && tiers.length==noOfTiers);
      
        //activate the sale process
        salesActive=true;
        
        contractPoweredUp = true;
    }
    
    //for Emergency stop of the sale
    function emergencyStop() public onlyOwner _saleActive{
        salesActive = false;
        saleEnded = true;    
        vault.close();
        SaleStopped(msg.sender, now);
    }
    
    /**
   * @dev Must be called after sale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
    function finalize()public onlyOwner _saleActive{
        require(saleTimeOver());
        salesActive = false;
        saleEnded = true;
        vault.close();
        Finalized(msg.sender, now);
    }
    
      // @return true if all the tiers has been ended
  function saleTimeOver() public view returns (bool) {
      if(noOfTiers==0){
          //since no tiers has been provided yet, hence sales has not started to end
          return false;
      }
      //If last tier has ended, it mean all tiers are finished
    return now > tiers[noOfTiers-1].endTime;
  }
  
    //if crowdsales is over, the money rasied should be transferred to the wallet address
  function withdrawFunds() public onlyOwner _saleEnded{
  
      vault.withdrawToWallet();
  }
  
  /**
  * @dev Can be called only once. The method to allow owner to set tier information
  * @param _noOfTiers The integer to set number of tiers
  * @param _startTimes The array containing start time of each tier
  * @param _endTimes The array containing end time of each tier
  * @param _hardCaps The array containing hard cap for each tier
  * @param _rates The array containing number of tokens per ether for each tier
  * @param _bonusPercentages The array containing bonus percentage for each tier
  * The arrays should be in sync with each other. For each index 0 for each of the array should contain info about Tier 1, similarly for Tier2, 3,4 and 5.
  * Sales hard cap will be the hard cap of last tier
  */
  function setTiersInfo(uint8 _noOfTiers, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps, uint256[] _rates, uint8[] _bonusPercentages)public onlyOwner tiersEmpty{
    
    //Minimu number of tiers should be 1 and less than or equal to 5
    require(_noOfTiers>=1 && _noOfTiers<=5);
    
    //Each array should contain info about each tier
    require(_startTimes.length == _noOfTiers);
    require(_endTimes.length==_noOfTiers);
    require(_hardCaps.length==_noOfTiers);
    require(_rates.length==_noOfTiers);
    require(_bonusPercentages.length==_noOfTiers);
    
    noOfTiers = _noOfTiers;
    
    for(uint8 i=0;i<noOfTiers;i++){
        require(_hardCaps[i]>0);
        require(_endTimes[i]>_startTimes[i]);
        require(_rates[i]>0);
        require(_bonusPercentages[i]>0);
        if(i>0){
            
            //check hard cap for this tier should be greater than the previous tier
            require(_hardCaps[i] > _hardCaps[i-1]);
            
            //start time of this tier should be greater than previous tier
            require(_startTimes[i]>_endTimes[i-1]);
            
            tiers.push(TierInfo({
                hardcap:_hardCaps[i].mul( 10 ** uint256(token.decimals())),
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                rate:_rates[i],
                bonusPercentage:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
            //start time of tier1 should be greater than current time
            require(_startTimes[i]>now);
          
            tiers.push(TierInfo({
                hardcap:_hardCaps[i].mul( 10 ** uint256(token.decimals())), //multiplying with decimal places. So if hard cap is set to 1 it is actually set to 1 * 10^decimals
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                rate:_rates[i],
                bonusPercentage:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
    crowdSaleHardCap = _hardCaps[noOfTiers-1].mul( 10 ** uint256(token.decimals()));
  }
    
    /**
    * @dev Allows owner to transfer unsold tokens to his/her address
    * This method should only be called once the sale has been stopped/ended
    */
   function ownerWithdrawUnspentCredits()public onlyOwner _saleEnded{
        require(!unspentCreditsWithdrawn);
        unspentCreditsWithdrawn = true;
        token.transfer(owner, token.balanceOf(this));
   }
   
   //Fallback function used to buytokens
   function()public payable{
       buyTokens(msg.sender);
   }
   
   /**
   * @dev Low level token purchase function
   * @param beneficiary The address who will receive the tokens for this transaction
   */
   function buyTokens(address beneficiary)public _saleActive nonZeroEth nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentTierIndex = getCurrentlyRunningTier();
       assert(currentTierIndex>=0);
       
       TierInfo storage currentlyRunningTier = tiers[uint256(currentTierIndex)];
       
       //hard cap for this tier has not been reached
       require(tokensSold < currentlyRunningTier.hardcap);
       
       uint256 weiAmount = msg.value;
       
       uint256 tokens = weiAmount.mul(currentlyRunningTier.rate);
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningTier.bonusPercentage);
       
       //Total tokens sold including current sale should be less than hard cap of this tier
       assert(tokensSold.add(bonusedTokens) <= currentlyRunningTier.hardcap);
       
       tokensSold = tokensSold.add(bonusedTokens);
       
       totalFunding = totalFunding.add(weiAmount);
       
       currentlyRunningTier.weiRaised = currentlyRunningTier.weiRaised.add(weiAmount);
       vault.deposit.value(msg.value)(msg.sender);
       token.transfer(beneficiary, bonusedTokens);
       TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);
       
   }
   
     function applyBonus(uint256 tokens, uint8 percent) internal pure returns  (uint256 bonusedTokens) {
        uint256 tokensToAdd = tokens.mul(percent).div(100);
        return tokens.add(tokensToAdd);
    }
    
   /**
    * @dev returns the currently running tier index as per time
    * Return -1 if no tier is running currently
    * */
   function getCurrentlyRunningTier()public view returns(int8){
      for(uint8 i=0;i<noOfTiers;i++){
          if(now>=tiers[i].startTime && now<tiers[i].endTime){
              return int8(i);
          }
      }   
      return -1;
   }
   
   /**
   * @dev Get functing info of user/address. It will return how much funding the user has made in terms of wei
   */
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }
   
      
}