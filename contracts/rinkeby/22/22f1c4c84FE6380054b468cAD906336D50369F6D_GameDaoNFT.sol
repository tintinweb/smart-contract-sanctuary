// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

//只有众筹合约可以调用这个合约 其他没限制 限制合约全在众筹合约中

contract GameDaoNFT is ERC721,Ownable,Pausable {
    using Strings for uint256;

    uint256 public totalSupply;

    mapping(address => bool) private _allowList;

    string private _contractURI = "";
    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";

    constructor(string memory name, string memory symbol) ERC721(name,symbol) {}


    function addToAllowList(address addr) external onlyOwner whenNotPaused {
        require(addr != address(0),"zero address");
        _allowList[addr] = true;
    }

    function removeFromAllowList(address addr) external onlyOwner whenNotPaused {
        require(addr != address(0),"zero address");
        require(_allowList[addr],"invalid address");
        _allowList[addr] = false;
    }


    function mintTo(uint256 numberOfTokens,address to) external whenNotPaused payable {
        require(to != address(0),"zero address");
        require(_allowList[msg.sender],"u are not on the allow list");

        for (uint256 i=0;i<numberOfTokens;i++) {
            uint256 tokenId = totalSupply+1;
            totalSupply+=1;
            _safeMint(to,tokenId);
        }
    }


    function setContractURI(string calldata URI) external  onlyOwner whenNotPaused {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external  onlyOwner  whenNotPaused {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external  onlyOwner whenNotPaused {
        _tokenRevealedBaseURI = revealedBaseURI;
    }


    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        _tokenBaseURI;
    }

}