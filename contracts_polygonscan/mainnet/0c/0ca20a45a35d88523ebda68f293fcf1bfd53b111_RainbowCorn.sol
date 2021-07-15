// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
contract RainbowCorn is ERC20,Ownable,ERC20Burnable {

    constructor () ERC20("RainbowCorn", "RBC") {
        _mint(msg.sender, 900000000000 * (10 ** uint256(decimals())));
    }
    
}