/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity >=0.4.22 <0.7.0;

contract Debit{
    string public message;
    event DebitLog(bytes32 data, uint blockNumber);
    constructor() public {
    }
    function createDebit(bytes32 DebitMessage) public {
        emit DebitLog(DebitMessage,block.number);
    }
}