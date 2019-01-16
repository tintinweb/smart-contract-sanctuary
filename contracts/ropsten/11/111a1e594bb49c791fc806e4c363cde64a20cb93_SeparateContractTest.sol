pragma solidity >=0.4.22 <0.6.0;

contract SeparateContractTest {
    
    event Print(string _name, uint _value);
    
    constructor() public {
        A(2);
    }
    function A(uint p_param1) public returns (uint ret)  {
        uint input = p_param1+2;
        emit Print("input",input);
        return input;
    }
}
/*
contract Test2 {
    SeparateContractTest test;
    
    function SetTest(address add) public {
        test = SeparateContractTest(add);
    }
    function CallTest() public payable {
        test.A(3);
    }
}*/