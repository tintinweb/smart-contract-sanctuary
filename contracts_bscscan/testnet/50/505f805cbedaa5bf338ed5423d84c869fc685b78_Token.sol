pragma solidity 0.5.16;

import "./BEP20Token.sol";

contract Token is BEP20Token {
    constructor() public {
        _initialize("Kiwi Defi", "KWD", 18, 10000000 * 10**18, false);
    }
}