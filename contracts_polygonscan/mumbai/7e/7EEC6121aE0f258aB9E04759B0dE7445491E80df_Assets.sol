// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "ERC1155.sol";

contract Assets is ERC1155 {
    bool internal _isInitialized;
    mapping(uint256 => address) internal _minters;
    mapping(uint256 => bool) internal _mintingLocks;

    event MintingLocked(uint256 indexed id);

    modifier onlyMinter(uint256 id) {
        require(
            msg.sender == _minters[id],
            "Assets: caller must be the minter"
        );
        _;
    }

    modifier onlyWhenMintingUnlocked(uint256 id) {
        require(!_mintingLocks[id], "Assets: minting must be unlocked");
        _;
    }

    constructor() ERC1155("") {}

    function initialize(string memory uri) external {
        require(!_isInitialized, "Assets: contract is already initialized");

        _isInitialized = true;

        _setURI(uri);
    }

    function minterOf(uint256 id) external view returns (address) {
        return _minters[id];
    }

    function isMintingLocked(uint256 id) external view returns (bool) {
        return _mintingLocks[id];
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyWhenMintingUnlocked(id) {
        address minter = _minters[id];
        if (minter == address(0)) {
            _minters[id] = msg.sender;
        } else {
            require(msg.sender == minter, "Assets: caller must be the minter");
        }

        _mint(to, id, amount, data);
    }

    function lockMinting(uint256 id) external onlyMinter(id) {
        if (_mintingLocks[id]) {
            return;
        }

        _mintingLocks[id] = true;

        emit MintingLocked(id);
    }
}