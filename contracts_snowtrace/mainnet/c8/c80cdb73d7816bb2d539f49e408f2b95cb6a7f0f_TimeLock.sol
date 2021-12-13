/**
 *Submitted for verification at snowtrace.io on 2021-12-13
*/

// File: Timelock.sol
/**
* @title Hashed Timelock Contracts (HTLCs) on Ethereum ERC20 tokens.
*
* This contract provides a way to create and keep HTLCs for ERC20 tokens.
*
* See HashedTimelock.sol for a contract that provides the same functions
* for the native ETH token.
*
* Protocol:
*
*  1) newContract(receiver, hashlock, timelock, tokenContract, amount) - a
*      sender calls this to create a new HTLC on a given token (tokenContract)
*       for a given amount. A 32 byte contract id is returned
*  2) withdraw(contractId, preimage) - once the receiver knows the preimage of
*      the hashlock hash they can claim the tokens with this function
*  3) refund() - after timelock has expired and if the receiver did not
*      withdraw the tokens the sender / creator of the HTLC can get their tokens
*      back with this function.
 */

pragma solidity ^0.7.6;

contract TimeLock {

    uint256 value;

    constructor (uint256 _time) {
        value = _time;
    }

    function settime(uint256 _n) payable public {
        value = _n;
    }

    function setNtime(uint256 _n) public {
        value = _n;
    }

    function get () view public returns (uint256) {
        return value;
    }
}