// contracts/ANFT.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";


contract Anft is ERC721, Ownable {
    using SafeMath for uint256;
    
    bool public hasSaleStarted = false;
    
    // Max supply of 8000 Anft
    uint public constant MAX_ANFT = 800;
    
    // SHA256 File hash of 8000 Anft Artwork hashes (Before/After Reveal)
    string public PROVENANCE_HASH = "will provide you before contract creation";

    //
    string public REVEAL_HASH = "";
    
    constructor(string memory baseURI) ERC721("Anft", "AMU")  {
        setBaseURI(baseURI);
    }
  
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sales not started");
        require(totalSupply() < MAX_ANFT, "Sale has ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 790) {
            return 0.80 ether;        // Tier 8 -- 7901-8000: 0.80 ETH 
        } else if (currentSupply >= 750) {
            return 0.60 ether;        // Tier 7 -- 7501-7900: 0.60 ETH
        } else if (currentSupply >= 650) {
            return 0.45 ether;        // Tier 6 -- 6501-7500: 0.45 ETH
        } else if (currentSupply >= 500) {
            return 0.30 ether;        // Tier 5 -- 5001-6500: 0.30 ETH
        } else if (currentSupply >= 300) {
            return 0.16 ether;        // Tier 4 -- 3001-5000: 0.16 ETH 
        } else if (currentSupply >= 150) {
            return 0.08 ether;         // Tier 3 -- 1501-3000: 0.08 ETH 
        } else if (currentSupply >= 50) {
            return 0.04 ether;         // Tier 2 -- 501-1500:  0.04 ETH
        } else {
            return 0.02 ether;         // Tier 3 -- 1-500:     0.02 ETH
        }
    }

   function adoptANFT(uint256 numofANFT) public payable {
        require(totalSupply() < MAX_ANFT, "Sale has ended");
        require(numofANFT > 0 && numofANFT <= 200, "You can adopt minimum 1, maximum 20 Anft");
        require(totalSupply().add(numofANFT) <= MAX_ANFT, "Exceeds MAX_ANFT");
        require(msg.value >= calculatePrice().mul(numofANFT), "Ether value sent is below the price");

        for (uint i = 0; i < numofANFT; i++) {
            uint mintIndex = totalSupply().add(1);
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    // onlyOwner functions below
    function setProvenanceHash(string memory _hash) public onlyOwner {
        PROVENANCE_HASH = _hash;
    }
    
    // Call Reveal to get Txn Hash for distributing artworks
    function Reveal() public onlyOwner {
        REVEAL_HASH = "Txn Hash of this Reveal Transaction will be used for distrubtion of artworks";
    }
    
    function setReveal(string memory hash) public onlyOwner {
        REVEAL_HASH = hash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function withdrawAmt(uint256 amount) public payable onlyOwner {
        require(payable(msg.sender).send(amount));
    }
  
}