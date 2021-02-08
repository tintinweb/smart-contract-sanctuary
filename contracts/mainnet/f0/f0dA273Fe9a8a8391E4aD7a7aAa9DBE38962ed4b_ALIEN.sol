pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract ALIEN is CappedToken {

    string public name = "ALIEN TOKEN";
    string public symbol = "ALIEN";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}