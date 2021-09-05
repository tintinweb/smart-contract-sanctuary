/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PostId{
    string public name;
    string public id;
    
    event create(string name,string id);
    
    function Create(string memory  _name,string memory _id)public {
        name=_name;
        id=_id;
        emit create(_name,_id);
    }
}