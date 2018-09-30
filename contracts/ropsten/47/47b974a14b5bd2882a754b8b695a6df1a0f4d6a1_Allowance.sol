pragma solidity ^0.4.25;

/*
TODO
Add a constructor that triggers the cool down every 24 hours and resets the allowance.
*/


contract Allowance{
    address public owner;
    address ledger;
    uint AllowanceDay = 10000000000000000 wei;
    uint dayCooldown;
    uint _Amount;
    uint64 coolDownTime = 86400 seconds;
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);


  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  function Ownable() {
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
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist 
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist, 
   * false if all addresses were already in the whitelist  
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist, 
   * false if the address wasn&#39;t in the whitelist in the first place 
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist, 
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }


    function _triggerCooldown() public onlyOwner{
      dayCooldown = now + coolDownTime;
    }

    //White listed addresses will be able to withdraw all the money into their address
    function withdrawAll() external onlyOwner{
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
    }

    //White listed addresses will be able to withdraw all the money they want into their address
    //The decision was made to net whitelisted users have an effect on the overall allowance for normal users and it does not trigger the cooldwon either
    function withdrawOwner(uint _Amount) external payable onlyWhitelisted{
          ledger.transfer(_Amount);
    }

    //The user excuting the withdrawal function will be in charge of setting up the amount desired to withdraw up to the AllowanceDay limit of course.
    function withdraw(uint _Amount) public{
          require(now >= dayCooldown && address(this).balance >= AllowanceDay);
          ledger.transfer(_Amount);

          //We have to make sure the withdrawal is subtracted from the daily allowance.
          AllowanceDay = _Amount - AllowanceDay;
         
          //We also have to make sure that the cool down is triggered when the allowance hits 0
          if(AllowanceDay == 0){
            _triggerCooldown();  
          }
  }

    //Allows the owner to  set the allowance for every day
    function _setAllowance(uint _Allowance) external onlyOwner{ 
          AllowanceDay = _Allowance;
    }

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