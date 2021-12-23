// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";

contract NftEye is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant OG_MAX_SUPPLY = 128;
    uint256 public constant CREATION_MAX_SUPPLY = 1024;
    uint256 public OG_PRICE = 0;
    uint256 public CREATION_PRICE = 0.512 ether;

    Counters.Counter private _ogTokenIdCounter;
    Counters.Counter private _creationTokenIdCount;

    mapping(address => bool) public OGList;

    constructor() ERC721("NFTEYE NFT", "NEN") {
        _ogTokenIdCounter.increment(); //start from 1
        _creationTokenIdCount._value = _ogTokenIdCounter.current() + OG_MAX_SUPPLY; //start from 129
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.nfteye.io/nft/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addToOGList(address[] calldata OGs) public onlyOwner {
        for (uint256 i = 0; i < OGs.length; i++) {
            address og = OGs[i];
            require(og != address(0), "Null address");
            require(!OGList[og], "Duplicated address");
            OGList[og] = true;
        }
    }

    function removeFromOGList(address[] calldata OGs) public onlyOwner {
        for (uint256 i = 0; i < OGs.length; i++) {
            address og = OGs[i];
            require(og != address(0), "Null address");
            OGList[og] = false;
        }
    }

    function safeMint() public payable whenNotPaused {
        if (OGList[msg.sender]) {
            require(msg.value >= OG_PRICE);
            _OGMint(msg.sender);
        } else {
            require(msg.value >= CREATION_PRICE);
            _CreationMint(msg.sender);
        }
    }

    function _OGMint(address to) internal {
        uint256 tokenId = _ogTokenIdCounter.current();
        require(tokenId <= OG_MAX_SUPPLY);
        require(balanceOf(to) == 0); //Only one for OG
        _ogTokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _CreationMint(address to) internal {
        uint256 tokenId = _creationTokenIdCount.current();
        require(tokenId <= (CREATION_MAX_SUPPLY + OG_MAX_SUPPLY));
        _creationTokenIdCount.increment();
        _safeMint(to, tokenId);
    }

    function withdraw() public onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        return balance;
    }
}