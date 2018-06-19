pragma solidity ^0.4.16;

/* A small utility contract that sends ether to other addresses by means of 
 * SUICIDE/SELFDESTRUCT. Unlike for a normal send/call, if the receiving address
 * belongs to a contract, the contract&#39;s code is never called; one can
 * forcibly increase a contract&#39;s balance!
 *
 * To send $x to y using this technique, simply call `suicideSend(y)` with a 
 * value of $x.
 *
 *
 * If you&#39;re interested in the implications of this trick, I recommend
 * looking at Jo&#227;o Carvalho&#39;s and Richard Moore&#39;s entries to the first
 * Underhanded Solidity Contest [1]. Anybody writing smart ontracts should be 
 * aware of forced balance increases lest their contracts be vulnerable.
 * 
 * [1] https://medium.com/@weka/announcing-the-winners-of-the-first-underhanded-solidity-coding-contest-282563a87079
 */
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