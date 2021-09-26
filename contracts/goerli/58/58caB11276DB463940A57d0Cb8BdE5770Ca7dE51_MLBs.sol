// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MLBs is ERC1155, Ownable {
    uint256 public constant MLBFun = 0;
    uint256 public constant MLBNFun = 1;
    
    constructor(uint256 MLBFunIS)
    ERC1155("https://siasky.net/AAC4OM8JRWH3DAx3bQ7qjAcVcpYD52WXzICO11KfvD4i3w") {
        _mint(msg.sender, MLBFun, MLBFunIS * (10 **18), "");
        _mint(msg.sender, MLBNFun, 1, "");
    }

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