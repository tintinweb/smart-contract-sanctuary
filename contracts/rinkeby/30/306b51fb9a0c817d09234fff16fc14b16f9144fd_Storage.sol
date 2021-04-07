/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.4.23;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
}