/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

// MyEthMeta contract
// for more info, see https://github.com/TheBojda/myethmeta or http://myethmeta.org

pragma solidity ^0.8.0;

contract MyEthMeta {
    mapping(address => string) private metaURIs;

    event MetaURIChanged(address indexed ethAddress, string uri);

    function setMetaURI(string memory uri) public {
        metaURIs[msg.sender] = uri;
        emit MetaURIChanged(msg.sender, uri);
    }

    function getMetaURI(address ethAddress)
        public
        view
        returns (string memory)
    {
        return metaURIs[ethAddress];
    }
}