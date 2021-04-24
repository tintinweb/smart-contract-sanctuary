pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract NVST is CappedToken {

    string public name = "Invest";
    string public symbol = "NVST";
    uint8 public decimals = 8;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}