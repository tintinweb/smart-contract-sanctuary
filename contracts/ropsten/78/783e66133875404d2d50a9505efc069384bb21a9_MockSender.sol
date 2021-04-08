/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.8.2;

contract MockSender {
    receive() external payable{
    }
    function sendTransfer(address payable[] calldata recipient, uint256[] calldata amount) external {
        for(uint256 i = 0; i<recipient.length; i++){
            recipient[i].transfer(amount[i]);
        }
    }

    function sendCall(address payable recipient, uint256 amount) external {
        recipient.call{value:amount}("");
    }

    function ethBalance(address wallet) external view returns(uint256) {
        return wallet.balance;
    }
}