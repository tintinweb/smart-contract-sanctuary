/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity 0.8.7;

contract etherSender {
    event transfersDone(address receiver, uint value);
    
    /** @notice receive ethers sent to the contract */
    receive() external payable{
        
    }

    /** @notice send ethers from 'msg.sender' to another address and emit
        @param _to receiver address */
    function sendEthersTo(address payable _to, uint _amount) public {
        require(_amount > 0);
        require(_to != address(0), "can't send to address 0");
        require(_amount <= address(this).balance, "not enough liquidity in contract");
        _to.transfer(_amount);

        emit transfersDone(_to, _amount);
    }
}