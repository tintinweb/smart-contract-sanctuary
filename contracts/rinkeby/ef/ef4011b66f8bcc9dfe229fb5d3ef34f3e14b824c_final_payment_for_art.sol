/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract final_payment_for_art {

    // Mappings of studentNames to flag; Its like a key => value list data type.
    // Public storage variables can be accessed by anyone (solidity creates a getter implicitly), but can't be modified directly.
    mapping (string => string) public buyers;
    
    // Recieves the payment, and also the students name (your students must call this function with their name as a parameter).
    function invest(string memory studentName) external payable {
        
        // check if "studentname" isn't empty.
        require(bytes(studentName).length != 0, "You forgot to specify your student name.");
        
        // check if the payment is 10 eth.
        require(msg.value == 5 ether , "You are either paying too much, or too little.");
        
        // check if the student already bought, by checking if his flag is set in the mapping.
        require(bytes(buyers[studentName]).length == 0, "You already bought the art.");
        
        // set flag for student.
        // While regular string literals can only contain ASCII, 
        // Unicode literals – prefixed with the keyword unicode – can contain any valid UTF-8 sequence (this allows you to use emogis and whatnot).
        // They also support the very same escape sequences as regular string literals. 
        buyers[studentName] = unicode"Mystiko{nice_piece_of_art} 😃";
    }

    //function balance_of() external view returns(uint) {
    //    return address(this).balance;
    //}
}