/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Visitor {
    
    string name;
    string company;
    uint256 tel;
    string email;
    string addr;

    event reg_event(string indexed name,string indexed company,uint256 tel,string email,string addr,address owner, uint256 indexed time);

    function reg(string memory _name,string memory _company,uint256 _tel,string memory _email,string memory _addr) public {
        name    = _name;
        company = _company;
        tel     = _tel;
        email   = _email;
        addr    = _addr;
        emit reg_event(_name, _company,_tel, _email, _addr,msg.sender,block.timestamp);
    }

}