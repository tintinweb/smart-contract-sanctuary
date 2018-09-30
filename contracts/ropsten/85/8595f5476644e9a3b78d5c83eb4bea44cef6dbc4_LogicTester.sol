pragma solidity ^0.4.24;

contract LogicTester {
    
    uint num;
    
    function getNum() external view returns (uint) {
        return num;
    }
    
    function setNum(uint _num) external {
        num = _num;
    }
}