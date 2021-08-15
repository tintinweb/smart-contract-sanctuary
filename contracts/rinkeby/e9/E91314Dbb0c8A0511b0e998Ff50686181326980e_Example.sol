/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// File: Example.sol

contract Example {

    event WithDrawToManyReceiver(address indexed caller, uint amount);
    uint public myEth;

    function dep(uint _amountToBeSend) public payable {
        _amountToBeSend;
    }

    struct PaymentReceiver {
        address receiver;
        uint amount;
    }

    struct Info {
        PaymentReceiver[] receiver;
        uint amount;
        string toEmit;
        bool isEmit;
    }

    function withDrawWithInfomation(Info memory info) public {
        for(uint i = 0; i < info.receiver.length; i++) {
            (bool success, ) = info.receiver[i].receiver.call{value: info.receiver[i].amount}(new bytes(0));
            require(success, "!withdraw");
        }
        (bool success, ) = msg.sender.call{value: info.amount}(new bytes(0));
        require(success, "!withdraw");
        if (info.isEmit) {
            emit WithDrawToManyReceiver(msg.sender, info.amount);
        }
    }

}