// SPDX-License-Identifier: MIT
// solc -o GDAC --bin --abi --bin-runtime --overwrite GDAC.sol

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

contract GDACToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("GDAC Exchange Token", "GT") {
        _mint(msg.sender, initialSupply);
    }
}