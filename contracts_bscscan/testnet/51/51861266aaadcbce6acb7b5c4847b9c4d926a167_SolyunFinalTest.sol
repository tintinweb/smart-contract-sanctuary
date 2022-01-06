pragma solidity ^0.4.18;
import "./InvestorsFeature.sol";

contract SolyunFinalTest is Ownable, StandardToken, InvestorsFeature  {
    

  string public constant name = "SolyunDigitalBank";
  string public constant symbol = "SOLY";
  uint8 public constant decimals = 10;
  
  uint256 public constant INITIAL_SUPPLY = 4500000000000000000; // 90,000,000 * 10(decimal) = 900000000000000000
  
  
  
  function SolyunFinalTest() public {
    totalSupply = INITIAL_SUPPLY;
    balances[this] = INITIAL_SUPPLY;
    Transfer(address(0), this, INITIAL_SUPPLY);
  }
  

  
  function send(address addr, uint amount) public onlyOwner {
      sendp(addr, amount);
  }

  function moneyBack(address addr) public onlyOwner {
      require(addr != 0x0);
      addr.transfer(this.balance);
  }
  
  function burnRemainder(uint) public onlyOwner {
      uint value = balances[this];
      totalSupply = totalSupply.sub(value);
      balances[this] = 0;
  }
 
}