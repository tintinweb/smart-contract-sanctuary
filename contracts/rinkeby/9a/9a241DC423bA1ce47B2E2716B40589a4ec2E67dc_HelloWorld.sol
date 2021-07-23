/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.5.0;

contract HelloWorld {
    string public hello = "Hi, BbbbbB";
    
    uint256[] private numbers;
    
    mapping (string => uint256) public keyValueStore;
    mapping (string => bool) public hasValue;
    
    constructor(uint256[] memory initData) public {
        numbers = initData;
    }
    
    //Array numbers
    function pushNumber(uint256 newNumber) public {
        numbers.push(newNumber);
    }
    
    function getNumber(uint256 index) public view returns (uint256) {
        return numbers[index];
    }
    
    function getNumberLength() public view returns (uint256) {
        return numbers.length;
    }
    
    //Mapping Key value store
    function setKeyValue(string memory key, uint256 value) public {
        keyValueStore[key] = value;
        hasValue[key] = true;
    }
    
    //function hashValue(string memory key) public view returns(bool) {
      //  return keyValueStore[key] != 0;
    //}
}