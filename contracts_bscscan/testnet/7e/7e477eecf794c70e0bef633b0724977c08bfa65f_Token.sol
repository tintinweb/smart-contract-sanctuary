pragma solidity 0.5.16;

import "./BEP20Token.sol";

contract Token is BEP20Token {
    constructor() public {
        _initialize("BABYLON GROUP", "BBG", 18, 30000000 * 10**18, false);
    }
}