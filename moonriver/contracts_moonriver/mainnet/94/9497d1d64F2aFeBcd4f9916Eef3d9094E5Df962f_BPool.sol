pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import "./BToken.sol";
import "./BMath.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/ISideStaking.sol";
import "../../utils/SafeERC20.sol";


/**
 * @title BPool
 *
 * @dev Used by the (Ocean version) BFactory contract as a bytecode reference to
 *      deploy new BPools.
 *
 * This contract is a friendly fork of Balancer [1]
 *  [1] https://github.com/balancer-labs/balancer-core/contracts/.

 * All fees are expressed in wei.  Examples:
 *  (1e17 = 10 % , 1e16 = 1% , 1e15 = 0.1%, 1e14 = 0.01%)
 */
contract BPool is BMath, BToken, IPool {
    using SafeERC20 for IERC20;
    struct Record {
        bool bound; // is token bound to pool
        uint256 index; // private
        uint256 denorm; // denormalized weight
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut,
        uint256 timestamp,
        uint256 inBalance,
        uint256 outBalance,
        uint256 newSpotPrice
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn,
        uint256 timestamp
    );
    event LOG_SETUP(
        address indexed caller,
        address indexed baseToken,
        uint256 baseTokenAmountIn,
        uint256 baseTokenWeight,
        address indexed datatoken,
        uint256 datatokenAmountIn,
        uint256 datatokenWeight
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut,
        uint256 timestamp
    );

    event LOG_CALL(
        bytes4 indexed sig,
        address indexed caller,
        uint256 timestamp,
        bytes data
    );

    event LOG_BPT(uint256 bptAmount);
    event LOG_BPT_SS(uint256 bptAmount); //emitted for SS contract

    event OPCFee(
        address caller,
        address OPCWallet,
        address token,
        uint256 amount
    );
    event SwapFeeChanged(address caller, uint256 amount);
    event PublishMarketFee(
        address caller,
        address marketAddress,
        address token,
        uint256 amount
    );
    // emited for fees sent to consumeMarket
    event ConsumeMarketFee(address to, address token, uint256 amount);
    event SWAP_FEES(uint LPFeeAmount, uint oceanFeeAmount, uint marketFeeAmount,
        uint consumeMarketFeeAmount, address tokenFeeAddress);
    //emitted for every change done by publisherMarket
    event PublishMarketFeeChanged(address caller, address newMarketCollector, uint256 swapFee);
    event Gulped(address token, uint256 oldBalance, uint256 newBalance);
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

    bool private _mutex;

    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    //address public _publishMarketCollector;
    address public _publishMarketCollector;
    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint256 private _totalWeight;
    ISideStaking ssContract;

    //-----------------------------------------------------------------------
    //Proxy contract functionality: begin
    bool private initialized;

    /**
     * @dev getId
     *      Return template id in case we need different ABIs. 
     *      If you construct your own template, please make sure to change the hardcoded value
     */
    function getId() pure public returns (uint8) {
        return 1;
    }

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    // Called prior to contract initialization (e.g creating new BPool instance)
    // Calls private _initialize function. Only if contract is not initialized.
    function initialize(
        address controller,
        address factory,
        uint256[] calldata swapFees,
        bool publicSwap,
        bool finalized,
        address[2] calldata tokens,
        address[1] calldata feeCollectors
    ) external returns (bool) {
        require(!initialized, "ERR_ALREADY_INITIALIZED");
        require(controller != address(0), "ERR_INVALID_CONTROLLER_ADDRESS");
        require(factory != address(0), "ERR_INVALID_FACTORY_ADDRESS");
        require(swapFees[0] >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFees[0] <= MAX_FEE, "ERR_MAX_FEE");
        require(swapFees[1] == 0 || swapFees[1]>= MIN_FEE, "ERR_MIN_FEE");
        require(swapFees[1] <= MAX_FEE, "ERR_MAX_FEE");
        return
            _initialize(
                controller,
                factory,
                swapFees,
                publicSwap,
                finalized,
                tokens,
                feeCollectors
            );
    }

    // Private function called on contract initialization.
    function _initialize(
        address controller,
        address factory,
        uint256[] memory swapFees,
        bool publicSwap,
        bool finalized,
        address[2] memory tokens,
        address[1] memory feeCollectors
    ) private returns (bool) {
        _controller = controller;
        router = factory;
        _swapFee = swapFees[0];
        emit SwapFeeChanged(msg.sender, _swapFee);
        _swapPublishMarketFee = swapFees[1];
        _publicSwap = publicSwap;
        _finalized = finalized;
        _datatokenAddress = tokens[0];
        _baseTokenAddress = tokens[1];
        _publishMarketCollector = feeCollectors[0];
        emit PublishMarketFeeChanged(msg.sender, _publishMarketCollector, _swapPublishMarketFee);
        initialized = true;
        ssContract = ISideStaking(_controller);
        return initialized;
    }

    
    /**
     * @dev setup
     *      Initial setup of the pool
     *      Can be called only by the controller
     * @param datatokenAddress datatokenAddress
     * @param datatokenAmount how many datatokens in the initial reserve
     * @param datatokenWeight datatoken weight (hardcoded in deployer at 50%)
     * @param baseTokenAddress base token
     * @param baseTokenAmount how many basetokens in the initial reserve
     * @param baseTokenWeight base weight (hardcoded in deployer at 50%)
     */
    function setup(
        address datatokenAddress,
        uint256 datatokenAmount,
        uint256 datatokenWeight,
        address baseTokenAddress,
        uint256 baseTokenAmount,
        uint256 baseTokenWeight
    ) external _lock_ {
        require(msg.sender == _controller, "ERR_INVALID_CONTROLLER");
        require(
            datatokenAddress == _datatokenAddress,
            "ERR_INVALID_DATATOKEN_ADDRESS"
        );
        require(
            baseTokenAddress == _baseTokenAddress,
            "ERR_INVALID_baseToken_ADDRESS"
        );
        // other inputs will be validated prior
        // calling the below functions
        // bind datatoken
        bind(datatokenAddress, datatokenAmount, datatokenWeight);
        emit LOG_JOIN(
            msg.sender,
            datatokenAddress,
            datatokenAmount,
            block.timestamp
        );

        // bind baseToken
        bind(baseTokenAddress, baseTokenAmount, baseTokenWeight);
        emit LOG_JOIN(
            msg.sender,
            baseTokenAddress,
            baseTokenAmount,
            block.timestamp
        );
        // finalize
        finalize();
        emit LOG_SETUP(
            msg.sender,
            baseTokenAddress,
            baseTokenAmount,
            baseTokenWeight,
            datatokenAddress,
            datatokenAmount,
            datatokenWeight
        );
    }

    //Proxy contract functionality: end
    //-----------------------------------------------------------------------
    /**
     * @dev isPublicSwap
     *      Returns true if swapping is allowed
     */
    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }
    /**
     * @dev isFinalized
     *      Returns true if pool is finalized
     */
    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    /**
     * @dev isBound
     *      Returns true if token is bound
     * @param t token to be checked
     */
    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function _checkBound(address token) internal view {
        require(_records[token].bound, "ERR_NOT_BOUND");
    }

    /**
     * @dev getNumTokens
     *      Returns number of tokens bounded to pool
     */
    function getNumTokens() external view returns (uint256) {
        return _tokens.length;
    }

    /**
     * @dev getCurrentTokens
     *      Returns tokens bounded to pool, before the pool is finalized
     */
    function getCurrentTokens()
        external
        view
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    /**
     * @dev getFinalTokens
     *      Returns tokens bounded to pool, after the pool was finalized
     */
    function getFinalTokens()
        public
        view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    /**
     * @dev collectOPC
     *      Collects and send all OPC Fees to _opcCollector.
     *      This funtion can be called by anyone, because fees are being sent to _opcCollector
     */
    function collectOPC() external {
        address[] memory tokens = getFinalTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = communityFees[tokens[i]];
            communityFees[tokens[i]] = 0;
            address _opcCollector = IFactoryRouter(router).getOPCCollector();
            emit OPCFee(msg.sender, _opcCollector, tokens[i], amount);
            IERC20(tokens[i]).safeTransfer(_opcCollector, amount);
        }
    }

    /**
     * @dev getCurrentOPCFees
     *      Get the current amount of fees which can be withdrawned by OPC
     * @return address[] - array of tokens addresses
     *         uint256[] - array of amounts
     */
    function getCurrentOPCFees()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory poolTokens = getFinalTokens();
        address[] memory tokens = new address[](poolTokens.length);
        uint256[] memory amounts = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; i++) {
            tokens[i] = poolTokens[i];
            amounts[i] = communityFees[poolTokens[i]];
        }
        return (tokens, amounts);
    }

    /**
     * @dev getCurrentMarketFees
     *      Get the current amount of fees which can be withdrawned by _publishMarketCollector
     * @return address[] - array of tokens addresses
     *         uint256[] - array of amounts
     */
    function getCurrentMarketFees()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory poolTokens = getFinalTokens();
        address[] memory tokens = new address[](poolTokens.length);
        uint256[] memory amounts = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; i++) {
            tokens[i] = poolTokens[i];
            amounts[i] = publishMarketFees[poolTokens[i]];
        }
        return (tokens, amounts);
    }

    /**
     * @dev collectMarketFee
     *      Collects and send all Market Fees to _publishMarketCollector.
     *      This function can be called by anyone, because fees are being sent to _publishMarketCollector
     */
    function collectMarketFee() external {
        address[] memory tokens = getFinalTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = publishMarketFees[tokens[i]];
            publishMarketFees[tokens[i]] = 0;
            emit PublishMarketFee(
                msg.sender,
                _publishMarketCollector,
                tokens[i],
                amount
            );
            IERC20(tokens[i]).safeTransfer(_publishMarketCollector, amount);
        }
    }

    /**
     * @dev updatePublishMarketFee
     *      Set _newCollector as _publishMarketCollector
     * @param _newCollector new _publishMarketCollector
     * @param _newSwapFee new swapFee
     */
    function updatePublishMarketFee(address _newCollector, uint256 _newSwapFee) external {
        require(_publishMarketCollector == msg.sender, "ONLY MARKET COLLECTOR");
        require(_newCollector != address(0), "Invalid _newCollector address");
        require(_newSwapFee ==0 || _newSwapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(_newSwapFee <= MAX_FEE, "ERR_MAX_FEE");
        _publishMarketCollector = _newCollector;
        _swapPublishMarketFee = _newSwapFee;
        emit PublishMarketFeeChanged(msg.sender, _publishMarketCollector, _swapPublishMarketFee);
    }

    /**
     * @dev getDenormalizedWeight
     *      Returns denormalized weight of a token
     * @param token token to be checked
     */
    function getDenormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        _checkBound(token);
        return _records[token].denorm;
    }

     /**
     * @dev getTotalDenormalizedWeight
     *      Returns total denormalized weught of the pool
     */
    function getTotalDenormalizedWeight()
        external
        view
        _viewlock_
        returns (uint256)
    {
        return _totalWeight;
    }

    /**
     * @dev getNormalizedWeight
     *      Returns normalized weight of a token
     * @param token token to be checked
     */
    
    function getNormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        _checkBound(token);
        uint256 denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }


    /**
     * @dev getBalance
     *      Returns the current token reserve amount
     * @param token token to be checked
     */
    function getBalance(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        _checkBound(token);
        return _records[token].balance;
    }

    /**
     * @dev getSwapFee
     *      Returns the current Liquidity Providers swap fee
     */
    function getSwapFee() external view returns (uint256) {
        return _swapFee;
    }

    /**
     * @dev getMarketFee
     *      Returns the current fee of publishingMarket
     */
    function getMarketFee() external view returns (uint256) {
        return _swapPublishMarketFee;
    }

    /**
     * @dev getController
     *      Returns the current controller address (ssBot)
     */
    function getController() external view returns (address) {
        return _controller;
    }

    /**
     * @dev getDatatokenAddress
     *      Returns the current datatoken address
     */
    function getDatatokenAddress() external view returns (address) {
        return _datatokenAddress;
    }

    /**
     * @dev getBaseTokenAddress
     *      Returns the current baseToken address
     */
    function getBaseTokenAddress() external view returns (address) {
        return _baseTokenAddress;
    }


    /**
     * @dev setSwapFee
     *      Allows controller to change the swapFee
     * @param swapFee new swap fee (max 1e17 = 10 % , 1e16 = 1% , 1e15 = 0.1%, 1e14 = 0.01%)
     */
    function setSwapFee(uint256 swapFee) public {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
        emit SwapFeeChanged(msg.sender, swapFee);
    }

    /**
     * @dev finalize
     *      Finalize pool. After this,new tokens cannot be bound
     */
    function finalize() internal {
        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    /**
     * @dev bind
     *      Bind a new token to the pool.
     * @param token token address
     * @param balance initial reserve
     * @param denorm denormalized weight
     */
    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) internal {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    /**
     * @dev rebind
     *      Update pool reserves & weight after a token bind
     * @param token token address
     * @param balance initial reserve
     * @param denorm denormalized weight
     */
    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) internal {
        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint256 oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, we don't have EXIT_FEES
            uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(
                token,
                msg.sender,
                tokenBalanceWithdrawn
            );
        }
    }

    /**
     * @dev getSpotPrice
     *      Return the spot price of swapping tokenIn to tokenOut
     * @param tokenIn in token
     * @param tokenOut out token
     * @param _consumeMarketSwapFee consume market swap fee 
     */
    function getSpotPrice(
        address tokenIn,
        address tokenOut,
        uint256 _consumeMarketSwapFee
    ) external view _viewlock_ returns (uint256 spotPrice) {
        _checkBound(tokenIn);
        _checkBound(tokenOut);
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return
            calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                _consumeMarketSwapFee
            );
    }

    // view function used for batch buy. useful for frontend
     /**
     * @dev getAmountInExactOut
     *      How many tokensIn do you need in order to get exact tokenAmountOut.
            Returns: tokenAmountIn, LPFee, opcFee , publishMarketSwapFee, consumeMarketSwapFee
     * @param tokenIn token to be swaped
     * @param tokenOut token to get
     * @param tokenAmountOut exact amount of tokenOut
     * @param _consumeMarketSwapFee consume market swap fee
     */

    function getAmountInExactOut(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 _consumeMarketSwapFee
    )
        external
        view
        returns (
            // _viewlock_
            uint256 tokenAmountIn, uint lpFeeAmount, 
            uint oceanFeeAmount, 
            uint publishMarketSwapFeeAmount,
            uint consumeMarketSwapFeeAmount
        )
    {
        _checkBound(tokenIn);
        _checkBound(tokenOut);
        uint256[4] memory data = [
            _records[tokenIn].balance,
            _records[tokenIn].denorm,
            _records[tokenOut].balance,
            _records[tokenOut].denorm
        ];
        uint tokenAmountInBalance;
        swapfees memory _swapfees;
        (tokenAmountIn, tokenAmountInBalance, _swapfees) =        
            calcInGivenOut(
                data,
                tokenAmountOut,
                // tokenIn,
                _consumeMarketSwapFee
            );
        return(tokenAmountIn, _swapfees.LPFee, _swapfees.oceanFeeAmount, 
        _swapfees.publishMarketFeeAmount, _swapfees.consumeMarketFee);

    }

    // view function useful for frontend
    /**
     * @dev getAmountOutExactIn
     *      How many tokensOut you will get for a exact tokenAmountIn
            Returns: tokenAmountOut, LPFee, opcFee ,  publishMarketSwapFee, consumeMarketSwapFee
     * @param tokenIn token to be swaped
     * @param tokenOut token to get
     * @param tokenAmountOut exact amount of tokenOut
     * @param _consumeMarketSwapFee consume market swap fee
     */
    function getAmountOutExactIn(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountIn,
        uint256 _consumeMarketSwapFee
    )
        external
        view
        returns (
            //  _viewlock_
            uint256 tokenAmountOut,
            uint lpFeeAmount, 
            uint oceanFeeAmount, 
            uint publishMarketSwapFeeAmount,
            uint consumeMarketSwapFeeAmount
        )
    {
        _checkBound(tokenIn);
        _checkBound(tokenOut);
        uint256[4] memory data = [
            _records[tokenIn].balance,
            _records[tokenIn].denorm,
            _records[tokenOut].balance,
            _records[tokenOut].denorm
        ];
        uint balanceInToAdd;
        swapfees memory _swapfees;
         (tokenAmountOut, balanceInToAdd, _swapfees) =        
            calcOutGivenIn(
                data,
                tokenAmountIn,
               // tokenIn,
                _consumeMarketSwapFee
            );
        return(tokenAmountOut, _swapfees.LPFee, 
        _swapfees.oceanFeeAmount, _swapfees.publishMarketFeeAmount, _swapfees.consumeMarketFee);
    }


    /**
     * @dev swapExactAmountIn
     *      Swaps an exact amount of tokensIn to get a mimum amount of tokenOut
     * @param tokenInOutMarket array of addreses: [tokenIn, tokenOut, consumeMarketFeeAddress]
     * @param amountsInOutMaxFee array of ints: [tokenAmountIn, minAmountOut, maxPrice, consumeMarketSwapFee]
     */
    function swapExactAmountIn(
        address[3] calldata tokenInOutMarket, 
        uint256[4] calldata amountsInOutMaxFee
    ) external _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(tokenInOutMarket[0] != tokenInOutMarket[1], 'Cannot swap same token');
        _checkBound(tokenInOutMarket[0]);
        _checkBound(tokenInOutMarket[1]);
        Record storage inRecord = _records[address(tokenInOutMarket[0])];
        Record storage outRecord = _records[address(tokenInOutMarket[1])];
        require(amountsInOutMaxFee[3] ==0 || amountsInOutMaxFee[3] >= MIN_FEE,'ConsumeSwapFee too low');
        require(amountsInOutMaxFee[3] <= MAX_FEE,'ConsumeSwapFee too high');
        require(
            amountsInOutMaxFee[0] <= bmul(inRecord.balance, MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        uint256 spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            amountsInOutMaxFee[3]
        );

        require(
            spotPriceBefore <= amountsInOutMaxFee[2],
            "ERR_BAD_LIMIT_PRICE"
        );
        uint256 balanceInToAdd;
        uint256[4] memory data = [
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm
        ];
        swapfees memory _swapfees;
        (tokenAmountOut, balanceInToAdd, _swapfees) = calcOutGivenIn(
            data,
            amountsInOutMaxFee[0],
           // tokenInOutMarket[0],
            amountsInOutMaxFee[3]
        );
        // update balances
        communityFees[tokenInOutMarket[0]] = badd(communityFees[tokenInOutMarket[0]],_swapfees.oceanFeeAmount);
        publishMarketFees[tokenInOutMarket[0]] = 
        badd(publishMarketFees[tokenInOutMarket[0]],_swapfees.publishMarketFeeAmount);
        emit SWAP_FEES(_swapfees.LPFee, _swapfees.oceanFeeAmount,
        _swapfees.publishMarketFeeAmount,_swapfees.consumeMarketFee, tokenInOutMarket[0]);
        require(tokenAmountOut >= amountsInOutMaxFee[1], "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, balanceInToAdd);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            amountsInOutMaxFee[3]
        );

        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= amountsInOutMaxFee[2], "ERR_LIMIT_PRICE");

        require(
            spotPriceBefore <= bdiv(amountsInOutMaxFee[0], tokenAmountOut),
            "ERR_MATH_APPROX"
        );

        emit LOG_SWAP(
            msg.sender,
            tokenInOutMarket[0],
            tokenInOutMarket[1],
            amountsInOutMaxFee[0],
            tokenAmountOut,
            block.timestamp,
            inRecord.balance,
            outRecord.balance,
            spotPriceAfter

        );

        _pullUnderlying(tokenInOutMarket[0], msg.sender, amountsInOutMaxFee[0]);
        uint256 consumeMarketFeeAmount = bsub(
            amountsInOutMaxFee[0],
            bmul(amountsInOutMaxFee[0], bsub(BONE, amountsInOutMaxFee[3]))
        );
        if (amountsInOutMaxFee[3] > 0) {
            IERC20(tokenInOutMarket[0]).safeTransfer(
                tokenInOutMarket[2],
                consumeMarketFeeAmount
            );
            emit ConsumeMarketFee(
                tokenInOutMarket[2],
                tokenInOutMarket[0],
                consumeMarketFeeAmount
            );
        }
        _pushUnderlying(tokenInOutMarket[1], msg.sender, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter); //returning spot price 0 because there is no public spotPrice
    }


    /**
     * @dev swapExactAmountOut
     *      Swaps a maximum  maxAmountIn of tokensIn to get an exact amount of tokenOut
     * @param tokenInOutMarket array of addreses: [tokenIn, tokenOut, consumeMarketFeeAddress]
     * @param amountsInOutMaxFee array of ints: [maxAmountIn,tokenAmountOut,maxPrice, consumeMarketSwapFee]
     */
    function swapExactAmountOut(
        address[3] calldata tokenInOutMarket,
        uint256[4] calldata amountsInOutMaxFee
    ) external _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(tokenInOutMarket[0] != tokenInOutMarket[1], 'Cannot swap same token');
        require(amountsInOutMaxFee[3] ==0 || amountsInOutMaxFee[3] >= MIN_FEE,'ConsumeSwapFee too low');
        require(amountsInOutMaxFee[3] <= MAX_FEE,'ConsumeSwapFee too high');
        _checkBound(tokenInOutMarket[0]);
        _checkBound(tokenInOutMarket[1]);
        Record storage inRecord = _records[address(tokenInOutMarket[0])];
        Record storage outRecord = _records[address(tokenInOutMarket[1])];

        require(
            amountsInOutMaxFee[1] <= bmul(outRecord.balance, MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        uint256 spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            amountsInOutMaxFee[3]
        );

        require(
            spotPriceBefore <= amountsInOutMaxFee[2],
            "ERR_BAD_LIMIT_PRICE"
        );
        // this is the amount we are going to register in balances
        // (only takes account of swapFee, not OPC and market fee,
        //in order to not affect price during following swaps, fee wtihdrawl etc)
        uint256 balanceToAdd;
        uint256[4] memory data = [
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm
        ];
        swapfees memory _swapfees;
        (tokenAmountIn, balanceToAdd,
        _swapfees) = calcInGivenOut(
            data,
            amountsInOutMaxFee[1],
            //tokenInOutMarket[0],
            amountsInOutMaxFee[3]
        );
        communityFees[tokenInOutMarket[0]] = badd(communityFees[tokenInOutMarket[0]],_swapfees.oceanFeeAmount);
        publishMarketFees[tokenInOutMarket[0]] 
        = badd(publishMarketFees[tokenInOutMarket[0]],_swapfees.publishMarketFeeAmount);
        emit SWAP_FEES(_swapfees.LPFee, _swapfees.oceanFeeAmount,
        _swapfees.publishMarketFeeAmount,_swapfees.consumeMarketFee, tokenInOutMarket[0]);
        require(tokenAmountIn <= amountsInOutMaxFee[0], "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, balanceToAdd);
        outRecord.balance = bsub(outRecord.balance, amountsInOutMaxFee[1]);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            amountsInOutMaxFee[3]
        );

        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= amountsInOutMaxFee[2], "ERR_LIMIT_PRICE");
        require(
            spotPriceBefore <= bdiv(tokenAmountIn, amountsInOutMaxFee[1]),
            "ERR_MATH_APPROX"
        );

        emit LOG_SWAP(
            msg.sender,
            tokenInOutMarket[0],
            tokenInOutMarket[1],
            tokenAmountIn,
            amountsInOutMaxFee[1],
            block.timestamp,
            inRecord.balance,
            outRecord.balance,
            spotPriceAfter
        );
        _pullUnderlying(tokenInOutMarket[0], msg.sender, tokenAmountIn);
        uint256 consumeMarketFeeAmount = bsub(
            tokenAmountIn,
            bmul(tokenAmountIn, bsub(BONE, amountsInOutMaxFee[3]))
        );
        if (amountsInOutMaxFee[3] > 0) {
            IERC20(tokenInOutMarket[0]).safeTransfer(
                tokenInOutMarket[2],// market address
                consumeMarketFeeAmount
            );
            emit ConsumeMarketFee(
                tokenInOutMarket[2], // to (market address)
                tokenInOutMarket[0], // token
                consumeMarketFeeAmount
            );
        }
        _pushUnderlying(tokenInOutMarket[1], msg.sender, amountsInOutMaxFee[1]);
        return (tokenAmountIn, spotPriceAfter);
    }

    /**
     * @dev joinswapExternAmountIn
     *      Single side add liquidity to the pool,
     *      expecting a minPoolAmountOut of shares for spending tokenAmountIn basetokens
     * @param tokenAmountIn exact number of base tokens to spend
     * @param minPoolAmountOut minimum of pool shares expectex
     */
    function joinswapExternAmountIn(
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external _lock_ returns (uint256 poolAmountOut) {
        //tokenIn = _baseTokenAddress;
        require(_finalized, "ERR_NOT_FINALIZED");
        _checkBound(_baseTokenAddress);
        require(
            tokenAmountIn <= bmul(_records[_baseTokenAddress].balance, MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );
        //ask ssContract
        Record storage inRecord = _records[_baseTokenAddress];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            _totalSupply,
            tokenAmountIn
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        emit LOG_JOIN(msg.sender, _baseTokenAddress, tokenAmountIn, block.timestamp);
        emit LOG_BPT(poolAmountOut);

        

        //ask the ssContract to stake as well
        //calculate how much should the 1ss stake
        Record storage ssInRecord = _records[_datatokenAddress];
        uint256 ssAmountIn = calcSingleInGivenPoolOut(
            ssInRecord.balance,
            _totalSupply,
            poolAmountOut
        );
        if (ssContract.canStake(_datatokenAddress, ssAmountIn)) {
            
            //call 1ss to approve
            ssContract.Stake(_datatokenAddress, ssAmountIn);
            // follow the same path
            ssInRecord.balance = badd(ssInRecord.balance, ssAmountIn);
            emit LOG_JOIN(
                _controller,
                _datatokenAddress,
                ssAmountIn,
                block.timestamp
            );
            emit LOG_BPT_SS(poolAmountOut);
            _mintPoolShare(poolAmountOut);
            _pushPoolShare(_controller, poolAmountOut);
            _pullUnderlying(_datatokenAddress, _controller, ssAmountIn);
            
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(_baseTokenAddress, msg.sender, tokenAmountIn);
        return poolAmountOut;
    }

    
    /**
     * @dev exitswapPoolAmountIn
     *      Single side remove liquidity from the pool,
     *      expecting a minAmountOut of basetokens for spending poolAmountIn pool shares
     * @param poolAmountIn exact number of pool shares to spend
     * @param minAmountOut minimum amount of basetokens expected
     */
    function exitswapPoolAmountIn(
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external _lock_ returns (uint256 tokenAmountOut) {
        //tokenOut = _baseTokenAddress;
        require(_finalized, "ERR_NOT_FINALIZED");
        _checkBound(_baseTokenAddress);

        Record storage outRecord = _records[_baseTokenAddress];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            _totalSupply,
            poolAmountIn
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(
            tokenAmountOut <= bmul(_records[_baseTokenAddress].balance, MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        //uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        emit LOG_EXIT(msg.sender, _baseTokenAddress, tokenAmountOut, block.timestamp);
        emit LOG_BPT(poolAmountIn);

        //ask the ssContract to unstake as well
        //calculate how much should the 1ss unstake
        
        if (
            ssContract.canUnStake(_datatokenAddress, poolAmountIn)
        ) {
            Record storage ssOutRecord = _records[_datatokenAddress];
            uint256 ssAmountOut = calcSingleOutGivenPoolIn(
                ssOutRecord.balance,
                _totalSupply,
                poolAmountIn
            );

            ssOutRecord.balance = bsub(ssOutRecord.balance, ssAmountOut);
            //exitFee = bmul(poolAmountIn, EXIT_FEE);
            emit LOG_EXIT(
                _controller,
                _datatokenAddress,
                ssAmountOut,
                block.timestamp
            );
            _pullPoolShare(_controller, poolAmountIn);
            //_burnPoolShare(bsub(poolAmountIn, exitFee));
            _burnPoolShare(poolAmountIn);
            //_pushPoolShare(_factory, exitFee);
            _pushUnderlying(_datatokenAddress, _controller, ssAmountOut);
            //call unstake on 1ss to do cleanup on their side
            ssContract.UnStake(
                _datatokenAddress,
                ssAmountOut,
                poolAmountIn
            );
            emit LOG_BPT_SS(poolAmountIn);
        }
        
        _pullPoolShare(msg.sender, poolAmountIn);
        //_burnPoolShare(bsub(poolAmountIn, exitFee));
        _burnPoolShare(poolAmountIn);
        //_pushPoolShare(_factory, exitFee);
        _pushUnderlying(_baseTokenAddress, msg.sender, tokenAmountOut);
        return tokenAmountOut;
    }

    

    /**
     * @dev calcSingleOutPoolIn
     *      Returns expected amount of tokenOut for removing exact poolAmountIn pool shares from the pool
     * @param tokenOut tokenOut
     * @param poolAmountIn amount of shares spent
     */
    function calcSingleOutPoolIn(address tokenOut, uint256 poolAmountIn)
        external
        view
        returns (uint256 tokenAmountOut)
    {
        Record memory outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            _totalSupply,
            poolAmountIn
        );

        return tokenAmountOut;
    }

    /**
     * @dev calcPoolInSingleOut
     *      Returns number of poolshares needed to withdraw exact tokenAmountOut tokens
     * @param tokenOut tokenOut
     * @param tokenAmountOut expected amount of tokensOut
     */
    function calcPoolInSingleOut(address tokenOut, uint256 tokenAmountOut)
        external
        view
        returns (uint256 poolAmountIn)
    {
        Record memory outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
            outRecord.balance,
            _totalSupply,
            tokenAmountOut
        );
        return poolAmountIn;
    }

    /**
     * @dev calcSingleInPoolOut
     *      Returns number of tokens to be staked to the pool in order to get an exact number of poolshares
     * @param tokenIn tokenIn
     * @param poolAmountOut expected amount of pool shares
     */
    function calcSingleInPoolOut(address tokenIn, uint256 poolAmountOut)
        external
        view
        returns (uint256 tokenAmountIn)
    {
        Record memory inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
            inRecord.balance,
            _totalSupply,
            poolAmountOut
        );

        return tokenAmountIn;
    }

    /**
     * @dev calcPoolOutSingleIn
     *      Returns number of poolshares obtain by staking exact tokenAmountIn tokens
     * @param tokenIn tokenIn
     * @param tokenAmountIn exact number of tokens staked
     */
    function calcPoolOutSingleIn(address tokenIn, uint256 tokenAmountIn)
        external
        view
        returns (uint256 poolAmountOut)
    {
        Record memory inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            _totalSupply,
            tokenAmountIn
        );

        return poolAmountOut;
    }


    // Internal functions below

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety
    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        uint256 balanceBefore = IERC20(erc20).balanceOf(address(this));
        IERC20(erc20).safeTransferFrom(from, address(this), amount);
        require(IERC20(erc20).balanceOf(address(this)) >= balanceBefore + amount,
                    "Transfer amount is too low");
        //require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        IERC20(erc20).safeTransfer(to, amount);
        //require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint256 amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external
        _lock_
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = IERC20(token).balanceOf(address(this));
        emit Gulped(token,oldBalance, _records[token].balance);
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import './BNum.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../interfaces/IERC20.sol';
// Highly opinionated token implementation

// interface IERC20 {
//     event Approval(address indexed src, address indexed dst, uint amt);
//     event Transfer(address indexed src, address indexed dst, uint amt);

//     function totalSupply() external view returns (uint);
//     function balanceOf(address whom) external view returns (uint);
//     function allowance(address src, address dst) external view returns (uint);

//     function approve(address dst, uint amt) external returns (bool);
//     function transfer(address dst, uint amt) external returns (bool);
//     function transferFrom(
//         address src, address dst, uint amt
//     ) external returns (bool);
// }

contract BTokenBase is BNum {

    mapping(address => uint)                   internal _balance;
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
        require(
            _balance[address(this)] >= amt, 
            'ERR_INSUFFICIENT_BAL'
        );
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, 'ERR_INSUFFICIENT_BAL');
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

contract BToken is BTokenBase {

    function name() external view returns (string memory) {
        return 'Ocean Pool Token';
    }

    function symbol() external view returns (string memory) {
        return 'OPT';
    }

    function decimals() external view returns(uint8) {
        return 18;
    }

    function allowance(address src, address dst) external view returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external returns (bool) {
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

    function transfer(address dst, uint amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src, 
        address dst, 
        uint amt
    ) 
    external
    returns (bool) 
    {
        require(
            msg.sender == src || amt <= _allowance[src][msg.sender], 
            'ERR_BTOKEN_BAD_CALLER'
        );
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(int(-1)) ) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(src, msg.sender, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import './BNum.sol';


import "../../interfaces/IFactoryRouter.sol";

contract BMath is BConst, BNum {

   // uint public _swapMarketFee;
    uint public _swapPublishMarketFee;
    uint internal _swapFee;
  
    address public router; // BFactory address to push token exitFee to

    address internal _datatokenAddress; //datatoken address
    address internal _baseTokenAddress; //base token address
    mapping(address => uint) public communityFees;

     mapping(address => uint) public publishMarketFees;
   // mapping(address => uint) public marketFees;


    function getOPCFee() public view returns (uint) {
        return IFactoryRouter(router).getOPCFee(_baseTokenAddress);
    }
    
    struct swapfees{
        uint256 LPFee;
        uint256 oceanFeeAmount;
        uint256 publishMarketFeeAmount;
        uint256 consumeMarketFee;
    }
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
        uint _swapMarketFee
    )
        internal view
        returns (uint spotPrice)
        
    {   
       

        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, _swapFee+getOPCFee()+_swapPublishMarketFee+_swapMarketFee));
      
        return  (spotPrice = bmul(ratio, scale));
    }

    
    //    data = [
    //         inRecord.balance,
    //         inRecord.denorm,
    //         outRecord.balance,
    //         outRecord.denorm
    //     ];
    function calcOutGivenIn(
        uint[4] memory data,
        uint tokenAmountIn,
        //address tokenInAddress,
        uint256 _consumeMarketSwapFee

    )
        public view
        returns (uint tokenAmountOut, uint balanceInToAdd, swapfees memory _swapfees)
    {
        uint weightRatio = bdiv(data[1], data[3]);

        _swapfees.oceanFeeAmount =  bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, getOPCFee())));

        
        _swapfees.publishMarketFeeAmount =  bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _swapPublishMarketFee)));
        

        _swapfees.LPFee = bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _swapFee)));
        _swapfees.consumeMarketFee = bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _consumeMarketSwapFee)));
        uint totalFee =_swapFee+getOPCFee()+_swapPublishMarketFee+_consumeMarketSwapFee;

        uint adjustedIn = bsub(BONE, totalFee);
        
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
         
        uint y = bdiv(data[0], badd(data[0], adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        

        tokenAmountOut = bmul(data[2], bar);
       
        return (tokenAmountOut, bsub(tokenAmountIn,(_swapfees.oceanFeeAmount+_swapfees.publishMarketFeeAmount+_swapfees.consumeMarketFee)), _swapfees);
        
    }

     
    function calcInGivenOut(
        uint[4] memory data,
        uint tokenAmountOut,
        uint _consumeMarketSwapFee
    )
        public view 
        returns (uint tokenAmountIn, uint tokenAmountInBalance, swapfees memory _swapfees)
    {
        uint weightRatio = bdiv(data[3], data[1]);
        uint diff = bsub(data[2], tokenAmountOut);
        uint y = bdiv(data[2], diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        uint totalFee =_swapFee+getOPCFee()+_consumeMarketSwapFee+_swapPublishMarketFee;
        
        
        tokenAmountIn = bdiv(bmul(data[0], foo), bsub(BONE, totalFee));
        _swapfees.oceanFeeAmount =  bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, getOPCFee())));
        
     
        _swapfees.publishMarketFeeAmount =  bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _swapPublishMarketFee)));

     
        _swapfees.LPFee = bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _swapFee)));
        _swapfees.consumeMarketFee = bsub(tokenAmountIn, bmul(tokenAmountIn, bsub(BONE, _consumeMarketSwapFee)));
        
      
        tokenAmountInBalance = bsub(tokenAmountIn,(_swapfees.oceanFeeAmount+_swapfees.publishMarketFeeAmount+_swapfees.consumeMarketFee));
      
        
        return (tokenAmountIn, tokenAmountInBalance,_swapfees);
    }

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint poolSupply,
        uint tokenAmountIn
       
    )
        internal pure
        returns (uint poolAmountOut)
    {
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, BONE);
        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);
        uint poolRatio = bsub(tokenInRatio,BONE);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        require(newPoolSupply >= 2, 'ERR_TOKEN_AMOUNT_IN_TOO_LOW'); 
        newPoolSupply = newPoolSupply/2;
        return newPoolSupply;
    }

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint poolSupply,
        uint poolAmountOut
    )
        internal pure
        returns (uint tokenAmountIn)
    {
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);
        uint tokenInRatio = bsub(poolRatio, BONE);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        require(newTokenBalanceIn >= 1, 'ERR_POOL_AMOUNT_OUT_TOO_LOW'); 
        newTokenBalanceIn = newTokenBalanceIn * 2;
        return newTokenBalanceIn;
    }

    function calcSingleOutGivenPoolIn(
        uint tokenSupply,
        uint poolSupply,
        uint poolAmountIn
    )
        internal pure
        returns (uint tokenAmountOut)
    {
        require(poolAmountIn >= 1, 'ERR_POOL_AMOUNT_IN_TOO_LOW'); 
        poolAmountIn = poolAmountIn * 2;
        uint newPoolSupply = bsub(poolSupply, poolAmountIn);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);
        uint tokenOutRatio = bsub(BONE,poolRatio);
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenSupply);
        return newTokenBalanceOut;
    }

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint poolSupply,
        uint tokenAmountOut
    )
        internal pure
        returns (uint poolAmountIn)
    {
        uint newTokenBalanceOut = bsub(
            tokenBalanceOut, 
            tokenAmountOut
        );
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);
        uint poolRatio = bsub(BONE,tokenOutRatio);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        require(newPoolSupply >= 2, 'ERR_TOKEN_AMOUNT_OUT_TOO_LOW'); 
        newPoolSupply = newPoolSupply/2;
        return newPoolSupply;
    }


    

}

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IPool {
    function getDatatokenAddress() external view returns (address);

    function getBaseTokenAddress() external view returns (address);

    function getController() external view returns (address);

    function setup(
        address datatokenAddress,
        uint256 datatokenAmount,
        uint256 datatokennWeight,
        address baseTokenAddress,
        uint256 baseTokenAmount,
        uint256 baseTokenWeight
    ) external;

    function swapExactAmountIn(
        address[3] calldata tokenInOutMarket, //[tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee //[tokenAmountIn,minAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address[3] calldata tokenInOutMarket, // [tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee // [maxAmountIn,tokenAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function getAmountInExactOut(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 _consumeMarketSwapFee
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function getAmountOutExactIn(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountIn,
        uint256 _consumeMarketSwapFee
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function setSwapFee(uint256 swapFee) external;
    function getId() pure external returns (uint8);

    function exitswapPoolAmountIn(
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);
    
    function joinswapExternAmountIn(
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);
}

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface ISideStaking {


    function newDatatokenCreated(
        address datatokenAddress,
        address baseTokenAddress,
        address poolAddress,
        address publisherAddress,
        uint256[] calldata ssParams
    ) external returns (bool);

    function getDatatokenCirculatingSupply(address datatokenAddress)
        external
        view
        returns (uint256);

    function getPublisherAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getBaseTokenAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getPoolAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getBaseTokenBalance(address datatokenAddress)
        external
        view
        returns (uint256);

    function getDatatokenBalance(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingEndBlock(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingAmount(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingLastBlock(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingAmountSoFar(address datatokenAddress)
        external
        view
        returns (uint256);



    function canStake(
        address datatokenAddress,
        uint256 amount
    ) external view returns (bool);

    function Stake(
        address datatokenAddress,
        uint256 amount
    ) external;

    function canUnStake(
        address datatokenAddress,
        uint256 amount
    ) external view returns (bool);

    function UnStake(
        address datatokenAddress,
        uint256 amount,
        uint256 poolAmountIn
    ) external;

    function getId() pure external returns (uint8);

  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/IERC20.sol";
import "./ERC721/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import './BConst.sol';

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
        require(c >= a, 'ERR_ADD_OVERFLOW');
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, 'ERR_SUB_UNDERFLOW');
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
        require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, 'ERR_MUL_OVERFLOW');
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, 'ERR_DIV_ZERO');
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint b = a;
        uint z = n % 2 != 0 ? b : BONE;

        for (n /= 2; n != 0; n /= 2) {
            b = bmul(b, b);

            if (n % 2 != 0) {
                z = bmul(z, b);
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
        require(base >= MIN_BPOW_BASE, 'ERR_BPOW_BASE_TOO_LOW');
        require(base <= MAX_BPOW_BASE, 'ERR_BPOW_BASE_TOO_HIGH');

        uint whole = bfloor(exp);
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
        uint a = exp;
        (uint x, bool xneg) = bsubSign(base, BONE);
        uint term = BONE;
        uint sum = term;
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

}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

contract BConst {
    uint public constant BONE              = 1e18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 2;

    uint public constant MIN_FEE           = BONE / 1e4;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 1e12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 1e10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 2) + 1 wei;
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IFactoryRouter {
    function deployPool(
        address[2] calldata tokens, // [datatokenAddress, baseTokenAddress]
        uint256[] calldata ssParams,
        uint256[] calldata swapFees,
        address[] calldata addresses
    ) external returns (address);

    function deployFixedRate(
        address fixedPriceAddress,
        address[] calldata addresses,
        uint256[] calldata uints
    ) external returns (bytes32 exchangeId);

    function getOPCFee(address baseToken) external view returns (uint256);
    function getOPCFees() external view returns (uint256,uint256);
    function getOPCConsumeFee() external view returns (uint256);
    function getOPCProviderFee() external view returns (uint256);

    function getMinVestingPeriod() external view returns (uint256);
    function deployDispenser(
        address _dispenser,
        address datatoken,
        uint256 maxTokens,
        uint256 maxBalance,
        address owner,
        address allowedSwapper
    ) external;

    function isApprovedToken(address) external view returns(bool);
    function getApprovedTokens() external view returns(address[] memory);
    function isSSContract(address) external view returns(bool);
    function getSSContracts() external view returns(address[] memory);
    function isFixedRateContract(address) external view returns(bool);
    function getFixedRatesContracts() external view returns(address[] memory);
    function isDispenserContract(address) external view returns(bool);
    function getDispensersContracts() external view returns(address[] memory);
    function isPoolTemplate(address) external view returns(bool);
    function getPoolTemplates() external view returns(address[] memory);

    struct Stakes {
        address poolAddress;
        uint256 tokenAmountIn;
        uint256 minPoolAmountOut;
    }
    function stakeBatch(Stakes[] calldata) external;

    enum operationType {
        SwapExactIn,
        SwapExactOut,
        FixedRate,
        Dispenser
    }

    struct Operations {
        bytes32 exchangeIds; // used for fixedRate or dispenser
        address source; // pool, dispenser or fixed rate address
        operationType operation; // type of operation: enum operationType
        address tokenIn; // token in address, only for pools
        uint256 amountsIn; // ExactAmount In for swapExactIn operation, maxAmount In for swapExactOut
        address tokenOut; // token out address, only for pools
        uint256 amountsOut; // minAmountOut for swapExactIn or exactAmountOut for swapExactOut
        uint256 maxPrice; // maxPrice, only for pools
        uint256 swapMarketFee;
        address marketFeeAddress;
    }
    function buyDTBatch(Operations[] calldata) external;
    function updateOPCCollector(address _opcCollector) external;
    function getOPCCollector() view external returns (address);
}

pragma solidity 0.8.12;
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/utils/[email protected]