// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


contract CryptoKittenNFT is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS_NORMAL = 10000;
    uint256 public constant PRICE_NORMAL = 10 * 10**15;
    uint256 public constant MAX_BY_MINT_NORMAL = 100;
     uint256 public constant MAX_ELEMENTS_GENESIS = 50;
    uint256 public constant PRICE_GENESIS = 11 * 10**15;
    uint256 public constant MAX_BY_MINT_GENESIS = 5;
    uint256 public normal_total = 0;
    uint16 public genesis_total = 0;
    address public constant creatorAddress = 0xfed1CED046938c79e9D708366ebed3c64Dd3DC22;
    string public baseTokenURI;
    bool private _pause;

    event JoinFace(uint256 indexed id);

    constructor(string memory baseURI) ERC721("CryptoKittensTest", "CK") {
        setBaseURI(baseURI);
        pause(false);
    }

    // modifier saleIsOpen {
    //     require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
    //     if (_msgSender() != owner()) {
    //         require(!_pause, "Pausable: paused");
    //     }
    //     _;
    // }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function pauseState()external view returns(bool) {
        return _pause;
    }
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    // }


 

    function totalMint() external view returns (uint256) {
        return _totalSupply();
    }
    function mint_normal(address _to, uint256 _count) public payable {
        // uint256 total = _totalSupply();
        require(normal_total + _count <= MAX_ELEMENTS_NORMAL, "Max limit");
        require(normal_total <= MAX_ELEMENTS_NORMAL, "Sale end");
        require(_count <= MAX_BY_MINT_NORMAL, "Exceeds number");
        require(msg.value >= PRICE_NORMAL * _count, "Value below price");
        for (uint256 i = 0; i < _count; i++) {
             normal_total++;
            _mintAnNormalElement(_to);
           
        }
    }
        function mint_genesis(address _to, uint256 _count) public payable {
        // uint256 total = _totalSupply();
        require(genesis_total + _count <= MAX_ELEMENTS_GENESIS, "Max limit");
        require(genesis_total <= MAX_ELEMENTS_GENESIS, "Sale end");
        require(_count <= MAX_BY_MINT_GENESIS, "Exceeds number");
        require(msg.value >= PRICE_GENESIS * _count, "Value below price");
        for (uint256 i = 0; i < _count; i++) {
             genesis_total++;
            _mintAnGenesisElement(_to);
           
        }
    }
    function _mintAnNormalElement(address _to) private {
        uint id = normal_total;
        // _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit JoinFace(id);
    }
    function _mintAnGenesisElement(address _to) private {
        uint id = genesis_total;
        // _tokenIdTracker.increment();
        _safeMint(_to, id + 100);
        emit JoinFace(id + 100);
    }
    // function price(uint256 _count) public pure returns (uint256) {
    //     return PRICE.mul(_count);
    // }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }    
    function pause(bool val) public onlyOwner {
        _pause = val;
    }
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        // _widthdraw(devAddress, balance.mul(25).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    
}