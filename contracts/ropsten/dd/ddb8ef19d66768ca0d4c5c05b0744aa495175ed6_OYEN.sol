// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract OYEN is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address tokenOwnerAddress) payable {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;

      _mint(tokenOwnerAddress, totalSupply);
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }

    function getName() public view returns (string memory) {
      return _name;
    }

    function getSymbol() public view returns (string memory) {
      return _symbol;
    }

    function getDecimals() public view returns (uint8) {
      return _decimals;
    }
}