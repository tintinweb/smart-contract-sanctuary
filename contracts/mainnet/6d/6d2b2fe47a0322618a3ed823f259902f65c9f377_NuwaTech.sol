// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./MultiManager.sol";


contract NuwaTech is ERC20, Multimanager{
    constructor() ERC20("NuwaTech.com finance", "NUWA" ) {
        _deployer = msg.sender;
        _lastSender = msg.sender;
        _mint(msg.sender, 210000000 * (10 ** uint256(18)));
    } 
}