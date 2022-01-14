// SPDX-License-Identifier: MIT

import './ERC721Enumerable.sol';
import './Ownable.sol';

// Contract: X07 Kiddos
// Created by: Notifao Technologies Corp.

pragma solidity ^0.8.7;

contract X07Kiddos is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 private _reserved = 108;        // -1 = 107 reserved tokens
    uint256 public cost = 0.07 ether;       // mint price
    bool public paused = false;
    bool public whitelistOnly = true;
    mapping(address => bool) public whitelisted;
    address public proxyRegistryAddress;    // OpenSea proxy address to eliminate fees on approval

    mapping(address => bool) public projectProxy;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount < 11);                                                          // -1 = 10 is max mint amount
        require(supply + _mintAmount < 7778 - _reserved);                                   // -1 = 7777 is token max supply
        require((balanceOf(msg.sender) + _mintAmount) < 11, "Wallet limit is reached.");    // -1 = 10 is max wallet limit

        if (whitelistOnly == false) {
            if (msg.sender != owner()) {
                if(whitelisted[msg.sender] != true) {
                    require(msg.value >= cost * _mintAmount);
                }
            }

            for (uint256 i; i < _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
        else if (whitelistOnly == true) {
            require(whitelisted[msg.sender] == true, "Address is not whitelisted.");

            for (uint256 i; i < _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

 // only owner

    function collectReserves(address _to, uint256 _reservesAmount) external onlyOwner() {
        require(_reservesAmount < _reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        for(uint256 i; i < _reservesAmount; i++){
            _safeMint(_to, supply + i);
        }

        _reserved -= _reservesAmount;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
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

    function activateWhitelist(bool _state) public onlyOwner {
        whitelistOnly = _state;
    }

    function whitelistUser(address[] memory _user) public onlyOwner {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            whitelisted[_user[x]] = true;
        }
    }

    function removeWhitelistUser(address[] memory _user) public onlyOwner {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            whitelisted[_user[x]] = false;
        }
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}