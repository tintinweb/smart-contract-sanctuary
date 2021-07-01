/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract A {
    function tip() public payable {
        block.coinbase.transfer(msg.value);
        for (uint i = 0; i < 125; i++) {}
    }
}