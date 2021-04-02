pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract SQRT is CappedToken {

    string public name = "Squirtle";
    string public symbol = "SQRT";
    uint8 public decimals = 12;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}