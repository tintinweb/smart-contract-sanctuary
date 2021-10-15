// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title ERC-721 Smart Contract
 */

/**
 * @title TTTT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TTTT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string public PROVENANCE = "";
    uint256 public constant tokenPrice = 1000000000000000; // 0.001 ETH
    uint public constant maxTokenPurchase = 15;
    uint256 public MAX_TOKENS = 100;
    bool public saleIsActive = false;
    bool public revealed = false;
    uint public presaleMaxMint = 7;
    bool public presaleActive = false;
    mapping(address => bool) private presaleList;
    mapping(address => uint256) private presalePurchases;

    string baseURI;
    string private notRevealedUri;
    string public baseExtension = ".json";
    

    constructor(
        string memory _initNotRevealedUri
        ) ERC721("TTTT", "TTTT") {
          setNotRevealedURI(_initNotRevealedUri);
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
    presaleMaxMint = _presaleMaxMint;
    }

    function setPresaleActive(bool _presaleActive) external onlyOwner {
    presaleActive = _presaleActive;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!presaleList[addresses[i]]) {
                presaleList[addresses[i]] = true;
                presalePurchases[addresses[i]] = 0;
            }
        }
    }

    function isOnPresaleList(address addr) external view returns (bool) {
        return presaleList[addr];
    }

    function presaleAmountAvailable(address addr) external view returns (uint256) {
        if (presaleList[addr]) {
            return presaleMaxMint - presalePurchases[addr];
        }
            return 0;
    }

    function mintPresale(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(presaleActive, "Presale not active");
        require(_mintAmount > 0, "_mintAmount must be gt 0");
        require(_mintAmount <= presaleMaxMint, "_mintAmount must be <= presaleMaxMint");
        require(supply + _mintAmount <= MAX_TOKENS, "Mint must not surpass maxSupply");
        require(msg.value >= tokenPrice * _mintAmount, "Not enough money");
        require(presaleList[msg.sender] == true, "Not on the list");
        require(presalePurchases[msg.sender] + _mintAmount <= presaleMaxMint, "No presale mints left");

        presalePurchases[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // CHANGED: added to account for changes in openzeppelin versions
    

    // CHANGED: added to account for changes in openzeppelin versions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function reveal() public onlyOwner() {
        revealed = true;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function reserveTokens() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 13; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function mintGoat(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        // CHANGED: mult and add to + and *
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        // CHANGED: mult and add to + and *
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}