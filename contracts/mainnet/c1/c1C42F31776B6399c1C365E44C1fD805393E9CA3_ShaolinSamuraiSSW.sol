// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ShaolinSamuraiSSW is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public salePrice = 0.0888 ether;
    uint256 public constant maxTokenSupply = 8888;
    uint256 public whiteListMintMaxSupply = 3000;

    bool public whiteListSale = false;
    bool public regularSale = false;
    bool public reserveTokens = false;
    bool public revealed = false;
    bool public paused = true;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public totalAvailableForUser;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
    }

    function viewWhitelistForUser(address _user)
        external
        view
        returns (uint256)
    {
        return totalAvailableForUser[_user];
    }

    function whitelistBuy(uint256 _mintAmount) public payable {
        require(!paused);
        uint256 supply = totalSupply();
        require(msg.value >= salePrice.mul(_mintAmount));
        require(supply + _mintAmount <= whiteListMintMaxSupply);
        require(totalAvailableForUser[msg.sender] >= 1);
        require(whiteListSale == true);
        for (uint256 i = 0; i < _mintAmount; i++) {
            totalAvailableForUser[msg.sender] = totalAvailableForUser[
                msg.sender
            ].sub(1);
            _safeMint(msg.sender, supply + i);
        }
    }

    function regularSaleMint(uint256 _mintAmount) public payable {
        require(!paused);
        uint256 supply = totalSupply();
        require(msg.value >= salePrice.mul(_mintAmount));
        require(supply + _mintAmount <= maxTokenSupply);
        require(regularSale == true);
        require(_mintAmount <= 10);

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function reserve() public onlyOwner {
        require(reserveTokens == false);
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 500; i++) {
            _safeMint(msg.sender, supply + i);
        }
        reserveTokens = true;
    }

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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //owner
    function populateWhitelist(address[] memory _whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            totalAvailableForUser[_whitelisted[i]] = totalAvailableForUser[
                _whitelisted[i]
            ].add(2);
        }
    }

    function setWhitelistSale(bool _trueOrFalse) external onlyOwner {
        whiteListSale = !_trueOrFalse;
    }

    function setRegularSale(bool _trueOrFalse) external onlyOwner {
        regularSale = !_trueOrFalse;
    }

    function setSalePrice(uint256 _priceInWei) external onlyOwner {
        salePrice = _priceInWei;
    }

    function setNotRevealedURI(string memory _uri) external onlyOwner {
        notRevealedUri = _uri;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function PauseContract(bool _trueOrFalse) external onlyOwner {
        paused = !_trueOrFalse;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setwhiteListMintMaxSupply(uint256 _maxSupply) external onlyOwner {
        whiteListMintMaxSupply = _maxSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}