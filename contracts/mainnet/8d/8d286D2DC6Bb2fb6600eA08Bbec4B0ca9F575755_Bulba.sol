pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract Bulba is CappedToken {

    string public name = "Bulba";
    string public symbol = "Bulba";
    uint8 public decimals = 12;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}