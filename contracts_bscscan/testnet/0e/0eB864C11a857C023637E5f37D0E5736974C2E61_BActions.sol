// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

library RightsManager {
    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
        bool canChangeProtocolFee;
    }
}

abstract contract ERC20 {
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address dst, uint256 amt) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function balanceOf(address whom) external view virtual returns (uint256);

    function allowance(address, address) external view virtual returns (uint256);
}

abstract contract BalancerOwnable {
    function setController(address controller) external virtual;
}

abstract contract AbstractPool is ERC20, BalancerOwnable {
    function setSwapFee(uint256 swapFee) external virtual;

    function setProtocolFee(uint256 protocolFee) external virtual;

    function setRoles(bytes32[] memory roles) external virtual;

    function setAccessControlAddress(address accessAddress) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external virtual;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external virtual returns (uint256 poolAmountOut);
}

abstract contract BPool is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens() external view virtual returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint256);
}

abstract contract BFactory {
    function newBPool() external virtual returns (BPool);
}

abstract contract ConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint256[] tokenBalances;
        uint256[] tokenWeights;
        uint256 swapFee;
        uint256 protocolFee;
    }

    struct CrpParams {
        uint256 initialSupply;
        uint256 minimumWeightChangeBlockPeriod;
        uint256 addTokenTimeLockInBlocks;
    }

    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriod,
        uint256 addTokenTimeLockInBlocks
    ) external virtual;

    function createPool(uint256 initialSupply) external virtual;

    function setCap(uint256 newCap) external virtual;

    function updateWeight(address token, uint256 newWeight) external virtual;

    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external virtual;

    function commitAddToken(
        address token,
        uint256 balance,
        uint256 denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function removeToken(address token) external virtual;

    function whitelistLiquidityProvider(address[] calldata providers) external virtual;

    function removeWhitelistedLiquidityProvider(address[] calldata providers) external virtual;

    function bPool() external view virtual returns (BPool);

    function setCanWhitelistLPs(bool) external virtual;
}

abstract contract CRPFactory {
    function newCrp(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams calldata params,
        RightsManager.Rights calldata rights
    ) external virtual returns (ConfigurableRightsPool);
}

