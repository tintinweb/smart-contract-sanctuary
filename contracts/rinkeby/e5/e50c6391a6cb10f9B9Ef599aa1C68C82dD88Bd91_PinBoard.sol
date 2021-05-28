/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity >=0.8.0 <0.9.0;

contract PinBoard {

    address immutable public deployer;
    address public sender;
    string public message;

    constructor() payable {
        deployer = msg.sender;
    }
    
    
    function pin(string calldata newMessage) public {
        message = newMessage;
        sender = msg.sender;
    }
}