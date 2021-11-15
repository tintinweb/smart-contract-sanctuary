// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

contract Ammendment {
    struct TextAmmendment {
        bool encrypted;
        string text;
    }

    struct MetaDataAmmendment {
        string uri;
        bytes32 metaDataHash;
    }

    mapping(uint256 => TextAmmendment[]) public textAmmendments;
    mapping(uint256 => MetaDataAmmendment[]) public metaDataAmmendments;

    event TextAmmendmentCreated(
        uint256 indexed tokenId,
        address indexed sender,
        uint256 index,
        TextAmmendment textAmmendment
    );

    event MetaDataAmmendmentCreated(
        uint256 indexed tokenId,
        address indexed sender,
        uint256 index,
        MetaDataAmmendment metaDataAmmendment
    );

    constructor() public {}

    function createMetaDataAmmendment(
        uint256 tokenId,
        string memory uri,
        bytes32 metaDataHash
    ) external virtual {
        MetaDataAmmendment[] storage metaDataAmmendmentsForToken =
            metaDataAmmendments[tokenId];
        MetaDataAmmendment memory metaDataAmmendment =
            MetaDataAmmendment({uri: uri, metaDataHash: metaDataHash});

        metaDataAmmendmentsForToken.push(metaDataAmmendment);
        emit MetaDataAmmendmentCreated(
            tokenId,
            msg.sender,
            metaDataAmmendmentsForToken.length - 1,
            metaDataAmmendment
        );
    }

    function getMetaDataAmmendment(uint256 tokenId, uint256 index)
        external
        virtual
        returns (MetaDataAmmendment memory)
    {
        return metaDataAmmendments[tokenId][index];
    }

    function createTextAmmendment(
        uint256 tokenId,
        bool encrypted,
        string memory text
    ) external virtual {
        TextAmmendment[] storage textAmmendmentsForToken =
            textAmmendments[tokenId];
        TextAmmendment memory textAmmendment =
            TextAmmendment({encrypted: encrypted, text: text});

        textAmmendmentsForToken.push(textAmmendment);
        emit TextAmmendmentCreated(
            tokenId,
            msg.sender,
            textAmmendmentsForToken.length - 1,
            textAmmendment
        );
    }

    function getTextAmmendment(uint256 tokenId, uint256 index)
        external
        virtual
        returns (TextAmmendment memory)
    {
        return textAmmendments[tokenId][index];
    }
}

