pragma solidity ^0.5.13;

import "./ERC20.sol";
import "./TestTokenConfig.sol";

contract TestToken is TestTokenConfig, ERC20 {

    constructor()
        ERC20(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            TOKEN_TOTALMINTCAPACITY,
            TOKEN_DAILYMINTCAPACITY)
        public
    {}
}