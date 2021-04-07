/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-03-09
*/

pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

contract TransactionBatcher {
    function batchSend(address[] memory targets, uint[] memory values, bytes[] memory datas) public payable {
        for (uint i = 0; i < targets.length; i++)
            targets[i].call.value(values[i])(datas[i]);
    }
}