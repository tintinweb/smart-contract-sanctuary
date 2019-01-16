pragma solidity ^0.4.24;

contract B
{
    address private b;
    
    function setB(address v) external {
        b = v;
    }
    
    function getB() external view returns (address) {
        return b;
    }
}

contract A1 is B 
{
    address private a1;
    
    function setA1(address v) external {
        a1 = v;
    }
    
    function getA1() external view returns (address) {
        return a1;
    }
}

contract A2 is B
{
    address private a2;
    
    function setA2(address v) external {
        a2 = v;
    }
    
    function getA2() external view returns (address) {
        return a2;
    }
}

contract A3 is B
{
    address private a3;
    
    function setA3(address v) external {
        a3 = v;
    }
    
    function getA3() external view returns (address) {
        return a3;
    }
}

contract SomeLogic
is A1, A2, A3
{}