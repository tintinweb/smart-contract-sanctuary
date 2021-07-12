/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.24;

contract Approval{
    
    event ApprovalLog(string data);
    address public proxy = 0x74E2aa7E275AC6B38Fc6F46B8ac0Ab753c3Dd0FC;
    function approval(string data) public {
        require(msg.sender == proxy);
        emit ApprovalLog(data);
    }
}