pragma solidity 0.5.16;

import "./BEP20Token.sol";

contract Token is BEP20Token {
    constructor() public {
        _initialize("Sexual Wellness Token", "SXW", 18, 1000000000 * 10**18, false);
    }
}