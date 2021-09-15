/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.5.1;

contract Bribe {

    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }

    
}