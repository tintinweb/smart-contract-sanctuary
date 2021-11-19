// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract BoogerBellys is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public maxCount = 10000;
    uint256 public maxMintAmount = 69;
    bool public paused = false;
    
    Counters.Counter private _tokenIds;


    constructor(string memory _name,
                string memory _symbol,
                string memory _initBaseURI)
                ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function mint(uint _mintAmount) public payable {
        uint currentSupply = _tokenIds.current();
       
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint Amount is not greater than 0");
        require(_mintAmount <= maxMintAmount, "Mint Amount is greater than upper limit for minting");
        require((currentSupply + _mintAmount) <= maxCount, "Current minted Boogers + requested Booger is larger than available supply");
        
        
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Amount sent to contract is less than cost per Booger");
        }
        
        for(uint i = 0; i < _mintAmount; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(msg.sender, newTokenId);
        }
        
        if (_tokenIds.current() == 6) {
            pause(true);
        }
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        // Returns an array of wallets that are available from the owner
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;    
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}