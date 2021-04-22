// contracts/Antimasks.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Antimasks is ERC721, Ownable {

    using SafeMath for uint256;
    uint public constant MAX_ANTIMASKS = 3000;
    bool public hasSaleStarted = false;
    
    // provenance hash of all Antimasks
    string public ANTIMASKS_PROVENANCE = "";

    constructor(string memory baseURI) ERC721("Antimasks","ANTI")  {
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
        require(hasSaleStarted == true, "Sale has not started");
        require(totalSupply() < (MAX_ANTIMASKS - 500), "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 2451) {
            return 250000000000000000;         // 2451-2500:  0.25 ETH
        } else if (currentSupply >= 2301) {
            return 200000000000000000;         // 2301-2450:  0.20 ETH
        } else if (currentSupply >= 1901) {
            return 150000000000000000;         // 1901-2300:  0.15 ETH
        } else if (currentSupply >= 1151) {
            return 100000000000000000;         // 1151-1900:  0.10 ETH
        } else if (currentSupply >= 401) {
            return 60000000000000000;          // 401-1150:   0.06 ETH 
        } else {
            return 30000000000000000;          // 1-400:      0.03 ETH
        }
    }

    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < (MAX_ANTIMASKS - 500), "Sale has already ended");

        if (_id >= 2451) {
            return 250000000000000000;         // 2451-2500:  0.25 ETH
        } else if (_id >= 2301) {
            return 200000000000000000;         // 2301-2450:  0.20 ETH
        } else if (_id >= 1901) {
            return 150000000000000000;         // 1901-2300:  0.15 ETH
        } else if (_id >= 1151) {
            return 100000000000000000;         // 1151-1900:  0.10 ETH
        } else if (_id >= 401) {
            return 60000000000000000;          // 401-1150:   0.06 ETH 
        } else {
            return 30000000000000000;          // 1-400:      0.03 ETH
        }
    }
    
   function mintAntimask(uint256 numAntimasks) public payable {
        require(totalSupply() < (MAX_ANTIMASKS - 500), "Sale has already ended");
        require(numAntimasks > 0 && numAntimasks <= 5, "You can mint from 1 to 5 Antimasks");
        require(totalSupply().add(numAntimasks) <= (MAX_ANTIMASKS - 500), "Exceeds MAX_ANTIMASKS");
        require(msg.value >= calculatePrice().mul(numAntimasks), "Ether value sent is below the price");

        for (uint i = 0; i < numAntimasks; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    // set provenance hash after all Antimasks minted
    function setProvenanceHash(string memory _hash) public onlyOwner {
        ANTIMASKS_PROVENANCE = _hash;
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

}