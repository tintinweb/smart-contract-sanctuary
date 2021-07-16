pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract XPD is CappedToken {
    string public name = "podduang";
    string public symbol = "XPD";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}