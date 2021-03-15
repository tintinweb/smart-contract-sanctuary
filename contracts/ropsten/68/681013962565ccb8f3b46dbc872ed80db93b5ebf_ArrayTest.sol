/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.4.22 <=0.8.1;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retreive value in a variable
 */
contract ArrayTest {

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
    function retreive() public view returns (uint256){
        return number;
    }
    
    struct Dog{
        string name;
        uint256 age;
    }
    
    Dog[] public dogList;
    
    function getDogList() public view returns(Dog[] memory){
        return dogList;
    }
    
    function addDog() public{
        Dog memory d=Dog("a",12);
        dogList[0]=d;
    }
}