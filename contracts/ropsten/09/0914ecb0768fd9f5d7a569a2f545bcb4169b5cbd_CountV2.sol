pragma solidity ^0.4.25;

contract CountV2 {
    
    uint256 count = 0;
    uint256 addNum = 100;
    uint256 oldCount = 0;
    
    function add() public {
        oldCount = count;
        count = count + addNum;
        
        emit AddTwo(oldCount, addNum, count);
    }
    
    function getCount() public view returns(uint256) {
        return count;
    }
    
    event Add(uint256 _addNumber, uint256 _count);
    event AddTwo(uint256 _oldCount, uint256 _addNumber, uint256 _count);
    
}