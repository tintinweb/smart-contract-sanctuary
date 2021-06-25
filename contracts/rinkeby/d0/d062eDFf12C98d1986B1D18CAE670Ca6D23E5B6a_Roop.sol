pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract Roop is CappedToken {

    string public name = "Roople";
    string public symbol = "Roop";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}