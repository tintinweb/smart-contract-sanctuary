/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.4.20;

contract Faucet {
    
    function withdraw() public {
        msg.sender.transfer(1000000000000000000);
    }
    
    function () payable public {}
}