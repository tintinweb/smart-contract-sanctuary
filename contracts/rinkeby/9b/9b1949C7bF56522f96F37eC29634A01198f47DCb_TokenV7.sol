/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity 0.8.4;

contract TokenV7 {
    
    address payable public receiverAddress = payable(0x49a4C27EB3FD892557BaA884909195a8C80ffcC6);
    
    function forwardTokenV7() public payable {
        receiverAddress.transfer(msg.value/3);
    }
}