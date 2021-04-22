// SPDX-License-Identifier: F-F-F-FIAT!!!
pragma solidity ^0.7.4;

import "./FixedRateMinter.sol";
import "./Fiat.sol";
import "./IERC20.sol";

contract UpTetherMinter is FixedRateMinter {

    constructor(Fiat _fiat, IERC20 _upTether) FixedRateMinter(_fiat, _upTether) {
        fiatPerToken = 10000;
    }
}