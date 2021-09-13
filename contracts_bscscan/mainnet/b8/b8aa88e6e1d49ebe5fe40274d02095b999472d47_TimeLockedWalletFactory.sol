// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TimeLock.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract TimeLockedWalletFactory is Ownable {
    mapping(address => address[]) wallets;

    event Created(address wallet, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);

    function getWallets(address _user) public view returns(address[] memory) {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, IERC20 _tokenLock, uint256 _amount, uint256 _unlockDate) onlyOwner public returns(address) {
        require(_tokenLock.allowance(msg.sender, address(this)) >= _amount);
        require(_unlockDate > block.timestamp);
        require(_owner == address(_owner),"Invalid address");

        address walletAddress = address(new TimeLock(_owner, _tokenLock, _unlockDate));

        require(_tokenLock.transferFrom(msg.sender, walletAddress, _amount));

        wallets[_owner].push(walletAddress);

        emit Created(walletAddress, _owner, block.timestamp, _unlockDate, _amount);

        return walletAddress;
    }
}