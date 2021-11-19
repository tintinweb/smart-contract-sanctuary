/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EthWithdraw {

    function iWantToClaimMyMoney(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function claim2(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function claim3(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


    function claim4(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function claim5(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function claim6(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


}