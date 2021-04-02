pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract OM is CappedToken {

    string public name = "OMG";
    string public symbol = "OM";
    uint8 public decimals = 10;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}