pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract STUX is CappedToken {

    string public name = "Stux";
    string public symbol = "STUX";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




