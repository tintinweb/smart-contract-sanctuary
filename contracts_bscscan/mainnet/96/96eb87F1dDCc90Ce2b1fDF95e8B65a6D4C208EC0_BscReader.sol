/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IExpxPool {

    function getBalance(address token)
    external view returns (uint256);

    function getDenormalizedWeight(address token)
    external view returns (uint256);

    function getSwapFee()
    external view returns (uint256);
}

interface IPancakePair {
    function getReserves() external view
    returns (uint256, uint256, uint256);

    function swapFee() external view
    returns (uint256);
}

contract BscReader {

    string internal constant BI = "Bi";

    function allData(
        address[] memory expxPools,
        address[] memory expxTokens1,
        address[] memory expxTokens2,
        address[] memory uniswapPairs,
        string[] memory uniswapNames
    ) public view returns(
        uint256 blockNumber,
        uint256[] memory expxBalances1,
        uint256[] memory expxBalances2,
        uint256[] memory expxDenorms1,
        uint256[] memory expxDenorms2,
        uint256[] memory expxFees,
        uint256[] memory uniswapReserves1,
        uint256[] memory uniswapReserves2,
        uint256[] memory uniswapFees)
    {
        blockNumber = block.number;

        (, expxBalances1, expxBalances2, expxDenorms1, expxDenorms2, expxFees) =
        expxData(expxPools, expxTokens1, expxTokens2);

        (, uniswapReserves1, uniswapReserves2, uniswapFees) =
        uniswapData(uniswapPairs, uniswapNames);
    }

    function expxData(
        address[] memory pools,
        address[] memory tokens1,
        address[] memory tokens2
    ) public view returns(
        uint256 blockNumber,
        uint256[] memory balances1,
        uint256[] memory balances2,
        uint256[] memory denorms1,
        uint256[] memory denorms2,
        uint256[] memory fees)
    {
        blockNumber = block.number;

        balances1 = new uint256[](pools.length);
        balances2 = new uint256[](pools.length);
        denorms1 = new uint256[](pools.length);
        denorms2 = new uint256[](pools.length);
        fees = new uint256[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            IExpxPool pool = IExpxPool(pools[i]);

            balances1[i] = pool.getBalance(tokens1[i]);
            balances2[i] = pool.getBalance(tokens2[i]);
            denorms1[i] = pool.getDenormalizedWeight(tokens1[i]);
            denorms2[i] = pool.getDenormalizedWeight(tokens2[i]);
            fees[i] = pool.getSwapFee();
        }
    }

    function uniswapData(
        address[] memory pairs,
        string[] memory names
    ) public view returns(
        uint256 blockNumber,
        uint256[] memory reserves1,
        uint256[] memory reserves2,
        uint256[] memory fees)
    {
        blockNumber = block.number;

        reserves1 = new uint256[](pairs.length);
        reserves2 = new uint256[](pairs.length);
        fees = new uint256[](pairs.length);

        bytes32 bi = convert(BI);

        for (uint256 i = 0; i < pairs.length; i++) {
            IPancakePair pair = IPancakePair(pairs[i]);
            (uint256 r1, uint256 r2, ) = pair.getReserves();

            reserves1[i] = r1;
            reserves2[i] = r2;

            if (convert(names[i]) == bi) {
                fees[i] = pair.swapFee();
            }
        }
    }

    function convert(
        string memory str
    ) private pure returns(bytes32)  {
        return keccak256(abi.encodePacked(str));
    }
}