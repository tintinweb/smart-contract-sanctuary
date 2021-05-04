/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//yeong hea
pragma solidity 0.8.0;

contract Likelion_5 {
     string[] names;
     bytes32 hash;
     
     
      function pushName(string memory _name) public{
          
          if( keccak256(bytes(_name)) != keccak256(bytes("james")) ){
              names.push(_name);
          }
          else if( keccak256(bytes(_name)) != keccak256(bytes("James")) ){
              names.push(_name);
          }
      }
      
      function getName(uint i) public view returns(string memory) {
          return names[i];
      }
    
      
      function hashing(uint iId, uint iPass) public{
          
          hash = keccak256(abi.encodePacked(iId, iPass));
          
      }
      
      function login(uint id, uint pass) public view returns(string memory) {
          string memory log = "Login";
          string memory error = "Error";
          
          bytes32 password = keccak256(abi.encodePacked(id, pass));
          
          if(password == hash) {
              return log;
          }
          else{
              return error;
          }
      }
}