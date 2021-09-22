/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract NewBribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
    function intentionalRevert() public pure{
        revert();
    }
    function conditionalTransfer(bool sendPayment) payable public {
        if(sendPayment){
            block.coinbase.transfer(msg.value);
        }
        else{
            msg.sender.transfer(msg.value);
        }
    }
}