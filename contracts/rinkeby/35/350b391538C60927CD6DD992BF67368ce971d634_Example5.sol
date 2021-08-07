/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

pragma solidity 0.8.4;

contract Example5 {
    
    address payable public receiverAddress = payable(0xE9D40E8D586AA78844C8fB945A498E7183bB6c29);
    
    function forwardEther() public payable {
        receiverAddress.send(msg.value/3);
        receiverAddress.transfer(msg.value/3);
        receiverAddress.call{value: msg.value/3}("");
    }
    
}