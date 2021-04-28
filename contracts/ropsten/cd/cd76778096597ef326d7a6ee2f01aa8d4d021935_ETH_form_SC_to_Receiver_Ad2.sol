/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;

contract ETH_form_SC_to_Receiver_Ad2{
    function invest() external payable {
        if(msg.value < 1000){
            revert();
        }
    }
    uint transfer_amount = 0.1 ether;
    address payable[] recipients;
    function sendEther(address payable recipient) external {
    }
}