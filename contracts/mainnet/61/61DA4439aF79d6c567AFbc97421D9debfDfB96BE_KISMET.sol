pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract KISMET is CappedToken {

    string public name = "KismetCoin";
    string public symbol = "KISMET";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}