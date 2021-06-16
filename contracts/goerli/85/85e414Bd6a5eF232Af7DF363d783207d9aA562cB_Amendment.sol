// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Signature.sol";

contract Amendment is Signature {
    struct TextAmendment {
        bool encrypted;
        string text;
    }

    struct MetaDataAmendment {
        string uri;
        bytes32 metaDataHash;
    }

    mapping(uint256 => TextAmendment[]) public textAmendments;
    mapping(uint256 => MetaDataAmendment[]) public metaDataAmendments;

    event TextAmendmentCreated(
        uint256 indexed tokenId,
        address indexed sender,
        uint256 index,
        TextAmendment textAmendment
    );

    event MetaDataAmendmentCreated(
        uint256 indexed tokenId,
        address indexed sender,
        uint256 index,
        MetaDataAmendment metaDataAmendment
    );

    constructor() public {}

    function createMetaDataAmendment(
        uint256 tokenId,
        string memory uri,
        bytes32 metaDataHash
    ) external virtual {
        MetaDataAmendment[] storage metaDataAmendmentsForToken =
            metaDataAmendments[tokenId];
        MetaDataAmendment memory metaDataAmendment =
            MetaDataAmendment({uri: uri, metaDataHash: metaDataHash});

        metaDataAmendmentsForToken.push(metaDataAmendment);
        emit MetaDataAmendmentCreated(
            tokenId,
            msg.sender,
            metaDataAmendmentsForToken.length - 1,
            metaDataAmendment
        );
    }

    function getMetaDataAmendment(uint256 tokenId, uint256 index)
        external
        virtual
        returns (MetaDataAmendment memory)
    {
        return metaDataAmendments[tokenId][index];
    }

    function createTextAmendment(
        uint256 tokenId,
        bool encrypted,
        string memory text
    ) external virtual {
        TextAmendment[] storage textAmendmentsForToken =
            textAmendments[tokenId];
        TextAmendment memory textAmendment =
            TextAmendment({encrypted: encrypted, text: text});

        textAmendmentsForToken.push(textAmendment);
        emit TextAmendmentCreated(
            tokenId,
            msg.sender,
            textAmendmentsForToken.length - 1,
            textAmendment
        );
    }

    function textAmendmentHash(
        uint256 tokenId,
        bool encrypted,
        string memory text
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, encrypted, text));
    }

    function createTextAmendment(
        uint256 tokenId,
        bool encrypted,
        string memory text,
        address signer,
        bytes memory signature
    ) external virtual {
        require(
            verify(
                textAmendmentHash(tokenId, encrypted, text),
                signer,
                signature
            ),
            "Signature doesn't match signer."
        );

        TextAmendment[] storage textAmendmentsForToken =
            textAmendments[tokenId];
        TextAmendment memory textAmendment =
            TextAmendment({encrypted: encrypted, text: text});

        textAmendmentsForToken.push(textAmendment);
        emit TextAmendmentCreated(
            tokenId,
            signer,
            textAmendmentsForToken.length - 1,
            textAmendment
        );
    }

    function getTextAmendment(uint256 tokenId, uint256 index)
        external
        virtual
        returns (TextAmendment memory)
    {
        return textAmendments[tokenId][index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

contract Signature {
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        bytes32 messageHash,
        address signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}