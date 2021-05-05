/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.6.0;

contract Example1 {
    mapping(uint256 => string) MappedValue;
    event changed(uint256 indexed key, string something);
    
    constructor(string memory _a) public {
        MappedValue[0] = _a;
    }
    
    function storeSomething(uint256 _a, string memory _b) public {
        MappedValue[_a] = _b;
        emit changed(_a, _b);
    }
    
    function getSomething(uint256 _a) public view returns (string memory) {
        return MappedValue[_a];
    }
}

contract Factory123456 {
    constructor() public {}
    
    function createNewContract(string memory name) public {
        Example1 a = new Example1(name);
    }
}