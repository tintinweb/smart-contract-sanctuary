/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract TodoList{
    
    string[] listMessages;
    address[] listAddress;
    
    function addListItem(string memory _message) external {
        listMessages.push(_message);
        listAddress.push(msg.sender);
    }
    
    function getList() external view returns(address[] memory, string[] memory) {
        return (listAddress, listMessages);
    }
    
    function removeListItem(uint _index) external {
        delete listMessages[_index]; 
        delete listAddress[_index];
    }
    
}