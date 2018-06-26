pragma solidity ^0.4.18;

contract C {
    uint[20] x;
    
    function getx() public view returns (uint[20]) {
        return x;
    }

    function nochange() public view {
        g(x);
    }
    
    function change() public {
        h(x);
    }

    function g(uint[20] y) internal pure {
        y[2] = 3;
    }

    function h(uint[20] storage y) internal {
        y[2] = 4;
    }
}