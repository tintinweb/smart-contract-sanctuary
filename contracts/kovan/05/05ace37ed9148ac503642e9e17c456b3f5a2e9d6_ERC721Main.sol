// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./IExchangeProvider.sol";

contract ERC721Main is
    ERC721Burnable,
    ERC721Enumerable,
    ERC721URIStorage,
    AccessControl
{
    bytes32 public SIGNER_ROLE = keccak256("SIGNER_ROLE");

    string public baseURI;

    address public factory;

    uint256 private _lastMintedId;
    mapping(string => bool) private hasTokenWithURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        address signer
    ) ERC721(_name, _symbol) {
        factory = _msgSender();
        baseURI = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        _setupRole(SIGNER_ROLE, signer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721._beforeTokenTransfer(from, to, tokenId);
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        hasTokenWithURI[tokenURI(tokenId)] = false;
        ERC721URIStorage._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function mint(
        string calldata _tokenURI,
        bytes calldata signature
    ) external {
        _verifySigner(_tokenURI, signature);
        require(!hasTokenWithURI[_tokenURI], "ERC721Main: URI already exists");

        uint256 tokenId = _lastMintedId++;
        _safeMint(_msgSender(), tokenId);

        hasTokenWithURI[_tokenURI] = true;
        _setTokenURI(tokenId, _tokenURI);
        setApprovalForAll(IExchangeProvider(factory).exchange(), true);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _verifySigner(string calldata _tokenURI, bytes calldata signature) private view {
        address signer =
            ECDSA.recover(keccak256(abi.encodePacked(this, _tokenURI)), signature);
        require(
            hasRole(SIGNER_ROLE, signer),
            "ERC721Main: Signer should sign transaction"
        );
    }
}