//SourceUnit: FakeMedianizer.sol

pragma solidity ^0.5.8;

contract FakeMedianizer {
    uint256 price = 0;
    constructor(uint256 _price) public {price = _price;}
    function read() public view returns (bytes32) {return bytes32(price);}
}