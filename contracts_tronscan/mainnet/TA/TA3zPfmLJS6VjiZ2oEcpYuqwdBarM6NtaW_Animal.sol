//SourceUnit: cat.sol

pragma solidity ^0.7.6;

contract Animal{
    uint256 public l  = 0;
    address public owner;
    constructor() public{
        l = 1;
        owner = msg.sender;
    }

}

contract Cat{
    function newCat() public returns(Animal addr){
        addr = new Animal();
    }
}