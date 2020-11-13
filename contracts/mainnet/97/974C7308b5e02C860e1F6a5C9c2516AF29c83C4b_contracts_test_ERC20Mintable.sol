pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract ERC20Mintable is ERC20UpgradeSafe {

  function mint(
    address account,
    uint256 amount
  ) external {
    _mint(account, amount);
  }

}