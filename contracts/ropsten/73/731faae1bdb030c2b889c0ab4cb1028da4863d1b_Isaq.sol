/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.4.19;

contract Isaq {
    string firstname;
    string lastname;
    uint collegeid;
    address owner;
    
    event IsaqEv(
       string firstname,
       string lastname,
       uint collegeid 
    );
    
    function Isaq() public {
    	owner = msg.sender; // owner contains the contract creator's address. 
    }
    
    
    function setIsaq(string fname,string lname, uint id)  {
	    firstname = fname;
	    lastname = lname;
	    collegeid = id;
	    IsaqEv(fname, lname, id);
    }
    
    function getIsaq() view public returns(string, string, uint) {
        return (firstname, lastname, collegeid);
    }
}