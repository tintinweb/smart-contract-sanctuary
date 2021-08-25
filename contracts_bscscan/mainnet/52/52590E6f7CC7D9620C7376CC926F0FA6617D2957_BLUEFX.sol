pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract BLUEFX is CappedToken {

    string public name = "BLUEFX";
    string public symbol = "BLUEFX";
    uint8 public decimals = 8;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}