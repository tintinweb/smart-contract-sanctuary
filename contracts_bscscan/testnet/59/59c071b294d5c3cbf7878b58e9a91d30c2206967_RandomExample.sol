/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

pragma solidity ^0.4.25;

library LibThunderRNG {
    function rand() internal returns (uint256) {
        uint256[1] memory m;
        assembly {
            if iszero(call(not(0), 0x5f163c94E0a94B42B49dD24C139af1d0F274D19b, 0, 0, 0x0, m, 0x20)) {
                revert(0, 0)
            }
        }
        return m[0];
    }
}

contract RandomExample {
    event didWin(bool);
    uint256 public contractBalance;

    constructor() payable {
        contractBalance = uint256(msg.value);
    }

    function betNumber(uint256 bet) payable external returns (bool) {
        if (msg.value < 5) {
            contractBalance = contractBalance + msg.value;

            didWin(false);
            return false;
        }

        uint256 randomNumber = LibThunderRNG.rand();
        if (bet < randomNumber) {
            msg.sender.transfer(msg.value+1);
            didWin(true);

            contractBalance = contractBalance - (msg.value+1);
            return true;
        }

        contractBalance = contractBalance + msg.value;
        didWin(false);
        return false;
    }
}