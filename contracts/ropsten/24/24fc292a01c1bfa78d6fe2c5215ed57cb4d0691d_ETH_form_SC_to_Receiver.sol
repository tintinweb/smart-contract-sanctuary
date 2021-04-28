/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;
contract ETH_form_SC_to_Receiver {  
    uint transfer_amount = 99999;
    address payable[] recipients;     
    function sendEther(address payable recipient) external {       
        recipient.transfer(transfer_amount);        
        msg.sender.transfer(transfer_amount);        
    }
}