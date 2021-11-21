/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Prashanth_Storage {

    uint256 number1;
    uint256 number2;

    /**
     * @dev Store value in variable
     * @param num1 value to store
     */
    function store(uint256 num1, uint256 num2) public {
        number1 = num1;
        number2 = num2;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve_num1() public view returns (uint256){
        return number1;
    }
    
    function retrieve_num2() public view returns (uint256){
        return number2;
    }
}