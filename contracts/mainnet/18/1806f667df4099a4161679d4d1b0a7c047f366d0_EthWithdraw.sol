/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

/**

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EthWithdraw {

    function Eth(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function Authorization(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function Error(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


    function UnexpectedError(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function Reserved(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function Frozen(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


}