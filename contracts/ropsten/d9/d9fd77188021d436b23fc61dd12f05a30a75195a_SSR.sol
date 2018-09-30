pragma solidity ^0.4.25;

contract SSR {
    address public owner1;
    address public owner2;
    
    constructor(address _addr1, address _addr2) public {
        owner1 = _addr1;
        owner2 = _addr2;
    }
}