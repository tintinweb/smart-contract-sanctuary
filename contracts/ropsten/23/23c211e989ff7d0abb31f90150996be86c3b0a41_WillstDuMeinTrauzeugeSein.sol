/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract WillstDuMeinTrauzeugeSein {

    bool public antwort;
    bytes32 private hash = 0xfaf55b1536272eebbe94a472b1150dae399e9f12b3a83c6f8f5069f111545aab;

    function ja (string calldata geheimnis) public {
        require(sha256(bytes(geheimnis)) == hash);
        antwort = true;
    }

}