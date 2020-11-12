pragma solidity ^0.6.0;

abstract contract ERC20 {
  function balanceOf(address account) external view virtual returns (uint256);
  function transfer(address recipient, uint256 amount) external virtual returns (bool);
  function burn(uint256 amount) external virtual returns (bool);
}

contract Presale {
  address payable public owner = msg.sender;
  uint public startBlock = 11221812;
  uint public duration = 120;
  uint public min = 500 finney;
  uint public max = 1000 finney;
  uint public price = 10 finney;
  address public tokenAddress = 0xb3ef3ce629B6E81944f532580806B399Fe6f0Bd0;
  bool finished;
  
  mapping (address => uint) public bought;
  
  receive() external payable {
    require(!finished);
    require(block.number >= startBlock);
    require(msg.value >= min);
    require(msg.value % price == 0);
    require(bought[msg.sender] + msg.value <= max);
    
    ERC20 token = ERC20(tokenAddress);
    
    if (block.number > startBlock + duration) {
      token.burn(token.balanceOf(address(this)));
      finished = true;
    } else {
      bought[msg.sender] += msg.value;
      owner.transfer(msg.value);
      token.transfer(msg.sender, msg.value / price * 1 ether);
    }
  }
}