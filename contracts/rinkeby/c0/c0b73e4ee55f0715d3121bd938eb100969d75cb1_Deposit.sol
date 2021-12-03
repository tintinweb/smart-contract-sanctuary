/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >0.5.0 < 0.9.0;

contract Deposit{
    receive() external payable{

    }

    fallback() external payable{

    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}