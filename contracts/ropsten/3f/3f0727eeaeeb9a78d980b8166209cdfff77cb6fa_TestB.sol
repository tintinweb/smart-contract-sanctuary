/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity 0.8.7;

interface TestA{
    function call1(uint _val) external returns (address);
}

contract TestB {
    address public immutable owner;
    address public constructor_call1;
    
    address public last_caller_A;
    address public last_caller_B;
    uint public last_value;
    TestA constant _testA = TestA(0x1b78BAa0f107a2aC42A9BbD688778c8343953F09);
    
    constructor(){
        owner=msg.sender;
        constructor_call1=_testA.call1(1);
        last_value=1;
    }
    
    function update() external returns(address){
        last_value++;
        last_caller_B=msg.sender;
        last_caller_A=_testA.call1(last_value);
        return msg.sender;
    }
}