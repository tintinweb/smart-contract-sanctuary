pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract Stew is CappedToken {

    string public name = "Stewie Griffin ";
    string public symbol = "Stew";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}