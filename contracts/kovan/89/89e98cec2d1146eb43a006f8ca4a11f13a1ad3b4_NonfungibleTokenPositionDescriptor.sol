// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './IUniswapV3Pool.sol';

import './INonfungiblePositionManager.sol';
import './INonfungibleTokenPositionDescriptor.sol';
import './PoolAddress.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract NonfungibleTokenPositionDescriptor is INonfungibleTokenPositionDescriptor {
    /// @inheritdoc INonfungibleTokenPositionDescriptor
    function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        (, , address token0, address token1, uint24 fee, , , , , , , ) = positionManager.positions(tokenId);

        IUniswapV3Pool pool =
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    positionManager.factory(),
                    PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
                )
            );

        // todo: compute name and description from details about the position and the pool
        string memory name = 'Uniswap V3 Position';
        string memory description = 'Represents a position in Uniswap V3.';

        return
            string(abi.encodePacked('data:application/json,{"name":"', name, '", "description":"', description, '"}'));
    }
}