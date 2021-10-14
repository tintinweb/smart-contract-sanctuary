// SPDX-License-Identifier: MIT

pragma solidity 0.8.0; 

import "./ERC20.sol";
import "./IERC20.sol";


contract Nutra is ERC20 {
    
    address public deployer;
    constructor() ERC20("NUTRA", "NUTRA" ) {
        _mint(msg.sender, 100000000 * (10 ** decimals()));
        deployer = msg.sender;
    } 
}