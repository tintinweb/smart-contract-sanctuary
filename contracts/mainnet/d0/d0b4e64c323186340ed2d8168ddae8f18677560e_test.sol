pragma solidity ^0.4.24;

contract test {
    
    function sub1(uint256 _a, uint256 _b) public pure returns (uint256 result) {
        require(_a >= _b);
        return _a - _b;
    }
    
    function sub2(uint256 _a, uint256 _b) public pure returns (uint256 result) {
        require(_a >= _b, "_a cannot be less than _b");
        return _a - _b;
    }
    
}