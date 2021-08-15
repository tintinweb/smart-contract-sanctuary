/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// #######  ##    ## ##    ## ##    ##     ######## ##    ## ######## ######## ##    ## ######## ##    ##  ####### //
// ##    ## ##    ## ###   ## ##   ##      ##       ##    ##    ##    ##       ##   ##  ##       ###   ## ##       //
// ##    ## ##    ## ## #  ## ##  ##       ##       ##    ##    ##    ##       ##  ##   ##       ## #  ##  ##      //
// #######  ##    ## ## #  ## ####         ##       ########    ##    ##       ####     ######## ## #  ##    ##    //
// ##       ##    ## ##  # ## ##  ##       ##       ##    ##    ##    ##       ##  ##   ##       ##  # ##      ##  //
// ##       ##    ## ##   ### ##   ##      ##       ##    ##    ##    ##       ##   ##  ##       ##   ###       ## //
// ##       ######## ##    ## ##    ##     ######## ##    ## ######## ######## ##    ## ######## ##    ##  ######  //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract PunkChickens is ERC721Enumerable, Ownable {
    
    uint constant public maxTokens = 9999;
    uint public maxChickensNestTokens = 500;
        
    uint public normalTokensMinted = 0;
    uint public chickensNestTokensMinted = 0;
    
    uint public mintPrice = 0.02 ether;
    bool public publicMinting = false;
    uint public maxTokensPerMint = 20;

    string internal baseTokenURI;
    
    address public chickensNest;
    address public chickensTreasury;
    
    event Mint(address to, uint tokenId_);
    
    constructor () payable ERC721("Punk Chickens", "PUNKC") {}
    
    // modifiers
    modifier onlySender() {
        require(msg.sender == tx.origin, "Sender must be origin!");
        _;
    }
    modifier onlyChickensNest() {
        require(msg.sender == chickensNest, "You are not the chickens nest!");
        _;
    }
    modifier publicMintingEnabled() {
        require(publicMinting == true, "Public Minting is not yet available!");
        _;
    }
    
    // internal workers
    function getNormalMintId() internal view returns (uint) {
        return maxChickensNestTokens + normalTokensMinted;
    }
    
    // view functions
    function tokenURI(uint tokenId_) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId_)));
    }
    function getTokensOfAddress(address address_) public view returns (uint[] memory) {
        uint _tokenBalance = balanceOf(address_);
        uint[] memory _tokenIds = new uint[](_tokenBalance);
        for (uint i = 0; i < _tokenBalance; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(address_, i);
        }
        return _tokenIds;
    }

    // owner functions
    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function setPublicMinting(bool bool_) external onlyOwner {
        publicMinting = bool_;
    }
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }
    function setMintPrice(uint mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }
    function setChickensNest(address address_) external onlyOwner {
        chickensNest = address_;
    }
    function setChickensTreasury(address address_) external onlyOwner {
        chickensTreasury = address_;
    }
    
    // owner mint
    function ownerMint(address to_, uint amount_) external onlyOwner {
        require(amount_ <= maxTokensPerMint, "Over Max Tokens Per Mint!");
        require(normalTokensMinted + maxChickensNestTokens + amount_ <= maxTokens, "Not enough chickens remaining!");
        for (uint i = 0; i < amount_; i ++) {
            uint _tokenId = getNormalMintId();
            normalTokensMinted++;
            _mint(to_, _tokenId);
            emit Mint(to_, _tokenId);
        }
    }
    
    // chickens nest mint
    function chickensNestMint(address to_, uint amount_) external onlyChickensNest {
        require(amount_ <= maxTokensPerMint, "Over Max Tokens Per Mint!");
        require(chickensNestTokensMinted + amount_ <= maxChickensNestTokens, "Not enough chickens remaining from nest!");
        for (uint i = 0; i < amount_; i++) {
            uint _tokenId = chickensNestTokensMinted;
            chickensNestTokensMinted++;
            _mint(to_, _tokenId);
            emit Mint(to_, _tokenId);
        }
    }
    
    // normal mint
    function normalMint(uint amount_) payable external onlySender publicMintingEnabled {
        require(msg.value == mintPrice * amount_, "Invalid value!");
        require(amount_ <= maxTokensPerMint, "Over Max Tokens Per Mint!");
        require(normalTokensMinted + maxChickensNestTokens + amount_ <= maxTokens, "Not enough chickens remaining!");
        for (uint i = 0; i < amount_; i++) {
            uint _tokenId = getNormalMintId();
            normalTokensMinted++;
            _mint(msg.sender, _tokenId);
            emit Mint(msg.sender, _tokenId);
        }
    }
    
    ///// ***--- < Just-In-Case-Functions (Start) > ---*** /////
    /// receivable fallback functions just in case
    fallback () external payable {}
    receive () external payable {}

    /// withdrawal functions just in case
    function withdrawERC20(address contractAddress_) external onlyOwner {
        IERC20 _token = IERC20(contractAddress_);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    function withdrawERC721(address contractAddress_, uint tokenId_) external onlyOwner {
        IERC721(contractAddress_).safeTransferFrom(address(this), msg.sender, tokenId_);
    }
    function withdrawERC1155(address contractAddress_, uint tokenId_, uint amount_, bytes memory data_) external onlyOwner {
        IERC1155(contractAddress_).safeTransferFrom(address(this), msg.sender, tokenId_, amount_, data_);
    }
    ///// ***--- < Just-In-Case-Functions (End) > ---*** /////
}