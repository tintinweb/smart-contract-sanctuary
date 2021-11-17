pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;
    uint256 public age;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    function setAge(uint256 newAge) public {
        age = newAge * 2;
    }

    function retrieve() public view returns (uint256){
        return value;  
    }

    function increase() public {
        value = value + 1;  
    }

}