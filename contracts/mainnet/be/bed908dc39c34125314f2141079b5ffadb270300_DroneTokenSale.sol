pragma solidity 0.4.21;


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
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function decimals()public view returns (uint8);
    function burnAllTokens() public;
}

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Funds will be transferred to owner once sale ends
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Withdraw }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Withdraw();
    event RefundsEnabled();
    event Withdrawn(address _wallet);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
      
    function Vault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        require(state == State.Active || state == State.Withdraw);//allowing to deposit even in withdraw state since withdraw state will be started once totalFunding reaches 10,000 ether
        deposited[investor] = deposited[investor].add(msg.value);
        
    }

    function activateWithdrawal() public onlyOwner {
        if(state == State.Active){
          state = State.Withdraw;
          emit Withdraw();
        }
    }
    
    function activateRefund()public onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }
    
    function withdrawToWallet() onlyOwner public{
    require(state == State.Withdraw);
    wallet.transfer(this.balance);
    emit Withdrawn(wallet);
  }
  
   function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
  
 function isRefunding()public onlyOwner view returns(bool) {
     return (state == State.Refunding);
 }
}


contract DroneTokenSale is Ownable{
      using SafeMath for uint256;
      
      //Token to be used for this sale
      Token public token;
      
      //All funds will go into this vault
      Vault public vault;
  
      //rate of token in ether 1eth = 20000 DRONE
      uint256 public rate = 20000;
      /*
      *There will be 4 phases
      * 1. Pre-sale
      * 2. ICO Phase 1
      * 3. ICO Phase 2
      * 4. ICO Phase 3
      */
      struct PhaseInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint8 [3] bonusPercentages;//3 type of bonuses above 100eth, 10-100ether, less than 10ether
          uint256 weiRaised;
      }
      
      //info of each phase
      PhaseInfo[] public phases;
      
      //Total funding
      uint256 public totalFunding;
      
      //total tokesn available for sale
      uint256 tokensAvailableForSale = 3000000000;
      
      
      uint8 public noOfPhases;
      
      
      //Keep track of whether contract is up or not
      bool public contractUp;
      
      //Keep track of whether the sale has ended or not
      bool public saleEnded;
      
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
    modifier _contractUp(){
        require(contractUp);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != address(0));
        _;
    }
    
    modifier minEthContribution() {
        require(msg.value >= 0.1 ether);
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

        // Contract should have enough DRONE credits
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
        
      
        //activate the sale process
        contractUp = true;
    }
    
    //for Emergency/Hard stop of the sale
    function emergencyStop() external onlyOwner _contractUp _saleNotEnded{
        saleEnded = true;    
        
     if(totalFunding < 10000 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
        
      emit SaleStopped(msg.sender, now);
    }
    
    /**
   * @dev Must be called after sale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
    function finalize()public onlyOwner _contractUp _saleNotEnded{
        require(saleTimeOver());
        
        saleEnded = true;
        
        if(totalFunding < 10000 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
       
       emit Finalized(msg.sender, now);
    }
    
      // @return true if all the tiers has been ended
  function saleTimeOver() public view returns (bool) {
    
    return now > phases[noOfPhases-1].endTime;
  }
  
    //if crowdsales is over, the money rasied should be transferred to the wallet address
  function withdrawFunds() public onlyOwner{
  
      vault.withdrawToWallet();
  }
  
  //method to refund money
  function getRefund()public {
      
      vault.refund(msg.sender);
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
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps, uint8[3][4] _bonusPercentages)private {
    
    
    require(_noOfPhases==4);
    
    //Each array should contain info about each tier
    require(_startTimes.length == _noOfPhases);
    require(_endTimes.length==_noOfPhases);
    require(_hardCaps.length==_noOfPhases);
    require(_bonusPercentages.length==_noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i=0;i<_noOfPhases;i++){
        require(_hardCaps[i]>0);
        require(_endTimes[i]>_startTimes[i]);
        if(i>0){
            
        
            
            //start time of this tier should be greater than previous tier
            require(_startTimes[i] > _endTimes[i-1]);
            
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
            //start time of tier1 should be greater than current time
            require(_startTimes[i]>now);
          
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
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
    function DroneTokenSale(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](4);
        uint256[] memory endTimes = new uint256[](4);
        uint256[] memory hardCaps = new uint256[](4);
        uint8[3] [4] memory bonusPercentages;
        
        //pre-sales
        startTimes[0] = 1522321200; //MARCH 29, 2018 11:00 AM GMT
        endTimes[0] = 1523790000; //APRIL 15, 2018 11:00 AM GMT
        hardCaps[0] = 10000 ether;
        bonusPercentages[0][0] = 35;
        bonusPercentages[0][1] = 30;
        bonusPercentages[0][2] = 25;
        
        //phase-1
        startTimes[1] = 1525172460; //MAY 01, 2018 11:01 AM GMT 
        endTimes[1] = 1526382000; //MAY 15, 2018 11:00 AM GMT
        hardCaps[1] = 20000 ether;
        bonusPercentages[1][0] = 25;// above 100 ether
        bonusPercentages[1][1] = 20;// 10<=x<=100
        bonusPercentages[1][2] = 15;// less than 10 ether
        
        
        //phase-2
        startTimes[2] = 1526382060; //MAY 15, 2018 11:01 AM GMT
        endTimes[2] = 1527850800; //JUNE 01, 2018 11:00 AM GMT
        hardCaps[2] = 30000 ether;
        bonusPercentages[2][0] = 15;
        bonusPercentages[2][1] = 10;
        bonusPercentages[2][2] = 5;
        
        //phase-3
        startTimes[3] = 1527850860; //JUNE 01, 2018 11:01 AM GMT
        endTimes[3] = 1533034800; //JULY 31, 2018 11:OO AM GMT
        hardCaps[3] = 75000 ether;
        bonusPercentages[3][0] = 0;
        bonusPercentages[3][1] = 0;
        bonusPercentages[3][2] = 0;

        setTiersInfo(4, startTimes, endTimes, hardCaps, bonusPercentages);
        
    }
    

   //Fallback function used to buytokens
   function()public payable{
       buyTokens(msg.sender);
   }
   
   /**
   * @dev Low level token purchase function
   * @param beneficiary The address who will receive the tokens for this transaction
   */
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded minEthContribution nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex>=0);
       
        // recheck this for storage and memory
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

       //Check hard cap for this phase has not been reached
       require(weiAmount.add(currentlyRunningPhase.weiRaised) <= currentlyRunningPhase.hardcap);
       
       
       uint256 tokens = weiAmount.mul(rate).div(1000000000000000000);//considering decimal places to be zero for token
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningPhase.bonusPercentages, weiAmount);
       
      
       
      
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
    * @param percentages Array of bonus percentages for the phase as per ethers sent
    * @param weiSent Amount of ethers(in form of wei) sent by the user
    */
     function applyBonus(uint256 tokens, uint8 [3]percentages, uint256 weiSent) private pure returns  (uint256) {
         
         uint256 tokensToAdd = 0;
         
         if(weiSent<10 ether){
             tokensToAdd = tokens.mul(percentages[2]).div(100);
         }
         else if(weiSent>=10 ether && weiSent<=100 ether){
              tokensToAdd = tokens.mul(percentages[1]).div(100);
         }
         
         else{
              tokensToAdd = tokens.mul(percentages[0]).div(100);
         }
        
        return tokens.add(tokensToAdd);
    }
    
   /**
    * @dev returns the currently running tier index as per time
    * Return -1 if no tier is running currently
    * */
   function getCurrentlyRunningPhase()public view returns(int8){
      for(uint8 i=0;i<noOfPhases;i++){
          if(now>=phases[i].startTime && now<=phases[i].endTime){
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
   
   /**
   *@dev Method to check whether refund process has been initiated or not by the contract.
   */
   function isRefunding()public view returns(bool) {
       return vault.isRefunding();
   }
   
   /**
   *@dev Method to burn all remanining tokens left with the sales contract after the sale has ended
   */
   function burnRemainingTokens()public onlyOwner _contractUp _saleEnded {
       
       token.burnAllTokens();
   }
   
   /**
   * @dev Method to activate withdrawal of funds even in between of sale. The WIthdrawal will only be activate iff totalFunding has reached 10,000 ether
   */
   function activateWithdrawal()public onlyOwner _saleNotEnded _contractUp {
       
       require(totalFunding >= 10000 ether);
       vault.activateWithdrawal();
       
   }
      
}