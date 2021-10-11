// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";


contract Ore is ERC20, Ownable {
  mapping (address => bool) public minters;
  mapping (address => bool) public burners;

  // Add this modifier to all functions which are only accessible by the minters
  modifier onlyMinter() {
    require(minters[msg.sender], "Unauthorized Access");
    _;
  }

  // Add this modifier to all functions which are only accessible by the burners
  modifier onlyBurner() {
    require(burners[msg.sender], "Unauthorized Access");
    _;
  }

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  // Add/remove the specified address to the minter groups
  function setMinter(address _address, bool _state) external onlyOwner {
    require(_address != address(0), "Invalid Address");

    if (minters[_address] != _state) {
      minters[_address] = _state;
    }
  }

  // Add/remove the specified address to the burner groups
  function setBurner(address _address, bool _state) external onlyOwner {
    require(_address != address(0), "Invalid Address");

    if (burners[_address] != _state) {
      burners[_address] = _state;
    }
  }

  function mint(address _account, uint256 _amount) external onlyMinter {
    require(_amount > 0, "Invalid Amount");
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external onlyBurner {
    require(_amount > 0, "Invalid Amount");
    _burn(_account, _amount);
  }
}