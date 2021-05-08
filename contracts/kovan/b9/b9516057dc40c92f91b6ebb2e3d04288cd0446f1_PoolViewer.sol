/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.6.7;

contract PoolViewer {
    // --- Mint  ---
    /**
     * @notice Helper function to simulate(non state-mutating) a mint action on a uniswap v3 pool
     * @param pool The address of the target pool
     * @param recipient The address that will receive and pay for tokens
     * @param tickLower The lower bound of the range to deposit the liquidity to
     * @param tickUpper The upper bound of the range to deposit the liquidity to
     * @param amount The uamount of liquidity to mint
     * @param data The data for the callback function
     */
    function mintViewer(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external {
        (bool success, bytes memory ret) =
            pool.call(abi.encodeWithSignature("mint(address,int24,int24,uint128,bytes)", recipient, tickLower, tickUpper, amount, data));
        (uint256 amount0, uint256 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint256, uint256));

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }

    // --- Collect  ---
    /**
     * @notice Helper function to simulate(non state-mutating) an action on a uniswap v3 pool
     * @param pool The address of the target pool
     * @param recipient The address that will receive and pay for tokens
     * @param tickLower The lower bound of the range to deposit the liquidity to
     * @param tickUpper The upper bound of the range to deposit the liquidity to
     * @param amount0Requested The amount of token0 requested
     * @param amount1Requested The amount of token1 requested
     */
    function collectViewer(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external {
        (bool success, bytes memory ret) =
            pool.call(
                abi.encodeWithSignature("collect(address,int24,int24,uint128,uint128)", recipient, tickLower, tickUpper, amount0Requested, amount1Requested)
            );
        (uint128 amount0, uint128 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint128, uint128));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }

    // --- Burn ---
    /**
     * @notice Helper function to simulate(non state-mutating) an action on a uniswap v3 pool
     * @param pool The address of the target pool
     * @param tickLower The lower bound of the uni v3 position
     * @param tickUpper The lower bound of the uni v3 position
     * @param amount The amount of liquidity to burn
     */
    function burnViewer(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external {
        (bool success, bytes memory ret) = pool.call(abi.encodeWithSignature("burn(int24,int24,uint128)", tickLower, tickUpper, amount));
        (uint256 amount0, uint256 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint256, uint256));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }
}