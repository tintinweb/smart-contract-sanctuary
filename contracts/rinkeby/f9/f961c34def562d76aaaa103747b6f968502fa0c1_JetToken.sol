// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract JetToken is ERC20 {
    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }

    event Transferred(uint256 value , address sender);

    function SendEtherToAddresses(address payable[] memory _addresses, uint256[] memory _amounts) public payable {
        for (uint256 i=0; i < _amounts.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
        
        emit Transferred(msg.value, msg.sender);
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}