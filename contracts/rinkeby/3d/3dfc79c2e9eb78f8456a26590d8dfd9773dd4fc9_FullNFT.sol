// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract FullNFT is ERC721Enumerable, Ownable {

    string public baseURI = "";
    uint public supplyLimit = 10000;
    uint public tokenPrice = 8000000000000000; // 0.008 ether
    uint public buyLimitPerTransaction = 20;
    bool public salesEnabled = true;
    
    

    constructor(string memory initialBaseURI) ERC721("Plupppppy Token", "PPPNFT")  {
        baseURI = initialBaseURI;
    }

    /*
    function mint(address _to, uint256 _tokenId) external onlyOwner {
        require(super.totalSupply() + 1 <= supplyLimit);
        super._mint(_to, _tokenId);
    }
    */
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleSalesEnabled() public onlyOwner {
        salesEnabled = !salesEnabled;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /*
    function mintMultiple(address[] memory to, uint256[] memory tokenId) public onlyOwner returns (bool) {
        require(super.totalSupply() + to.length <= supplyLimit);
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
        }
        return true;
    }
    */
    
    function mintTokens(uint numberOfTokens) public payable {
        require(salesEnabled, 'Unable to buy tokens now');
        require(numberOfTokens <= buyLimitPerTransaction, 'Exceed purchase limit per transaction');
        require(totalSupply() + numberOfTokens <= supplyLimit, 'Exceeds supply limit');
        require(msg.value >= numberOfTokens * tokenPrice, 'Not enough money');
        
        for (uint i = 0; i < numberOfTokens; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    
    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function reserveTokens(uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            super._mint(msg.sender, totalSupply());
        }
    }
    
    function getAllTokensBelongToUser(address user) public view returns (uint[] memory tokens) {
        uint ownedCount = balanceOf(user);
        tokens = new uint[](ownedCount);
        for (uint i = 0 ; i < ownedCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(user, i);
        }
    }
    
}