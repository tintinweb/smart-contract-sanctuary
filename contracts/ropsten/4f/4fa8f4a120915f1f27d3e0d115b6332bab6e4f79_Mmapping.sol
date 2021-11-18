/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract Mmapping{
    uint256 counter = 0;
    address owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    mapping(uint=>Person) public peoples;
    
    struct Person
    {
        uint _id;
        string _firstName;
        string _secondName;
        bool marry;
        uint _year;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    function AddPerson(string memory firstName, string memory secondName, bool marry, uint year) public onlyOwner{
        Increment();
        peoples[counter] = Person(counter,firstName,secondName, marry, year);
        
    }
    
    function Increment() internal
    {
        counter++;
    }
    
}