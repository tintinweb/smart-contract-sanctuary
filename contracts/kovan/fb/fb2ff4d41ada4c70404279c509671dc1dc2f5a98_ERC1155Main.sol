// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Burnable.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./IExchangeProvider.sol";
import "./ERC1155URIStorage.sol";

contract ERC1155Main is ERC1155Burnable, ERC1155URIStorage, AccessControl {
    bytes32 public SIGNER_ROLE = keccak256("SIGNER_ROLE");
    address public factory;

    uint256 private _lastMintedId;
    mapping(string => bool) hasTokenWithURI;

    constructor(string memory _baseUri, address signer) ERC1155("") {
        factory = _msgSender();
        _setBaseUri(_baseUri);
        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        _setupRole(SIGNER_ROLE, signer);
    }

    function mint(
        uint256 amount,
        string calldata _tokenURI,
        bytes calldata signature
    ) external {
        _verifySigner(_tokenURI, amount, signature);
        require(!hasTokenWithURI[_tokenURI], "ERC1155Main: URI already exists");

        uint256 id = _lastMintedId++;
        _mint(_msgSender(), id, amount, "");
        setApprovalForAll(IExchangeProvider(factory).exchange(), true);
        _markTokenId(id);
        hasTokenWithURI[_tokenURI] = true;
        _setTokenURI(id, _tokenURI);
    }

    function mint(
        uint256 amount,
        string calldata _tokenURI,
        bytes memory data,
        bytes calldata signature
    ) external {
        _verifySigner(_tokenURI, amount, signature);
        require(!hasTokenWithURI[_tokenURI], "ERC1155Main: URI already exists");

        uint256 id = _lastMintedId++;
        _mint(_msgSender(), id, amount, data);
        setApprovalForAll(IExchangeProvider(factory).exchange(), true);
        _markTokenId(id);
        hasTokenWithURI[_tokenURI] = true;
        _setTokenURI(id,_tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.tokenURI(tokenId);
    }

    function _verifySigner(
        string calldata _tokenURI,
        uint256 amount,
        bytes calldata signature
    ) private view {
        address signer =
            ECDSA.recover(
                keccak256(abi.encodePacked(this, _tokenURI, amount)),
                signature
            );
        require(
            hasRole(SIGNER_ROLE, signer),
            "ERC1155Main: Signer should sign transaction"
        );
    }
}