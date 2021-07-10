pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract CRC is CappedToken {
    string public name = "Creditcoin";
    string public symbol = "CRC";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}