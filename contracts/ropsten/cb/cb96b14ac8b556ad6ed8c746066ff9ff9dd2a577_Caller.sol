/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCalltransferERC20Tokens(address _addr, address recipient, uint256 amount) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount)
        );

        emit Response(success, data);
    }
    
    function testDelegateCalltransferERC20Tokens(address _addr, address recipient, uint256 amount) public {
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount)
        );
        emit Response(success, data);
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    
}