/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.8.4;

contract Helloworld {
    
    string public message;
    address public owner;
    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
    }
    function hello() public view returns (string memory){
        return message;
    }
    function setMessage(string memory _message) public payable {
        require(msg.sender == owner);
        message = _message;
    }
}