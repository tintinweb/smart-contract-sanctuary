/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint){
        return number;
    }
}