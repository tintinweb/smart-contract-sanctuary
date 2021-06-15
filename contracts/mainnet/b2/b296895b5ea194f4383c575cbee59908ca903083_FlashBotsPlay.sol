/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity >=0.8.0;

contract FlashBotsPlay {
    
    uint public z;

    function reset() external {
        z = 0;
    }

    function x() external payable{
        z = 0;
        z = 3;
        block.coinbase.transfer(msg.value);
    }
}