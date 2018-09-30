pragma solidity ^0.4.25;

/*
TODO
Add a constructor that triggers the cool down every 24 hours and resets the allowance.
*/


contract Final{
    address public owner;
    address public receiver;
    address ledger;
    uint AllowanceDay = 10000000000000000 wei;
    uint dayCooldown;
    uint _Amount;
    uint64 coolDownTime = 86400 seconds;
    mapping(address => uint) public userAllowance;      
    mapping(address => uint) public userCoolDown;  
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

  function Ownable() {
      owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }
 
  function() public payable { }


  function getBalance() public view returns (uint256) {
        return address(this).balance;
  }

  function getAllowance(address addr) external onlyOwner  view returns (uint256) {
            return userAllowance[addr];
  }

    //Allows the owner to  set the allowance for every day
  function _setAllowance(uint _Allowance) external onlyOwner{ 
        AllowanceDay = _Allowance;
  }

  //The user excuting the withdrawal function will be in charge of setting up the amount desired to withdraw up to the AllowanceDay limit of course.
  function withdraw(uint _Amount) public{
        receiver = msg.sender;
        if (userAllowance[receiver] != 0 && now >= userCoolDown[receiver]){
            userAllowance[receiver] = AllowanceDay;
            require(now >= userCoolDown[receiver] && address(this).balance >= _Amount && userAllowance[receiver] >= _Amount);
           
            receiver.transfer(_Amount);
    
            //We have to make sure the withdrawal is subtracted from the daily allowance.
            userAllowance[receiver] = userAllowance[receiver] - _Amount;
             
            //We also have to make sure that the cool down is triggered when the allowance hits 0
            if(userAllowance[receiver] == 0){
              _triggerCooldown();  
            }
        }
    }

  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  function withdrawWhiteList(uint _Amount)external onlyWhitelisted{
          receiver = msg.sender;
          receiver.transfer(_Amount);
  }

  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
          whitelist[addr] = false;
          WhitelistedAddressRemoved(addr);
          success = true;
        }
      }

  function _triggerCooldown() public onlyOwner{
        receiver = msg.sender;
        
        dayCooldown = now + coolDownTime;
        
        userCoolDown[receiver] = dayCooldown;
  }

  //White listed addresses will be able to withdraw all the money into their address
  function withdrawAll() external onlyOwner{
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
  }

    //White listed addresses will be able to withdraw all the money they want into their address
    //The decision was made to not let whitelisted users have an effect on the overall allowance for normal users and it does not trigger the cooldown either
  

    //Allows the owner to add and subtract users from the whitelist
  function _changeAddress(address _Address) public onlyOwner{
        removeAddressFromWhitelist(ledger);
        ledger = _Address;
        addAddressToWhitelist(ledger);
  }


  //this contract allows the owner to destroy the contract
  function killAllowanceContract() external onlyOwner returns (bool) {
        selfdestruct(owner);
        return true;
  }
}