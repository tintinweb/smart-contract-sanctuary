/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ~ splitPaymentSystem
contract SplitPaymentSystem is Context {

//splitPayment any coin
function airdropBNB(address payable[] memory to) payable external {
    for(uint index = 0; index < to.length; index++) {
      to[index].transfer(msg.value);
    }
}}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~