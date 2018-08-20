pragma solidity^0.4.24; 

contract Test {
    address public someone;
    address public other;
    
    constructor(address _someone) public {
        someone = _someone;
    }
    
    function Test1(int a) public {
        someone = address(a);
    }
    
    function Test2(address a) public {
        someone = a;
    }
    
    function Test3(address a) public {
        other = a;
    }
}