// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";

 contract SSJ20 is ERC20 {
    // constructor() payable ERC20("SSJ20", "#") {
    //     _mint(msg.sender, msg.value);
    // }
    
    constructor(string memory _name, string memory _symbol) payable ERC20(_name, _symbol) {
        _mint(msg.sender, msg.value);
    }
    
    function faucet(address recipient, uint amount) external {
        _mint(msg.sender, amount);
        transfer(recipient, amount);
    }
}