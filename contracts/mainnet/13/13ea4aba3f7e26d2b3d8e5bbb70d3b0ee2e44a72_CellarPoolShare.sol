// SPDX-License-Identifier: Apache-2.0
// VolumeFi Software, Inc.

pragma solidity 0.8.11;

import "./interfaces.sol";

/**
 * @title Sommelier Cellar Pool Share contract
 * @notice Main Cellar Pool share contract for Sommelier Network
 * @author VolumeFi Software
 */

contract CellarPoolShare is ICellarPoolShare, BlockLock {
    using SafeERC20 for IERC20;

    // Set the Uniswap V3 contract Addresses.
    address private constant _NONFUNGIBLEPOSITIONMANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    address private constant _UNISWAPV3FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant _SWAPROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant _DOMINATOR = 10000;

    uint256 private constant _YEAR = 31556952;

    uint256 private constant _TOLERANCE = 25; // 0.5% slippage -> 1.0025 tolerance of sqrtPrice

    AggregatorV3Interface private constant _ETHPRICEFEED =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    // Declare the variables and mappings
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public validator;

    mapping(address => bool) public adjuster;

    uint256 private _totalSupply;
    address private _owner;
    bool private _isEntered;
    string private _name;
    string private _symbol;

    address public immutable token0;
    address public immutable token1;
    uint24 public immutable feeLevel;
    CellarTickInfo[] public cellarTickInfo;
    uint256 public transactionFee = 2000;

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NonPermission();
        _;
    }

    modifier onlyValidator() {
        if (!validator[msg.sender]) revert NonPermission();
        _;
    }

    modifier nonReentrant() {
        if (_isEntered) revert Reentrance();
        _isEntered = true;
        _;
        _isEntered = false;
    }

    /**
     * @notice Create the constructor that identifies 
     * the toke names, symbols, and address for each token 
     * pair of any Uniswap v3 AMM
     */

    constructor(
        string memory name_,
        string memory symbol_,
        address _token0,
        address _token1,
        uint24 _feeLevel,
        CellarTickInfo[] memory _cellarTickInfo
    ) {
        _name = name_;
        _symbol = symbol_;
        if (_token0 >= _token1) {
            revert UnsortedTokens();
        }
        token0 = _token0;
        token1 = _token1;
        feeLevel = _feeLevel;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].weight == 0) revert ZeroWeight();
            if (_cellarTickInfo[i].tokenId != 0) revert NonEmptyTokenId();
            if (_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i].tickLower) revert WrongTickTier();
            if (i > 0) {
                if (_cellarTickInfo[i].tickUpper > _cellarTickInfo[i - 1].tickLower) revert WrongTickTier();
            }
            cellarTickInfo.push(
                CellarTickInfo({
                    tokenId: 0,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    tickLower: _cellarTickInfo[i].tickLower,
                    weight: _cellarTickInfo[i].weight
                })
            );
        }
        _owner = msg.sender;
        validator[msg.sender] = true;
        adjuster[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function totalPrice(uint256 amount0, uint256 amount1) internal view returns (uint256 total) {
        uint256 priceEth = uint256(_ETHPRICEFEED.latestAnswer());
        total = amount0 * 10 ** 8 + priceEth * amount1;
    }

    function addLiquidityForUniV3(CellarAddParams calldata cellarParams)
        external
        payable
        override
        nonReentrant
        notLocked(msg.sender)
    {
        if (token0 == _WETH) {
            if (msg.value >= cellarParams.amount0Desired) {
                if (msg.value > cellarParams.amount0Desired) {
                    payable(msg.sender).transfer(
                        msg.value - cellarParams.amount0Desired
                    );
                }
                IWETH(_WETH).deposit{value: cellarParams.amount0Desired}();
            } else {
                IERC20(_WETH).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cellarParams.amount0Desired
                );
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount1Desired
            );
        } else if (token1 == _WETH) {
            if (msg.value >= cellarParams.amount1Desired) {
                if (msg.value > cellarParams.amount1Desired) {
                    payable(msg.sender).transfer(
                        msg.value - cellarParams.amount1Desired
                    );
                }
                IWETH(_WETH).deposit{value: cellarParams.amount1Desired}();
            } else {
                IERC20(_WETH).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cellarParams.amount1Desired
                );
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount0Desired
            );
        } else {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount0Desired
            );
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount1Desired
            );
        }

        (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        ) = _addLiquidity(cellarParams);

        if (liquidityBefore == 0) {
            _mint(msg.sender, liquiditySum);
        } else {
            _mint(
                msg.sender,
                FullMath.mulDiv(liquiditySum, _totalSupply, liquidityBefore)
            );
        }

        if (inAmount0 < cellarParams.amount0Min || inAmount1 < cellarParams.amount1Min) revert InsufficientAmount();

        if (totalPrice(inAmount0, inAmount1) > 10000 * 10 ** 26) {
            revert OverDeposit(); // 10000 * 10 ** 18 * 10 ** 8
        }

        uint256 retAmount0 = cellarParams.amount0Desired - inAmount0;
        uint256 retAmount1 = cellarParams.amount1Desired - inAmount1;

        if (retAmount0 > 0) {
            if (token0 == _WETH) {
                IWETH(_WETH).withdraw(retAmount0);
                payable(msg.sender).transfer(retAmount0);
            } else {
                IERC20(token0).safeTransfer(msg.sender, retAmount0);
            }
        }
        if (retAmount1 > 0) {
            if (token1 == _WETH) {
                IWETH(_WETH).withdraw(retAmount1);
                payable(msg.sender).transfer(retAmount1);
            } else {
                IERC20(token1).safeTransfer(msg.sender, retAmount1);
            }
        }
        emit AddedLiquidity(liquiditySum, inAmount0, inAmount1);
    }

    function removeLiquidityFromUniV3(
        CellarRemoveParams calldata cellarParams
    ) external override nonReentrant notLocked(msg.sender) {
        (uint256 outAmount0, uint256 outAmount1, uint128 liquiditySum, ) =
            _removeLiquidity(cellarParams, false);
        _burn(msg.sender, cellarParams.tokenAmount);

        if (outAmount0 < cellarParams.amount0Min || outAmount1 < cellarParams.amount1Min) revert InsufficientAmount();

        if (token0 == _WETH) {
            IWETH(_WETH).withdraw(outAmount0);
            payable(msg.sender).transfer(outAmount0);
            IERC20(token1).safeTransfer(msg.sender, outAmount1);
        } else {
            IERC20(token0).safeTransfer(msg.sender, outAmount0);
            if (token1 == _WETH) {
                IWETH(_WETH).withdraw(outAmount1);
                payable(msg.sender).transfer(outAmount1);
            } else {
                IERC20(token1).safeTransfer(msg.sender, outAmount1);
            }
        }
        emit RemovedLiquidity(
            liquiditySum,
            outAmount0,
            outAmount1
        );
    }

    function _midSwap(
        address _token0, address _token1,
        uint256 inAmount0, uint256 inAmount1,
        uint256 balance0, uint256 balance1,
        uint256 sqrtPriceX96
    )
        private
    {
            uint256 swapAmount;
            // nothing added means either token exists and price range is not out of range for the token.
            // the case is balance0 > 0, balance1 = 0, swap half amount of token0 into token1
            if (inAmount0 == 0 && inAmount1 == 0) {
                swapAmount = balance0 / 2;
            }
            // calculate swap amount from bal0, bal1, in0, in1.
            // bal0, bal1 are token balance to add. in0, in1 are added balance in the first adding liquidity.
            // approximated result because in swapping, because the price changes.
            else {
                swapAmount = (balance0* inAmount1 - balance1 * inAmount0)
                    /
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            inAmount0,
                            sqrtPriceX96,
                            FixedPoint96.Q96),
                        sqrtPriceX96,
                        FixedPoint96.Q96)
                    + inAmount1);
            }
            IERC20(_token0).safeApprove(_SWAPROUTER, swapAmount);
            try ISwapRouter(_SWAPROUTER).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _token0,
                    tokenOut: _token1,
                    fee: feeLevel,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: swapAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            ) {} catch {}
            IERC20(_token0).safeApprove(_SWAPROUTER, 0);
    }

    /**
     * @notice invest token into Uniswap V3 liquidity
     * @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
     * @return totalInAmount0 token0 amount added into liquidity
     * @return totalInAmount1 token1 amount added into liquidity
     */
    function _invest(uint160 sqrtPriceX96)
        private
        nonReentrant
        returns (
            uint256 totalInAmount0,
            uint256 totalInAmount1
        )
    {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        (uint256 inAmount0, uint256 inAmount1, , ) =
            _addLiquidity(
                CellarAddParams({
                    amount0Desired: balance0,
                    amount1Desired: balance1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        balance0 = balance0 - inAmount0;
        balance1 = balance1 - inAmount1;

        totalInAmount0 = totalInAmount0 + inAmount0;
        totalInAmount1 = totalInAmount1 + inAmount1;
        // uint256 swapAmount;
        // b0 / b1 > i0 / i1 means token0 will remain. swap some token0 into token1
        if (balance0 * inAmount1 > balance1 * inAmount0 || (inAmount0 == 0 && inAmount1 == 0 && balance0 > balance1)) {
            _midSwap(token0, token1, inAmount0, inAmount1, balance0, balance1, sqrtPriceX96);
        }
        // b0 / b1 < i0 / i1 means token1 will remain. swap some token1 into token0
        if (balance0 * inAmount1 < balance1 * inAmount0 || (inAmount0 == 0 && inAmount1 == 0 && balance0 < balance1)) {
            uint256 revertedSqrtPriceX96 = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, sqrtPriceX96);
            _midSwap(token1, token0, inAmount1, inAmount0, balance1, balance0, revertedSqrtPriceX96);
        }
        (inAmount0, inAmount1, , ) =
            _addLiquidity(
                CellarAddParams({
                    amount0Desired: IERC20(token0).balanceOf(address(this)),
                    amount1Desired: IERC20(token1).balanceOf(address(this)),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

        totalInAmount0 += inAmount0;
        totalInAmount1 += inAmount1;
    }

    function reinvest(uint256 currentPriceX96) external override onlyValidator notLocked(msg.sender) {
        uint256 weightSum;
        uint256 balance0;
        uint256 balance1;
        uint256 fee0;
        uint256 fee1;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        unchecked{
            if (uint256(sqrtPriceX96) - currentPriceX96 >= currentPriceX96 * _TOLERANCE / _DOMINATOR
                && currentPriceX96 - uint256(sqrtPriceX96) >= currentPriceX96 * _TOLERANCE / _DOMINATOR)
                revert HighSlippage();
        }
        for (uint256 index = 0; index < cellarTickInfo.length; index++) {
            if (cellarTickInfo[index].tokenId == 0) revert InvalidTokenId();
            weightSum += cellarTickInfo[index].weight;
            (uint256 amount0, uint256 amount1) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: cellarTickInfo[index].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            balance0 += amount0;
            balance1 += amount1;
        }
        uint256 txFee0 = balance0 * transactionFee / _DOMINATOR;
        uint256 txFee1 = balance1 * transactionFee / _DOMINATOR;
        fee0 += txFee0;
        fee1 += txFee1;
        if (fee0 > balance0) {
            fee0 = balance0;
        }
        if (fee1 > balance1) {
            fee1 = balance1;
        }
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
        (uint256 investedAmount0, uint256 investedAmount1) = _invest(sqrtPriceX96);

        emit Reinvest(
            balance0,
            balance1,
            0,
            0,
            txFee0,
            txFee1,
            investedAmount0,
            investedAmount1
        );
    }

    function rebalance(CellarTickInfo[] memory _cellarTickInfo, uint256 currentPriceX96)
        external
        override
        notLocked(msg.sender)
    {
        if (!adjuster[msg.sender]) revert NonPermission();
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        unchecked{
            if (uint256(sqrtPriceX96) - currentPriceX96 >= currentPriceX96 * _TOLERANCE / _DOMINATOR
                && currentPriceX96 - uint256(sqrtPriceX96) >= currentPriceX96 * _TOLERANCE / _DOMINATOR)
                revert HighSlippage();
        }
        CellarRemoveParams memory removeParams =
            CellarRemoveParams({
                tokenAmount: _totalSupply,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (, , , CellarFees memory cellarFees) =
            _removeLiquidity(removeParams, true);

        uint256 fee0 = cellarFees.transaction0;
        uint256 fee1 = cellarFees.transaction1;
        if (fee0 > cellarFees.collect0) {
            fee0 = cellarFees.collect0;
        }
        if (fee1 > cellarFees.collect1) {
            fee1 = cellarFees.collect1;
        }

        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
        for (uint256 i = 0; i < cellarTickInfo.length; i++) {
            INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).burn(
                cellarTickInfo[i].tokenId
            );
        }
        delete cellarTickInfo;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i].tickLower) revert WrongTickTier();
            if (i > 0) {
                if (_cellarTickInfo[i].tickUpper > _cellarTickInfo[i - 1].tickLower) revert WrongTickTier();
            }
            if (_cellarTickInfo[i].weight == 0) revert ZeroWeight();
            if (_cellarTickInfo[i].tokenId != 0) revert NonEmptyTokenId();
            cellarTickInfo.push(_cellarTickInfo[i]);
        }

        (uint256 investedAmount0, uint256 investedAmount1) = _invest(sqrtPriceX96);

        emit Rebalance(
            cellarFees.collect0,
            cellarFees.collect1,
            0,
            0,
            cellarFees.transaction0,
            cellarFees.transaction1,
            investedAmount0,
            investedAmount1
        );
    }

    function setValidator(address _validator, bool value) external override onlyOwner {
        if (_validator == address(0)) revert InvalidInput();
        validator[_validator] = value;
        emit SetValidator(_validator, value);
    }

    function setAdjuster(address _adjuster, bool value) external override onlyOwner {
        if (_adjuster == address(0)) revert InvalidInput();
        adjuster[_adjuster] = value;
        emit SetAdjuster(_adjuster, value);
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        if (newOwner == address(0)) revert InvalidInput();
        _owner = newOwner;
        emit TransferOwnership(newOwner);
    }

    function setTransactionFee(uint256 newFee) external override onlyOwner {
        if (newFee >= _DOMINATOR) revert InvalidInput();
        transactionFee = newFee;
        emit SetTransactionFee(newFee);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function getCellarTickInfo()
        external
        view
        override
        returns (CellarTickInfo[] memory)
    {
        return cellarTickInfo;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (sender == address(0)) revert TransferFromZeroAddress();
        if (recipient == address(0)) revert TransferToZeroAddress();

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert MintToZeroAddress();

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert BurnFromZeroAddress();

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) internal {
        if (owner_ == address(0)) revert ApproveFromZeroAddress();
        if (spender == address(0)) revert ApproveToZeroAddress();

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @notice get weight information of positions
     * @dev every position has its weight but it is for liquidity weight, not token amount weight.
     *      this function calculates token amount weight and sum of weights from liquidity weight.
     * @param _cellarTickInfo cellar tick info struct array
     * @return weightSum0 sum of weights for token0
     * @return weightSum1 sum of weights for token1
     * @return liquidityBefore total liquidity of all positions
     * @return weight0 weights array for token0
     * @return weight1 weights array for token1
     */
    function _getWeightInfo(CellarTickInfo[] memory _cellarTickInfo)
        internal
        view
        returns (
            uint256 weightSum0,
            uint256 weightSum1,
            uint128 liquidityBefore,
            uint256[] memory weight0,
            uint256[] memory weight1
        )
    {
        weight0 = new uint256[](_cellarTickInfo.length);
        weight1 = new uint256[](_cellarTickInfo.length);
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        UintPair memory sqrtPrice0;
        // price of ticks is increasing through ticks.
        // At the first tick, token0 weight is maximum. Last tick, token1 weight is maximum.

        uint256 weight00;// token0 maximum weight
        uint256 weight10;// token1 maximum weight

        sqrtPrice0.a = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickLower
        );
        sqrtPrice0.b = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickUpper
        );
        weight00 = _cellarTickInfo[0].weight; // first position
        weight10 = _cellarTickInfo[_cellarTickInfo.length - 1].weight; // last position

        // calculate token weight from liquidity weight per tick position
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].tokenId > 0) {
                (, , , , , , , uint128 liquidity, , , , ) =
                    INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .positions(_cellarTickInfo[i].tokenId);
                liquidityBefore += liquidity;
            }

            UintPair memory sqrtCurrentTickPriceX96;
            sqrtCurrentTickPriceX96.a = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickLower
            );
            sqrtCurrentTickPriceX96.b = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickUpper
            );
            // current tick is less than tickLower of the position.
            // token1 amount is 0, So consider token0 amount and weight only.
            if (currentTick <= _cellarTickInfo[i].tickLower) {
                weight0[i] = // weight for token0
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b -
                                sqrtCurrentTickPriceX96.a,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtCurrentTickPriceX96.a
                    ) // token0 amount
                     * _cellarTickInfo[i].weight) /
                    weight00;
                weightSum0 += weight0[i];
            // current tick is greater than tickLower of the position.
            // token0 amount is 0, So consider token1 amount and weight only.
            } else if (currentTick >= _cellarTickInfo[i].tickUpper) {
                weight1[i] = // weight for token1
                    (FullMath.mulDiv(
                        sqrtCurrentTickPriceX96.b - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum1 += weight1[i];
            // current tick is in the range, recalculate both tokens weight.
            } else {
                weight0[i] =
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b - sqrtPriceX96,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtPriceX96
                    ) * _cellarTickInfo[i].weight) /
                    weight00;

                weight1[i] =
                    (FullMath.mulDiv(
                        sqrtPriceX96 - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum0 += weight0[i];
                weightSum1 += weight1[i];
            }
        }
    }

    /**
     * @notice modify weight information of positions
     * @dev some positions consist of either token.
     *      that's why if we distribute tokens according to the weights, some tokens will remain.
     *      so we remove weights from the weight sum if the position doesn't include either token.
     * @param _cellarTickInfo cellar tick info struct array
     * @param amount0Desired token0 amount to add liquidity
     * @param amount1Desired token1 amount to add liquidity
     * @param weightSum0 sum of weights for token0
     * @param weightSum1 sum of weights for token1
     * @param weight0 token0 weight array
     * @param weight1 token1 weight array
     * @return newWeightSum0 updated sum of weights for token0
     * @return newWeightSum1 updated sum of weights for token1
     */
    function _modifyWeightInfo(
        CellarTickInfo[] memory _cellarTickInfo,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 weightSum0,
        uint256 weightSum1,
        uint256[] memory weight0,
        uint256[] memory weight1
    ) internal view returns (uint256 newWeightSum0, uint256 newWeightSum1) {
        if (_cellarTickInfo.length == 1) {
            return (weightSum0, weightSum1);
        }

        UintPair memory liquidity;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        liquidity.a = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[0], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[0], weightSum1)
        );
        uint256 tickLength = _cellarTickInfo.length - 1;
        liquidity.b = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[tickLength], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[tickLength], weightSum1)
        );

        if (
            liquidity.a * _cellarTickInfo[tickLength].weight >
            liquidity.b * _cellarTickInfo[0].weight
        ) {
            if (liquidity.b * _cellarTickInfo[0].weight > 0) {
                newWeightSum0 = FullMath.mulDiv(
                    weightSum0,
                    liquidity.a * _cellarTickInfo[tickLength].weight,
                    liquidity.b * _cellarTickInfo[0].weight
                );
            }
            else {
                newWeightSum0 = 0;
            }
            newWeightSum1 = weightSum1;
        } else {
            newWeightSum0 = weightSum0;
            if (liquidity.a * _cellarTickInfo[tickLength].weight > 0) {
                newWeightSum1 = FullMath.mulDiv(
                    weightSum1,
                    liquidity.b * _cellarTickInfo[0].weight,
                    liquidity.a * _cellarTickInfo[tickLength].weight
                );
            }
            else {
                newWeightSum1 = 0;
            }
        }
    }

    /**
     * @notice add liquidity into Uniswap positions
     * @param cellarParams params struct to add liquidity
     * @return inAmount0 token0 amount added into liquidity
     * @return inAmount1 token1 amount added into liquidity
     * @return liquidityBefore liquidity sum before add liquidity
     * @return liquiditySum liquidity sum after add liquidity
     */
    function _addLiquidity(CellarAddParams memory cellarParams)
        internal
        returns (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        IERC20(token0).safeApprove(
            _NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount0Desired
        );
        IERC20(token1).safeApprove(
            _NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount1Desired
        );

        uint256 weightSum0;
        uint256 weightSum1;
        uint256[] memory weight0 = new uint256[](_cellarTickInfo.length);
        uint256[] memory weight1 = new uint256[](_cellarTickInfo.length);

        (
            weightSum0,
            weightSum1,
            liquidityBefore,
            weight0,
            weight1
        ) = _getWeightInfo(_cellarTickInfo);
        if (weightSum0 > 0 && weightSum1 > 0) {
            (weightSum0, weightSum1) = _modifyWeightInfo(
                _cellarTickInfo,
                cellarParams.amount0Desired,
                cellarParams.amount1Desired,
                weightSum0,
                weightSum1,
                weight0,
                weight1
            );
        }

        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            INonfungiblePositionManager.MintParams memory mintParams =
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: feeLevel,
                    tickLower: _cellarTickInfo[i].tickLower,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: cellarParams.deadline
                });

                INonfungiblePositionManager.IncreaseLiquidityParams
                    memory increaseLiquidityParams
             =
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            if (weightSum0 > 0) {
                mintParams.amount0Desired = FullMath.mulDiv(
                    cellarParams.amount0Desired,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Desired = mintParams
                    .amount0Desired;
                mintParams.amount0Min = FullMath.mulDiv(
                    cellarParams.amount0Min,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Min = mintParams.amount0Min;
            }
            if (weightSum1 > 0) {
                mintParams.amount1Desired = FullMath.mulDiv(
                    cellarParams.amount1Desired,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Desired = mintParams
                    .amount1Desired;
                mintParams.amount1Min = FullMath.mulDiv(
                    cellarParams.amount1Min,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Min = mintParams.amount1Min;
            }
            if (
                mintParams.amount0Desired > 0 || mintParams.amount1Desired > 0
            ) {
                MintResult memory mintResult;
                if (_cellarTickInfo[i].tokenId == 0) {

                    try INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .mint(mintParams) returns (uint256 r1, uint128 r2, uint256 r3, uint256 r4) {
                        mintResult.tokenId = r1;
                        mintResult.liquidity = r2;
                        mintResult.amount0 = r3;
                        mintResult.amount1 = r4;
                    } catch {}

                    cellarTickInfo[i].tokenId = uint184(mintResult.tokenId);

                    inAmount0 = inAmount0 + mintResult.amount0;
                    inAmount1 = inAmount1 + mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                } else {
                    try INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .increaseLiquidity(increaseLiquidityParams) returns (uint128 r1, uint256 r2, uint256 r3) {
                        mintResult.liquidity = r1;
                        mintResult.amount0 = r2;
                        mintResult.amount1 = r3;
                    } catch {}
                    inAmount0 = inAmount0 + mintResult.amount0;
                    inAmount1 = inAmount1 + mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                }
            }
        }
        IERC20(token0).safeApprove(_NONFUNGIBLEPOSITIONMANAGER, 0);
        IERC20(token1).safeApprove(_NONFUNGIBLEPOSITIONMANAGER, 0);
    }

    /**
     * @notice remove liquidity from Uniswap positions
     * @param cellarParams params struct to add liquidity
     * @param getFee true if calculate fee and return as cellarFees param
            set false when don't need fee calculation for saving gas.
     * @return outAmount0 token0 amount added into liquidity
     * @return outAmount1 token1 amount added into liquidity
     * @return liquiditySum liquidity sum after add liquidity
     * @return cellarFees fee information struct when getFee is true, otherwise empty
     */
    function _removeLiquidity(CellarRemoveParams memory cellarParams, bool getFee)
        internal
        returns (
            uint256 outAmount0,
            uint256 outAmount1,
            uint128 liquiditySum,
            CellarFees memory cellarFees
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                    .positions(_cellarTickInfo[i].tokenId);
            uint128 outLiquidity =
                uint128(
                    FullMath.mulDiv(
                        liquidity,
                        cellarParams.tokenAmount,
                        _totalSupply
                    )
                );

                INonfungiblePositionManager.DecreaseLiquidityParams
                    memory decreaseLiquidityParams
             =
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    liquidity: outLiquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            UintPair memory amount;
            (amount.a, amount.b) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                    .decreaseLiquidity(decreaseLiquidityParams);
            UintPair memory collectAmount;
            (collectAmount.a, collectAmount.b) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: _cellarTickInfo[i].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            outAmount0 = outAmount0 + amount.a;
            outAmount1 = outAmount1 + amount.b;
            liquiditySum += outLiquidity;
            if (getFee) {
                cellarFees.collect0 = cellarFees.collect0 + collectAmount.a - amount.a;
                cellarFees.collect1 = cellarFees.collect1 + collectAmount.b - amount.b;
            }
        }
        if (getFee) {
            cellarFees.transaction0 = cellarFees.collect0 * transactionFee / _DOMINATOR;
            cellarFees.transaction1 = cellarFees.collect1 * transactionFee / _DOMINATOR;
        }
    }

    receive() external payable {
        require(msg.sender == _WETH);
    }
}