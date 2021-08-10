// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "./SafeMath.sol";
import "./Address.sol";

contract EthersTest {
    using SafeMath for uint256;
    using Address for address;

    uint256 private _number;
    address private _owner;

    constructor() {
        _number = 0;
        _owner = msg.sender;
    }

    function number() public view returns (uint256) {
        return _number;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function add(uint256 n) public view returns (uint256) {
        _number.add(n);
        return _number;
    }

    function sub(uint256 n) public view returns (uint256) {
        _number.sub(n);
        return _number;
    }

}