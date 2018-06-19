pragma solidity ^0.4.20;

contract PLATPriceOracle {

  mapping (address => bool) admins;
  
  // How much Eth you get for 1 PLAT, multiplied by 10^18
  // Default value is the ICO price, make sure you update
  uint256 public PLATprice = 12500000000000;
  
  event PLATPriceChanged(uint256 newPrice);
    
  function PLATPriceOracle() public {
    admins[msg.sender] = true;
  }

  function updatePrice(uint256 _newPrice) public {
    require(_newPrice > 0);
    require(admins[msg.sender] == true);
    PLATprice = _newPrice;
    emit PLATPriceChanged(_newPrice);
  }
  
  function setAdmin(address _newAdmin, bool _value) public {
    require(admins[msg.sender] == true);
    admins[_newAdmin] = _value;   
  }
}