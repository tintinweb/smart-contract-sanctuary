// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";


contract OracleDefi is ERC20 {
    
    address public deployer;
    constructor() ERC20("oracledefi.finance", "ORA" ) {
        _mint(msg.sender, 100000 * (10 ** uint256(18)));
        deployer = msg.sender;
    } 
}