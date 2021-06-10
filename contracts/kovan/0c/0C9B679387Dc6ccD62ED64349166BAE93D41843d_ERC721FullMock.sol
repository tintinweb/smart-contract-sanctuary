// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Extensions.sol";
import "./Counters.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./IERC721FullMock.sol";

/**
 * @title ERC721Mock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract ERC721FullMock is IERC721FullMock, ERC721Extensions, AccessControlEnumerable, Pausable {
    string private _baseTokenURI;
    address public owner;
    
    using Counters for Counters.Counter;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    
    Counters.Counter private _tokenIdTracker;

    constructor (string memory name, string memory symbol, string memory baseTokenURI, uint256 initTokenID) ERC721(name, symbol) {
        require(initTokenID > 0, "ERC721Mock: initTokenID must be larger than 0");
        owner = _msgSender();
        _tokenIdTracker._value += initTokenID;
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view override returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    function mint(address toAddress, string memory tokenURI) public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        uint tokenIDTemp = _tokenIdTracker.current();
        _mint(toAddress, tokenIDTemp);
        _setTokenURI(tokenIDTemp, tokenURI);
        _tokenIdTracker.increment();
        emit Mint(msg.sender, toAddress, tokenURI, tokenIDTemp);
    }

    function safeMint(address toAddress, string memory tokenURI) override public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        uint tokenIDTemp = _tokenIdTracker.current();
        _safeMint(toAddress, tokenIDTemp);
        _setTokenURI(tokenIDTemp, tokenURI);
        _tokenIdTracker.increment();
        emit SafeMint(msg.sender, toAddress, tokenURI, tokenIDTemp);
    }

    function safeMint(address toAddress, string memory tokenURI, bytes memory _data) override public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        uint tokenIDTemp = _tokenIdTracker.current();
        _safeMint(toAddress, tokenIDTemp, _data);
        _setTokenURI(tokenIDTemp, tokenURI);
        _tokenIdTracker.increment();
        emit SafeMint(msg.sender, toAddress, tokenURI, _data, tokenIDTemp);
    }

    function burn(uint256 tokenId) public override {
        require(hasRole(BURN_ROLE, _msgSender()) || _isApprovedOrOwner(_msgSender(), tokenId), "ERC721PresetMinterPauserAutoId: must have burner role to burn");
        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }
    
    function pause() public virtual override {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
        emit Pauser(_msgSender());
    }
    
    function unpause() public virtual override {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
        emit Unpauser(_msgSender());
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Extensions) {
        require(!paused(), "ERC721Pausable: token transfer while paused");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721FullMock, ERC721Extensions, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}