/**
 *Submitted for verification at polygonscan.com on 2021-09-20
*/

pragma solidity ^0.8.0;
/**
* @title Bounties
* @author Joshua Cassidy- <[email protected]>
* @dev Simple smart contract which allows any user to issue a bounty in ETH linked to requirements
* which anyone can fulfil by submitting the evidence of their fulfilment
*/
contract HelloWorld {
    
    string message;

    constructor(string memory msg) public {
        message = msg;
    }

    function setMesasge(string memory msg) public {
        message = msg;
    }
    
    function getMesasge() public view returns (string memory)
    {
        return message;
    }

}