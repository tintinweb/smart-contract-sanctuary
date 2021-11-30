// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CrocZERC721.sol";

interface ISwamp {
    function burn(address _from, uint256 _amount) external;
    function updateCroczReward(address _from, address _to) external;
} 

contract CrocZ is CrocZERC721 {

    modifier croczOwner(uint256 croczId) {
        require(ownerOf(croczId) == msg.sender, "Cannot interact with a CrocZ you do not own");
        _;
    }

    ISwamp public Swamp;

    constructor(string memory name, string memory symbol, uint256 supply) CrocZERC721(name, symbol, supply) {}

    function setSwamp(address swampAddress) external onlyOwner {
        Swamp = ISwamp(swampAddress);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxSupply) {
            Swamp.updateCroczReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < maxSupply) {
            Swamp.updateCroczReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}