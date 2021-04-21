pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract TOTO is CappedToken {

    string public name = "ToTo Finance";
    string public symbol = "TOTO";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}