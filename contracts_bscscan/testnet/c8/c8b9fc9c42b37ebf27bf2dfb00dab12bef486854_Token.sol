pragma solidity 0.5.16;

import "./BEP20Token.sol";

contract Token is BEP20Token {
    constructor() public {
        _initialize("VERO FARM", "VERO", 6, 1000000000 * 10**6, false);
    }
}