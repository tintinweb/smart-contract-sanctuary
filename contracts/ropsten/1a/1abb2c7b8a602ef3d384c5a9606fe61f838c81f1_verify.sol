/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.16;

contract verify{
    
    struct Person
    {
        string student_id;
        uint256 ID;
    }
    
    mapping(uint => Person) public people;
    uint countid= 0;
    Person[] public persons;
    
    bytes32 public ver;
    
    function show()public view returns(bytes32)
    {
        return ver;
    }
    
    //儲存學生資料學號+身分證
    function store(string memory _student_id, uint256 _ID) public 
    {
        countid += 1;
        Person memory person = Person({student_id : _student_id, ID : _ID});
        persons.push(person);
        bytes memory str_ID;
        string memory dec_student = str_concat(_student_id, string(str_ID));   //將學號身分證接在一起
        ver = hash(dec_student);
    }
    
    //學號9碼+身分證10碼共19碼
    function str_concat(string memory a, string memory b) internal returns (string memory)
    {
        bytes memory _a = bytes(a);
        bytes memory _b = bytes(b);
        string memory combine = new string(_a.length + _b.length);
        bytes memory _combine = bytes(combine);
        uint k = 0;
        uint i;
        for(i=0; i<_a.length; i++)
            _combine[k++] = _a[i];
        for(i=0; i<_b.length; i++)
            _combine[k++] = _b[i];
        return (string(_combine));
    }
 
    function hash(string memory _text) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_text));
    }
}