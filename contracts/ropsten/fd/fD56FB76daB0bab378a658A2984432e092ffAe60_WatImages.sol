// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract WatImages is Ownable, ERC721Enumerable, ReentrancyGuard {
    uint256 private _priceForSingleMint;

    constructor() ERC721("WatermarkedImage", "WMI") {
        _priceForSingleMint = 0.02 ether;
    }

    struct Image {
        uint256 id;
        string name;
        string description;
        string tokenURL;
        uint256 imageHash; 
    }
    Image[] private images;

    function setCostForMintingWatermarkedImage(uint256 _price) external onlyOwner(){
        _priceForSingleMint = _price;
    }

    function getCostForMintingWatermarkedImage(uint256 _numToMint) public view returns (uint256) {
        return _numToMint * _priceForSingleMint;
    }

    function mint(uint8 v, bytes32 r, bytes32 s, address _to, uint256 _tokenId, string memory _tokenName, string memory _description, string memory _tokenURL, uint256 _imageHash) public payable nonReentrant() {
        require(!_exists(_tokenId), "ERROR: Can't mint - token already exists");
        require(_to != address(0), "ERROR: Can't mint - address (0)");
        require(_to == msg.sender, "ERROR: Can't mint - msg.sender is not equal to _to address");
        
        string memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(keccak256(abi.encodePacked(_tokenId, _to)), keccak256(abi.encodePacked(_tokenName)), keccak256(abi.encodePacked(_description)), keccak256(abi.encodePacked(_tokenURL)), keccak256(abi.encodePacked(_imageHash))))));
        require(ecrecover(prefixedHash, v, r, s) == owner(), "ERROR: Verifying signature failed");

        uint256 costForMintingWatermarkedImage = getCostForMintingWatermarkedImage(1);
        require(msg.value >= costForMintingWatermarkedImage, "Too little sent, please send more eth.");
        if (msg.value > costForMintingWatermarkedImage) {
            payable(msg.sender).transfer(msg.value - costForMintingWatermarkedImage);
        }

        _safeMint(_to, _tokenId);
        images.push(Image(_tokenId, _tokenName, _description, _tokenURL, _imageHash));
    }

    function mint(uint8 v, bytes32 r, bytes32 s, address _to, uint256[] memory _tokenId, string[] memory _tokenName, string[] memory _description, string[] memory _tokenURL, uint256[] memory _imageHash) public payable nonReentrant() {
        require(_to != address(0), "ERROR: Can't mint - address (0)");
        require(_to == msg.sender, "ERROR: Can't mint - msg.sender is not equal to _to address");
        for (uint i = 0; i < _tokenId.length; i++){
            require(!_exists(_tokenId[i]), "ERROR: Can't mint - token already exists");
        }
        require(_tokenId.length == _tokenName.length && _tokenId.length == _imageHash.length && _tokenId.length == _description.length && _description.length == _tokenURL.length, "ERROR: Unequal list length");

        string memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory sumMessage;
        for (uint i = 0; i < _tokenId.length; i++){
            sumMessage = abi.encodePacked(sumMessage, keccak256(abi.encodePacked(_tokenId[i])), keccak256(abi.encodePacked(_tokenName[i])), keccak256(abi.encodePacked(_description[i])), keccak256(abi.encodePacked(_tokenURL[i])), keccak256(abi.encodePacked(_imageHash[i])));
        }
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(keccak256(abi.encodePacked(_to)), keccak256(sumMessage)))));
        require(ecrecover(prefixedHash, v, r, s) == owner(), "ERROR: Verifying signature failed");

        uint256 costForMintingWatermarkedImage = getCostForMintingWatermarkedImage(_tokenId.length);
        require(msg.value >= costForMintingWatermarkedImage, "Too little sent, please send more eth.");
        if (msg.value > costForMintingWatermarkedImage) {
            payable(msg.sender).transfer(msg.value - costForMintingWatermarkedImage);
        }
        for (uint i = 0; i < _tokenId.length; i++){
            _safeMint(_to, _tokenId[i]);
            images.push(Image(_tokenId[i], _tokenName[i], _description[i], _tokenURL[i], _imageHash[i]));
        }
    }
    

    function getAllTokens() external view returns (Image[] memory) {
        return images;
    }

    function getAllDataOfOwnerTokens(address _tokensOwner) external view returns (Image[] memory) {
        require(_tokensOwner != address(0), "ERC721: tokens for the zero address");
        require(balanceOf(_tokensOwner) > 0, "Address doesn't have any tokens");
        Image[] memory imagesOfOwner = new Image[](balanceOf(_tokensOwner));
        for (uint i=0; i<balanceOf(_tokensOwner); i++) {
            uint256 tokenIndex = _getIndexInAllTokensIndex(_getTokenFromOwnedTokens(_tokensOwner,i));
            imagesOfOwner[i] = Image(images[tokenIndex].id, images[tokenIndex].name, images[tokenIndex].description, images[tokenIndex].tokenURL, images[tokenIndex].imageHash);
        }
        return imagesOfOwner;
    }

    function getAllDataOfToken(uint256 _tokenId) public view returns (Image memory) {
        require(_exists(_tokenId), "Nonexistent token");
        uint256 tokenIndex = _getIndexInAllTokensIndex(_tokenId);
        return Image(images[tokenIndex].id, images[tokenIndex].name, images[tokenIndex].description, images[tokenIndex].tokenURL, images[tokenIndex].imageHash);
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

}