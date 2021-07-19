//SourceUnit: Test.sol

pragma solidity ^0.5.10;

contract TestContract{
    uint256 testNum;
   
    function Add(uint256 Num) public {
        testNum = Num;
    }
    
    function Show() public view returns(uint256) {
        return testNum;
    }
}