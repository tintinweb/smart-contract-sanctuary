pragma solidity ^0.4.24;
contract SimpleContract {
    
    address owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    
    function calculateSha3(string a) internal pure returns(bytes32){
        return keccak256(abi.encodePacked(a));
    }
    
}