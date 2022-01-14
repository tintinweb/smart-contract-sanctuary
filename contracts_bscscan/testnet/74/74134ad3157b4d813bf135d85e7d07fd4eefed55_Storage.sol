/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

    function reandom1() public returns(uint) {
        number = uint(keccak256(abi.encodePacked(gasleft())));
        return number;
    }

    function reandom2() public returns(uint) {
        number = uint(keccak256(abi.encodePacked(number + block.timestamp)));
        return number;
    }

    function reandom3() public returns(uint) {
        number = uint(keccak256(abi.encodePacked(number,block.timestamp)));
        return number;
    }

    function reandom4() public returns(uint) {
        number = uint(keccak256(abi.encodePacked(number,gasleft())));
        return number;
    }

}