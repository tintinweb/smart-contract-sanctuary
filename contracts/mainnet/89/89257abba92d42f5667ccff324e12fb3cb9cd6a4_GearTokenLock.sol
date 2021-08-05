pragma solidity ^0.6.0;

import "IERC20.sol";
import "TokenTimelock.sol";


contract GearTokenLock is TokenTimelock {
    constructor () public TokenTimelock(
        IERC20(0xdD5d1A256b25e1087Fc3B098b443e96Cfa73237d), // token
        0x444d9D3e82BF3f1F918d0fb89D8b6dc573C9115d, // beneficiary
        1605190192) {
    }
}