/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity ^0.8.7;
contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}