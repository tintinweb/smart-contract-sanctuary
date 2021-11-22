// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./TimeLockedWallet.sol";

contract TimeLockedWalletFactory {
 
    mapping(address => TimeLockedWallet[]) wallets;

    function getWallets(address _user) public view returns(TimeLockedWallet[] memory){
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint256 _unlockDate) payable public returns(TimeLockedWallet wallet) {
        // Create new wallet.
        wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
        
        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

        // Send ether from this transaction to the created contract.
        payable(wallet).transfer(msg.value);

        // Emit event.
        emit Created(address(wallet), msg.sender, _owner, block.timestamp, _unlockDate, msg.value);
    }

    // Prevents accidental sending of ether to the factory
    fallback () external {
        revert();
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}