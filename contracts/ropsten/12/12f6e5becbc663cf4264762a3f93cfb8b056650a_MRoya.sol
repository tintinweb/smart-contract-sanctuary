// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC20.sol";
contract MRoya is ERC20 {
    
    constructor(address _recipient) public ERC20("mRoya Token", "mRoya") {
        _mint(_recipient, 100000000000000000000000000000);
    }
    
}