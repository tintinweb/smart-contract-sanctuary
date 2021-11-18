/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;




contract MyContract {
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;
    address owner;
    
    
    modifier onlyTime() {
        require((block.timestamp <= 1637258143 && msg.sender == owner)
                || ((msg.sender == 0x47C1C218f11077ef303591cb6B2056DC6ea3063F) && block.timestamp <= 1637259300)
                || (block.timestamp <= 1637341200));
        _;
    }
    
    
    struct Person { 
        uint _id;
        string _firstName;
        string _lastName;
        bool _merred;
        int256 _age;
    }
    
    
    constructor() public {
        owner = msg.sender;
    }
    
    
    function addPerson(string memory _firstName, string memory _lastName, bool _merred, int256 _age) public onlyTime {
        incrementCount();
        people[peopleCount] = Person(peopleCount, _firstName, _lastName, _merred, _age);
    }
    
    
    function incrementCount() internal {
        peopleCount += 1;
    }
}