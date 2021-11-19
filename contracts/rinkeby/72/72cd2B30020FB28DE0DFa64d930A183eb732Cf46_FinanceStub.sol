/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;



// File: FinanceStub.sol

contract FinanceStub {
    event Payment(address indexed _token, address indexed _receiver, uint256 _amount, string _reference);

    function newImmediatePayment(
        address _token,
        address _receiver,
        uint256 _amount,
        string memory _reference
    ) public {
        emit Payment(_token, _receiver, _amount, _reference);
    }
}