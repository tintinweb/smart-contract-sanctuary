pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/ERC777.sol";

contract ERC777Mintable is ERC777UpgradeSafe {

  function mint(
    address account,
    uint256 amount
  ) external {
    _mint(account, amount, "", "");
  }

}