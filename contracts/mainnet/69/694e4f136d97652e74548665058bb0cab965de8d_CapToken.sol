pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract SPC is CappedToken {

    string public name = "Spinelcoin";
    string public symbol = "SPC";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




