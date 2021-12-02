/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.9;

struct PackedOrNah {
    uint128 first;
    uint128 second;
}

contract Packed {

    event Nice(PackedOrNah);

    function nice() public {
        PackedOrNah memory pon;
        pon.first  = 69;
        pon.second = 420;
        emit Nice(pon);
    }
}