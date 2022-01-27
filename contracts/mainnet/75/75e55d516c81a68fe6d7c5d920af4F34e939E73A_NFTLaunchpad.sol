// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FullERC721.sol";

contract NFTLaunchpad is ERC721Enumerable, Ownable {

    uint256 public _maxSupply = 10000;
    uint256 public _price = 0.05 ether;
    bool public _paused = false;

    mapping (uint256 => string) private _tokenId2image;
    mapping (uint256 => string) private _tokenId2desc;

    constructor() ERC721("NFTLaunchpad", "NFTLP") Ownable() {
	}

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "NFTLP #', Strings.toString(tokenId), 
                            '", "description": "', _tokenId2desc[tokenId], '", "image": "', _tokenId2image[tokenId], '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    function nextAvailableToken() external view returns (uint256) {
        for(uint256 i = 1; i <= _maxSupply; i++) {
            if(!_exists(i)) return i;
        }
        return 0;
    }
    function mint(uint256 tokenId) external payable {
        require(!_paused, "Sale paused");
        require(totalSupply() < _maxSupply, "Exceeds maximum supply");
        require(msg.value >= _price, "Ether sent is not correct");

        _tokenId2desc[tokenId] = "NFTLaunchpad lets you make your own NFT. Visit http://nftlaunchpad.io for more info";
        _safeMint(msg.sender, tokenId);
    }
    function setTokenImage(uint256 tokenId, string memory _tokenImage, string memory _desc) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "not authorized");
        _tokenId2image[tokenId] = _tokenImage;
        if(bytes(_desc).length > 0)
            _tokenId2desc[tokenId] = _desc;
    }
    function setMaxSupply(uint256 newVal) external onlyOwner {
        _maxSupply = newVal;
    }
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }
    function setPause(bool val) external onlyOwner {
        _paused = val;
    }
    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}