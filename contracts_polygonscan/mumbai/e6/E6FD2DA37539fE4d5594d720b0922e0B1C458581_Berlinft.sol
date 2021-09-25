// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC1155.sol";
import "Ownable.sol";

contract Berlinft is ERC1155, Ownable {
    constructor() ERC1155("https://berlinft.berlin/api/token/") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}