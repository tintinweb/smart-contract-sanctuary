pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CWCExchange is ERC20 {
    constructor() public ERC20("CryptoWale Coin", "CWC") {
        _mint(msg.sender, 10000000 * (10**uint256(decimals())));
    }
}