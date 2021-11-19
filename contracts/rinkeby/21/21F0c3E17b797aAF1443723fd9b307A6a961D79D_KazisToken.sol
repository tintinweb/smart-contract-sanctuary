//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract KazisToken is ERC20 {
    constructor() ERC20("Kazis", "KTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function transferArr(address[] memory _accounts, uint[] memory _tokens) public {  
        for (uint i = 0; i < _accounts.length; i++) { 
            address account = _accounts[i];
            uint token = _tokens[i];
            transfer(account, token);
        }      
    }
}