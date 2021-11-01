//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
    uint[] members;

    function createMembers(uint newMembers) public {
        for(uint i = 0; i < newMembers;i++){
            members.push(1);
        }
    }

    function getMembers(uint numb) public view returns(uint) {
        uint tot = 0;
        for(uint i = 0; tot < numb;i++) {
            tot = tot + members[i];
        }
        return tot;
    }


}