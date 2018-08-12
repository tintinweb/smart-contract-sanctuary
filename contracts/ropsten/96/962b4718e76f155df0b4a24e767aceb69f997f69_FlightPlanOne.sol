pragma solidity ^0.4.21;

// -----------------------------------------------------------------------------------------------
// FlightPlanOne
//
// Ethereum contract for Flight Plan One - Dapp prototyping tool for putting 3 fields 
// onto the blockchain
//
// Flight Plan (theflightplan.io) is a Blockchain Design Suite
// to help you get your ideas off the ground. 
//
//
// (c) Nas Munawar / Gendry Morales. The Flight Plan. 2018. The MIT Licence.
//

contract FlightPlanOne {
    
   string input1;
   string input2;
   string input3;


  /* Define event types used to publish to EVM log */
  event assign(string input1, string input2, string input3, address indexed from, uint txTime);
   
  /* Set the inputs and publish to EVM log */
   function setInputs(string _input1, string _input2, string _input3) public {
       input1 = _input1;
       input2 = _input2;
       input3 = _input3;
       emit assign(_input1, _input2, _input3, msg.sender, now);
   }

   function getLastInput() public constant returns (string, string, string) {
       return (input1, input2, input3);
   }
    
}