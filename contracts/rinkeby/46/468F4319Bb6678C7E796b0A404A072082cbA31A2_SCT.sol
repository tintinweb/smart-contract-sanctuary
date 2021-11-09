// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SCT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public price = 0.065 ether;
    uint256 public maxSupply = 9999;
    uint256 public reservedGiveaway = 99; // Reserved last 99 SharkCats for giveaway (SharkCat ID 9901 - 9999)
    uint256 public limitMintPerAddress = 20;
    string public baseURI;
    string public baseExtension = ".json";
    bytes32 private rootOGWhitelist;
    bytes32 private rootWhitelist;
    bool public paused = true;
    bool public hidden = true;
    
    enum SaleRound {
        OG,
        Whitelist,
        Public
    }
    
    SaleRound public saleRound = SaleRound.OG;
    
    mapping(SaleRound => uint256) public totalPreMintCount;
    mapping(SaleRound => mapping(address => uint256)) public preMintAddressesMintedCount;
    mapping(address => uint256) public addressesMintedCount;
    
    constructor(
        string memory _initBaseURI
    ) ERC721("SCT", "SCT") {
        setBaseURI(_initBaseURI);
    }
    
    modifier openMint(uint _mintAmount) {
        uint256 supply = totalSupply();
        require(!paused, "Sale paused");
        require(msg.sender != owner());
        require(supply + _mintAmount <= maxSupply - reservedGiveaway, "Exceeds the maximum SharkCats supply");
        require(msg.value >= price * _mintAmount, "Insufficient funds");
        _;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function isOGWhitelisted(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(address(this), msg.sender));
        return MerkleProof.verify(proof, rootOGWhitelist, leaf);
    }
    
    function isWhitelisted(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(address(this), msg.sender));
        return MerkleProof.verify(proof, rootWhitelist, leaf);
    }
    
    function preSaleMint(uint256 _mintAmount, bytes32[] memory proof) public payable openMint(_mintAmount) {
        uint256 supply = totalSupply();
        require(saleRound == SaleRound.OG || saleRound == SaleRound.Whitelist, "Already open for public sale");
        if (saleRound == SaleRound.OG) {
            require(isOGWhitelisted(proof), "Not OG whitelisted");
            require(totalPreMintCount[SaleRound.OG] + _mintAmount <= 1000, "Exceeds reserved OG SharkCats supply");
            require(
                preMintAddressesMintedCount[SaleRound.OG][msg.sender] + _mintAmount <= 2,
                "Mint SharkCat per address exceeded, come back next mint round"
            );
        } else if (saleRound == SaleRound.Whitelist) {
            require(isWhitelisted(proof) || isOGWhitelisted(proof), "Not whitelisted");
            require(totalPreMintCount[SaleRound.Whitelist] + _mintAmount <= 3000, "Exceeds reserved whitelist SharkCats supply");
            require(
                preMintAddressesMintedCount[SaleRound.Whitelist][msg.sender] + _mintAmount <= 1,
                "Mint SharkCat per address exceeded, come back next mint round"
            );
        }
        require(
            addressesMintedCount[msg.sender] + _mintAmount <= limitMintPerAddress,
            "Mint SharkCat per address exceeded"
        );
        
        preMintAddressesMintedCount[saleRound][msg.sender] += _mintAmount;
        addressesMintedCount[msg.sender] += _mintAmount;
        if (saleRound == SaleRound.OG) {
            totalPreMintCount[SaleRound.OG] += _mintAmount;
        } else if (saleRound == SaleRound.Whitelist) {
            totalPreMintCount[SaleRound.Whitelist] += _mintAmount;
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i - (99 - reservedGiveaway));
        }
    }
    
    function mint(uint256 _mintAmount) public payable openMint(_mintAmount) {
        uint256 supply = totalSupply();
        require(saleRound == SaleRound.Public, "Not ready for public sale");
        require(
            addressesMintedCount[msg.sender] + _mintAmount <= limitMintPerAddress,
            "Mint SharkCat per address exceeded"
        );
        
        addressesMintedCount[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i - (99 - reservedGiveaway));
        }
    }
    
    function giveAway(address _to, uint256[] memory _tokenIds) external onlyOwner {
        uint256 supply = totalSupply();
        require(_tokenIds.length > 0, "The minimum of giveaway is 1");
        require(_tokenIds.length <= reservedGiveaway, "Exceeds reserved giveaway SharkCats supply");
        require(supply + _tokenIds.length <= maxSupply, "Exceeds maximum SharkCats supply");
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(!_exists(_tokenIds[i]), "Giveaway Token ID already exists");
            require(_tokenIds[i] >= 9901 && _tokenIds[i] <= 9999, "Token ID out of range");
        }
        
        reservedGiveaway -= _tokenIds.length;
        for (uint i = 0; i < _tokenIds.length; i++){
            _safeMint(_to, _tokenIds[i]);
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        string memory currentBaseURI = _baseURI();
        if (hidden) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, baseExtension))
            : "";
        }
        
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function setRootOGWhitelist(bytes32 _root) public onlyOwner {
        rootOGWhitelist = _root;
    }
    
    function setRootWhitelist(bytes32 _root) public onlyOwner {
        rootWhitelist = _root;
    }

    function setLimitMintPerAddress(uint256 _newLimitAmount) public onlyOwner {
        limitMintPerAddress = _newLimitAmount;
    }
    
    function setSaleRound(SaleRound _round) external onlyOwner {
        saleRound = _round;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setHidden(bool _state) public onlyOwner {
        hidden = _state;
    }
    
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}