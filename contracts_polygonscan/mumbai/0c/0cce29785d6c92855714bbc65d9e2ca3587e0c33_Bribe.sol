/**
 *Submitted for verification at polygonscan.com on 2021-11-22
*/

pragma solidity ^0.7.0;
contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}