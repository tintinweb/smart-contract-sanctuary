pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract MulanFinance is CappedToken {

    string public name = "Mulan.Finance";
    string public symbol = "$MULAN";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




