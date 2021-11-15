// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Registry for Curve Pools with Utility functions.

pragma solidity ^0.5.7;

import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveFactoryRegistry {
    function get_n_coins(address _pool)
        external
        view
        returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

contract Curve_Registry_V2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ICurveAddressProvider private constant CurveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
    ICurveRegistry public CurveRegistry;

    ICurveFactoryRegistry public FactoryRegistry;

    address private constant wbtcToken =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sbtcCrvToken =
        0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public shouldAddUnderlying;
    mapping(address => address) private depositAddresses;

    constructor() public {
        CurveRegistry = ICurveRegistry(CurveAddressProvider.get_registry());
        FactoryRegistry = ICurveFactoryRegistry(
            CurveAddressProvider.get_address(3)
        );
    }

    function isCurvePool(address swapAddress) public view returns (bool) {
        if (CurveRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    function isFactoryPool(address swapAddress) public view returns (bool) {
        if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice This function is used to get the curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return curve pool deposit address or the swap address not mapped
    */
    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress)
    {
        depositAddress = depositAddresses[swapAddress];
        if (depositAddress == address(0)) return swapAddress;
    }

    /**
    @notice This function is used to get the curve pool swap address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool swap address or address(0) if pool doesnt exist
    */
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress)
    {
        swapAddress = CurveRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return tokenAddress;
        }
        return address(0);
    }

    /**
    @notice This function is used to check the curve pool token address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool token address or address(0) if pool doesnt exist
    */
    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress)
    {
        tokenAddress = CurveRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return swapAddress;
        }
        return address(0);
    }

    /**
    @notice Checks the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return number of underlying tokens in the pool
    */
    function getNumTokens(address swapAddress) public view returns (uint256) {
        if (isCurvePool(swapAddress)) {
            return CurveRegistry.get_n_coins(swapAddress)[0];
        } else {
            (uint256 numTokens, ) = FactoryRegistry.get_n_coins(swapAddress);
            return numTokens;
        }
    }

    /**
    @notice This function is used to check if the curve pool is a metapool
    @notice all factory pools are metapools
    @param swapAddress Curve swap address for the pool
    @return true if the pool is a metapool, false otherwise
    */
    function isMetaPool(address swapAddress) public view returns (bool) {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts =
                CurveRegistry.get_n_coins(swapAddress);
            if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
            else return true;
        }
        if (isFactoryPool(swapAddress)) return true;
    }

    /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return returns 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        if (isMetaPool(swapAddress)) {
            if (isFactoryPool(swapAddress)) {
                address[2] memory poolUnderlyingCoins =
                    FactoryRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            } else {
                address[8] memory poolUnderlyingCoins =
                    CurveRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            }

            return poolTokens;
        } else {
            address[8] memory poolUnderlyingCoins;
            if (isBtcPool(swapAddress) && !isMetaPool(swapAddress)) {
                poolUnderlyingCoins = CurveRegistry.get_coins(swapAddress);
            } else {
                poolUnderlyingCoins = CurveRegistry.get_underlying_coins(
                    swapAddress
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        }
    }

    /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function isBtcPool(address swapAddress) public view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken || poolTokens[i] == sbtcCrvToken)
                return true;
        }
        return false;
    }

    /**
    @notice This function checks if the curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
    function isEthPool(address swapAddress) external view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == ETHAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice This function is used to check if the pool contains the token
    @param swapAddress Curve swap address for the pool
    @param tokenContractAddress contract address of the token
    @return true if the pool contains the token, false otherwise
    @return index of the token in the pool, 0 if pool does not contain the token
    */
    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint256) {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == tokenContractAddress) return (true, i);
        }
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_curve_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_registry();

        require(address(CurveRegistry) != new_address, "Already updated");

        CurveRegistry = ICurveRegistry(new_address);
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_factory_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(3);

        require(address(FactoryRegistry) != new_address, "Already updated");

        FactoryRegistry = ICurveFactoryRegistry(new_address);
    }

    /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
    function updateShouldAddUnderlying(
        address[] calldata swapAddresses,
        bool[] calldata addUnderlying
    ) external onlyOwner {
        require(
            swapAddresses.length == addUnderlying.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            shouldAddUnderlying[swapAddresses[i]] = addUnderlying[i];
        }
    }

    /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
    function updateDepositAddresses(
        address[] calldata swapAddresses,
        address[] calldata _depositAddresses
    ) external onlyOwner {
        require(
            swapAddresses.length == _depositAddresses.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            depositAddresses[swapAddresses[i]] = _depositAddresses[i];
        }
    }

    /**
    //@notice Add new pools which use the _use_underlying bool
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from Curve pools
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.5.7;
import "../_base/ZapOutBaseV2.sol";
import "./Curve_Registry_V2.sol";

interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool removeUnderlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 index)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 tokenAmount,
        int128 index,
        bool _use_underlying
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 index)
        external
        view
        returns (uint256);
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

contract Curve_ZapOut_General_V4_2 is ZapOutBaseV2_1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    Curve_Registry_V2 public curveReg;

    mapping(address => bool) public approvedTargets;

    mapping(address => bool) internal v2Pool;

    constructor(
        Curve_Registry_V2 _curveRegistry,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) public ZapBaseV1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        v2Pool[0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5] = true;
        curveReg = _curveRegistry;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice This method removes the liquidity from curve pools to ETH/ERC tokens
    @param swapAddress indicates Curve swap address for the pool
    @param incomingCrv indicates the amount of lp tokens to remove
    @param intermediateToken specifies in which token to exit the curve pool
    @param toToken indicates the ETH/ERC token to which tokens to convert
    @param minToTokens indicates the minimum amount of toTokens to receive
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    @param affiliate Affiliate address to share fees
    @param shouldSellEntireBalance True if incomingCrv is determined at execution time (i.e. contract is caller)
    @return ToTokensBought- indicates the amount of toTokens received
     */
    function ZapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        uint256 minToTokens,
        address _swapTarget,
        bytes calldata _swapCallData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external stopInEmergency returns (uint256 ToTokensBought) {
        address poolTokenAddress = curveReg.getTokenAddress(swapAddress);

        // get lp tokens
        incomingCrv = _pullTokens(
            poolTokenAddress,
            incomingCrv,
            shouldSellEntireBalance
        );

        if (intermediateToken == address(0)) {
            intermediateToken = ETHAddress;
        }

        // perform zapOut
        ToTokensBought = _zapOut(
            swapAddress,
            incomingCrv,
            intermediateToken,
            toToken,
            _swapTarget,
            _swapCallData
        );
        require(ToTokensBought >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        // Transfer tokens
        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                ToTokensBought,
                affiliate,
                true
            );
            Address.sendValue(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                ToTokensBought,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        }

        emit zapOut(msg.sender, swapAddress, toToken, ToTokensBought);

        return ToTokensBought.sub(totalGoodwillPortion);
    }

    function _zapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 ToTokensBought) {
        (bool isUnderlying, uint256 underlyingIndex) =
            curveReg.isUnderlyingToken(swapAddress, intermediateToken);

        // not metapool
        if (isUnderlying) {
            uint256 intermediateBought =
                _exitCurve(
                    swapAddress,
                    incomingCrv,
                    underlyingIndex,
                    intermediateToken
                );

            if (intermediateToken == ETHAddress) intermediateToken = address(0);

            ToTokensBought = _fillQuote(
                intermediateToken,
                toToken,
                intermediateBought,
                _swapTarget,
                _swapCallData
            );
        } else {
            // from metapool
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            uint8 i;
            for (; i < 4; i++) {
                if (curveReg.getSwapAddress(poolTokens[i]) != address(0)) {
                    intermediateSwapAddress = curveReg.getSwapAddress(
                        poolTokens[i]
                    );
                    break;
                }
            }
            // _exitCurve to intermediateSwapAddress Token
            uint256 intermediateCrvBought =
                _exitMetaCurve(swapAddress, incomingCrv, i, poolTokens[i]);
            // _performZapOut: fromPool = intermediateSwapAddress
            ToTokensBought = _zapOut(
                intermediateSwapAddress,
                intermediateCrvBought,
                intermediateToken,
                toToken,
                _swapTarget,
                _swapCallData
            );
        }
    }

    /**
    @notice This method removes the liquidity from meta curve pools
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitMetaCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, swapAddress);

        uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
        ICurveSwap(swapAddress).remove_liquidity_one_coin(
            incomingCrv,
            int128(index),
            0
        );
        tokensReceived = (IERC20(exitTokenAddress).balanceOf(address(this)))
            .sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method removes the liquidity from given curve pool
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        address depositAddress = curveReg.getDepositAddress(swapAddress);

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, depositAddress);

        address balanceToken =
            exitTokenAddress == ETHAddress ? address(0) : exitTokenAddress;

        uint256 iniTokenBal = _getBalance(balanceToken);

        if (curveReg.shouldAddUnderlying(swapAddress)) {
            // aave
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0,
                true
            );
        } else if (v2Pool[swapAddress]) {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                index,
                0
            );
        } else {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0
            );
        }

        tokensReceived = _getBalance(balanceToken).sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method swaps the fromToken to toToken using the 0x swap
    @param _fromTokenAddress indicates the ETH/ERC20 token
    @param _toTokenAddress indicates the ETH/ERC20 token
    @param _amount indicates the amount of from tokens to swap
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    */
    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;

        if (
            _fromTokenAddress == wethTokenAddress &&
            _toTokenAddress == address(0)
        ) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        } else if (
            _fromTokenAddress == address(0) &&
            _toTokenAddress == wethTokenAddress
        ) {
            IWETH(wethTokenAddress).deposit.value(_amount)();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) valueToSend = _amount;
        else _approveToken(_fromTokenAddress, _swapTarget, _amount);

        uint256 iniBal = _getBalance(_toTokenAddress);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call.value(valueToSend)(_swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toTokenAddress);

        amountBought = finalBal.sub(iniBal);

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param swapAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove.
    @return  amount Quantity of token removed
    */
    function removeLiquidityReturn(
        address swapAddress,
        address tokenAddress,
        uint256 liquidity
    ) external view returns (uint256 amount) {
        if (tokenAddress == address(0)) tokenAddress = ETHAddress;
        (bool underlying, uint256 index) =
            curveReg.isUnderlyingToken(swapAddress, tokenAddress);
        if (underlying) {
            if (v2Pool[swapAddress]) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, uint256(index));
            } else if (curveReg.shouldAddUnderlying(swapAddress)) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, int128(index), true);
            } else {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, int128(index));
            }
        } else {
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            for (uint256 i = 0; i < 4; i++) {
                intermediateSwapAddress = curveReg.getSwapAddress(
                    poolTokens[i]
                );
                if (intermediateSwapAddress != address(0)) break;
            }
            uint256 metaTokensRec =
                ICurveSwap(swapAddress).calc_withdraw_one_coin(
                    liquidity,
                    int128(1)
                );

            (, index) = curveReg.isUnderlyingToken(
                intermediateSwapAddress,
                tokenAddress
            );

            return
                ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
                    metaTokensRec,
                    int128(index)
                );
        }
    }

    function updateCurveRegistry(Curve_Registry_V2 newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    function setV2Pool(address[] calldata pool, bool[] calldata isV2Pool)
        external
        onlyOwner
    {
        require(pool.length == isV2Pool.length, "Invalid Input length");

        for (uint256 i = 0; i < pool.length; i++) {
            v2Pool[pool[i]] = isV2Pool[i];
        }
    }
}

pragma solidity ^0.5.7;

import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

contract ZapBaseV1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(uint256 _goodwill, uint256 _affiliateSplit) public {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, uint256(-1));
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 _token = IERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance.sub(
                    totalAffiliateBalance[tokens[i]]
                );
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this)).sub(
                    totalAffiliateBalance[tokens[i]]
                );
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]]
                .sub(tokenBal);

            if (tokens[i] == ETHAddress) {
                Address.sendValue(msg.sender, tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapOutBaseV2_1 is ZapBaseV1 {
    /**
    @dev Transfer tokens from msg.sender to this contract
    @param token The ERC20 token to transfer to this contract
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            IERC20 _token = IERC20(token);
            uint256 allowance = _token.allowance(msg.sender, address(this));
            _token.safeTransferFrom(msg.sender, address(this), allowance);

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

