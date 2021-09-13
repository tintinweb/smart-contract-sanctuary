// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TimeLock {
    address public owner;
    IERC20 public tokenLock;
    uint256 public unlockDate;
    uint256 public createdAt;

    event WithdrewTokens(IERC20 tokenLock, address to, uint256 amount);

    constructor(address _owner, IERC20 _tokenLock, uint256 _unlockDate){
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
        tokenLock = _tokenLock;
        owner = _owner;
    }

    function withdrawTokens() public {
        require(block.timestamp >= unlockDate);

        uint256 amount = tokenLock.balanceOf(address(this));

        (bool success, bytes memory data) = address(tokenLock).call(abi.encodeWithSelector(0xa9059cbb, owner, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');

        emit WithdrewTokens(tokenLock, owner, amount);
    }

    function info() public view returns(IERC20, address, uint256, uint256, uint256) {
        return (tokenLock, owner, unlockDate, createdAt, tokenLock.balanceOf(address(this)));
    }
}