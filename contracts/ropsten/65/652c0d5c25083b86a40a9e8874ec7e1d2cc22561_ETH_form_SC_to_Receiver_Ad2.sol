/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;

contract ETH_form_SC_to_Receiver_Ad2{
    uint transfer_amount = 0.1 ether;
    uint transfer_forwarding_one_third;
    address payable owner = 0x3a4442C71b51443D05B8A0FA40C29A645272cbd4;
    function invest() external payable {
        if(msg.value < 1000){
            revert();
        }
        transfer_forwarding_one_third = (msg.value) / 3;
        owner.transfer(transfer_forwarding_one_third);
        
    }
    address payable[] recipients;
    function sendEther(address payable recipient) external {
        recipient.transfer(transfer_amount);
    }
}