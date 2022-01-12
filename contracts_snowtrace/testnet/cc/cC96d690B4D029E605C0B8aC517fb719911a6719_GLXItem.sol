// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./Strings.sol";

contract GLXItem is Context, AccessControl, ERC1155 {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory baseURI) ERC1155(baseURI) {
    	_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    	_grantRole(MINTER_ROLE, _msgSender());
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    	_grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    	_revokeRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
    	_mint(to, id, amount, "");
    }

    function burn(address from, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
    	_burn(from, id, amount);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
	    return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
    	public
    	view
    	override(AccessControl, ERC1155)
    	returns (bool)
    {
    	return super.supportsInterface(interfaceId);
    }
}