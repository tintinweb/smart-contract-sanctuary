pragma solidity 0.5.16;

import "./BEP20Token.sol";

contract Token is BEP20Token {
    constructor() public {
        _initialize("GVD", "GVD", 18, 21000000 * 10**18, false);
    }
}