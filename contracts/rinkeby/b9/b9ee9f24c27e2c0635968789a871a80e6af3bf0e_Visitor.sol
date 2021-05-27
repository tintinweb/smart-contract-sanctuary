/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Visitor {
    
    uint id;
    string name;
    string company;
    string addr;

    event reg_event(uint id,string indexed name,string indexed company,string addr);

    function reg(uint _id,string memory _name,string memory _company,string memory _addr) public {
        id      = _id;
        name    = _name;
        company = _company;
        addr    = _addr;
        emit reg_event(_id, _name, _company, _addr);
    }

}