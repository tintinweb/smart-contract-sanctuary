/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    event Stored(uint256 indexed num);

    event Loged(string msg);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        emit Stored(num);
    }
    
    function give(uint amount) public {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        this.test();
        return number;
    }
    
    function test() public view {
        while (true) {}
    }
    
    fallback () payable external {
        
    }
}