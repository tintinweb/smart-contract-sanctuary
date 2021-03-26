// contracts/PicklzTest.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// Inspired/Copied fromm BGANPUNKS V2 (bastardganpunks.club) && Chubbies (chubbies.io)
contract Picklz is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_PICKLZ = 4269;
    bool public hasSaleStarted = false;
    
    // The IPFS hash for all Picklz concatenated (to be updated once reveal is set):
    string public METADATA_PROVENANCE_HASH = "";

    // Truth.　
    string public constant R = "Some of our pickles are looking for love, others just want to watch the world burn.";

    constructor(string memory baseURI) ERC721("The Pickle Shop Test Token","PICKLZTEST")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
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
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_PICKLZ, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply > 4200) {
            return 690000000000000000; // 4200-4269: 0.69 ETH
        } else if (currentSupply > 4000) {
            return 500000000000000000; // 4000-4200: 0.50 ETH
        } else if (currentSupply > 3200) {
            return 400000000000000000; // 3200-4000: 0.40 ETH
        } else if (currentSupply > 2200) {
            return 300000000000000000; // 2200-3200: 0.30 ETH
        } else if (currentSupply > 1200) {
            return 200000000000000000; // 1200-2200: 0.20 ETH
        } else if (currentSupply > 200) {
            return 100000000000000000; // 200-1200:  0.10 ETH
        } else {
            return 50000000000000000;  // 0 - 200:   0.05 ETH
        }
    }


    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < MAX_PICKLZ, "Sale has already ended");

        if (_id >= 4200) {
            return 690000000000000000; // 4200-4269: 0.69 ETH
        } else if (_id >= 4000) {
            return 500000000000000000; // 4000-4200: 0.50 ETH
        } else if (_id >= 3200) {
            return 400000000000000000; // 3200-4000: 0.40 ETH
        } else if (_id >= 2200) {
            return 300000000000000000; // 2200-3200: 0.30 ETH
        } else if (_id >= 1200) {
            return 200000000000000000; // 1200-2200: 0.20 ETH
        } else if (_id >= 200) {
            return 100000000000000000; // 200-1200:  0.10 ETH
        } else {
            return 50000000000000000;  // 0 - 200:   0.05 ETH
        }
    }
    
   function buyPicklz(uint256 numPicklz) public payable {
        require(totalSupply() < MAX_PICKLZ, "Sale has already ended");
        require(numPicklz > 0 && numPicklz <= 20, "You can adopt minimum 1, maximum 20 chubbies");
        require(totalSupply().add(numPicklz) <= MAX_PICKLZ, "Exceeds MAX_PICKLZ");
        require(msg.value >= calculatePrice().mul(numPicklz), "Ether value sent is below the price");

        for (uint i = 0; i < numPicklz; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    // God Mode
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveGiveaway(uint256 numPicklz) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply().add(numPicklz) <= 10, "Exceeded giveaway supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numPicklz; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}