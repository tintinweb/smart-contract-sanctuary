pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract THB is CappedToken {
    string public name = "Thai Baht";
    string public symbol = "THB";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}