pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract DCC is CappedToken {

    string public name = "DataCubeCoin";
    string public symbol = "DCC";
    uint8 public decimals = 7;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}