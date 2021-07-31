// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Dommies is ERC721Enumerable, Ownable {
    uint public constant MAX_TOKENS = 10000;
    uint public constant MAX_DOMMIES_PURCHASE = 20;
    uint public mintPrice = 69 * 10 ** 15; // 0.069 ETH    
    bool public isSalesActive = false;
    string _baseTokenURI;
    string _contractURI;

    //LFG
    constructor(string memory baseURI, string memory sContractURI, uint iPrice) ERC721("Dommies", "DOM")  {
        setBaseURI(baseURI);
        setContractURI(sContractURI);
        setMintPrice(iPrice);
    }

    function mintMyNFT(address _to, uint _count) public payable {
        uint256 totalTokens = totalSupply();
        require(isSalesActive, "Dommies Sale has not started!");
        require((totalTokens + _count) < (MAX_TOKENS + 1), "Sorry you tried to mint too many Dommies!");
        require(totalTokens < MAX_TOKENS, "No more Dommies left!");
        require(_count < (MAX_DOMMIES_PURCHASE + 1), "Leave some Dommies for others!");
        require(msg.value >= (mintPrice * _count), "Need more ETH to unwrap the Dommies!");

        uint mintTime = block.timestamp;
        for(uint i = 0; i < _count; i++){
            uint256 mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
            emit TokenMinted(msg.sender, mintIndex, mintTime);
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Events
    event TokenMinted(address owner, uint256 tokenID, uint mintTime);

    // onlyOwner Functions //
    function setSaleState(bool newState) public onlyOwner {
        isSalesActive = newState;
    }

    function setMintPrice(uint newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }
    
    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}