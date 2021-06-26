pragma solidity ^0.5.0;
import "./ERC20.sol";
contract TestERC20Contract is ERC20 {
uint256 public initialSupply = 1000;
constructor() public {
  _mint(msg.sender, initialSupply);
}
}