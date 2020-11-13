// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

abstract contract ERC20Optional is Context, ERC20, Pausable, Ownable {

    mapping (address => uint256) private _releaseTimestamp;

    function lock(uint256 releaseTimestamp) public virtual {
        require(owner() != address(0), "ERC20Optional: owner is the zero address");

        _releaseTimestamp[_msgSender()] = releaseTimestamp;
    }

    function isLocked(address account) public view returns (bool) {
        return (block.timestamp < _releaseTimestamp[account]);
    }

    function releaseTimestamp(address account) public view returns (uint256) {
        return _releaseTimestamp[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(block.timestamp >= _releaseTimestamp[from], "ERC20Optional: account is locked");
        require(!paused(), "ERC20Optional: token transfer while paused");
    }

    function pause() public virtual onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() public virtual onlyOwner returns (bool) {
        _unpause();
        return true;
    }
}