pragma solidity 0.4.24;


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
  constructor () public {
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
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function decimals()external view returns (uint8);
}

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Funds will be transferred to owner once sale ends
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    address public wallet;
   
    event Withdrawn(address _wallet);
         
    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        deposited[investor] = deposited[investor].add(msg.value);
        
    }
    
    function withdrawToWallet() onlyOwner public{
    
    wallet.transfer(address(this).balance);
     emit Withdrawn(wallet);
  }
}


contract ESTTokenSale is Ownable{
      using SafeMath for uint256;
      
      //Token to be used for this sale
      Token public token;
      
      //All funds will go into this vault
      Vault public vault;

     // This mapping stores the addresses of whitelisted users
      mapping(address => bool) public whitelisted;
  
      //rate of token :  1 EST = 0.00005804 ETH
      uint256 public rate = 58040000000000;
      /*
      *There will be 4 phases
      * 1. Pre-sale
      * 2. ICO Phase 1
      * 3. ICO Phase 2
      * 4. ICO Phase 3
      */
      struct PhaseInfo{
          uint256 cummulativeHardCap;
          uint256 startTime;
          uint256 endTime;
          uint8 bonusPercentages;
          uint256 weiRaised;
      }
      
      //info of each phase
      PhaseInfo[] public phases;
      
      //Total funding
      uint256 public totalFunding;
      
      //total tokens available for sale
      uint256 tokensAvailableForSale = 45050000000000000; //considering 8 decimal places
      
      
      uint8 public noOfPhases;
      
      
      //Keep track of whether contract is up or not
      bool public contractUp;
      
      //Keep track of whether the sale has ended or not
      bool public saleEnded;
      
      //Event to trigger Sale stop
      event SaleStopped(address _owner, uint256 time);
      
      //Event to trigger normal flow of sale end
      event SaleEnded(address _owner, uint256 time);
      
      //Event to add user to the whitelist
      event LogUserAdded(address user);

      //Event to remove user to the whitelist
      event LogUserRemoved(address user);
    
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
  
    
    /**
    *     @dev Check if sale contract has enough tokens on its account balance 
    *     to reward all possible participations within sale period
    */
    function powerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractUp);

        // Contract should have enough EST credits
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
        //activate the sale process
        contractUp = true;
    }
    
    //for Emergency/Hard stop of the sale
    function emergencyStop() external onlyOwner _contractUp _saleNotEnded{
    
      saleEnded = true;    
        
      emit SaleStopped(msg.sender, now);
    }
    
    /**
   * @dev Must be called to end the sale
   */

   function endSale() public onlyOwner _contractUp _saleNotEnded {

       require(saleTimeOver());

       saleEnded = true;
       emit SaleEnded(msg.sender, now);
   }
    

      // @return true if all the tiers has been ended
  function saleTimeOver() public view returns (bool) {
    
    return now > phases[noOfPhases-1].endTime;
  }

  
  /**
  * @dev Can be called only once. The method to allow owner to set tier information
  * @param _noOfPhases The integer to set number of tiers
  * @param _startTimes The array containing start time of each tier
  * @param _endTimes The array containing end time of each tier
  * @param _cummulativeHardCaps The array containing cumulative hard cap for each tier
  * @param _bonusPercentages The array containing bonus percentage for each tier
  * The arrays should be in sync with each other. For each index 0 for each of the array should contain info about Tier 1, similarly for Tier2, 3 and 4 .
  * Sales hard cap will be the hard cap of last tier
  */
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _cummulativeHardCaps, uint8[4] _bonusPercentages)private {
    
    
    require(_noOfPhases == 4);
    
    //Each array should contain info about each tier
    require(_startTimes.length == _noOfPhases);
    require(_endTimes.length ==_noOfPhases);
    require(_cummulativeHardCaps.length ==_noOfPhases);
    require(_bonusPercentages.length ==_noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i = 0; i < _noOfPhases; i++){
        require(_cummulativeHardCaps[i] > 0);
        require(_endTimes[i] > _startTimes[i]);
        if(i > 0){
            
            //start time of this tier should be greater than previous tier
            require(_startTimes[i] > _endTimes[i-1]);
            
            phases.push(PhaseInfo({
                cummulativeHardCap:_cummulativeHardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
            //start time of tier1 should be greater than current time
            require(_startTimes[i] > now);
          
            phases.push(PhaseInfo({
                cummulativeHardCap:_cummulativeHardCaps[i],
                startTime:_startTimes[i],
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
    constructor (address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](4);
        uint256[] memory endTimes = new uint256[](4);
        uint256[] memory cummulativeHardCaps = new uint256[](4);
        uint8 [4] memory bonusPercentages;
        
        //pre-sales
        startTimes[0] = 1532044800; //JULY 20, 2018 12:00:00 AM GMT
        endTimes[0] = 1535759999; //AUGUST 31, 2018 11:59:59 PM GMT
        cummulativeHardCaps[0] = 2107040600000000000000 wei;
        bonusPercentages[0] = 67;
        
        //phase-1
        startTimes[1] = 1535846400; //SEPTEMBER 02, 2018 12:00:00 AM GMT 
        endTimes[1] = 1539647999; //OCTOBER 15, 2018 11:59:59 PM GMT
        cummulativeHardCaps[1] = 7766345900000000000000 wei;
        bonusPercentages[1] = 33;
        
        
        //phase-2
        startTimes[2] = 1539648000; //OCTOBER 16, 2018 12:00:00 AM GMT
        endTimes[2] = 1543622399; //NOVEMBER 30, 2018 11:59:59 PM GMT
        cummulativeHardCaps[2] = 14180545900000000000000 wei;
        bonusPercentages[2] = 18;
        
        //phase-3
        startTimes[3] = 1543622400; //DECEMBER 01, 2018 12:00:00 AM GMT
        endTimes[3] = 1546300799; //DECEMBER 31, 2018 11:59:59 PM GMT
        cummulativeHardCaps[3] = 21197987200000000000000 wei;
        bonusPercentages[3] = 8;

        setTiersInfo(4, startTimes, endTimes, cummulativeHardCaps, bonusPercentages);
        
    }
    

   //Fallback function used to buytokens
   function()public payable{
       buyTokens(msg.sender);
   }
   
   function getFundingInfoOfPhase(uint8 phase) public view returns (uint256){
       
       PhaseInfo storage currentlyRunningPhase = phases[uint256(phase)];
       
       return currentlyRunningPhase.weiRaised;
       
   } 
   
   /**
   * @dev Low level token purchase function
   * @param beneficiary The address who will receive the tokens for this transaction
   */
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded nonZeroAddress(beneficiary) payable returns(bool){
       
       require(whitelisted[beneficiary]);

       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex >= 0);
       
        // recheck this for storage and memory
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

       //Check cummulative Hard Cap for this phase has not been reached
       require(weiAmount.add(totalFunding) <= currentlyRunningPhase.cummulativeHardCap);
       
       
       uint256 tokens = weiAmount.div(rate).mul(100000000);//considering decimal places to be 8 for token
       
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
    * @param percentage  of bonus  for the phase 
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
      for(uint8 i = 0; i < noOfPhases; i++){
          if(now >= phases[i].startTime && now <= phases[i].endTime){
              return int8(i);
          }
      }   
      return -1;
   }
   
   // Add a user to the whitelist
   function addUser(address user) public nonZeroAddress(user) onlyOwner returns (bool) {

       require(whitelisted[user] == false);
       
       whitelisted[user] = true;

       emit LogUserAdded(user);
       
       return true;

    }

    // Remove an user from the whitelist
    function removeUser(address user) public nonZeroAddress(user) onlyOwner returns(bool){
      
        require(whitelisted[user] = true);

        whitelisted[user] = false;
        
        emit LogUserRemoved(user);
        
        return true;


    }

    // Add many users in one go to the whitelist
    function addManyUsers(address[] users)public onlyOwner {
        
        require(users.length < 100);

        for (uint8 index = 0; index < users.length; index++) {

             whitelisted[users[index]] = true;

             emit LogUserAdded(users[index]);

        }
    }

     //Method to check whether a user is there in the whitelist or not
    function checkUser(address user) onlyOwner public view  returns (bool){
        return whitelisted[user];
    }
   
   /**
   * @dev Get funding info of user/address. It will return how much funding the user has made in terms of wei
   */
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }
   
   
   /**
   *@dev Method to transfer all remanining tokens left to owner left with the sales contract after the sale has ended
   */
   function transferRemainingTokens()public onlyOwner _contractUp _saleEnded {
       
       token.transfer(msg.sender,address(this).balance);
      
   }
   
   //method to check how many tokens are left
   function tokensLeftForSale() public view returns (uint256){
       return token.balanceOf(address(this));
   }
   
   //method to check the user balance
   function checkUserTokenBalance(address _user) public view returns(uint256) {
       return token.balanceOf(_user);
   }
   
   //method to check how many tokens have been sold out till now out of 450.5 Million
   function tokensSold() public view returns (uint256) {
       return tokensAvailableForSale.sub(token.balanceOf(address(this)));
   }
   
   //Allowing owner to transfer the  money rasied to the wallet address
   function withDrawFunds()public onlyOwner _contractUp {
      
       vault.withdrawToWallet();
    }
      
}