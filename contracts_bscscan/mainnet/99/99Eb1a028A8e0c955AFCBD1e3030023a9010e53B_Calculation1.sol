// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Calculation1 {

    function countAmountOfTokens(
        uint256 _hardCap,
        uint256 _tokenPrice,
        uint256 _liqPrice,
        uint256 _liqPerc,
        uint8 _decimalsToken,
        uint8 _decimalsNativeToken
    ) external pure returns (uint256[] memory) {
        uint256[] memory tokenAmounts = new uint256[](3);
        if (_liqPrice != 0 && _liqPerc != 0) {
            uint256 factor;
            if(_decimalsNativeToken != 18){
                if(_decimalsNativeToken < 18)
                    factor = uint256(10)**uint256(18 - _decimalsNativeToken);
                else
                    factor = uint256(10)**uint256(_decimalsNativeToken - 18);
            }
            else
                factor = 1;
            tokenAmounts[0] = ((_hardCap *
                _liqPerc *
                (uint256(10)**uint256(_decimalsToken)) * factor) / (_liqPrice * 100));
            require(tokenAmounts[0] > 0, "Wrokng");
        }

        tokenAmounts[1] =
            (_hardCap * (uint256(10)**uint256(_decimalsToken))) /
            _tokenPrice;
        tokenAmounts[2] = tokenAmounts[0] + tokenAmounts[1];
        require(tokenAmounts[1] > 0, "Wrong parameters");
        return tokenAmounts;
    }

}

