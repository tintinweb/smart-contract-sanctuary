pragma solidity ^0.4.21;

contract Ownable {
    //Owner address
    address public owner;
    
    //event transfer ownershipp
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    //set modifier only owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //transfer of ownership
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract NestEgg is Ownable{
    //variable for contract address
    string public userData;

    constructor() public {
    }   
    
    // return current balance
    function getCurrentAddress() public view returns (address){
        return address(this);
    }
   
    //set data to  smart-contract(for data) 
    function setData(string _userData) public onlyOwner  returns (bool){
        userData = _userData;
        return true;
    }

    
    //return smart-contract(for data) address
    function getData() public view returns(string){
        return userData;
    }

    //destruct smart-contract and withdrawing eteher to owner
    function ownerKill() public onlyOwner {
        selfdestruct(owner);
    }

}