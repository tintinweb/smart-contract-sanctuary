/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Mekaverse {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function Mint() external payable {
            require(msg.value == 0.2 ether, "Mekaverse Mint");
    }
    
    function refund() external {
        require(msg.sender == owner, "No");
        msg.sender.transfer(address(this).balance);
    }
    
    function balance() external view returns(uint balanceEth) {
        balanceEth = address(this).balance;
        //Whitelist Sender For Mekaverse Presale Mint
    }
}