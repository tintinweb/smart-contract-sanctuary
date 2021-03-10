pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract VUEZ is CappedToken {

    string public name = "VuezTV Token";
    string public symbol = "VUEZ";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}