/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title HW
 * @dev Simple bank, deposit and withdraw money & retrieve balance
 */
contract HW {

    mapping(address => uint) private balances; 
    address private owner; // owner of the contract
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    /**
     * @dev return balance 
     * @return value of balance of the contract owner
     */
    function balance() public view returns (uint256) {
        /**
         * Only contract owner can ask for the balance
         */
        require(msg.sender == owner, "Caller is not owner");
        return balances[owner];
    }
    
    /**
     * @dev Increase balance by deposit amount
     * @param num value to increase the balance with
     */
    function depositMoney(uint256 num) public {
        /**
         * Only contract owner can ask for the balance
         * Money that you want to deposit should be a positive number
         */
        require(msg.sender == owner, "Caller is not owner");
        require(num > 0, "Number is not positive");
        balances[owner] += num;
    }
    
    /**
     * @dev Decrease balance by withdraw amount
     * @param num value to decrease the balance with
     */
    function withdrawMoney(uint256 num) public {
        /**
         * Only contract owner can ask for the balance
         * Money that you want to withdraw should be a positive number
         * Cannot withdraw more money than available on the balance
         */
        require(msg.sender == owner, "Caller is not owner");
        require(num > 0, "Number is not positive");
        require(balances[owner] >= num, "Not enough money");
        balances[owner] -= num;
    }
}