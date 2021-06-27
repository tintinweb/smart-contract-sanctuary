/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
/// Invalid balance to transfer. Needed `minRequired` but sent `amount`
/// @param sent sent amount.
/// @param minRequired minimum amount to send.
error InvalidAmount (uint256 sent, uint256 minRequired);
contract TestToken {
    mapping(address => uint) balances;
    uint minRequired;
    
    constructor (uint256 _minRequired) {
        minRequired = _minRequired;
    }
    
    function list() public payable {
        uint256 amount = msg.value;
        if (amount < minRequired) {
            revert InvalidAmount({
                sent: amount,
                minRequired: minRequired
            });
        }
        balances[msg.sender] += amount;
    }
}