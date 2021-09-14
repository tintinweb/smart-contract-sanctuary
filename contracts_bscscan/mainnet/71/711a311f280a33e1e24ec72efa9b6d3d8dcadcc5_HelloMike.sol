/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// This is a comment

contract HelloMike {
    string name = 'Mike';
    bool isHeMarried = false;
    uint256 age = 26;
    
    function getMike() public view returns(string memory,bool,uint256) {
        return (name,isHeMarried,age);
    }
    
    function setMike(string memory newName, bool newIsHeMarried, uint256 newAge) public {
        name = newName;
        isHeMarried = newIsHeMarried;
        age =  newAge;
    }
}