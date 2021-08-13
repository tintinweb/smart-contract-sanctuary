/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.3;



// File: Weird.sol

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract Weird {

    event WithDrawToManyReceiver(address indexed caller, uint amount);
    uint public myEth;

    function depositionEtherNamingWeird(uint _amountToBeSend) public payable {
        myEth += address(this).balance - _amountToBeSend;
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