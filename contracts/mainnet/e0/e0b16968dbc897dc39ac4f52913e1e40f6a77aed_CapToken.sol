pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract CapToken is CappedToken {

    string public name = "Thank You";
    string public symbol = "TY";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}