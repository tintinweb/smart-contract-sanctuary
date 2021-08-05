/**
 *Submitted for verification at Etherscan.io on 2020-04-22
*/

/*

Custom ETH Contract to send funds to multiple addresses in a single call

*/


pragma solidity  ^0.6.3;

contract InfinitePower {
   
function multisend(uint256[] memory amounts, address payable[] memory receivers) payable public {
assert(amounts.length == receivers.length);
assert(receivers.length <= 100); //maximum receievers can be 100
   
        for(uint i = 0; i< receivers.length; i++){
            receivers[i].transfer(amounts[i]);
        }
    }
}