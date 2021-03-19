// contracts/EPANToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

// import "contracts/lib/ERC20.sol";
import "ERC20.sol";

contract EPANToken is ERC20 {

    // uint256 public constant initialSupply = 94697000;
    constructor(uint256 initialSupply) {
        // const initialSupply = 94697000;
        _mint(msg.sender, 94697000000000000000000000);
    }
}

// https://mainnet.infura.io/v3/9698ade175d94981abe3e552c59f6e8e