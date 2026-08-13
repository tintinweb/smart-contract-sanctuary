/**
 *Submitted for verification at hecoinfo.com on 2022-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractURI {

    string public uri;

    constructor(string memory _uri) {
        uri = _uri;
        // https://ipfs.io/ipfs/QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/8520
        // https://nft.deepsuns.com/file/oss/prd/nft/meta/trophy-2022/0
        // https://static.schoolbuy.top/media/ula/1
    }

    function set(string memory _tokenURI) public {
        uri = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        return uri;
    }
}