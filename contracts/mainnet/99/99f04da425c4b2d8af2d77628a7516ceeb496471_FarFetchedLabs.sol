// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";


contract FarFetchedLabs is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    bool public public_sale_running = false;
    bool public private_sale_running = false;
    
    constructor () ERC721("Far Fetched Labs", "FFLABZ") {
        _safeMint(0x6B003507d437caF2bF3E1C79e536136513153cD8, 0); // sheesh
        _safeMint(0x6912b3052FF909B801C17294532e4300E1a4d176, 1); // Graffito
        _safeMint(0x61be5fD058AF66D3143d225A5642D628c8E9cbba, 2); // Astro
        _safeMint(0xa4322cB9d8dE8Ea605fe295C32Ef21D5e611164A, 3); // Linette
        _safeMint(0x06A6f7341fb29A390d83250D66dAD91b6aBa6c00, 4); // cinta de oro
        _safeMint(0x8147c04cb5c13b482820064e2BdD8A41Ab9A4B51, 5); // Goldentrees
        _safeMint(0xAd17BdfFD0805f6d871016964a29F910e564CcD7, 6); // Axie
        _safeMint(0x4bCA5f46dB7AF63CB3FfD73E68CB3A09B8410b6e, 7); // Primo
        _safeMint(0x9408c666a65F2867A3ef3060766077462f84C717, 8); // z1
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://farfetchedlabs.io/metadata/", (tokenId + 1).toString()));
    }   
    
    function privateMint(uint _quantity) external payable {
        require(private_sale_running, "Private sale is not running");
        require(_quantity <= 3, "Invalid number of tokens queries for minting");
        require(msg.value == 0.06 ether * _quantity, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= 5000, "Not enough tokens left to mint");
        require(balanceOf(msg.sender) + _quantity <= 3, "Max 3 tokens per wallet");

        for (uint i = 0; i < _quantity; ++i) _safeMint(msg.sender, totalSupply());
    }

    function publicMint(uint _quantity) external payable {
        require(public_sale_running, "Public sale is not running");
        require(_quantity <= 5, "Invalid number of tokens queries for minting");
        require(msg.value == 0.06 ether * _quantity, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= 5000, "Not enough tokens left to mint");
        require(balanceOf(msg.sender) + _quantity <= 5, "Max 5 tokens per wallet");
        
        for (uint i = 0; i < _quantity; ++i) _safeMint(msg.sender, totalSupply());
    }
    
    function togglePublicSale() external onlyOwner {
        public_sale_running = !public_sale_running;
    }

    function togglePrivateSale() external onlyOwner {
        private_sale_running = !private_sale_running;
    }
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;

        payable(0x4bCA5f46dB7AF63CB3FfD73E68CB3A09B8410b6e).transfer(18 * balance / 100);
        payable(0xAd17BdfFD0805f6d871016964a29F910e564CcD7).transfer(18 * balance / 100);
        payable(0x6912b3052FF909B801C17294532e4300E1a4d176).transfer(18 * balance / 100);
        payable(0x9408c666a65F2867A3ef3060766077462f84C717).transfer(125 * balance / 1000);
        payable(0x6B003507d437caF2bF3E1C79e536136513153cD8).transfer(125 * balance / 1000);
        payable(0x8147c04cb5c13b482820064e2BdD8A41Ab9A4B51).transfer(3 * balance / 100);
        payable(0x4A51aA187Af2814D945a1A6C5211BD873bc6AbfD).transfer(address(this).balance);
    }
}