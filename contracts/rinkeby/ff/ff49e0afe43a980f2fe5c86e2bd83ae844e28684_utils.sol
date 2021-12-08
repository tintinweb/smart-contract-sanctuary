/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.6.0;

contract utils {
    bytes32 public hash;
    uint public number;
    bytes32 public old_hash;

    constructor() public {
        number = block.number;
    }

    function update_hash() public {
        number = block.number;
        hash = blockhash(number);
        old_hash = blockhash(number-257);
    }

}