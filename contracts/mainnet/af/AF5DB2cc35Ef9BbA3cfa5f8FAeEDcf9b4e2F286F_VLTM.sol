pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract VLTM is CappedToken {

    string public name = "Voltium";
    string public symbol = "VLTM";
    uint8 public decimals = 8;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}