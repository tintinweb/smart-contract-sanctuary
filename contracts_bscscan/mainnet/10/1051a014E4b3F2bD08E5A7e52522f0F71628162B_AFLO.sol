pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract AFLO is CappedToken {

    string public name = "aisleflo";
    string public symbol = "AFLO";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}