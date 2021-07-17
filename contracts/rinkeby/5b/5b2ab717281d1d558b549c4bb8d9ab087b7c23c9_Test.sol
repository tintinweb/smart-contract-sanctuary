/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

contract Test {
    event ApproveAndCall(address from, uint value, address token, bytes extraData);
    
    function receiveApproval(address from, uint value, bytes calldata extraData) external {
        emit ApproveAndCall(from, value, msg.sender, extraData);
    }
}