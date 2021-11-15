//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/access/Ownable.sol";

interface StoreInterface {
    function getValue() external returns(uint256);
}

contract Store is StoreInterface {
    //State Variables
    uint256 private value;

    //Events
    event Stored(uint256 indexed _value);

    //Functions
    function storeValue(uint256 _value) external {
        value = _value;
        emit Stored(_value);
    }

    function getValue() external view override returns(uint256) {
        return value;
    }
}

