// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract DeepGoToken is ERC20Permit, ERC20Burnable, Ownable {
    constructor(address _owner) ERC20("DeepGo Token", "DGT") EIP712("DeepGo Token", "1") {
        _mint(_owner, 1e8 ether); // Total supply 100 million
        transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}