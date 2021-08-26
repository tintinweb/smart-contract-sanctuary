/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Antwort {
    
    bytes32 private hash = 0xce1ecd20c81b581163c589b41e98e7d535bcffe3060550cbfb3e082c48cf05a1;
    bool private geantwortet = false;
    string public frage = "Willst du mein Trauzeuge sein?";
    string public antwort;
    
    function antworten (string calldata geheimnis, string calldata _antwort) public {
        require(hash == sha256(bytes(geheimnis)));
        require(!geantwortet);
        antwort = _antwort;
        geantwortet = true;
    }
    
}