pragma solidity ^0.4.25;

contract CountV1 {
    address forProxy;
    
    uint256 count = 0;
    uint256 addNum = 1;
    
    function add() public {
        count = count + addNum;
        
        emit Add(addNum, count);
    }
    
    function getCount() public view returns(uint256) {
        return count;
    }
    
    event Add(uint256 _addNumber, uint256 _count);
    
}