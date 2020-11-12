pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract YOK is CappedToken {

    string public name = "YOKcoin";
    string public symbol = "YOK";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




