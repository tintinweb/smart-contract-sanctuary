pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract KRATOM is CappedToken {

    string public name = "KRATOM Awareness";
    string public symbol = "KRATOM";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}