// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract testNFT4 is ERC721Enumerable, ERC721Burnable, Ownable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    uint256 private maxMint = 20;
    string private baseTokenURI;

    constructor(
        string memory _uri,
        string memory _contractName,
        string memory _tokenSymbol,
        uint256 _maxMint
    ) ERC721(_contractName, _tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        maxMint = _maxMint;
        baseTokenURI = _uri;
    }

    function mint(address to) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        require(_tokenIdTracker.current() < maxMint, "Max mint reached");

        _mint(to, _tokenIdTracker.current());

        _tokenIdTracker.increment();
    }

    function canMint(uint256 quantity) external view returns (bool) {
        return (_tokenIdTracker.current() + quantity) <= maxMint;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata uri) public onlyOwner() {
        baseTokenURI = uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}