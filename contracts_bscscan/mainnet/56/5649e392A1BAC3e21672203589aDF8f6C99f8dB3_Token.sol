pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(0xF56A8c643163461478EFd12fCdEeA409EfB79Aa9, 100000000 * 10**18);
    }
}