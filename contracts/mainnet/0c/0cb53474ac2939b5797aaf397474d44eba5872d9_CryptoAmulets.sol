// contracts/CryptoAmulets.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";


contract CryptoAmulets is ERC721, Ownable {
    using SafeMath for uint256;
    
    bool public hasSaleStarted = false;
    
    // Max supply of 8000 AMULETS
    uint public constant MAX_AMULETS = 8000;
    
    // SHA256 File hash of 8000 CryptoAmulets Artwork hashes (Before/After Reveal)
    string public PROVENANCE_HASH = "446A8BEB34E8049DF458F8C131A3F6F90394413E7DB2CC14F90D64DA820D30DE";

    // Txn Hash of the Reveal Function Call
    string public REVEAL_HASH = "";
    
    constructor(string memory baseURI) ERC721("CryptoAmulets", "AMULETS")  {
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
        require(hasSaleStarted == true, "Sales have not start");
        require(totalSupply() < MAX_AMULETS, "Sales have ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 7900) {
            return 0.80 ether;        // Tier 8 -- 7901-8000: 0.80 ETH 
        } else if (currentSupply >= 7500) {
            return 0.60 ether;        // Tier 7 -- 7501-7900: 0.60 ETH
        } else if (currentSupply >= 6500) {
            return 0.45 ether;        // Tier 6 -- 6501-7500: 0.45 ETH
        } else if (currentSupply >= 5000) {
            return 0.30 ether;        // Tier 5 -- 5001-6500: 0.30 ETH
        } else if (currentSupply >= 3000) {
            return 0.16 ether;        // Tier 4 -- 3001-5000: 0.16 ETH 
        } else if (currentSupply >= 1500) {
            return 0.08 ether;         // Tier 3 -- 1501-3000: 0.08 ETH 
        } else if (currentSupply >= 500) {
            return 0.04 ether;         // Tier 2 -- 501-1500:  0.04 ETH
        } else {
            return 0.02 ether;         // Tier 3 -- 1-500:     0.02 ETH
        }
    }

   function adoptAMULETS(uint256 numofAMULETS) public payable {
        require(totalSupply() < MAX_AMULETS, "Sales have ended");
        require(numofAMULETS > 0 && numofAMULETS <= 20, "You can adopt minimum 1, maximum 20 AMULETS");
        require(totalSupply().add(numofAMULETS) <= MAX_AMULETS, "Exceeds MAX no of AMULETS");
        require(msg.value >= calculatePrice().mul(numofAMULETS), "Ether value sent is insufficient");

        for (uint i = 0; i < numofAMULETS; i++) {
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