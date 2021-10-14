// SPDX-License-Identifier: MIT

/**
 ________  ________  ___  ___  ___  ___
|\   __  \|\   __  \|\  \|\  \|\  \|\  \
\ \  \|\ /\ \  \|\  \ \  \\\  \ \  \\\  \
 \ \   __  \ \   _  _\ \  \\\  \ \   __  \
  \ \  \|\  \ \  \\  \\ \  \\\  \ \  \ \  \
   \ \_______\ \__\\ _\\ \_______\ \__\ \__\
    \|_______|\|__|\|__|\|_______|\|__|\|__|
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * @title Dude contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract Dude is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public constant cost = 0.001 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 10;
  bool public salePaused = true;
  bool public revealed = false;
  string private notRevealedUri;

  uint public presaleMaxMint = 7;
  bool public presaleActive = false;
  mapping(address => bool) private presaleList;
  mapping(address => uint256) private presalePurchases;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("Dude", "HFSP") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    

    function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
        presaleMaxMint = _presaleMaxMint;
    }

    function setPresaleActive(bool _presaleActive) external onlyOwner {
        presaleActive = _presaleActive;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!presaleList[addresses[i]]) {
                presaleList[addresses[i]] = true;
                presalePurchases[addresses[i]] = 0;
            }
        }
    }

    function isOnPresaleList(address addr) external view returns (bool) {
        return presaleList[addr];
    }

    function presaleAmountAvailable(address addr) external view returns (uint256) {
        if (presaleList[addr]) {
            return presaleMaxMint - presalePurchases[addr];
        }
            return 0;
    }

    function mintPresaleBruh(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(presaleActive, "Presale not active");
        require(_mintAmount > 0, "_mintAmount must be at 0");
        require(_mintAmount <= presaleMaxMint, "_mintAmount must be <= presaleMaxMint");
        require(supply + _mintAmount <= maxSupply, "Mint must not surpass maxSupply");
        require(msg.value >= cost * _mintAmount, "Not enough Ether to buy");
        require(presaleList[msg.sender] == true, "Not on the list");
        require(presalePurchases[msg.sender] + _mintAmount <= presaleMaxMint, "No presale mints left");

        presalePurchases[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

// internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

// public
    function mintBruh(uint _mintAmount) public payable {
        require(!salePaused, "Sale must be active to mint Tokens");
        require(_mintAmount <= maxMintAmount, "Exceeded max token purchase");
        // CHANGED: mult and add to + and *
        require(totalSupply() + _mintAmount <= maxSupply, "Purchase would exceed max supply of tokens");
        // CHANGED: mult and add to + and *
        require(cost * _mintAmount <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < _mintAmount; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
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


    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        salePaused = _state;
    }
    function reserveTokens() public onlyOwner {
            uint supply = totalSupply();
            uint i;
            for (i = 0; i < 17; i++) {
                _safeMint(msg.sender, supply + i);
            }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}