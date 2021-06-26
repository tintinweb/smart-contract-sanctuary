/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity >=0.7.0 <0.9.0;

contract A {
    function tip() public payable {
        block.coinbase.transfer(msg.value);
    }
}