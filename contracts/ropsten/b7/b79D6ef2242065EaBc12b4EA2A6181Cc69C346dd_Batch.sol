/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// contracts/TesraBatch.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


interface BaseContract {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Batch {
    constructor () public {}
    // function batchTransfer(address tokenContractAddr, address from, uint256 amount) public {
    //     tokenContractAddr.call(abi.encodeWithSignature('transferFrom(address,address,uint256)', from, msg.sender, amount));
    // }
    
    function batchTransfer2(BaseContract tokenContractAddr, address[] calldata to, uint256[] calldata amount, uint num) public {
        for(uint i=0;i<num;++i){
            tokenContractAddr.transferFrom(msg.sender, to[i], amount[i]);
        }
    }
    
    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    function transferETH() public{
        
    }
}