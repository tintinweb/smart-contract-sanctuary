// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TheHighestOffice is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public constant THO_SUPPLY = 8400;
    
    bool private _saleActive = false;
    
    uint16[] idPool;
    
    address team1 = 0x60d235bCD1fD7c6017b298837fc4c40098e5FE14;
    address team2 = 0xe03bC396f212C8d286B9C08a2Bf88158018D8De6;
    address team3 = 0x30427e200BE02A3bEE014Ec6C8DE2b5b018C5Ee6;

    string private _metaBaseUri = "";
    
    // Public Functions
    
    constructor() ERC721("The Highest Office", "THO") {
        for (uint16 i = 1; i <= THO_SUPPLY; i++) {
            idPool.push(i);
        }
    }
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "THO sale not active");
        require(totalSupply().add(numberOfTokens) <= THO_SUPPLY, "Try less");
        require(numberOfTokens<=4, "Max mint per transaction is 4" );

        uint256 price = getCurrentPrice();
        require(price.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");        

        _mintTokens(numberOfTokens);
    }    
   
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }        

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }

    function getCurrentPrice() public view returns (uint256) {
        if (totalSupply() < 100) return 0;
        if (totalSupply() < 4200) return 49000000000000000;
        else return 65000000000000000;
    }
    
    // Owner Functions

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }   
  

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }


   function withdrawAll() external onlyOwner {
        uint256 _25percent = address(this).balance.mul(25).div(100);
        uint256 _65percent = address(this).balance.mul(65).div(100);
        uint256 _10percent = address(this).balance.mul(10).div(100);
        require(payable(team1).send(_25percent));
        require(payable(team2).send(_65percent));
        require(payable(team3).send(_10percent));        
    }

    // Internal Functions
    
    function _mintTokens(uint16 numberOfTokens) internal {

        uint256 idSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));

        for (uint16 i = 0; i < numberOfTokens; i++) {                 
            
            uint256 index = idSeed % idPool.length;
            uint16 tokenId = idPool[index];
            remove (index);

            _safeMint(msg.sender, tokenId);
         }
    }

    function remove(uint index) internal {
        if (index >= idPool.length) return;

         if (idPool.length > 1) {
            idPool[index] = idPool[idPool.length-1];        
        }
        idPool.pop();
    }

    
    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
    

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}