/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.4.19;

contract Professor {
    string firstname;
    string lastname;
    uint collegeid;
    address owner;
    
    event ProfessorEv(
       string firstname,
       string lastname,
       uint collegeid 
    );
    
    function _Professor() public {
    	owner = msg.sender; // owner contains the contract creator's address. 
    }
    
    
    function setProfessor(string fname,string lname, uint id) public {
	    firstname = fname;
	    lastname = lname;
	    collegeid = id;
	    emit ProfessorEv(fname, lname, id);
    }
    
    function getProfessor() view public returns(string, string, uint) {
        return (firstname, lastname, collegeid);
    }
}