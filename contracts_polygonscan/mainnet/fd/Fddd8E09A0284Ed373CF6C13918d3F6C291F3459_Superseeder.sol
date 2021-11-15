pragma solidity ^0.8.0;

contract Superseeder {
  function seed(
    ERC20 erc20,
    address[] calldata receivers,
    uint256[] calldata amounts
  ) external {
    for (uint256 i = 0; i < receivers.length; i++) {
      erc20.transferFrom(msg.sender, receivers[i], amounts[i]);
    }
  }
}

interface ERC20 {
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);
}