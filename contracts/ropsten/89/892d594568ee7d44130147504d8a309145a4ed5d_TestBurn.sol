// ./TestBurnable.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
// import "./ERC20Capped.sol";
// import "./ERC20Pausable.sol";
// import "./ERC20Snapshot.sol";
// import "./ERC20FlashMint.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/ERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 
// contract TestBurn is ERC20,ERC20Burnable , ERC20FlashMint, ERC20Snapshot, ERC20Pausable {
    
 contract TestBurn is ERC20, ERC20Burnable { 
    constructor (
        uint256 initialSupply
        ) ERC20("TestBurn", "TESTBURN") {
        _mint(msg.sender, initialSupply);
    }
    
    // constructor (uint256 cappedAmount) ERC20Capped(72000000000000000000000000)
}