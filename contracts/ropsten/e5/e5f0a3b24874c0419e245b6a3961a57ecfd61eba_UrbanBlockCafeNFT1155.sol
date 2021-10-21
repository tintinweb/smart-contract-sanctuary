// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./IERC165.sol";
import "./IERC1155MetadataURI.sol";

import "./AERC1155.sol";
import "./AERC1155MetadataURI.sol";

contract UrbanBlockCafeNFT1155 is IERC165, IERC1155MetadataURI, AERC1155, AERC1155MetadataURI {
    uint8 constant private TOKEN_TYPE_COUNT = 6;
    uint8 constant private AMOUNT_PER_TOKEN = 50;

    uint constant private UNAVAILABLE_SINCE = 1640966400; // 2022/1/1 00:00:00 UTC+8

    //address constant private INITIAL_TOKEN_OWNER = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
    address constant private INITIAL_TOKEN_OWNER = 0x006445c375C3D71052fC7Df1d7810fe26965B95b;

    string constant private IPFS_PUBLIC_GATEWAY = "https://ipfs.io/ipfs";
    string constant private IPFS_DIRECTORY_QMHASH = "QmUNTHhZkfc6vvML9CpD1qCcBfckTUbLNqeMQSJQvF7FNg";
    string constant private URI_POSTFIX = ".json";
    string constant private URI_SPLITER = "/";

    string constant private DESCRIPTION = "UrbanBlock Cafe NFT";
    string constant private YEAR = "2021";

    constructor() {
        for (uint8 i = 0; i < TOKEN_TYPE_COUNT; i++) {
            _balances[i][INITIAL_TOKEN_OWNER] = AMOUNT_PER_TOKEN;
        }
    }

    function supportsInterface(bytes4 interfaceId_) public view override(IERC165, AERC1155) returns (bool) {
        return type(IERC1155MetadataURI).interfaceId == interfaceId_ || super.supportsInterface(interfaceId_);
    }

    function uri(uint256 id_) public pure override(IERC1155MetadataURI, AERC1155MetadataURI) returns (string memory) {
        return string(abi.encodePacked(IPFS_PUBLIC_GATEWAY, URI_SPLITER, IPFS_DIRECTORY_QMHASH, URI_SPLITER, super.uri(id_), URI_POSTFIX));
    }

    function initialTokenOwner() external pure returns(address) {
        return INITIAL_TOKEN_OWNER;
    }

    function availabeTokenAmount(uint256 id_) external view returns (uint256) {
        return _balances[id_][INITIAL_TOKEN_OWNER];
    }

    function unavailableSince() external pure returns (uint) {
        return UNAVAILABLE_SINCE;
    }

    function description() external pure returns (string memory) {
        return string(abi.encodePacked(DESCRIPTION, " ", YEAR));
    }
}