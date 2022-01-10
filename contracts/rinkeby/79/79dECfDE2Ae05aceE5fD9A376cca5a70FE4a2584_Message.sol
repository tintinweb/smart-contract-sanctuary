pragma solidity ^0.8.0;

contract Message{
      mapping(address => string) message;
      function send_message(address receiver_address,string memory _message) public {
            message[receiver_address] = _message;
      }
      function retrieve_message(address receiver_address) public view returns(string memory){
            return message[receiver_address];
      }
}