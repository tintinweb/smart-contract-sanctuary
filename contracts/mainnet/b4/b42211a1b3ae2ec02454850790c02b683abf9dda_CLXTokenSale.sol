pragma solidity 0.4.23;


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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
    function decimals()external view returns (uint8);
}

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Funds will be transferred to owner on adhoc requests
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    address public wallet;
    
    event Withdrawn(address _wallet);
    
    function Vault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        deposited[investor] = deposited[investor].add(msg.value);
        
    }

    
    function withdrawToWallet() public onlyOwner {
     wallet.transfer(this.balance);
     emit Withdrawn(wallet);
  }
  
}


contract CLXTokenSale is Ownable{
      using SafeMath for uint256;
      
      //Token to be used for this sale
      Token public token;
      
      //All funds will go into this vault
      Vault public vault;
  
      //rate of token in ether 1ETH = 8000 CLX
      uint256 public rate = 8000;
      
      /*
      *There will be 2 phases
      * 1. Pre-sale
      * 2. ICO Phase 1
      */

      struct PhaseInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint8   bonusPercentages;
          uint256 minEtherContribution;
          uint256 weiRaised;
      }
      
         
      //info of each phase
      PhaseInfo[] public phases;
      
      //Total funding
      uint256 public totalFunding;

      //total tokens available for sale considering 8 decimal places
      uint256 tokensAvailableForSale = 17700000000000000;
      
      
      uint8 public noOfPhases;
      
      
      //Keep track of whether contract is up or not
      bool public contractUp;
      
      //Keep track of whether the sale has ended or not
      bool public saleEnded;

       //Keep track of emergency stop
      bool public ifEmergencyStop ;
      
      //Event to trigger Sale stop
      event SaleStopped(address _owner, uint256 time);
      
      //Event to trigger Sale restart
      event SaleRestarted(address _owner, uint256 time);
      
      //Event to trigger normal flow of sale end
      event Finished(address _owner, uint256 time);
    
     /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
     event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    //modifiers    
    modifier _contractUp(){
        require(contractUp);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != address(0));
        _;
    }
    
    modifier _saleEnded() {
        require(saleEnded);
        _;
    }
    
    modifier _saleNotEnded() {
        require(!saleEnded);
        _;
    }

    modifier _ifNotEmergencyStop() {
        require(!ifEmergencyStop);
        _;
    }

    /**
    *     @dev Check if sale contract has enough tokens on its account balance 
    *     to reward all possible participations within sale period
    */
    function powerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractUp);

        // Contract should have enough CLX credits
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
        //activate the sale process
        contractUp = true;
    }
    
    //for Emergency stop of the sale
    function emergencyStop() external onlyOwner _contractUp _ifNotEmergencyStop {
       
        ifEmergencyStop = true;  
        
        emit SaleStopped(msg.sender, now);
    }

    //to restart the sale after emergency stop
    function emergencyRestart() external onlyOwner _contractUp  {
        require(ifEmergencyStop);
       
        ifEmergencyStop = false;

        emit SaleRestarted(msg.sender, now);
    }
  
      // @return true if all the tiers has been ended
  function saleTimeOver() public view returns (bool) {
    
    return (phases[noOfPhases-1].endTime != 0);
  }
  
   
  /**
  * @dev Can be called only once. The method to allow owner to set tier information
  * @param _noOfPhases The integer to set number of tiers
  * @param _startTimes The array containing start time of each tier
  * @param _endTimes The array containing end time of each tier
  * @param _hardCaps The array containing hard cap for each tier
  * @param _bonusPercentages The array containing bonus percentage for each tier
  * The arrays should be in sync with each other. For each index 0 for each of the array should contain info about Tier 1, similarly for Tier2, 3 and 4 .
  * Sales hard cap will be the hard cap of last tier
  */
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps ,uint256[] _minEtherContribution, uint8[2] _bonusPercentages)private {
    
    
    require(_noOfPhases == 2);
    
    //Each array should contain info about each tier
    require(_startTimes.length ==  2);
   require(_endTimes.length == _noOfPhases);
    require(_hardCaps.length == _noOfPhases);
    require(_bonusPercentages.length == _noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i = 0; i < _noOfPhases; i++){

        require(_hardCaps[i] > 0);
       
        if(i>0){

            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                minEtherContribution : _minEtherContribution[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
            //start time of tier1 should be greater than current time
            require(_startTimes[i] > now);
          
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                minEtherContribution : _minEtherContribution[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
  }
  
  
    /**
    * @dev Constructor method
    * @param _tokenToBeUsed Address of the token to be used for Sales
    * @param _wallet Address of the wallet which will receive the collected funds
    */  
    function CLXTokenSale(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](2);
        uint256[] memory endTimes = new uint256[](2);
        uint256[] memory hardCaps = new uint256[](2);
        uint256[] memory minEtherContribution = new uint256[](2);
        uint8[2] memory bonusPercentages;
        
        //pre-sales
        startTimes[0] = 1525910400; //MAY 10, 2018 00:00 AM GMT
        endTimes[0] = 0; //NO END TIME INITIALLY
        hardCaps[0] = 7500 ether;
        minEtherContribution[0] = 0.3 ether;
        bonusPercentages[0] = 20;
        
        //phase-1: Public Sale
        startTimes[1] = 0; //NO START TIME INITIALLY
        endTimes[1] = 0; //NO END TIME INITIALLY
        hardCaps[1] = 12500 ether;
        minEtherContribution[1] = 0.1 ether;
        bonusPercentages[1] = 5;
        
        setTiersInfo(2, startTimes, endTimes, hardCaps, minEtherContribution, bonusPercentages);
        
    }
    
   //Fallback function used to buytokens
   function()public payable{
       buyTokens(msg.sender);
   }

   function startNextPhase() public onlyOwner _saleNotEnded _contractUp _ifNotEmergencyStop returns(bool){

       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       
       require(currentPhaseIndex == 0);

       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       uint256 tokensLeft;
       uint256 tokensInPreICO = 7200000000000000; //considering 8 decimal places
             
       //Checking if tokens are left after the Pre ICO sale, if left, transfer all to the owner   
       if(currentlyRunningPhase.weiRaised <= 7500 ether) {
           tokensLeft = tokensInPreICO.sub(currentlyRunningPhase.weiRaised.mul(9600).div(10000000000));
           token.transfer(msg.sender, tokensLeft);
       }
       
       phases[0].endTime = now;
       phases[1].startTime = now;

       return true;
       
   }

   /**
   * @dev Must be called to end the sale, to do some extra finalization
   * work. It finishes the sale, sends the unsold tokens to the owner&#39;s address
   * IMP : Call withdrawFunds() before finishing the sale 
   */
  function finishSale() public onlyOwner _contractUp _saleNotEnded returns (bool){
      
      int8 currentPhaseIndex = getCurrentlyRunningPhase();
      require(currentPhaseIndex == 1);
      
      PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
      uint256 tokensLeft;
      uint256 tokensInPublicSale = 10500000000000000; //considering 8 decimal places
          
          //Checking if tokens are left after the Public sale, if left, transfer all to the owner   
       if(currentlyRunningPhase.weiRaised <= 12500 ether) {
           tokensLeft = tokensInPublicSale.sub(currentlyRunningPhase.weiRaised.mul(8400).div(10000000000));
           token.transfer(msg.sender, tokensLeft);
       }
      //End the sale
      saleEnded = true;
      
      //Set the endTime of Public Sale
      phases[noOfPhases-1].endTime = now;
      
      emit Finished(msg.sender, now);
      return true;
  }

   
   /**
   * @dev Low level token purchase function
   * @param beneficiary The address who will receive the tokens for this transaction
   */
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded _ifNotEmergencyStop nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex >= 0);
       
        // recheck this for storage and memory
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

       //Check hard cap for this phase has not been reached
       require(weiAmount.add(currentlyRunningPhase.weiRaised) <= currentlyRunningPhase.hardcap);
       
       //check the minimum ether contribution
       require(weiAmount >= currentlyRunningPhase.minEtherContribution);
       
       
       uint256 tokens = weiAmount.mul(rate).div(10000000000);//considering decimal places to be 8 for token
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningPhase.bonusPercentages);


       totalFunding = totalFunding.add(weiAmount);
             
       currentlyRunningPhase.weiRaised = currentlyRunningPhase.weiRaised.add(weiAmount);
       
       vault.deposit.value(msg.value)(msg.sender);
       
       token.transfer(beneficiary, bonusedTokens);
       
       emit TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

       return true;
       
   }
   
    /**
    *@dev Method to calculate bonus for the user as per currently running phase and contribution by the user
    * @param tokens Total tokens purchased by the user
    * @param percentage Array of bonus percentages for the phase
    */
     function applyBonus(uint256 tokens, uint8 percentage) private pure returns  (uint256) {
         
         uint256 tokensToAdd = 0;
         tokensToAdd = tokens.mul(percentage).div(100);
         return tokens.add(tokensToAdd);
    }
    
   /**
    * @dev returns the currently running tier index as per time
    * Return -1 if no tier is running currently
    * */
   function getCurrentlyRunningPhase()public view returns(int8){
      for(uint8 i=0;i<noOfPhases;i++){

          if(phases[i].startTime!=0 && now>=phases[i].startTime && phases[i].endTime == 0){
              return int8(i);
          }
      }   
      return -1;
   }
   
   
   /**
   * @dev Get funding info of user/address.
   * It will return how much funding the user has made in terms of wei
   */
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }

   /**
   * @dev Allow owner to withdraw funds to his wallet anytime in between the sale process 
   */

    function withDrawFunds()public onlyOwner _saleNotEnded _contractUp {
      
       vault.withdrawToWallet();
    }
}