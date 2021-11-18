/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract MyContract {
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;

address sosed;
address vasya;
address switcher;
modifier onlySosed() {
    require(msg.sender == sosed);
    _; }
    
constructor() public{
    sosed = msg.sender;
}
    
struct Person {
    uint _id;
    string _firstName;
    string _lastName;
    bool _marriage;
    uint _age; }

    
function addPerson( string memory _firstName, string memory _lastName, bool _marriage, uint _age ) public onlySosed
{
peopleCount+=1;
people[peopleCount] = Person(peopleCount, _firstName, _lastName, _marriage, _age);
}
}