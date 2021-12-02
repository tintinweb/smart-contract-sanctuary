/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity ^0.5.16;  
/* It indicates Version of the compiler used to execute the code */
contract MomentNotes { 
    /* contract is a collection of data types ,functions ,methods are written */    
    string public notes; 
    uint public maxLength;
    /*string, uint are datatypes and notes is where our notes is going to be stored and
    maxLength is used for our string length public indicates that it can be accessed by
    any one.*/
    constructor() public { 
        notes = "ENTER NOTES";  
        maxLength = 280;
        /*These are things set initially which can be changed by following functions*/
    }
    /* We use this to initialize data as appropriate.*/
    function setNotes(string memory _notes) public {
        require(bytes(_notes).length <= maxLength, "That notes is too long.");                 
        notes = _notes;   
    }
    /*This is a function and is used to restrict the size of the notes*/ 
    function setMaxLength(uint _maxLength) public {
        maxLength = _maxLength;
    }/* used to set max length of notes*/
}