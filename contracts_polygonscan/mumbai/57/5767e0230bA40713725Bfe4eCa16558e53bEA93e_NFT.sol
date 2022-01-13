// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract NFT is ERC721, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseURI;
    mapping(address => bool) _minted;
    mapping(bytes32 => bool) _idMinted;

    address private _signer;

    // name: RSS3 X JIKE
    // symbol: RSS3JIKENFT
    constructor(
        address signer,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _signer = signer;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _hash(address _address, string memory id, uint256 salt) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_address, id, salt, address(this)));
    }

    function _verify(bytes32 hash, bytes memory sig) internal view returns (bool) {
        return (_recover(hash, sig) == _signer);
    }

    function _recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(sig);
    }

    function hasMinted(address account, string memory id) public view returns (bool, bool) {
        return (_minted[account], _idMinted[keccak256(abi.encodePacked(id))]);
    }

    function mint(address to, string memory id, uint256 salt, bytes memory sig) public {
        require(tx.origin == msg.sender, "Contract is now allowed to mint");
        require(_verify(_hash(to, id, salt), sig), "Invalid token");
        require(!_minted[to], "Already minted");

        bytes32 hash = keccak256(abi.encodePacked(id));
        require(!_idMinted[hash], "Id already minted");

        // mint
        _safeMint(to, totalSupply() + 1);
        _tokenIds.increment();

        // set minted flag
        _minted[to] = true;
        _idMinted[hash] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setSigner(address account) public onlyOwner {
        _signer = account;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return _baseURI();
    }
}