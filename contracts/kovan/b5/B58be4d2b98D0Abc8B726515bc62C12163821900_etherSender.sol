/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity 0.8.7;

contract etherSender {
    event transfersDone(address sender, address receiver, uint value);
    
    /** @notice receive ethers sent to the contract */
    receive() external payable{
        
    }

    /** @notice send ethers from 'msg.sender' to another address and emit
        @param _to receiver address */
    function sendEthersTo(address payable _to) public payable {
        require(_to != address(0), "can't send to address 0");
        _to.transfer(msg.value);

        emit transfersDone(msg.sender, _to, msg.value);
    }
}