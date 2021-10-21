/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PaymentManager {

    address private team1 = 0xf33dE3a660aeC91a68B1880F0Fd9c5460d53d3B3;
    address private team2 = 0x0c5cE143B093426BF200444787E9Ee3382fDa4f2;
    uint256 split1 = 8500;
    uint256 split2 = 1500;

    function splitFunds() public {
        uint256 total = address(this).balance;
        uint256 share1 = total*split1/10000;
        uint256 share2 = total*split2/10000;
        require(payable(team1).send(share1));
        require(payable(team2).send(share2));
    }

    receive() payable external {}
}