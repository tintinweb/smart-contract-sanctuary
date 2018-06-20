pragma solidity ^0.4.13;

/*
Proxy Buyer
========================
*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract ICOBuyer {

  // Emergency kill switch in case a critical bug is found.
  address public developer = 0xF23B127Ff5a6a8b60CC4cbF937e5683315894DDA;
  // The crowdsale address.  Settable by the developer.
  address public sale = 0x0;
  // The token address.  Settable by the developer.
  ERC20 public token;
  
  // Allows the developer to set the crowdsale and token addresses.
  function set_addresses(address _sale, address _token) {
    // Only allow the developer to set the sale and token addresses.
    require(msg.sender == developer);
    // Only allow setting the addresses once.
    // Set the crowdsale and token addresses.
    sale = _sale;
    token = ERC20(_token);
  }
  
  
  // Withdraws all ETH deposited or tokens purchased by the given user and rewards the caller.

  
  function withdrawToken(address _token){
      require(msg.sender == developer);
      require(token.transfer(developer, ERC20(_token).balanceOf(address(this))));
  }
  
  function withdrawETH(){
      require(msg.sender == developer);
      developer.transfer(this.balance);
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function buy(){
    require(sale != 0x0);
    require(sale.call.value(this.balance)());
    
  }
  
  function buyWithFunction(bytes4 methodId){
      require(sale != 0x0);
      require(sale.call.value(this.balance)(methodId));
  }
  
  function buyWithAddress(address _ICO){
      require(msg.sender == developer);
      require(_ICO != 0x0);
      require(_ICO.call.value(this.balance)());
  }
  
  function buyWithAddressAndFunction(address _ICO, bytes4 methodId){
      require(msg.sender == developer);
      require(_ICO != 0x0);
      require(_ICO.call.value(this.balance)(methodId));
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    
  }
}