// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Student {

    string private constant name ="jack";
    uint256 private constant age = 12;
    string private constant sex = "man";
    
    event set_event(string name, uint256 age,string _sex);

    function set(string memory _name, uint256 _age,string memory _sex) public {
        emit set_event(_name,_age,_sex);
    }

}