/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract BActions {
    // --- Pool Creation ---

    function create(
        BFactory factory,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata weights,
        uint256 swapFee,
        uint256 protocolFee,
        bool finalize
    ) external returns (BPool pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == weights.length, "ERR_LENGTH_MISMATCH");

        pool = factory.newBPool();
        pool.setSwapFee(swapFee);
        pool.setProtocolFee(protocolFee);

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(pool), balances[i]);
            pool.bind(tokens[i], balances[i], weights[i]);
        }

        if (finalize) {
            pool.finalize();
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        } else {
            pool.setPublicSwap(true);
        }
    }

    function createSmartPool(
        CRPFactory factory,
        BFactory bFactory,
        ConfigurableRightsPool.PoolParams calldata poolParams,
        ConfigurableRightsPool.CrpParams calldata crpParams,
        RightsManager.Rights calldata rights
    ) external returns (ConfigurableRightsPool crp) {
        require(poolParams.constituentTokens.length == poolParams.tokenBalances.length, "ERR_LENGTH_MISMATCH");
        require(poolParams.constituentTokens.length == poolParams.tokenWeights.length, "ERR_LENGTH_MISMATCH");

        crp = factory.newCrp(address(bFactory), poolParams, rights);

        for (uint256 i = 0; i < poolParams.constituentTokens.length; i++) {
            ERC20 token = ERC20(poolParams.constituentTokens[i]);
            require(token.transferFrom(msg.sender, address(this), poolParams.tokenBalances[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(crp), poolParams.tokenBalances[i]);
        }

        crp.createPool(
            crpParams.initialSupply,
            crpParams.minimumWeightChangeBlockPeriod,
            crpParams.addTokenTimeLockInBlocks
        );
        require(crp.transfer(msg.sender, crpParams.initialSupply), "ERR_TRANSFER_FAILED");
        // DSProxy instance keeps pool ownership to enable management
    }

    // --- Joins ---

    function joinPool(
        BPool pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.getFinalTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn);
    }

    function joinSmartPool(
        ConfigurableRightsPool pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.bPool().getCurrentTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn);
    }

    function joinswapExternAmountIn(
        AbstractPool pool,
        ERC20 token,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external {
        require(token.transferFrom(msg.sender, address(this), tokenAmountIn), "ERR_TRANSFER_FAILED");
        _safeApprove(token, address(pool), tokenAmountIn);
        uint256 poolAmountOut = pool.joinswapExternAmountIn(address(token), tokenAmountIn, minPoolAmountOut);
        require(pool.transfer(msg.sender, poolAmountOut), "ERR_TRANSFER_FAILED");
    }

    // --- Pool management (common) ---

    function setPublicSwap(AbstractPool pool, bool publicSwap) external {
        pool.setPublicSwap(publicSwap);
    }

    function setSwapFee(AbstractPool pool, uint256 newFee) external {
        pool.setSwapFee(newFee);
    }

    function setController(AbstractPool pool, address newController) external {
        pool.setController(newController);
    }

    function setProtocolFee(AbstractPool pool, uint256 newFee) external {
        pool.setProtocolFee(newFee);
    }

    function setRoles(AbstractPool pool, bytes32[] memory roles) external {
        pool.setRoles(roles);
    }

    function setAccessControlAddress(AbstractPool pool, address newAddress) external {
        pool.setAccessControlAddress(newAddress);
    }

    // --- Private pool management ---

    function setTokens(
        BPool pool,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms
    ) external {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (pool.isBound(tokens[i])) {
                if (balances[i] > pool.getBalance(tokens[i])) {
                    require(
                        token.transferFrom(msg.sender, address(this), balances[i] - pool.getBalance(tokens[i])),
                        "ERR_TRANSFER_FAILED"
                    );
                    _safeApprove(token, address(pool), balances[i] - pool.getBalance(tokens[i]));
                }
                if (balances[i] > 10**6) {
                    pool.rebind(tokens[i], balances[i], denorms[i]);
                } else {
                    pool.unbind(tokens[i]);
                }
            } else {
                require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
                _safeApprove(token, address(pool), balances[i]);
                pool.bind(tokens[i], balances[i], denorms[i]);
            }

            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
    }

    function finalize(BPool pool) external {
        pool.finalize();
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    // --- Smart pool management ---

    function increaseWeight(
        ConfigurableRightsPool crp,
        ERC20 token,
        uint256 newWeight,
        uint256 tokenAmountIn
    ) external {
        require(token.transferFrom(msg.sender, address(this), tokenAmountIn), "ERR_TRANSFER_FAILED");
        _safeApprove(token, address(crp), tokenAmountIn);
        crp.updateWeight(address(token), newWeight);
        require(crp.transfer(msg.sender, crp.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function decreaseWeight(
        ConfigurableRightsPool crp,
        ERC20 token,
        uint256 newWeight,
        uint256 poolAmountIn
    ) external {
        require(crp.transferFrom(msg.sender, address(this), poolAmountIn), "ERR_TRANSFER_FAILED");
        crp.updateWeight(address(token), newWeight);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function updateWeightsGradually(
        ConfigurableRightsPool crp,
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external {
        crp.updateWeightsGradually(newWeights, startBlock, endBlock);
    }

    function setCap(ConfigurableRightsPool crp, uint256 newCap) external {
        crp.setCap(newCap);
    }

    function commitAddToken(
        ConfigurableRightsPool crp,
        ERC20 token,
        uint256 balance,
        uint256 denormalizedWeight
    ) external {
        crp.commitAddToken(address(token), balance, denormalizedWeight);
    }

    function applyAddToken(
        ConfigurableRightsPool crp,
        ERC20 token,
        uint256 tokenAmountIn
    ) external {
        require(token.transferFrom(msg.sender, address(this), tokenAmountIn), "ERR_TRANSFER_FAILED");
        _safeApprove(token, address(crp), tokenAmountIn);
        crp.applyAddToken();
        require(crp.transfer(msg.sender, crp.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function removeToken(
        ConfigurableRightsPool crp,
        ERC20 token,
        uint256 poolAmountIn
    ) external {
        require(crp.transferFrom(msg.sender, address(this), poolAmountIn), "ERR_TRANSFER_FAILED");
        crp.removeToken(address(token));
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function whitelistLiquidityProvider(ConfigurableRightsPool crp, address[] calldata providers) external {
        crp.whitelistLiquidityProvider(providers);
    }

    function removeWhitelistedLiquidityProvider(ConfigurableRightsPool crp, address[] calldata providers) external {
        crp.removeWhitelistedLiquidityProvider(providers);
    }

    function setCanWhitelistLPs(ConfigurableRightsPool crp, bool _canChangeSwapFee) external {
        crp.setCanWhitelistLPs(_canChangeSwapFee);
    }

    // --- Internals ---

    function _safeApprove(
        ERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
        token.approve(spender, amount);
    }

    function _join(
        AbstractPool pool,
        address[] memory tokens,
        uint256 poolAmountOut,
        uint256[] memory maxAmountsIn
    ) internal {
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), maxAmountsIn[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(pool), maxAmountsIn[i]);
        }
        pool.joinPool(poolAmountOut, maxAmountsIn);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }
}

