pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract MNTX is CappedToken {

    string public name = "Mooneta";
    string public symbol = "MNTX";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}