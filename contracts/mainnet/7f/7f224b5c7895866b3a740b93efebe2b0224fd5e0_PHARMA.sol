pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract PHARMA is CappedToken {

    string public name = "Pharmaceutical Token";
    string public symbol = "PHARMA";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}