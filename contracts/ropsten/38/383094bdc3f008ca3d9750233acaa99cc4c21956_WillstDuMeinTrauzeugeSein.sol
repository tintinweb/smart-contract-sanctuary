/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract WillstDuMeinTrauzeugeSein {

    bool private antwort;
    bytes32 private hash = 0x44cb61ba64c1b4708acd17c0bc86a0a4eec01308bb674b33ef8d477a5831831a;

    function jaIchWillDeinTrauzeugeSein (string calldata geheimnis) public {
        require(sha256(bytes(geheimnis)) == hash);
        antwort = true;
    }

}