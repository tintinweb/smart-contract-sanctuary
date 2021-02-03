pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @dev CryptoWale ERC20 Token.
 */
contract CryptoWaleCoin is ERC20 {
    constructor() public ERC20("CryptoWaleCoin", "CWC") {
        _mint(msg.sender, 10000000 * (10**uint256(decimals())));
    }
}