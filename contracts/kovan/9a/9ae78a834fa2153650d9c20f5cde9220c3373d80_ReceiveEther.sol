/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract ReceiveEther {
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

    // receive 收款用的函數, msg.data 需要為空
    receive() external payable {}

    // fallback 收款用的函數, msg.data 不為空
    fallback() external payable {}

    // 取得此合約帳號的餘額
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}