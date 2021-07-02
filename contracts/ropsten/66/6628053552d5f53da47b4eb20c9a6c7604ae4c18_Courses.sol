/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.4.18;

contract Courses {
    address Owner;
    constructor(){
        Owner =msg.sender;
    }
    
    struct Instructor {
        uint amount;
        address _Addr;
        
    }
    
      mapping(address => uint256) private _balances;
    mapping (string => Instructor) instructors;
    string[] public memoSearch;
    
    uint public totalAmount  ;
    
    function setTransfer(address _address, string Memo) payable public {
        require(_address == msg.sender);
        var instructor = instructors[Memo];
        
        instructor.amount = msg.value;
        _balances[msg.sender] -= msg.value;
        instructor._Addr = _address;
        
      
        memoSearch.push(Memo) -1;
        Owner.transfer(msg.value);
        totalAmount += msg.value;
    }
    
    // function getSubmitAddress() view public returns(address[]) {
    //     return memoSearch;
    // }
    
    // function getInstructor(address _address) view public returns (uint, string) {
    //     return (instructors[_address].amount, instructors[_address].memo);
    // }
    
       function getMemoData(string memoval) view public returns (uint, address) {
        return (instructors[memoval].amount, instructors[memoval]._Addr);
    }
    
    function NumberOfInput() view public returns (uint) {
        return memoSearch.length;
    }
    
}


//0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c