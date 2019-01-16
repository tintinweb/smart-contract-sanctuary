pragma solidity ^0.4.24;

contract Number {
    uint256 public total;
    
    /**
     * @dev Increase total number
     * @param number uint256 which will be increase the total number
     */
    function increaseNumber(uint256 number) external {
        total += number;
    }
    
    /**
     * @dev Decrease total number
     * @param number uint256 which will be decrease the total number
     */
    function decreaseNumber(uint256 number) external {
        total -= number;
    }
}