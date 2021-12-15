// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";


contract Puppers is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    bool public private_sale_minting = false;
    bool public public_sale_minting = false;
    
    mapping(address => uint) public allocations;

    constructor () ERC721("Puppers", "PUPPERS") { }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://meta.puppersnft.com/", tokenId.toString()));
    }   

    function privateSaleMint(uint _quantity) external payable {
        require(allocations[msg.sender] >= _quantity, "Not enough allocation to mint presale");
        require(private_sale_minting, "Minting is currently disabled");
        require(msg.value == 0.05 ether * _quantity, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= 5555, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            --allocations[msg.sender];
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function publicSaleMint(uint _quantity) external payable {
        require(public_sale_minting, "Minting is currently disabled");
        require(_quantity <= 10, "Invalid number of tokens queries for minting");
        require(msg.value == 0.05 ether * _quantity, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= 5555, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) _safeMint(msg.sender, totalSupply());
    }

    function ownerMint(address _to, uint _quantity) external onlyOwner {
        require(_quantity <= 10, "Invalid number of tokens queries for minting");
        require(totalSupply() + _quantity <= 5555, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) _safeMint(_to, totalSupply());
    }

    function addPresale(address [] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; ++i) {
            allocations[addresses[i]] += 3;
        }
    }
    
    function togglePrivateSale() external onlyOwner {
        private_sale_minting = !private_sale_minting;
    }

    function togglePublicSale() external onlyOwner {
        public_sale_minting = !public_sale_minting;
    }
    
    function withdraw() external onlyOwner {
        payable(0xAfCA9a21Ae7c376CEf7844373380c81BAda0dcB9).transfer(address(this).balance);
    }
}