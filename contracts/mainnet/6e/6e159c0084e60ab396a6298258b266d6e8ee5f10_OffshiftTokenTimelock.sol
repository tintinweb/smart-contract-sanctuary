pragma solidity ^0.6.0;

import "IERC20.sol";
import "TokenTimelock.sol";


contract OffshiftTokenTimelock is TokenTimelock {
    constructor () public TokenTimelock(
        IERC20(0x2B9e92A5B6e69Db9fEdC47a4C656C9395e8a26d2), // token
        0xCFBE34bBFe9a9B6b1Aa37D0592a312Cf713A4437, // beneficiary
        1604481021) {
    }
}