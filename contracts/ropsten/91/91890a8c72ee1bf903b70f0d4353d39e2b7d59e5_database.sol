/**
 *Submitted for verification at Etherscan.io on 2021-04-26
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
    
    function create(string memory _student_id, uint256 _ID, uint _mark, string memory _dip_address) public returns (string memory, uint256)
    {
        count += 1;
        Person memory person = Person({student_id : _student_id, ID : _ID, mark : _mark, dip_address : _dip_address});
        persons.push(person);
        return (person.student_id, count); 
    }
    
    function show()public view returns(uint256){
        uint256 i = count;
        return i;
    }
    
    function get_student_id(uint256 num) public view returns (string memory)
    {
        uint256 i;
        for(i=count-1; i>=0; i--)
        {
            if(persons[i].ID == num)
                return (persons[i].student_id);
        }
        return "null";
        
    }
    
    function get_mark(uint256 _ID) public view returns (uint)
    {
        uint256 i;
        for(i=count-1; i>=0; i--)
        {
            if(persons[i].ID == _ID)
                return persons[i].mark;
        }
        return 999;
    }
    
    function get_dip(uint256 _ID) public view returns (string memory)
    {
        uint256 i;
        for(i=count-1; i>=0; i--)
        {
            if(persons[i].ID == _ID)
                return persons[i].dip_address;
        }
        return "mull";
    }
    
}