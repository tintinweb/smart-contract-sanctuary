// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./console.sol";

contract ERC721Item is ERC721Enumerable, AccessControl, Pausable {
    using Address for address;
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    address private gameAdmin;
    string private baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address gameAdmin_
    ) public ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);
        _setupRole(GAME_ADMIN, gameAdmin_);
        gameAdmin = gameAdmin_;
        baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 tokenId) public restricted {
        require(!_exists(tokenId), "Cannot mint existed tokenId");
        _mint(to, tokenId);
    }

    function exists(uint256 tokenId) public restricted returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory baseURI_) public restricted {
        baseURI = baseURI_;
    }

    function burn(uint256 tokenId) public restricted {
        _burn(tokenId);
    }

    function setGameAdmin(address _gameAdmin) public restricted {
        gameAdmin = _gameAdmin;
    }

    function setAdmin(address _adminAddress) public restricted {
        _setupRole(GAME_ADMIN, _adminAddress);
    }

    function removeAdmin(address _adminAddress) public restricted {
        _revokeRole(GAME_ADMIN, _adminAddress);
    }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function setPause() public restricted {
        _pause();
    }

    function unsetPause() public restricted {
        _unpause();
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // view
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}