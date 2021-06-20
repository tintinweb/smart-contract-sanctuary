/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: SignVerify.sol

/**
 * @dev
 */
contract SignatureVerifier {
    address public _signer;

    constructor(address signer) {
        _signer = signer;
    }

    function verify(
        address account,
        uint256 id,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(account, id);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function getMessageHash(address account, uint256 id)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, id));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
    public
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                messageHash
            )
        );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
    public
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}