pragma solidity ^0.4.25;

contract Owned{
    address public owner;
    bool public ownershipTransferAllowed=false;
    
    constructor() public{
        owner=msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    function allowTransferOwnership(bool flag) public onlyOwner{
        ownershipTransferAllowed=flag;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner !=0x0);
        require(ownershipTransferAllowed);
        owner=newOwner;
        ownershipTransferAllowed=false;
    }
}