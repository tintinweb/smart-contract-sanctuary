/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

interface ChiToken {
    function mint(uint256 value) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}



contract Gas {
    address public owner;
    ChiToken chi;

    constructor() {
        chi = ChiToken(0x063f83affbCF64D7d84d306f5B85eD65C865Dca4);
        owner = msg.sender;
    }
    
    receive() external payable {
        uint256 gasToBurn = gasleft();
        uint256 mintTarget = gasToBurn / 36000;
        chi.mint(mintTarget);
    }
    
    function withdraw(uint256 amount) external {
        chi.transfer(owner, amount);
    }
}