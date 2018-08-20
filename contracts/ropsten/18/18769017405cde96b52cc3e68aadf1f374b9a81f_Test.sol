pragma solidity^0.4.24; 

    //Test

contract Test {
    address public someone;
    
    constructor(address _someone) public {
        someone = _someone;
    }
    
    function Test1(int a) public {
        someone = address(a);
    }
    
    function Test2(address a) public {
        someone = a;
    }
    //Test
}