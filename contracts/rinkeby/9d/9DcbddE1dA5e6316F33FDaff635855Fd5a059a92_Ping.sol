/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity >=0.8.0 <0.9.0;

contract Ping {

    address immutable public deployer;

    constructor() payable {
        deployer = msg.sender;
    }
    
    
    function ping() public view returns (string memory, address){
        return ("pong", msg.sender);
    }
}