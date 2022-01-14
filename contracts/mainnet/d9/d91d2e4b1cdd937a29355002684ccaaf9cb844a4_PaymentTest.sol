/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract PaymentTest {

    function makeSplitPayment(address[] memory _addresses, uint256[] memory _amounts) public payable {
         for (uint i = 0; i < _addresses.length; i++){
             payable(_addresses[i]).transfer(_amounts[i]);
         }
    }
}