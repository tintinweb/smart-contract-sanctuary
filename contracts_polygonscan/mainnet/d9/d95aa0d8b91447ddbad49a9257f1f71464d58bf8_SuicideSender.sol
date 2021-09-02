/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

pragma solidity ^0.4.16;


contract SuicideSender {
    function suicideSend(address to) payable {
        address temp_addr;
        assembly {
            let free_ptr := mload(0x40)
            /* Prepare initcode that immediately forwards any funds to address
             * `to` by running [PUSH20 to, SUICIDE].
             */
            mstore(free_ptr, or(0x730000000000000000000000000000000000000000ff, mul(to, 0x100)))
            // Run initcode we just prepared.
            temp_addr := create(callvalue, add(free_ptr, 10), 22)
        }
        require(temp_addr != 0);
    }
}