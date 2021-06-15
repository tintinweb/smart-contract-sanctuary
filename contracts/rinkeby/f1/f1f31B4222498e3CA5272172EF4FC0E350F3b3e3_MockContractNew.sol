/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MockContractNew {
    address public lastReceiver;

    function _transfer(address payable _reciver, uint amount) public payable {
        _reciver.transfer(amount);

        lastReceiver = _reciver;
    }
}