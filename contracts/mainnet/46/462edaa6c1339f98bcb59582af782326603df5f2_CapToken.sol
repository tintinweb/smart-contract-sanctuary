pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract NTER is CappedToken {

    string public name = "NTerprise";
    string public symbol = "NTER";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




