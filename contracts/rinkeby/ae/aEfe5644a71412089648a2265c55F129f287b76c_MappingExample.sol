/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.8.4;

contract MappingExample {
    struct swap {
        address emiter;
        bytes32 source_chain;
        address recipient;
        bytes32 destination_chain;
        uint256 amount;
        
        bytes32 source_transaction;
        bytes32 destination_transaction;
    }

    mapping(bytes32 => swap) public proof;

    function addSwap(address emiter, bytes32 source_chain, address recipient, bytes32 destination_chain, uint256 amount, bytes32 source_transaction,  bytes32 destination_transaction) public {
        swap memory a = swap({
            emiter: emiter,
            source_chain: source_chain,
            recipient: recipient,
            destination_chain: destination_chain,
            amount: amount,
            source_transaction: source_transaction,
            destination_transaction: destination_transaction
        });
        bytes32 k = keccak256(abi.encodePacked(emiter,source_chain,recipient,destination_chain,amount));
        proof[k] = a;
    }
    function checkSwap(address emiter, bytes32 source_chain, address recipient, bytes32 destination_chain, uint256 amount) public returns (swap memory){
        bytes32 k = keccak256(abi.encodePacked(emiter,source_chain,recipient,destination_chain,amount));
        swap memory res = proof[k];
        return res;
    }
}