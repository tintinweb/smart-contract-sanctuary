/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract InternalTxn {
    bool public flag;
    
    function transferValueInternally(address _beneficiary) 
        external
        payable
        returns (bool) 
    {
        flag = _valueTransfer(_beneficiary, msg.value);
        return flag;
    }
    
    function _valueTransfer(
        address _beneficiary,
        uint256 _amount
    ) private returns (bool success) {
        (success, ) = payable(_beneficiary).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}