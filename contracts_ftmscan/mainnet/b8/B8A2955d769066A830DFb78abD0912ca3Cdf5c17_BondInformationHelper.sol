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

contract BondInformationHelper {
    function name(address _contractAddress) public view returns (string memory) {
        address principle = IBond(_contractAddress).principle();

        bool lp = IBond(_contractAddress).isLiquidityBond();

        if (!lp) {
            return ERC20(principle).name();
        }
    }

    function symbol(address _contractAddress) public view returns (string memory) {
        address principle = IBond(_contractAddress).principle();

        bool lp = IBond(_contractAddress).isLiquidityBond();

        if (!lp) {
            return ERC20(principle).symbol();
        }
    }
}