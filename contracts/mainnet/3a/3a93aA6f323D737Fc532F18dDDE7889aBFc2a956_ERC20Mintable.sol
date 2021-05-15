// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract ERC20Mintable is ERC20, ERC20Burnable, Ownable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        transferOwnership(_owner);
    }

    function mint(address _recipient, uint256 _amount) public onlyOwner {
        _mint(_recipient, _amount);
    }
}