pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract BTCLF is CappedToken {

    string public name = "BITCOIN LONG LIFE";
    string public symbol = "BTCLF";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}