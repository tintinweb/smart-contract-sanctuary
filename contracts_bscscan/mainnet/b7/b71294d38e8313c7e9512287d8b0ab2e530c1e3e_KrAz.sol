pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract KrAz is CappedToken {
    string public name = "Area51Token";
    string public symbol = "KrAz";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}