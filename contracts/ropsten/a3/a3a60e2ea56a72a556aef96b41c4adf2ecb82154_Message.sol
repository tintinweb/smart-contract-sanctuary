/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity >=0.7.0 <0.8.0;

contract Message {

    string message;
    event StoreMessage( address indexed from,  string indexed msg );

    function store(string memory msg_in) public {
        message = msg_in;
        emit StoreMessage(msg.sender, msg_in);
    }

    function retrieve() public view returns (string memory){
        return message;
    }
}