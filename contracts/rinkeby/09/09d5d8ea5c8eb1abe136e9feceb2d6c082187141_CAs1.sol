// contracts/CAs1.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";


contract CAs1 is ERC721, Ownable {
    using SafeMath for uint256;
    
    bool public hasSaleStarted = true;
    
    // Max supply of 8000 AMULETS
    uint public constant MAX_AMULETS = 1680;
    
    // SHA256 File hash of 8000 CryptoAmulets Artwork hashes (Before/After Reveal)
    string public PROVENANCE_HASH = "";

    // Txn Hash of the Reveal Function Call
    string public REVEAL_HASH = "";
    
    constructor(string memory baseURI) ERC721("CAs1", "cas1")  {
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

            return 0 ether;         
        
    }

   function adoptAMULETS(uint256 numofAMULETS) public {
        require(totalSupply() < MAX_AMULETS, "Sales have ended");
        require(numofAMULETS > 0 && numofAMULETS <= 200, "You can adopt minimum 1, maximum 200 AMULETS");
        require(totalSupply().add(numofAMULETS) <= MAX_AMULETS, "Exceeds MAX no of AMULETS");

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