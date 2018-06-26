pragma solidity 0.4.24;

contract Inner {
    uint public state2;
    
    function setState2WithStop(uint sb, uint sa) public  {
        state2 = sb;
        assembly {
            stop()
        }
        state2 = sa;
    }
    
}

contract TestStop {
    
    Inner public inner;
    uint public state1;
    
    constructor() public {
        inner = new Inner();
    }
    
    function setStates(uint s1b, uint s2b, uint s1a, uint s2a) public {
        state1 = s1b;
        inner.setState2WithStop(s2b, s2a);
        state1 = s1a; 
    }
    
    function state2() public view returns (uint) {
        return inner.state2();
    }
}