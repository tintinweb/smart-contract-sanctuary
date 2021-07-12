// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./BToken.sol";
import "./BMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../interfaces/IUnbinder.sol";
import "../interfaces/IBundle.sol";

/************************************************************************************************
Originally forked from https://github.com/balancer-labs/balancer-core/

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract Bundle is Initializable, BToken, BMath, IBundle {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== Modifiers ========== */

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    modifier _public_() {
        require(_publicSwap, "ERR_NOT_PUBLIC");
        _;
    }

    modifier _control_() {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _;
    }

    modifier _rebalance_() {
        require(msg.sender == _rebalancer && _rebalancable, "ERR_BAD_REBALANCE");
        _;
    }

    /* ========== Storage ========== */

    bool private _mutex;

    // Can use functions behind the _control_ modifier
    address private _controller;
    
    // Can rebalance the pool
    address private _rebalancer;

    // true if PUBLIC can call SWAP functions
    bool private _publicSwap;

    // swap fee
    uint256 private _swapFee;

    // exit fee
    uint256 private _exitFee;

    // Array of token addresses
    address[] private _tokens;

    // Records for each token
    mapping(address=>Record) private  _records;

    // Mapping of minimum balances for tokens added to the pool 
    mapping(address=>uint256) private _minBalances;

    // Sum of token denorms
    uint256 private _totalWeight;

    // Streaming fee
    uint256 private _streamingFee;

    // Start time for streaming fee
    uint256 private _lastStreamingTime;

    // Time delay for reweighting
    uint256 private _targetDelta;

    // Is rebalancable
    bool private _rebalancable;

    // Contract that handles unbound tokens
    IUnbinder private _unbinder;

    /* ========== Initialization ========== */

    /**
     * @dev Initializer function for upgradeability
     * TODO: Set unbound handler on initialization
     */
    function initialize(
        address controller, 
        address rebalancer,
        address unbinder,
        string calldata name, 
        string calldata symbol
    )
        public override
        initializer
    {
        _initializeToken(name, symbol);
        _controller = controller;
        _rebalancer = rebalancer;
        _unbinder = IUnbinder(unbinder);
        _swapFee = INIT_FEE;
        _streamingFee = INIT_STREAMING_FEE;
        _exitFee = INIT_EXIT_FEE;
        _publicSwap = false;
        _targetDelta = INIT_TARGET_DELTA;
    }

    /** @dev Setup function to initialize the pool after contract creation */
    function setup(
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms,
        address tokenProvider
    )
        external override
        _control_
    {
        require(_tokens.length == 0, "ERR_ALREADY_SETUP");
        require(tokens.length >= MIN_BOUND_TOKENS && tokens.length <= MAX_BOUND_TOKENS, "ERR_BAD_TOKEN_LENGTH");
        require(balances.length == tokens.length && denorms.length == tokens.length, "ERR_ARR_LEN");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 denorm = denorms[i];
            uint256 balance = balances[i];

            require(denorm >= MIN_WEIGHT && denorm <= MAX_WEIGHT, "ERR_BAD_WEIGHT");
            require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

            address token = tokens[i];
            require(!_records[token].bound, "ERR_DUPLICATE_TOKEN");
            _records[token] = Record({
                bound: true,
                ready: true,
                denorm: denorm,
                targetDenorm: denorm,
                targetTime: 0,
                lastUpdateTime: 0,
                index: uint8(i),
                balance: balance
            });

            _tokens.push(token);
            totalWeight = badd(totalWeight, denorm);
            // Move underlying asset to pool
            _pullUnderlying(token, tokenProvider, balance);
        }

        require(totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        _totalWeight = totalWeight;
        _publicSwap = true;
        _lastStreamingTime = block.timestamp;
        _rebalancable = true;
        emit LogPublicSwapEnabled();
        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(tokenProvider, INIT_POOL_SUPPLY);
    }

    /* ==========  Control  ========== */

    function setSwapFee(uint256 swapFee)
        external override
        _control_
    { 
        require(swapFee >= MIN_FEE && swapFee <= MAX_FEE, "ERR_BAD_FEE");
        _swapFee = swapFee;
        emit LogSwapFeeUpdated(msg.sender, swapFee);
    }

    function setRebalancable(bool rebalancable)
        external override
        _control_
    {
        _rebalancable = rebalancable;
        emit LogRebalancable(msg.sender, _rebalancable);
    }

    function setMinBalance(address token, uint256 minBalance) 
        external override
        _control_
    {
        require(_records[token].bound && !_records[token].ready, "ERR_BAD_TOKEN");
        _minBalances[token] = minBalance;
        emit LogMinBalance(msg.sender, token, minBalance);
    }

    function setStreamingFee(uint256 streamingFee) 
        external override
        _control_
    {
        require(streamingFee < MAX_STREAMING_FEE, "ERR_MAX_STREAMING_FEE");
        _streamingFee = streamingFee;
        emit LogStreamingFee(msg.sender, streamingFee);
    }

    function setExitFee(uint256 exitFee) 
        external override
        _control_
    {
        require(exitFee < MAX_EXIT_FEE, "ERR_MAX_STREAMING_FEE");
        _exitFee = exitFee;
        emit LogExitFee(msg.sender, exitFee);
    }

    function setTargetDelta(uint256 targetDelta)
        external override
        _control_
    {
        require(targetDelta >= MIN_TARGET_DELTA && targetDelta <= MAX_TARGET_DELTA, "ERR_TARGET_DELTA");
        _targetDelta = targetDelta;
        emit LogTargetDelta(msg.sender, targetDelta);
    }

    function collectStreamingFee()
        external override
        _lock_
        _control_
    {
        require(_tokens.length > 0, "ERR_SETUP");
        require(_lastStreamingTime < block.timestamp, "ERR_COLLECTION_TO_SOON");

        uint256 timeDelta = bsub(block.timestamp, _lastStreamingTime);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];

            // Shouldnt withdraw tokens if not ready
            if (_records[token].ready) {
                uint256 fee = bdiv(
                    bmul(bmul(_records[token].balance, _streamingFee), timeDelta),
                    BPY
                );

                _pushUnderlying(token, _controller, fee);
                _updateToken(token, bsub(_records[token].balance, fee));
            }
        }

        _lastStreamingTime = block.timestamp;
        emit LogCollectFee(msg.sender);
    }

    /* ==========  Getters  ========== */

    function isPublicSwap()
        external view override
        returns (bool)
    {
        return _publicSwap;
    }

    function isBound(address t)
        external view override
        returns (bool)
    {
        return _records[t].bound;
    }

    function isReady(address t)
        external view override
        returns (bool)
    {
        return _records[t].ready;
    }

    function getNumTokens()
        external view override
        returns (uint256) 
    {
        return _tokens.length;
    }

    function getCurrentTokens()
        external view override 
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view override
        _viewlock_
        returns (uint256)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external view override
        _viewlock_
        returns (uint256)
    {
        return _totalWeight;
    }

    function getBalance(address token)
        external view override
        _viewlock_
        returns (uint256)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee()
        external view override
        _viewlock_
        returns (uint256)
    {
        return _swapFee;
    }

    function getStreamingFee()
        external view override
        _viewlock_
        returns (uint256)
    {
        return _streamingFee;
    }

    function getExitFee()
        external view override
        _viewlock_
        returns (uint256)
    {
        return _exitFee;
    }

    function getController()
        external view override
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    function getRebalancer()
        external view override
        _viewlock_
        returns (address)
    {
        return _rebalancer;
    }

    function getRebalancable()
        external view override
        _viewlock_
        returns (bool)
    {
        return _rebalancable;
    }

    function getUnbinder()
        external view override
        _viewlock_
        returns (address)
    {
        return address(_unbinder);
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view override
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound && _records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view override
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound && _records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    /* ==========  External Token Weighting  ========== */

    /**
     * @dev Adjust weights for existing tokens
     * @param tokens A set of token addresses to adjust
     * @param targetDenorms A set of denorms to linearly update to
     */

    function reweighTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms
    )
        external override
        _lock_
        _control_
    {
        require(targetDenorms.length == tokens.length, "ERR_ARR_LEN");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 denorm = targetDenorms[i];
            if (denorm < MIN_WEIGHT) denorm = MIN_WEIGHT;
            _setTargetDenorm(tokens[i], denorm);
        }

        emit LogReweigh(msg.sender, tokens, targetDenorms);
    }

    /**
     * @dev Reindex the pool on a new set of tokens
     *
     * @param tokens A set of token addresses to be indexed
     * @param targetDenorms A set of denorms to linearly update to
     * @param minBalances Minimum balance thresholds for unbound assets
     */
    function reindexTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms,
        uint256[] calldata minBalances
    )
        external override
        _lock_
        _control_
    {
        require(
            targetDenorms.length == tokens.length && minBalances.length == tokens.length,
            "ERR_ARR_LEN"
        );
        uint256 unbindCounter = 0;
        bool[] memory receivedIndices = new bool[](_tokens.length);
        Record[] memory records = new Record[](tokens.length);

        // Mark which tokens on reindexing call are already in pool
        for (uint256 i = 0; i < tokens.length; i++) {
            records[i] = _records[tokens[i]];
            if (records[i].bound) receivedIndices[records[i].index] = true;
        }

        // If any bound tokens were not sent in this call
        // set their target weights to 0 and increment counter
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (!receivedIndices[i]) {
                _setTargetDenorm(_tokens[i], 0);
                unbindCounter++;
            }
        }

        require(unbindCounter <= _tokens.length - MIN_BOUND_TOKENS, "ERR_MAX_UNBIND");

        for (uint256 i = 0; i < tokens.length; i++) {
            // If an input weight is less than the minimum weight, use that instead.
            uint256 denorm = targetDenorms[i];
            if (denorm < MIN_WEIGHT) denorm = MIN_WEIGHT;
            if (!records[i].bound) {
                // If the token is not bound, bind it.
                _bind(tokens[i], minBalances[i], denorm);
            } else {
                _setTargetDenorm(tokens[i], denorm);
            }
        }

        // Ensure the number of tokens at equilibrium from this 
        // operation is lte max bound tokens
        require(_tokens.length - unbindCounter <= MAX_BOUND_TOKENS, "ERR_MAX_BOUND_TOKENS");
        emit LogReindex(msg.sender, tokens, targetDenorms, minBalances);

    }

    /* ==========  Internal Token Weighting  ========== */

    /**
     * @dev Bind a new token to the pool, may cause tokens to exceed max assets temporarily
     *
     * @param token Token to add to the pool
     * @param minBalance A set of denorms to linearly update to
     * @param denorm The target denorm to gradually adjust to
     */
    function _bind(address token, uint256 minBalance, uint256 denorm)
        internal
    {
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(denorm >= MIN_WEIGHT && denorm <= MAX_WEIGHT, "ERR_BAD_WEIGHT");
        require(minBalance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        _records[token] = Record({
            bound: true,
            ready: false,
            denorm: 0,
            targetDenorm: denorm,
            targetTime: badd(block.timestamp, _targetDelta),
            lastUpdateTime: block.timestamp,
            index: uint8(_tokens.length),
            balance: 0
        });

        _tokens.push(token);
        _minBalances[token] = minBalance;
        emit LogTokenBound(token);
    }

    /**
     * @dev Unbind a token from the pool
     *
     * @param token Token to remove from the pool
     */
    function _unbind(address token)
        internal
    {
        require(_records[token].bound, "ERR_NOT_BOUND");

        uint256 tokenBalance = _records[token].balance;
        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = _records[token].index;
        uint256 last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = uint8(index);
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            ready: false,
            index: 0,
            denorm: 0,
            targetDenorm: 0,
            targetTime: 0,
            lastUpdateTime: 0,
            balance: 0
        });

        _pushUnderlying(token, address(_unbinder), tokenBalance);
        _unbinder.handleUnboundToken(token);
        emit LogTokenUnbound(token);
    }

    /**
     * @dev Set the target denorm of a token
     * linearly adjusts by time + _targetDelta
     *
     * @param token Token to adjust
     * @param denorm Target denorm to set
     */
    function _setTargetDenorm(address token, uint256 denorm) 
        internal
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(denorm >= MIN_WEIGHT || denorm == 0, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        _updateDenorm(token);
        _records[token].targetDenorm = denorm;
        _records[token].targetTime = badd(block.timestamp, _targetDelta);
        _records[token].lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Updates the denorm on a given token to match target
     *
     * @param token Token to update denorm for
     */
    function _updateDenorm(address token)
        internal
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        Record storage record = _records[token];

        if (record.denorm != record.targetDenorm) {
            _totalWeight = bsub(_totalWeight, record.denorm);
            record.denorm = calcDenorm(
                record.lastUpdateTime, 
                block.timestamp, 
                record.targetTime, 
                record.denorm, 
                record.targetDenorm
            );
            _totalWeight = badd(_totalWeight, record.denorm);
            record.lastUpdateTime = bmin(block.timestamp, record.targetTime);
        }
    }

    /**
     * @dev Performs a full update on a tokens state
     *
     * @param token Token to adjust
     * @param balance New token balance
     */
    function _updateToken(
        address token,
        uint256 balance
    )
        internal
    {
        Record storage record = _records[token];
        if (!record.ready) {
            // Check if the minimum balance has been reached
            if (balance >= _minBalances[token]) {
                // Mark the token as ready
                record.ready = true;
                emit LogTokenReady(token);
                // Set the initial denorm value to the minimum weight times one plus
                // the ratio of the increase in balance over the minimum to the minimum
                // balance.
                // weight = min((1 + ((bal - min_bal) / min_bal)) * min_weight, MAX_WEIGHT)
                uint256 denorm = bmin(
                    badd(
                        MIN_WEIGHT, 
                        bmul(MIN_WEIGHT, bdiv(bsub(balance, _minBalances[token]), _minBalances[token]))
                    ),
                    MAX_WEIGHT
                );

                record.denorm = denorm;
                record.lastUpdateTime = block.timestamp;
                record.targetTime = badd(block.timestamp, _targetDelta);
                _totalWeight = badd(_totalWeight, record.denorm);
                // Remove the minimum balance record
                _minBalances[token] = 0;
            } else {
                uint256 currBalance = _getBalance(token);
                uint256 realToMinRatio = bdiv(bsub(currBalance, balance), currBalance);
                uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
                record.denorm = badd(MIN_WEIGHT, weightPremium);
            }
            record.balance = balance;
        } else {
            // Update denorm if token is ready
            _updateDenorm(token);
            record.balance = balance;
            // Always check if token needs to be unbound
            if (record.denorm < MIN_WEIGHT) {
                _unbind(token);
            }
        }
    }

    /**
     * @dev Internal view to get the current treatment balance for a token
     *
     * @param token Token to get balance for
     */
    function _getBalance(
        address token
    )
        internal view
        returns (uint256)
    {
        if (_records[token].ready) {
            return _records[token].balance;
        } else {
            return _minBalances[token];
        }
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external override
        _lock_
    {
        Record storage record = _records[token];
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        if (record.bound) {
            _updateToken(token, balance);
        } else {
            _pushUnderlying(token, address(_unbinder), balance);
            _unbinder.handleUnboundToken(token);
        }
    }

    /* ==========  Pool Entry/Exit  ========== */

    function joinPool(uint256 poolAmountOut, uint[] calldata maxAmountsIn)
        external override
        _public_
        _lock_
    {
        require(maxAmountsIn.length == _tokens.length, "ERR_ARR_LEN");

        uint256 poolTotal = totalSupply();
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _getBalance(t);
            uint256 tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            _updateToken(t, badd(_records[t].balance, tokenAmountIn));
            emit LogJoin(msg.sender, t, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint[] calldata minAmountsOut)
        external override
        _public_
        _lock_
    {
        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, _exitFee);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_controller, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            Record storage record = _records[t];

            if (record.ready) {
                uint256 tokenAmountOut = bmul(ratio, record.balance);
                require(tokenAmountOut != 0, "ERR_MATH_APPROX");
                require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
                _pushUnderlying(t, msg.sender, tokenAmountOut);
                _updateToken(t, bsub(record.balance, tokenAmountOut));
                emit LogExit(msg.sender, t, tokenAmountOut);
            } else {
                // Uninitialized tokens cannot exit the pool
                require(minAmountsOut[i] == 0, "ERR_NOT_READY");
            }
        }
    }

    /* ==========  Swaps  ========== */

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external override
        _lock_
        _public_
        _rebalance_
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_TOKEN_IN");
        require(_records[tokenOut].bound && _records[tokenOut].ready, "ERR_TOKEN_OUT");

        Record storage inRecord = _records[tokenIn];
        uint256 inRecordBalance = _getBalance(tokenIn);
        Record storage outRecord = _records[tokenOut];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint256 spotPriceBefore = calcSpotPrice(
                                    inRecordBalance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
                            inRecordBalance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountIn,
                            _swapFee
                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        // Update tokens
        _updateToken(tokenIn, badd(inRecord.balance, tokenAmountIn));
        _updateToken(tokenOut, bsub(outRecord.balance, tokenAmountOut));

        spotPriceAfter = calcSpotPrice(
                                _getBalance(tokenIn),
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");     
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LogSwap(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
        external override
        _lock_
        _public_
        _rebalance_
        returns (uint256 tokenAmountIn, uint256 spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_TOKEN_IN");
        require(_records[tokenOut].bound && _records[tokenOut].ready, "ERR_TOKEN_OUT");

        Record storage inRecord = _records[tokenIn];
        uint256 inRecordBalance = _getBalance(tokenIn);
        Record storage outRecord = _records[tokenOut];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        uint256 spotPriceBefore = calcSpotPrice(
                                    inRecordBalance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
                            inRecordBalance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountOut,
                            _swapFee
                        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        // Update tokens
        _updateToken(tokenIn, badd(inRecord.balance, tokenAmountIn));
        _updateToken(tokenOut, bsub(outRecord.balance, tokenAmountOut));

        spotPriceAfter = calcSpotPrice(
                                _getBalance(tokenIn),
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LogSwap(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        return (tokenAmountIn, spotPriceAfter);
    }

    /* ==========  Internal Helpers  ========== */

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint256 amount)
        internal
    {
        IERC20Upgradeable(erc20).safeTransferFrom(from, address(this), amount);
    }

    function _pushUnderlying(address erc20, address to, uint256 amount)
        internal
    {
        IERC20Upgradeable(erc20).safeTransfer(to, amount);
    }

    function _pullPoolShare(address from, uint256 amount)
        internal
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount)
        internal
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount)
        internal
    {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount)
        internal
    {
        _burn(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./BNum.sol";
import "../interfaces/IERC20.sol";

/************************************************************************************************
Originally forked from https://github.com/balancer-labs/balancer-core/

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

// Highly opinionated token implementation

contract BTokenBase is BNum {

    mapping(address => uint) internal _balance;
    mapping(address => mapping(address=>uint)) internal _allowance;
    uint internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract BToken is BTokenBase, IERC20 {

    uint8 private constant DECIMALS = 18;
    string private _name;
    string private _symbol;

    function _initializeToken(string memory name, string memory symbol) internal {
        require(bytes(_name).length == 0, "ERR_BTOKEN_INITIALIZED");
        require(bytes(name).length != 0 && bytes(symbol).length != 0, "ERR_BAD_PARAMS");
        _name = name;
        _symbol = symbol;
    }

    function name() external override view returns (string memory) {
        return _name;
    }

    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    function decimals() external override view returns(uint8) {
        return DECIMALS;
    }

    function allowance(address src, address dst) external override view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external override view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./BNum.sol";

/************************************************************************************************
Originally forked from https://github.com/balancer-labs/balancer-core/

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract BMath is BConst, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    )
        internal pure
        returns (uint spotPrice)
    {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return  (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountOut)
    {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountIn)
    {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        internal pure
        returns (uint poolAmountOut)
    {
        // Charge the trading fee for the proportion of tokenAi
        // which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee); 
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountIn)
    {
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);
      
        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = bdiv(BONE, normalizedWeight); 
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way 
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        internal pure
        returns (uint tokenAmountOut)
    {
        // unused function but add variable exit fee for consistency
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, exitFee));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);
     
        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side 
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee); 
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        internal pure
        returns (uint poolAmountIn)
    {
        // unused function but add variable exit fee for consistency
        // charge swap fee on the output token side 
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee); 
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, exitFee));
        return poolAmountIn;
    }

    // Computes the expected denorm for current timestamp
    function calcDenorm(
        uint256 lastUpdateTime,
        uint256 currTime,
        uint256 targetTime,
        uint256 denorm,
        uint256 targetDenorm
    )
        internal pure
        returns (uint256)
    {
        if (targetTime <= currTime) {
            return targetDenorm;
        }

        uint256 timeDelta = bsub(currTime, lastUpdateTime);
        uint256 timeLeft = bsub(targetTime, lastUpdateTime);
        if (denorm > targetDenorm) {
            uint256 denormDelta = bsub(denorm, targetDenorm);
            uint256 diff = bdiv(bmul(denormDelta, timeDelta), timeLeft);
            return bmax(bsub(denorm, diff), targetDenorm);
        } else {
            uint256 denormDelta = bsub(targetDenorm, denorm);
            uint256 diff = bdiv(bmul(denormDelta, timeDelta), timeLeft);
            return bmin(badd(denorm, diff), targetDenorm);
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@bundle-dao/pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
import "./IBundle.sol";

interface IUnbinder {
    struct SwapToken {
        bool flag;
        uint256 index;
    }

    event TokenUnbound(address token);

    event LogSwapWhitelist(
        address indexed caller,
        address         token,
        bool            flag
    );

    event LogPremium(
        address indexed caller,
        uint256         premium
    );

    function initialize(address bundle, address router, address controller, address[] calldata whitelist) external;

    function handleUnboundToken(address token) external;

    function distributeUnboundToken(address token, uint256 amount, uint256 deadline, address[][] calldata paths) external;

    function setPremium(uint256 premium) external;

    function setSwapWhitelist(address token, bool flag) external;

    function getPremium() external view returns (uint256);

    function getController() external view returns (address);

    function getBundle() external view returns (address);

    function isSwapWhitelisted(address token) external view returns (bool);

    function getSwapWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IUnbinder.sol";

interface IBundle {
    struct Record {
        bool bound;               // is token bound to pool
        bool ready;               // is token ready for swaps
        uint256 denorm;           // denormalized weight
        uint256 targetDenorm;     // target denormalized weight
        uint256 targetTime;      // target block to update by
        uint256 lastUpdateTime;  // last update block
        uint8 index;              // token index
        uint256 balance;          // token balance
    }

    /* ========== Events ========== */

    event LogSwap(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
    );

    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LogSwapFeeUpdated(
        address indexed caller,
        uint256         swapFee
    );

    event LogTokenReady(
        address indexed token
    );

    event LogPublicSwapEnabled();

    event LogRebalancable(
        address indexed caller,
        bool            rebalancable
    );

    event LogCollectFee(
        address indexed caller
    );

    event LogStreamingFee(
        address indexed caller,
        uint256         fee
    );

    event LogTokenBound(
        address indexed token
    );

    event LogTokenUnbound(
        address indexed token
    );

    event LogMinBalance(
        address indexed caller,
        address indexed token,
        uint256         minBalance
    );

    event LogTargetDelta(
        address indexed caller,
        uint256         targetDelta
    );

    event LogExitFee(
        address indexed caller,
        uint256         exitFee
    );

    event LogReindex(
        address indexed caller,
        address[]       tokens,
        uint256[]       targetDenorms,
        uint256[]       minBalances
    );

    event LogReweigh(
        address indexed caller,
        address[]       tokens,
        uint256[]       targetDenorms
    );

    /* ========== Initialization ========== */

    function initialize(
        address controller, 
        address rebalancer,
        address unbinder,
        string calldata name, 
        string calldata symbol
    ) external;

    function setup(
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms,
        address tokenProvider
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setRebalancable(bool rebalancable) external;

    function setMinBalance(address token, uint256 minBalance) external;

    function setStreamingFee(uint256 streamingFee) external;

    function setExitFee(uint256 exitFee) external;

    function setTargetDelta(uint256 targetDelta) external;

    function collectStreamingFee() external;

    function isPublicSwap() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function isReady(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256) ;

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getStreamingFee() external view returns (uint256);

    function getExitFee() external view returns (uint256);

    function getController() external view returns (address);

    function getRebalancer() external view returns (address);

    function getRebalancable() external view returns (bool);

    function getUnbinder() external view returns (address);

    function getSpotPrice(
        address tokenIn, 
        address tokenOut
    ) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(
        address tokenIn, 
        address tokenOut
    ) external view returns (uint256 spotPrice);

    /* ==========  External Token Weighting  ========== */

    /**
     * @dev Adjust weights for existing tokens
     * @param tokens A set of token addresses to adjust
     * @param targetDenorms A set of denorms to linearly update to
     */

    function reweighTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms
    ) external;

    /**
     * @dev Reindex the pool on a new set of tokens
     *
     * @param tokens A set of token addresses to be indexed
     * @param targetDenorms A set of denorms to linearly update to
     * @param minBalances Minimum balance thresholds for unbound assets
     */
    function reindexTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms,
        uint256[] calldata minBalances
    ) external;

    function gulp(address token) external;

    function joinPool(uint256 poolAmountOut, uint[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./BConst.sol";

/************************************************************************************************
Originally forked from https://github.com/balancer-labs/balancer-core/

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract BNum is BConst {

    function btoi(uint a)
        internal pure 
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);   
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom 
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

    function bmin(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function bmax(uint256 a, uint256 b) 
        internal pure 
        returns (uint256)
    {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

/************************************************************************************************
Originally forked from https://github.com/balancer-labs/balancer-core/

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract BConst {
    uint256 internal constant BONE               = 10**18;

    uint256 internal constant MIN_BOUND_TOKENS   = 2;
    uint256 internal constant MAX_BOUND_TOKENS   = 15;

    uint256 internal constant MIN_FEE            = BONE / 10**6;
    uint256 internal constant INIT_FEE           = (2 * BONE) / 10**2;
    uint256 internal constant MAX_FEE            = BONE / 10;
    
    uint256 internal constant INIT_EXIT_FEE      = (2 * BONE) / 10**2;
    uint256 internal constant MAX_EXIT_FEE       = (5 * BONE) / 10**2;

    uint256 internal constant MAX_STREAMING_FEE  = (4 * BONE) / 10**2;
    uint256 internal constant INIT_STREAMING_FEE = (2 * BONE) / 10**2;
    uint256 internal constant BPY                = 365 days;

    uint256 internal constant MIN_WEIGHT         = BONE / 2;
    uint256 internal constant MAX_WEIGHT         = BONE * 50;
    uint256 internal constant MAX_TOTAL_WEIGHT   = BONE * 51;
    uint256 internal constant MIN_BALANCE        = BONE / 10**12;

    uint256 internal constant INIT_POOL_SUPPLY   = BONE * 100;

    uint256 internal constant MIN_BPOW_BASE      = 1 wei;
    uint256 internal constant MAX_BPOW_BASE      = (2 * BONE) - 1 wei;
    uint256 internal constant BPOW_PRECISION     = BONE / 10**10;

    uint256 internal constant MAX_TARGET_DELTA   = 14 days;
    uint256 internal constant INIT_TARGET_DELTA  = 7 days;
    uint256 internal constant MIN_TARGET_DELTA   = 1 days;

    uint256 internal constant MAX_IN_RATIO       = BONE / 2;
    uint256 internal constant MAX_OUT_RATIO      = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}