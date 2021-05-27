/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract telephone  {
    
    address toCall;
    
    function setContractAddress(address _toCall) public {
        toCall = _toCall;
    }
    
    function call(address _owner) public returns(bool success){
        (success, ) = toCall.call(abi.encodeWithSignature("changeOwner(address _owner)", _owner));
        return true;
    }
}