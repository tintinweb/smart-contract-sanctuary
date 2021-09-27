/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract DelegateCaller {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _address, uint _num) public payable {
        (bool sent, bytes memory data) = _address.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}