pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CryptoWaleCoin is ERC20 {
    constructor() public ERC20("CryptoWaleCoin", "CWC") {
        _mint(msg.sender, 10000000 * (10**uint256(decimals())));
    }
}