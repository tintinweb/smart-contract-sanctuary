// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './ERC721.sol';
import './ERC721Enumerable.sol';
import './Ownable.sol';
import './SafeMath.sol';

contract L0F1 is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint;

    uint public availableSupply = 10000;
    bool public saleState = false;
    
    uint public price = 0.00777 ether;
    uint public maxBuy = 2;

    string public baseTokenURI;

    uint private nextIndexToAssign;
    bool public allAssigned = false;

    mapping (uint => bool) assignedTokenIds;

    modifier isMinteable() {
        _;
        require(
            !allAssigned,
            "Cannot mint more"
        );
        
        
        require(
            availableSupply >= 0,
            "Out of tokens"
        );
    }

    modifier isBuyeable(uint quantity) {
        _;

        require(
            saleState,
            "Sale closed"
        );

        require(
            quantity > 0 && quantity <= maxBuy,
            "Mini 1 and {maxBuy} L0F1 per Tx"
        );

        require(
            msg.value == price * quantity,
            "Should be {price} * {quantity}"
        );
    }

    constructor()
    ERC721("L0F1", "L0F1") {}

    // Set the sale ON/OFF
    function setSaleState()
    external onlyOwner {
        saleState = (!saleState ? true : false);
    }

    // Get L0F1
    function _mintL0F1(uint quantity, address to) private {
        uint i = 0;

        while (i < quantity) {
            uint tokenId = nextIndexToAssign;
            
            // if it is last {tokenID} then close minting by assigning
            // {allAssigned} to true
            if (tokenId == (availableSupply - 1)) {
                availableSupply--;
                allAssigned = true;
                _safeMint(to, tokenId);
                break;
            }
            
            // if {tokenId} is already assigned increment to next id
            if (assignedTokenIds[tokenId] == true) {
                nextIndexToAssign++;
                tokenId++;
            }
            
            availableSupply--;
            nextIndexToAssign++;
            assignedTokenIds[tokenId] = true;
            _safeMint(to, tokenId);
            i++;
        }
    }

    function buyL0F1(uint quantity)
    external payable isMinteable isBuyeable(quantity) {
        _mintL0F1(quantity, msg.sender);
    }

    function giftL0F1(address to, uint quantity)
    external onlyOwner isMinteable {
        _mintL0F1(quantity, to);
    }

    // Withdraw ETH balance of the contract
    function withdrawEquity()
    external onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    // Expose all token Ids held by the address parameter {owner}
    function exposeHeldIds(address owner)
    public view returns(uint[] memory) {
        uint tokenCount = balanceOf(owner);
        uint[] memory tokensId = new uint[](tokenCount);

        uint i = 0;
        while (i < tokenCount) { 
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
            i++;
        }
        return tokensId;
    }

    function _baseURI()
    internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _beforeTokenTransfer(
        address from, address to, uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}