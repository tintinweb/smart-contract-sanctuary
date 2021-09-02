//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract StandardNFT is ERC721, Ownable {
    
    uint public constant maxTokens = 1000;
    uint private currentTokens = 0;
    
    string private baseTokenURI;
    
    bool public mintingEnabled = false;
    uint public mintingCost = 0.05 ether;
    
    event Mint(address indexed to, uint indexed tokenId);
    
    constructor() payable ERC721("StandardNFT", "SNFT") {
    
    }
    
    // Modifiers
    modifier mintable() {
        require(currentTokens < maxTokens, "Already Fully Minted");
        _;
    }
    
    modifier onlySender() {
        require(msg.sender == tx.origin, "Sender Must be Origin");
        _;
    }
    
    modifier publicMinting() {
        require(mintingEnabled == true, "Minting is not enabled yet");
        _;
    }
    
    // Internal Workers
    function addMintCount() internal {
        currentTokens++;
    }
    
    // Admin Functions
    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);   
    }
    
    function withdrawERC20(address contractAddress_) external onlyOwner {
        IERC20 _token = IERC20(contractAddress_);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    
    function withdrawERC721(address contractAddress_, uint tokenId_) external onlyOwner {
        IERC721(contractAddress_).transferFrom(address(this), msg.sender, tokenId_);
    }
    
    function adminMint(uint tokenId_) external onlyOwner mintable onlySender {
        require(currentTokens + 1 <= maxTokens, "Over Max Tokens");
        _mint(msg.sender, tokenId_);
        emit Mint(msg.sender, tokenId_);
        addMintCount();
    }
    
    function adminNormalMint(uint mintAmount_) external onlyOwner mintable onlySender {
        require(currentTokens + mintAmount_ <= maxTokens, "Over Max Tokens");
        for (uint i = 0; i < mintAmount_; i++) {
            _mint(msg.sender, currentTokens);
            emit Mint(msg.sender, currentTokens);
            addMintCount();
        }
    }
    
    function setMintingCost(uint mintingCost_) external onlyOwner {
        mintingCost = mintingCost_;    
    }
    
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }
    
    function enableMinting() external onlyOwner {
        mintingEnabled = true;
    }
    
    function disableMinting() external onlyOwner {
        mintingEnabled = false;
    }
    
    // Normal Functions
    function normalMint(uint mintAmount_) external payable publicMinting mintable onlySender {
        require(currentTokens + mintAmount_ <= maxTokens, "Over Max Tokens");
        require(mintAmount_ > 0 && mintAmount_ <= 10, "Wrong Amount!");
        require(msg.value == mintingCost * mintAmount_, "Wrong Price!");
        for(uint i = 0; i < mintAmount_; i++) {
            _mint(msg.sender, currentTokens);
            emit Mint(msg.sender, currentTokens);
            addMintCount();
        }
    }
    
    // Read Only Functions
    function tokenURI(uint tokenId_) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId_)));   
    }
    
    function getMintingStatus() public view returns (bool) {
        return mintingEnabled;
    }
    
    function getMintingCost() public view returns (uint) {
        return mintingCost;
    }
    
    function getContractOwner() public view returns (address) {
        return owner();
    }
    
    function getMintCount() public view returns (uint) {
        return currentTokens;
    }
}