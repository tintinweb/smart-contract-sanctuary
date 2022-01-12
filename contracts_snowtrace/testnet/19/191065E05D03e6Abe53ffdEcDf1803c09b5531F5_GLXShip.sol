// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";

contract GLXShip is Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("Galaxy Ship", "GLXShip") {
    	_baseTokenURI = baseURI;

    	_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    	_grantRole(MINTER_ROLE, _msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
    	return _baseTokenURI;
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    	_grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    	_revokeRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 id) external onlyRole(MINTER_ROLE) {
    	_safeMint(to, id);
    }

    function supportsInterface(bytes4 interfaceId)
    	public
    	view
    	override(AccessControl, ERC721Enumerable)
    	returns (bool)
    {
    	return super.supportsInterface(interfaceId);
    }
}