/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.5.9;
contract file {
event Flag(address indexed _from);
function() external {emit Flag(msg.sender);}
}