pragma solidity 0.4.24;

import "./DetailedERC20.sol";
import "./MintableToken.sol";
import "./PausableToken.sol";

contract smeToken is MintableToken, PausableToken, DetailedERC20 {
    constructor()
        DetailedERC20("smeToken", "SME", 18)
        public
    {

    }
}