/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Metaverse {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable {
            require(msg.value == 0.2 ether, "Metaverse Mint");
    }
    
    function withdraw() external {
        require(msg.sender == owner, "No");
        msg.sender.transfer(address(this).balance);
    }
    
    function balance() external view returns(uint balanceEth) {
        balanceEth = address(this).balance;
        //Whitelist Sender For Metaverse Presale Mint
    }
}