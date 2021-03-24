pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract JEDI is CappedToken {

    string public name = "Jedi Token";
    string public symbol = "JEDI";
    uint8 public decimals = 9;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}