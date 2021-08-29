/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract Signature {
    /*  Get message hash to sign
    getMessageHash(
        beneficiary address,
        amount,
        nonce,
        payment contract 
    ) take the hash

    */
    function getMessageHash(
        address _to, uint _amount, uint _nonce, address _contract
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _amount, _nonce, _contract));
    }

    /* 2. Sign message hash
    # using browser console
    account = "copy paste account of signer here"
    hash = the hash created
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)
    */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /* 4. Verify signature
    signer = sender address
    to = beneficiary address
    amount = weis
    nonce 
    payment address
    signature = the sign hash created before
    */
    function verify(
        address _signer,
        address _to, uint _amount, uint _nonce, address _contract,
        bytes memory signature
    )
        public pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(_to, _amount, _nonce, _contract);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}