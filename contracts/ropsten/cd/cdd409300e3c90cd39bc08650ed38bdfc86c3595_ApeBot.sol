/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

library Types {

    struct AccountInfo {
        address owner;
        uint256 number;
    }
}


interface IApeBot {
    function smallApeCallback(bytes calldata data) external payable;
    function callFunction(address sender, Types.AccountInfo memory accountInfo, bytes memory data) external;

}

interface ApeBank {
    function flashApe(address payable callTo, uint256 flags, bytes calldata params) external payable;
}

contract ApeBot is IApeBot {
    
    address payable owner;
    
    ApeBank bank = ApeBank(0x00000000454a11ca3a574738C0aaB442B62D5D45);
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function transferTo(address payable to) external {
        require(to == owner);
        uint value = address(this).balance;
        to.transfer(value);
    }
    
    function smallApeCallback(bytes calldata data) external override payable {
        address localAddress = address(this);
        bank.flashApe{value: 0}(payable(localAddress), 0x0, "");
    }

    function kill() external { 
        if (msg.sender == owner) selfdestruct(owner); 
    }
    
    function callFunction(address sender, Types.AccountInfo memory accountInfo, bytes memory data) external override {
        
    }

    
}