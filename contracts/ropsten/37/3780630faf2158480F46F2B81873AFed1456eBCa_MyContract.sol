/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.7.4;

contract MyContract {
    
    string public Stringvalue = 'myvalue';
    bool public myBool = true;
    int public myint = -1;
    uint public myuint = 1;
    uint8 public myuint8 = 8;
    uint256 public myunit256 = 9999;
    enum State { waiting, ready, active }
    State public state;
    
    uint256 public peoplecount;
    Person[] public people;
    mapping(uint => Person) public mappeople;
    
    
   constructor() {
       state = State.waiting;
       Stringvalue = 'myvalue';
   }
   

   struct Person {
       uint _id;
       string _firstname;
       string _lastname;
       
   }
   
   function addperson(string memory _firstname, string memory _lastname) public {
       people.push(Person(peoplecount, _firstname, _lastname));
       peoplecount++;
   }
   function addmapperson(string memory _firstname, string memory _lastname) public {
       mappeople[peoplecount] = Person(peoplecount, _firstname, _lastname);
       peoplecount++;
   }
    
    // no longer needed because Stringvalue is public
    // function get() public view returns(string memory){
    //     return Stringvalue;
    // }
    
    function set(string memory _value) public {
        Stringvalue = _value;
    }
    
    // enumerated lists
    function activate() public {
        state = State.active;
    }
    
    function isactive() public view returns (bool) {
        return state == State.active;
    }
    
    
}