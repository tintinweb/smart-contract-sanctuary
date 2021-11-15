//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract BoxV3 {
    uint256 private value;
    event ValueChanged(uint256 newValue);

    function init(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }


    function retrieve() public view returns (uint256) {
        return value;
    }
    function increment() public returns (uint256){
        value = value + 1;
        emit ValueChanged(value);
        return value;
    }
    function decrement() public returns (uint256){
        value = value - 1;
        emit ValueChanged(value);
        return value;
    }
}

