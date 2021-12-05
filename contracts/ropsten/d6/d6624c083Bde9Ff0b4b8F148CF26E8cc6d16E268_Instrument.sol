/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Instrument {
    string public grantor;
    string public grantee;
    string public legal_description;
    string public city;
    string public state;
    string public country;
    string public acres;

    constructor(string memory _grantor, string memory _grantee, string memory _legal_description, string memory _city, string memory _state, string memory _country, string memory _acres) {
        grantor = _grantor;
        grantee = _grantee;
        legal_description = _legal_description;
        city = _city;
        state = _state;
        country = _country;
        acres = _acres;
    }
}