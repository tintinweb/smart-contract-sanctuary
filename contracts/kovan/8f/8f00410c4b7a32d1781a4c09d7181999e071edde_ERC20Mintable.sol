// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20Mintable is Ownable, ERC20 {
    address public minter;

    constructor (address minter_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
      minter = minter_;
    }

    function setMinter(address _minter) public onlyMinter {
      minter = _minter;
    }

    modifier onlyMinter() {
        require(minter == _msgSender(), "Only minter can call.");
        _;
    }


    function mint(address account, uint256 amount) onlyMinter public {
        _mint(account, amount);
    }
}