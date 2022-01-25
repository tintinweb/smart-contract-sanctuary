/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface I1155Setter {

function setURI(uint _id, string memory _uri) external;
}

contract NFT1155URISetter {
function setURIBatch(uint _id0, string memory _uri0,
uint _id1, string memory _uri1,
uint _id2, string memory _uri2,
uint _id3, string memory _uri3,
uint _id4, string memory _uri4,
address _contract)
public {
I1155Setter NFTaddr = I1155Setter(_contract);
NFTaddr.setURI(_id0,_uri0);
NFTaddr.setURI(_id1,_uri1);
NFTaddr.setURI(_id2,_uri2);
NFTaddr.setURI(_id3,_uri3);
NFTaddr.setURI(_id4,_uri4);
    }
}