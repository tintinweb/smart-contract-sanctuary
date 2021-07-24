// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721Custom.sol";
import "./Counters.sol";

contract HeroFiNFT is ERC721Custom {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address private _owner;

    string private _uri;

    uint256 private _categoryId;

    Counters.Counter private _tokenIdTracker;

    mapping(address => bool) private minters;

    event MintArt(address to, uint256 artId);

    constructor(
        string memory tokenName,
        string memory symbol,
        string memory baseUrl_,
        string memory uri_,
        uint256 categoryId_
    ) ERC721Custom(tokenName, symbol) {
        _owner = msg.sender;
        minters[msg.sender] = true;

        _setBaseURI(baseUrl_);
        _uri = uri_;
        _categoryId = categoryId_;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    function addMinter(address minter_) external virtual onlyOwner {
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyOwner {
        minters[minter_] = false;
    }

    function setBaseURI(string memory url_) public virtual onlyOwner {
        _setBaseURI(url_);
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "!minter");
        _;
    }

    function mintArt(address to) public onlyMinter returns (uint256) {
        _tokenIdTracker.increment();
        uint256 artId = _tokenIdTracker.current();
        _safeMint(to, artId);
        _setTokenURI(artId, _uri);
        emit MintArt(to, artId);

        return artId;
    }

    function ofCategory() external view virtual returns (uint256) {
        return _categoryId;
    }
}