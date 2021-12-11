// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "ERC721.sol";

contract DLS is ERC721 {
    constructor() ERC721("Digital Landowners Society KEY", "DLS") public {}

    function _baseURI() internal override view returns (string memory) {
        return "https://storage.googleapis.com/dls-keys/metadata/";
    }
}