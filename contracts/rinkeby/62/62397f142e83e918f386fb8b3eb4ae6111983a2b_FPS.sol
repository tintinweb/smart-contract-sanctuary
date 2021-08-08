/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

// https://ethereum.stackexchange.com/questions/17094/how-to-store-ipfs-hash-using-bytes32
// https://medium.com/temporal-cloud/efficient-usable-an`d-cheap-storage-of-ipfs-hashes-in-solidity-smart-contracts-eb3bef129eba

contract FPS {
    struct Content {
        string cid;
        string config;
    }

    event StorageRequest(address uploader, string cid, string config);

    mapping(address => mapping(string => Content)) uploaderToContent;

    function store(string calldata cid, string calldata config)
    external
    returns (bytes32)
    {
        uploaderToContent[msg.sender][cid] = Content(cid, config);
        emit StorageRequest(msg.sender, cid, config);
        // should return a requestId
    }
}