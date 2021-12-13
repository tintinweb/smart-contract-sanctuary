/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity 0.7.6;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MemBlock {

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
}