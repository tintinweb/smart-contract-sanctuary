/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.0;

contract NewStorage{
    constructor(uint256 _initial){
        number= _initial;
    }
    uint256 number;
    event AddData(uint256 Number, address Sender);
    function satData(uint256 _a) public{
        number = _a;
        emit AddData(number, msg.sender);
    }
    function viewdata()public view returns(uint256){
        return number;
    }

}