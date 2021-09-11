// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "Mintable.sol";
import "Strings.sol";

contract Photo is ERC721, Mintable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_imx) {}

    function _mintFor(
        address to,
        uint256 id,
        bytes calldata
    ) internal override {
        _safeMint(to, id);
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "https://photocentra.com/ajax/metadata.php?token=";
    }
    
}