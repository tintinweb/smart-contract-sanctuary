pragma solidity ^0.4.25;

/*
    The Dayly Limit:
    The current Smart Contract Triggers the coolDownTime  every time the allowance runs out, and allows for more withdrawal 24 hours later.
    The idea of setting up the schedule every day, was dicarded for security reasons, Ethereum doesnt have a native node clock, Additionally 
    it opens up the front for coordinated attacks on the smart contract. A malicious agent could execute a transaction with thousands of bots
    at 11:59 pm and then withdraw again at 00:01. potentially draining the contract and not giving legitimate users the time to withdraw their 
    funds.
    
    The Allowance Constraints:
    I have also assumed that allowances are not accumulable, so the allowance is "use it or loose it", just like real world banks do it.
    
    The WhiteList:
    An owner can dynamically add or remove any given address into the white list of the smart contract. This addresses would then be able to 
    withdraw as much money as they want so it should be used with care
    
    There is a number of functions that have been created for modularity and code calrity, and are not to be executed as stand alone functions.
    These functions are:
    initialiseValues(); This function is in charge of initialiseng all of the values for user who are withdrawing for the first time,
    its called directly from withdraw so theres no need to execute it independently.
    
    _triggerCooldown(); This function makes sure all the appropriate values are updated when a user withdraws all his Allowance, again it&#39;s called 
    from withdrawal so there is not need to call it individually.
*/



contract TokenCardFinal{
    
  address public receiver;
  
  uint AllowanceDay = 10000000000000000 wei;
  
  uint dayCooldown;  
  
  /// @notice Production Smart Sontract should set the coolDownTime to 86400seconds(1-day) 
  /// @notice Testing Smart Sontract should use 300seconds(5-minutes) to keep testing short.
  uint64 coolDownTime = 86400 seconds;

  mapping(address => bool) public whitelist;
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  mapping (address => userStruct) users;
  address[] public userAccts;
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  /// @notice modifies any function it gets attached to, only allows the owner of the smart contract to execute the function
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
  

  /// @notice Contains all the variables that make up a user and is directly tied to the Users mapping defined above
  struct userStruct {
    uint userAllowance;
    uint userCoolDown;
    bool userInitiliased;
  }
    
  /// @notice modifies any function it gets attached to, only allows the addressed in the list of white addresses to execute the function
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /// @notice enables the Smart Contract to accept deposits of ethereum
  function() public payable { }
    
  /// @return The users that have been active in the Smart Contract
  function getUsers() view public returns (address[]) {
    return userAccts;
  }

  /// @param ins The address of the recipient
  /// @return The Allowance, Cooldownperiod & whether a use has succesfully initialised all his varaibles for a specific address
  function getUser(address ins) view public returns (bool, uint, uint) {
    return (users[ins].userInitiliased, users[ins].userCoolDown, users[ins].userAllowance);
  }
    
  /// @return The current balance of the Smart Contract
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
  
  /// @notice The initialiseValues function is in charge of giving users an open passage and initialises all of the variables they need; Allowance and Cooldowm
  function initialiseValues() public{
    receiver = msg.sender;
    userStruct storage individualUser = users[receiver];
    
    if (individualUser.userInitiliased == true){
      return;
    }

    if(individualUser.userInitiliased == false && individualUser.userCoolDown<=now){
      individualUser.userInitiliased = true;
      individualUser.userCoolDown = 0;
      individualUser.userAllowance = AllowanceDay;
      userAccts.push(msg.sender);
    }
  } 
  
  /// @notice initialises the cool down for the individual address that triggered it once a user has reached its daily allowance it will be logged of the system and not allowed to withdraw until the cool off period has finished.
  function _triggerCooldown() public{   
    receiver = msg.sender;  
    userStruct storage individualUser = users[receiver];
    dayCooldown = now + coolDownTime;
    individualUser.userInitiliased = false;
    individualUser.userCoolDown = dayCooldown;
    individualUser.userAllowance = 0;
  }
      
  /// @notice Allows the Owner of the Smart Contract to dynamicaly set the maxium amount non-whitelisted users will be able to withdraw.
  /// @param _Allowance the allowance the owner wants to set for each user
  function _setAllowance(uint _Allowance) external onlyOwner{ 
    AllowanceDay = _Allowance;
  }
    
  /// @notice This function treats addresses independently of their status, every address can withdraw money(within the parameters), and all they have to do is specify the amount. 
  /// @notice Both the owner and Whitelisted user will get a cooldown period, if they wish to withdraw more they should do so in their respective functions.
  /// @param _Amount specifies the amount to be withdrawn to the users address.  
  function withdraw(uint _Amount) public{
    receiver = msg.sender;
    userStruct storage individualUser = users[receiver];
    
    /// @notice This &#39;if&#39; statement functions as a fail safe. In case a user has forgotten to initialiseValues.     
    if (individualUser.userInitiliased == false){
      initialiseValues();
    }
    
    /// Requires the cooldown to not be active, the balance in the contract to be greater than the withdrawal amount and the amount to be withdrwn to be less than or equal to the 
    require(
            now >= individualUser.userCoolDown &&
            address(this).balance >= _Amount &&
            individualUser.userAllowance >= _Amount &&
            individualUser.userInitiliased == true
            );
            
    /// Subtract the withdrwal from the address allowance
    individualUser.userAllowance -= _Amount;
     
    /// Transfer the funds from the smart contract to the user&#39;s address
    receiver.transfer(_Amount);
        
    /// In case the allowance is depleted the Cooldown should be triggered.
    if(individualUser.userAllowance == 0){
        _triggerCooldown();  
    }
  }
  
  /// @notice This is the withdrwal function for all the whitelisted addresses, it&#39;s not subject to cool downs or limits
  /// @param _Amount The amount to be withdrawn
  function withdrawWhiteList(uint _Amount)external onlyWhitelisted{
    receiver = msg.sender;
    receiver.transfer(_Amount);
  }
  
  /// @notice Allows the Owner of the Smart Contract to dynamicaly add new whitlisted addresses to the list.
  /// @param addr The address to be whitelisted
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  /// @notice Allows the Owner of the Smart Contract to dynamicaly remove new whitlisted addresses to the list.
  /// @param addr The address to be whitelisted  
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }
    
  /// @notice withdraw all the funs from the smart contract into the owners address
  function withdrawAll() external onlyOwner{
    require(address(this).balance > 0);
    owner.transfer(address(this).balance);
  }
  
  /*    
  /// @notice Destroy the contract, bad idea to have this activated so its commented out 
  function killAllowanceContract() external onlyOwner returns (bool) {
    selfdestruct(owner);
    return true;
  }*/
}