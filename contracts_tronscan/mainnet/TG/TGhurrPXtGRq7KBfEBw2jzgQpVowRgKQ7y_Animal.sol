//SourceUnit: cat0.8.6.sol

pragma solidity 0.8.6;
contract Animal{
    uint256 public l  = 0;
    address public owner;
    constructor() public{
        l = 1;
        owner = msg.sender;
    }
    function setOwner(address _addr) public returns(bool){
        owner = _addr;
        return true;
    }
    function sleep() public returns (uint256 a){
         a = 1 hours; // a = 3600
    }
    function sleep2() public returns (uint256){
        uint256 a = 1 minutes;
        return a;
    }

    
}
contract Cat{
    function newCat() public returns(Animal addr){
        addr = new Animal();
    }
}