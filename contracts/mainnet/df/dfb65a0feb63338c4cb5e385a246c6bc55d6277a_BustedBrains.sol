// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BustedBrains is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    uint256 public maxSupply = 7777;
    uint256 private _presaleAt;
    uint256 private _launchAt;
    bool public paused = false;

    uint256 public PRICE = 60000000000000000; // 0.06 ether
    address public constant creator1Address = 0xc103dc21FE364807652Ce389386fa964Ec5d7a92;
    address public constant creator2Address = 0x65fa94209a50E2B336924E77313F80605020e625;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 presaleAt_,
        uint256 launchAt_
    ) ERC721(_name, _symbol) {
        _presaleAt = presaleAt_;
        _launchAt = launchAt_;

        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function launchAt() external view returns (uint256) {
        return _launchAt;
    }

    function presaleAt() external view returns (uint256) {
        return _presaleAt;
    }

    function isPresale() external view returns (bool) {
        return block.timestamp >= _presaleAt && block.timestamp < _launchAt;
    }

    function isLaunched() external view returns (bool) {
        return block.timestamp >= _launchAt;
    }

    function presaleMint(address _to, uint256 _mintAmount) public payable {
        require(_presaleAt < block.timestamp, "presale has not begun");
        require(block.timestamp < _launchAt, "presale has ended");
        mint(_to, _mintAmount);
    }

    function launchMint(address _to, uint256 _mintAmount) public payable {
        require(!paused, "Sale hasn't started");
        require(_launchAt < block.timestamp, "Launch has not begun");
        mint(_to, _mintAmount);
    }

    function mint(address _to, uint256 _mintAmount) internal {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "You can get no fewer than 1");
        require(supply + _mintAmount <= maxSupply, "Sold out");

        if (msg.sender != owner()) {
            require(msg.value >= SafeMath.mul(PRICE, _mintAmount), "Amount of Ether sent is not correct");
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setLaunchAt(uint256 value) public onlyOwner {
        _launchAt = value;
    }

    function setPresaleAt(uint256 value) public onlyOwner {
        _presaleAt = value;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator2Address, balance.mul(10).div(100));
        _widthdraw(creator1Address, address(this).balance);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}