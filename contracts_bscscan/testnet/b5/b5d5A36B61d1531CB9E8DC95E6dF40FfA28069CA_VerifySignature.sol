pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

contract VerifySignature {
    address internal signer;

    constructor(){
        signer = msg.sender;
    }

    function verify(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_user, _slotsQty, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _sign) == signer;
    }

    function getMessageHash(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _slotsQty, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
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
    }
}