/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.5.8;

contract Storage {
    uint public val;
constructor(uint v) public {
        val = v;
    }
function setValue(uint v) public {
        val = v;
    }
}

contract Machine {
    Storage public s;
    
constructor(Storage addr) public {
        s = addr;
    }
    
    function saveValue(uint x) public returns (bool) {
        s.setValue(x);
        return true;
    }
function getValue() public view returns (uint) {
        return s.val();
    }
}