// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";


contract CryptoSimps is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    bool public minting_allowed = false;
    
    constructor () ERC721("CryptoSimps", "SIMPS") { }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://cryptosimpsnft.com/metadata/", (tokenId + 1).toString(), ".json"));
    }   
    
    function mintTokens(uint _quantity) external payable {
        require(minting_allowed, "Minting is currently disabled");
        require(_quantity <= 15, "Invalid number of tokens queries for minting");
        require(msg.value == 0.08 ether * _quantity, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= 485, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) _safeMint(msg.sender, totalSupply());
    }
    
    function toggleMinting() external onlyOwner {
        minting_allowed = !minting_allowed;
    }
    
    function withdraw() external onlyOwner {
        uint256 total_balance = address(this).balance;
        
        address simps_owner = 0x9CfFc247FfE168E6F5a0CD683F36782a7b57A4c9;
        address artist = 0x11e64Dc9C8156d6DB6Bdbd908A9c765813642071;
        address z1 = 0x9408c666a65F2867A3ef3060766077462f84C717;
        address djip = 0x22438B6e5732d0827Dd95Fb5762B93B721001380;
        
        payable(simps_owner).transfer(64 * total_balance / 100);
        payable(artist).transfer(6 * total_balance / 100);
        payable(z1).transfer(15 * total_balance / 100);
        payable(djip).transfer(address(this).balance);
    }
}