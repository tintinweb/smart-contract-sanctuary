/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity 0.6.0;

contract FrontRunMe {
    event Received(address, uint);
    
    function claim() public {
        msg.sender.transfer(10000000000000000);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}