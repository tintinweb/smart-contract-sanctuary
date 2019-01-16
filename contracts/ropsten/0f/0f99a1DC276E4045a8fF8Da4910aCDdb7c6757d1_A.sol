pragma solidity ^0.4.0;

contract A {
    bool locked = false;
    address addr; 
    
    function () payable public {
    }
    
    function unlock(bool b) public {
        locked = b;
    }
    
    function setAddress(address to) public {
        addr = to;
    }
    
    function goodbye(uint key) public {
        if (key == 0x1234567890) {
            selfdestruct(addr);
        }
    }
}