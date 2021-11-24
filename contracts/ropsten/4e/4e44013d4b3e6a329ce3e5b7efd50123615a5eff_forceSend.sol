/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.4.21;

contract forceSend {
    
    address public owner;

    constructor() payable {
        owner= msg.sender;
    }
    function kill(address _destination) public {
        require(owner==msg.sender);
        selfdestruct(_destination);
    }
}