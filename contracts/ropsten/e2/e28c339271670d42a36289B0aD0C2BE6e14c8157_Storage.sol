/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
 
contract Storage {
 
    uint256 number;
    event AddData(uint256 Number, address Sender);
 
    function setData(uint256 _a)public {
        number = _a;
        emit AddData(number, msg.sender);
    }
 
    function viewData() public view returns(uint256) {
        return number;
    }
 
}