// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./Ownable.sol";
import "./ERC20.sol";

/**
  * @title SAFE2 Token
  * @dev SAFE2 Mintable Token with migration from legacy contract. It is used as an in-between for COVER.
  */
contract Safe2 is Ownable, ERC20 {
    using SafeMath for uint256;

    address public minter;

    constructor() ERC20("SAFE2", "SAFE2") public {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "!minter");
        _;
    }

    function setMinter(address account) external onlyOwner {
        minter = account;
    } 

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}