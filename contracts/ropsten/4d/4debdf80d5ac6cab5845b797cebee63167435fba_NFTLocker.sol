/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NFTLocker {

    event Deposit(address account, address nft_contract, uint256 nft_id);

    event Withdraw(address account, address nft_contract, uint256 nft_id);

    function deposit() public {
        emit Deposit(msg.sender, 0x2F4e9c97aAFFD67D98A640062d90e355B4a1C539, 1892829712728);
    }

    function withdraw() public {
        emit Deposit(msg.sender, 0x2F4e9c97aAFFD67D98A640062d90e355B4a1C539, 1892829712728);
    }

}