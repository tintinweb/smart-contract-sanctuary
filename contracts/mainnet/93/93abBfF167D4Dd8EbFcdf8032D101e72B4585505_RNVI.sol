pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract RNVI is CappedToken {
    string public name = "RNVI";
    string public symbol = "RNVI";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}