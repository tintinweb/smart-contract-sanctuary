/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;

contract MyContract{
    uint256 peopleCount = 0;
    uint256 startTime;
    mapping (uint256 => Person) public people;
    function incrementCount() internal{
        peopleCount +=1;
    }
    struct Person{
        uint _ID;
        string _FirstName;
        string _LastName;
        uint256 _Age;
        bool _Married;
    }
    
    constructor() public{
        startTime = 1637257330;
    }
    modifier onlyWhileOpen(){
        require(block.timestamp >= startTime);
        _;
    }
    function AddPerson(string memory FirtsName, string memory LastName, uint256 Age, bool Married) public onlyWhileOpen{
       people[peopleCount] = Person(peopleCount, FirtsName, LastName, Age, Married);
       incrementCount();
    }
}