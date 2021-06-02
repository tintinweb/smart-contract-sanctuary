/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

contract Counter {
    
    // Total countter for increments
    uint256 public count = 0;
    
    // User's increments
    mapping(address => uint256) public counts;
    
    // Event for increments
    event UserIncrement(address indexed user, uint256 indexed newValue);
    
    /**
     * @dev Increment for user
     * @param amount amount for increments
     */
    function increment(uint256 amount) public {
        require(amount > 0 && amount <= 10, "Amount can be from 1 to 10");
        counts[msg.sender] += amount;
        
        count += 1;
        
        emit UserIncrement(msg.sender, counts[msg.sender]);
    }
    
    /**
     * @dev Get amounts for user
     * @param user address of increments
     * @return Counts
     */
    function getUserCount(address user) public view returns(uint256) {
        return counts[user];
    }
    
    /**
     * @dev Get total Counts
     * @return Counts
     */
    function getTotalCount() public view returns (uint256) {
        return count;
    }
}