pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract TheMaskSociety is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant cost = 0.04 ether;
    uint256 public constant maxSupply = 4447;
    uint256 public maxMintAmount = 5;
    uint256 public reserve = 150;
    bool public saleIsActive = false;
    bool public revealed = false;
    bool public isMetadataLocked = false;
    string baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale is not active at the moment");
        require(_mintAmount > 0, "Mint quantity must be greater than 0");
        require(_mintAmount <= maxMintAmount, "Your selection would exceed the total number of items to mint");
        require(supply + _mintAmount <= maxSupply - reserve, "Purchase would exceed max supply of Masks");

        require(msg.value >= cost * _mintAmount);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

    //only owner
    function reveal() public onlyOwner() {
        revealed = true;
    }


    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner() {
        maxMintAmount = _newMaxMintAmount;
    }

    function lockMetadata() public onlyOwner {
        isMetadataLocked = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        require(!isMetadataLocked,"Metadata is locked");
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!isMetadataLocked,"Metadata is locked");
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        require(!isMetadataLocked,"Metadata is locked");
        baseExtension = _newBaseExtension;
    }

    function setSaleIsActive(bool _state) public onlyOwner {
        saleIsActive = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function reserveMasks(address _to, uint256 _reserveAmount) public onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= reserve,
            "Not enough reserve left for team"
        );

        for (uint256 i = 1; i <= _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        reserve = reserve - _reserveAmount;
    }
}