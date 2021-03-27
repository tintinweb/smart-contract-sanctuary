pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract WENR is CappedToken {

    string public name = "Weiner";
    string public symbol = "WENR";
    uint8 public decimals = 12;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}