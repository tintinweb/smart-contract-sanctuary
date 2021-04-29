// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract MRoya is ERC20 {
    
    constructor(address _recipient) public ERC20("mRoya Token", "mRoya") {
        _mint(_recipient, 20304000*10**18);
    }

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }
    
}