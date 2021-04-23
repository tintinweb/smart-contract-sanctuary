/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.5.16;

contract database{
    
    struct Person
    {
        string student_id;
        uint256 ID; //last 3 numbers
        uint mark;  //1 or 0
        string dip_address; //IPFS hash
    }
    
    mapping(string => Person) public people;
    
    Person[] public persons;
    
    uint256 count = 0;
    
    function show()public view returns(string memory){
        return persons[0].student_id;
    }
    
    function create(string memory _student_id, uint256 _ID, uint _mark, string memory _dip_address) public returns (string memory, uint256)
    {
        count += 1;
        Person memory person = Person({student_id : _student_id, ID : _ID, mark : _mark, dip_address : _dip_address});
        persons.push(person);
        return (person.student_id, count); 
    }
    
    function get_student_id(uint256 _ID) public returns (string memory)
    {
        uint256 i;
        for(i=count-1; i>0; i--)
        {
            if(persons[i].ID == _ID)
                return (persons[i].student_id);
        }
        return "null";
    }
    
    function get_mark(uint256 _ID) public returns (uint)
    {
        uint256 i;
        for(i=count-1; i>0; i--)
        {
            if(persons[i].ID == _ID)
                return persons[i].mark;
        }
        return 999;
    }
    
    function get_dip(uint256 _ID) public returns (string memory)
    {
        uint256 i;
        for(i=count-1; i>0; i--)
        {
            if(persons[i].ID == _ID)
                return persons[i].dip_address;
        }
        return "mull";
    }
    
}