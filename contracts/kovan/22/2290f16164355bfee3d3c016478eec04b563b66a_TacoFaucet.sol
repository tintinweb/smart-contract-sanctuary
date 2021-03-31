/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.1;


interface Taco {
    function transfer(address to, uint256 amount) external returns (bool);
}


contract TacoFaucet {
    Taco public taco;
    
    constructor(address tacoAddress) {
        taco = Taco(tacoAddress);
    }
    
    function claim(uint256 amount) external {
        taco.transfer(msg.sender, amount);
    }
}