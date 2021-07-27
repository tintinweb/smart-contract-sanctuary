pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract USDT is CappedToken {

    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}