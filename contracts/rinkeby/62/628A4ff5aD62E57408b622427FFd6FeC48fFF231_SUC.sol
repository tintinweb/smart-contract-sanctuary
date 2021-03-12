pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract SUC is CappedToken {

    string public name = "Sucoin";
    string public symbol = "SUC";
    uint8 public decimals = 8;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}