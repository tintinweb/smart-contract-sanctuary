pragma solidity ^0.4.25;

/*
TODO
Add a constructor that triggers the cool down every 24 hours and resets the allowance.
*/


contract structSecond{
    address public owner;
    address public receiver;
    address ledger;
    uint AllowanceDay = 10000000000000000 wei;
    uint dayCooldown;
    uint64 coolDownTime = 86400 seconds;
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    mapping (address => userStruct) Users;
    address[] public userAccts;

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

  struct userStruct {
    uint userAllowance;
    uint userCoolDown;
    bool userLogin;
  }

  function getUsers() view public returns (address[]) {
        return userAccts;
  }

  function getUserAllowance(address ins) view public returns (uint) {

      return (Users[ins].userAllowance);
  
  }
  function getUserCoolDown(address ins) view public returns (uint) {

      return (Users[ins].userCoolDown);
  
  }
  function getUserLogin(address ins) view public returns (bool) {

      return (Users[ins].userLogin);
  
  }

  function Login() public{
    var User = Users[msg.sender];
    if (User.userLogin == true){
      return;
    }
    if(User.userLogin == false){
      User.userLogin = true;
      User.userCoolDown = 0 ;
      User.userAllowance = AllowanceDay;
      userAccts.push(msg.sender) -1;
    }
  }

  function getBalance() public view returns (uint256) {
        return address(this).balance;
  }

  //Allows the owner to  set the allowance for every day
  function _setAllowance(uint _Allowance) external onlyOwner{ 
        AllowanceDay = _Allowance;
  }

  //The user excuting the withdrawal function will be in charge of setting up the amount desired to withdraw up to the AllowanceDay limit of course.
  function withdraw(uint _Amount) public{
        var User = Users[msg.sender];
        receiver = msg.sender;
        var userAllowance = getUserAllowance(receiver);
        var userCoolDown = getUserCoolDown(receiver);
        var userLogin = getUserLogin(receiver);

        if (userLogin == false){
          Login();
        }

        if (userAllowance != 0 && now >= userCoolDown){
            require(now >= userCoolDown && address(this).balance >= _Amount && userAllowance >= _Amount);
            receiver.transfer(_Amount);
    
            //We have to make sure the withdrawal is subtracted from the daily allowance.
            User.userAllowance = AllowanceDay - _Amount;
             
            //We also have to make sure that the cool down is triggered when the allowance hits 0
            if(User.userAllowance == 0){
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
        var User = Users[msg.sender];
        
        dayCooldown = now + coolDownTime;
        
        User.userCoolDown = dayCooldown;
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