/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract messageBoard {
    string public message;
    
    constructor() {
        message = "test";
    }
    
    function editMessage(string memory _editMessage) public {
        message = _editMessage;
    }
    function viewMessage() public view returns(string memory) {
        return message;
    }
}