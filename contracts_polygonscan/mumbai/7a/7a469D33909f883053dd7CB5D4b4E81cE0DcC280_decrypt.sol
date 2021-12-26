// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./Sign.sol";

contract decrypt is Sign {
    function proofSignedWalletString(
        address wallet,
        string memory data_string,
        bytes memory sig
    ) public pure returns (address wallet_recovered, bool validated) {
        bytes32 message = _prefixed(keccak256(abi.encodePacked(wallet, data_string)));

        wallet_recovered = _recoverSigner(message, sig);

        if (wallet_recovered == wallet) {
            validated = true;
        }
    }

    function proofSignedWallet(address wallet, bytes memory sig)
        public
        pure
        returns (address wallet_recovered, bool validated)
    {
        bytes32 message = _prefixed(keccak256(abi.encodePacked(wallet)));

        wallet_recovered = _recoverSigner(message, sig);

        if (wallet_recovered == wallet) {
            validated = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

abstract contract Sign {
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Incorrect signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            //first 32 bytes, after the length prefix
            r := mload(add(sig, 0x20))
            //next 32 bytes
            s := mload(add(sig, 0x40))
            //final byte, first of next 32 bytes
            v := byte(0, mload(add(sig, 0x60)))
        }

        return (v, r, s);
    }

    function _recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}