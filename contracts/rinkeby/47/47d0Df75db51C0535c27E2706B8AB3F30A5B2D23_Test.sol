/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.7;

contract Test {
    event Done(address sender);
    
    address public constant sender = 0x30FDD607EbaE817eD92a1Fa735334A1aa78E99EB;
    
    function send() external {
        require(msg.sender == sender, "Go nah");
        emit Done(msg.sender);
    }
}