/**
 *Submitted for verification at Etherscan.io on 2020-04-26
*/

pragma solidity  ^0.6.3;

contract MaxViralMarketing {
   
function multisend(uint256[] memory amounts, address payable[] memory receivers) payable public {
assert(amounts.length == receivers.length);
assert(receivers.length <= 100); //maximum receievers can be 100
   
        for(uint i = 0; i< receivers.length; i++){
            receivers[i].transfer(amounts[i]);
        }
    }
}