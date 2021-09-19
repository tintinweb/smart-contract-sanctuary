/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity ^0.8.7;


// 
interface IHiveOracle {
    function get() external returns (int32);

    function set(int32 value) external;
}

// 
contract HiveOracle is IHiveOracle {
    int32 internal _value = 10;

    constructor()  {
    }

    function get() external override returns (int32) {
        return _value;
    }

    function set(int32 value) external override {
        _value = value;
    }
}