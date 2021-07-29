// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "ERC1155.sol";

contract Assets is ERC1155 {
    bool internal _isInitialized;
    mapping(uint256 => address) internal _minters;
    mapping(uint256 => bool) internal _mintingLocks;

    event MintingLocked(uint256 indexed id);

    modifier onlyMinter(uint256 id) {
        require(msg.sender == _minters[id], "Assets: caller is not the minter");
        _;
    }

    constructor() ERC1155("") {}

    function init(string memory uri) external {
        require(!_isInitialized, "Assets: already initialized");

        _setURI(uri);

        _isInitialized = true;
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
    ) external {
        _mint(to, id, amount, data);

        _minters[id] = msg.sender;
    }

    function lockMinting(uint256 id) external onlyMinter(id) {
        if (_mintingLocks[id]) {
            return;
        }

        _mintingLocks[id] = true;

        emit MintingLocked(id);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address, /* to */
        uint256[] memory ids,
        uint256[] memory, /* amounts */
        bytes memory /* data */
    ) internal view override {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                address minter = _minters[id];

                if (minter == address(0)) {
                    continue;
                }

                require(operator == minter, "Assets: caller is not the minter");
                require(!_mintingLocks[id], "Assets: minting locked");
            }
        }
    }
}