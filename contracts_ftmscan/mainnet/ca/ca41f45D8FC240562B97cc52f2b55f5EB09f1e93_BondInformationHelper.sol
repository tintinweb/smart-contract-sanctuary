/**
 *Submitted for verification at FtmScan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBond {
    function principle() external view returns (address);
    function isLiquidityBond() external view returns (bool);
}

interface ILiquidityToken {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

struct Result {
    string value0;
    string value1;
}

contract BondInformationHelper {
    function name(address _contractAddress) public view returns (Result memory) {
        address principle = IBond( _contractAddress ).principle();

        bool lp = IBond( _contractAddress ).isLiquidityBond();

        if (!lp) {
            return Result({
                value0: ERC20( principle ).name(),
                value1: ""
            });
        }

        return Result({
            value0: ERC20( ILiquidityToken( _contractAddress ).token0() ).name(),
            value1: ERC20( ILiquidityToken( _contractAddress ).token1() ).name()
        });
    }

    function symbol(address _contractAddress) public view returns (Result memory) {
        address principle = IBond( _contractAddress).principle();

        bool lp = IBond( _contractAddress ).isLiquidityBond();

        if (!lp) {
            return Result({
                value0: ERC20( principle ).symbol(),
                value1: ""
            });
        }

        return Result({
            value0: ERC20( ILiquidityToken( _contractAddress ).token0() ).symbol(),
            value1: ERC20( ILiquidityToken( _contractAddress ).token1() ).symbol()
        });
    }
}