// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol';

import './interfaces/IVolmexPool.sol';
import './interfaces/IVolmexProtocol.sol';
import './interfaces/IERC20Modified.sol';
import './interfaces/IVolmexOracle.sol';
import './interfaces/IPausablePool.sol';
import './interfaces/IVolmexController.sol';
import './interfaces/IFlashLoanReceiver.sol';
import './maths/Const.sol';

/**
 * @title Volmex Controller contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexController is
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC165StorageUpgradeable,
    Const,
    IVolmexController
{
    // Interface ID of VolmexController contract
    bytes4 private constant _IVOLMEX_CONTROLLER_ID = type(IVolmexController).interfaceId;
    // Interface ID of VolmexOracle contract
    bytes4 private constant _IVOLMEX_ORACLE_ID = type(IVolmexOracle).interfaceId;
    // Interface ID of VolmexPool contract
    bytes4 private constant _IVOLMEX_POOL_ID = type(IVolmexPool).interfaceId;
    // Interface ID of FlashLoanReceiver contract
    bytes4 private constant _IFlashLoan_Receiver_ID = type(IFlashLoanReceiver).interfaceId;

    // Used to set the index of stableCoin
    uint256 public stableCoinIndex;
    // Used to set the index of pool
    uint256 public poolIndex;
    // Used to store the pools
    address[] public allPools;
    // Address of the oracle
    IVolmexOracle public oracle;

    /**
     * Indices for Pool, Stablecoin and Protocol mappings
     *
     * Pool { 0 = ETHV, 1 = BTCV }
     * Stablecoin { 0 = DAI, 1 = USDC }
     * Protocol { 0 = ETHV-DAI, 1 = ETHV-USDC, 2 = BTCV-DAI, 3 = BTCV-USDC }
     *
     * Pools(Index)   Stablecoin(Index)     Protocol(Address)
     *    0                 0                     0
     *    0                 1                     1
     *    1                 0                     2
     *    1                 1                     3
     */
    // Store the addresses of protocols { pool index => stableCoin index => protocol address }
    mapping(uint256 => mapping(uint256 => IVolmexProtocol)) public protocols;
    /// @notice We have used IERC20Modified instead of IERC20, because the volatility tokens
    /// can't be typecasted to IERC20.
    /// Note: We have used the standard methods on IERC20 only.
    // Store the addresses of stableCoins
    mapping(uint256 => IERC20Modified) public stableCoins;
    // Store the addresses of pools
    mapping(uint256 => IVolmexPool) public pools;
    // Store the bool value of pools to confirm it is pool
    mapping(address => bool) public isPool;
    // Store the precision ratio according to stableCoin index
    mapping(uint256 => uint256) public precisionRatios;

    /**
     * @notice Initializes the contract
     *
     * @dev Sets the volatilityCapRatio
     *
     * @param _stableCoins Address of the collateral token used in protocol
     * @param _pools Address of the pool contract
     * @param _protocols Address of the protocol contract
     */
    function initialize(
        IERC20Modified[2] memory _stableCoins,
        IVolmexPool[2] memory _pools,
        IVolmexProtocol[4] memory _protocols,
        IVolmexOracle _oracle
    ) external initializer {
        require(
            IERC165Upgradeable(address(_oracle)).supportsInterface(_IVOLMEX_ORACLE_ID),
            'VolmexController: Oracle does not supports interface'
        );

        uint256 protocolCount;
        // Note: Since loop size is very small so nested loop won't be a problem
        for (uint256 i; i < 2; i++) {
            require(
                IERC165Upgradeable(address(_pools[i])).supportsInterface(_IVOLMEX_POOL_ID),
                'VolmexController: Pool does not supports interface'
            );
            require(
                address(_stableCoins[i]) != address(0),
                "VolmexController: address of stable coin can't be zero"
            );

            pools[i] = _pools[i];
            stableCoins[i] = _stableCoins[i];
            isPool[address(_pools[i])] = true;
            allPools.push(address(_pools[i]));
            for (uint256 j; j < 2; j++) {
                require(
                    _pools[i].tokens(0) ==
                        address(_protocols[protocolCount].volatilityToken()),
                    'VolmexController: Incorrect pool for add protocol'
                );
                require(
                    _stableCoins[j] == _protocols[protocolCount].collateral(),
                    'VolmexController: Incorrect stableCoin for add protocol'
                );
                protocols[i][j] = _protocols[protocolCount];
                try protocols[i][j].precisionRatio() returns (uint256 ratio) {
                    precisionRatios[j] = ratio;
                } catch (bytes memory) {
                    precisionRatios[j] = 1;
                }
                protocolCount++;
            }
        }
        oracle = _oracle;
        poolIndex++;
        stableCoinIndex++;

        __Ownable_init();
        __Pausable_init_unchained(); // Used this, because ownable init is calling context init
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_CONTROLLER_ID);
    }

    /**
     * @notice Used to set the pool on new index
     *
     * @param _pool Address of the Pool contract
     */
    function addPool(IVolmexPool _pool) external onlyOwner {
        require(
            IERC165Upgradeable(address(_pool)).supportsInterface(_IVOLMEX_POOL_ID),
            'VolmexController: Pool does not supports interface'
        );
        poolIndex++;
        pools[poolIndex] = _pool;

        isPool[address(_pool)] = true;
        allPools.push(address(_pool));

        emit PoolAdded(poolIndex, address(_pool));
    }

    /**
     * @notice Usesd to add the stableCoin on new index
     *
     * @param _stableCoin Address of the stableCoin
     */
    function addStableCoin(IERC20Modified _stableCoin) external onlyOwner {
        require(
            address(_stableCoin) != address(0),
            "VolmexController: address of stable coin can't be zero"
        );
        stableCoinIndex++;
        stableCoins[stableCoinIndex] = _stableCoin;

        emit StableCoinAdded(stableCoinIndex, address(_stableCoin));
    }

    /**
     * @notice Used to add the protocol on a particular pool and stableCoin index
     *
     * @param _protocol Address of the Protocol contract
     * @param _stableCoinIndex index of stable coin 
     */
    function addProtocol(
        uint256 _poolIndex,
        uint256 _stableCoinIndex,
        IVolmexProtocol _protocol
    ) external onlyOwner {
        require(
            stableCoins[_stableCoinIndex] == _protocol.collateral(),
            'VolmexController: Incorrect stableCoin for add protocol'
        );
        require(
            pools[_poolIndex].tokens(0) ==
                address(_protocol.volatilityToken()),
            'VolmexController: Incorrect pool for add protocol'
        );

        protocols[_poolIndex][_stableCoinIndex] = _protocol;

        try _protocol.precisionRatio() returns (uint256 ratio) {
            precisionRatios[_stableCoinIndex] = ratio;
        } catch (bytes memory) {
            precisionRatios[_stableCoinIndex] = 1;
        }

        emit ProtocolAdded(_poolIndex, _stableCoinIndex, address(_protocol));
    }

    /**
     * @notice Used to pause the pool
     */
    function pausePool(IPausablePool _pool) external onlyOwner {
        _pool.pause();
    }

    /**
     * @notice Used to un-pause the pool
     */
    function unpausePool(IPausablePool _pool) external onlyOwner {
        _pool.unpause();
    }

    /**
     * @notice Used to collect the pool token
     *
     * @param _pool Address of the pool
     */
    function collect(IVolmexPool _pool) external onlyOwner {
        uint256 collected = IERC20(_pool).balanceOf(address(this));
        bool xfer = _pool.transfer(owner(), collected);
        require(xfer, 'ERC20_FAILED');
        emit PoolTokensCollected(owner(), collected);
    }

    /**
     * @notice Finalizes the pool
     *
     * @param _primaryBalance Balance amount of primary token
     * @param _primaryLeverage Leverage value of primary token
     * @param _complementBalance  Balance amount of complement token
     * @param _complementLeverage  Leverage value of complement token
     * @param _exposureLimitPrimary Primary to complement swap difference limit
     * @param _exposureLimitComplement Complement to primary swap difference limit
     * @param _pMin Minimum amount of tokens in the pool
     * @param _qMin Minimum amount of token required for swap
     */
    function finalizePool(
        uint256 _poolIndex,
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin
    ) external onlyOwner {
        IVolmexPool _pool = pools[_poolIndex];

        _pool.finalize(
            _primaryBalance,
            _primaryLeverage,
            _complementBalance,
            _complementLeverage,
            _exposureLimitPrimary,
            _exposureLimitComplement,
            _pMin,
            _qMin,
            msg.sender
        );
    }

    /**
     * @notice Used to swap collateral token to a type of volatility token
     *
     * @param _amounts Amount of collateral token and minimum expected volatility token
     * @param _tokenOut Address of the volatility token out
     * @param _indices Indices of the pool and stablecoin to operate { 0: ETHV, 1: BTCV } { 0: DAI, 1: USDC }
     */
    function swapCollateralToVolatility(
        uint256[2] calldata _amounts,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external whenNotPaused {
        IERC20Modified stableCoin = stableCoins[_indices[1]];
        stableCoin.transferFrom(msg.sender, address(this), _amounts[0]);
        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[1]];
        _approveAssets(stableCoin, _amounts[0], address(this), address(_protocol));

        _protocol.collateralize(_amounts[0]);

        // Pool and Protocol fee array { 0: Pool, 1: Protocol }
        uint256[3] memory fees;
        uint256 volatilityAmount;
        fees[2] = _protocol.volatilityCapRatio();
        (volatilityAmount, fees[1]) = _calculateAssetQuantity(
            _amounts[0],
            _protocol.issuanceFees(),
            true,
            fees[2],
            precisionRatios[_indices[1]]
        );

        IERC20Modified volatilityToken = _protocol.volatilityToken();
        IERC20Modified inverseVolatilityToken = _protocol.inverseVolatilityToken();

        IVolmexPool _pool = pools[_indices[0]];

        bool isInverse = _pool.tokens(1) == _tokenOut;

        _pool.reprice();
        uint256 tokenAmountOut;
        (tokenAmountOut, fees[0]) = _pool.getTokenAmountOut(
            isInverse
                ? _pool.tokens(0)
                : _pool.tokens(1),
            volatilityAmount
        );

        _approveAssets(
            isInverse
                ? IERC20Modified(_pool.tokens(0))
                : IERC20Modified(_pool.tokens(1)),
            volatilityAmount,
            address(this),
            address(this)
        );
        (tokenAmountOut, ) = _pool.swapExactAmountIn(
            isInverse
                ? _pool.tokens(0)
                : _pool.tokens(1),
            volatilityAmount,
            _tokenOut,
            tokenAmountOut,
            address(this),
            true
        );

        uint256 totalVolatilityAmount = volatilityAmount + tokenAmountOut;

        require(
            totalVolatilityAmount >= _amounts[1],
            'VolmexController: Insufficient expected volatility amount'
        );

        _transferAsset(
            isInverse ? inverseVolatilityToken : volatilityToken,
            totalVolatilityAmount,
            msg.sender
        );

        emit CollateralSwapped(
            _amounts[0],
            totalVolatilityAmount,
            fees[1],
            fees[0],
            _indices[1],
            _tokenOut
        );
    }

    /**
     * @notice Used to swap a type of volatility token to collateral token
     *
     * @param _amounts Amounts array of volatility token and expected collateral
     * @param _indices Indices of the pool and stablecoin to operate { 0: ETHV, 1: BTCV } { 0: DAI, 1: USDC }
     * @param _tokenIn Address of in token
     */
    function swapVolatilityToCollateral(
        uint256[2] calldata _amounts,
        uint256[2] calldata _indices,
        IERC20Modified _tokenIn
    ) external whenNotPaused {
        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[1]];
        IVolmexPool _pool = pools[_indices[0]];

        bool isInverse = _pool.tokens(1) == address(_tokenIn);

        _pool.reprice();
        uint256[2] memory swapAmounts; // 0: tokenAmountIn, 1: tokenAmountOut
        (swapAmounts[0], swapAmounts[1], ) = _getSwappedAssetAmount(
            address(_tokenIn),
            _amounts[0],
            _pool,
            isInverse
        );

        // Pool and Protocol fee array { 0: Pool, 1: Protocol }
        uint256[2] memory fees;
        (swapAmounts[1], fees[0]) = _pool.swapExactAmountIn(
            address(_tokenIn),
            swapAmounts[0],
            isInverse
                ? _pool.tokens(0)
                : _pool.tokens(1),
            swapAmounts[1],
            msg.sender,
            true
        );

        require(
            swapAmounts[1] <= _amounts[0] - swapAmounts[0],
            'VolmexController: Amount out limit exploit'
        );

        uint256 collateralAmount;
        uint256 _volatilityCapRatio = _protocol.volatilityCapRatio();
        (collateralAmount, fees[1]) = _calculateAssetQuantity(
            swapAmounts[1] * _volatilityCapRatio,
            _protocol.redeemFees(),
            false,
            _volatilityCapRatio,
            precisionRatios[_indices[1]]
        );

        require(
            collateralAmount >= _amounts[1],
            'VolmexController: Insufficient expected collateral amount'
        );

        _tokenIn.transferFrom(msg.sender, address(this), swapAmounts[1]);
        _protocol.redeem(swapAmounts[1]);

        IERC20Modified stableCoin = stableCoins[_indices[1]];
        _transferAsset(stableCoin, collateralAmount, msg.sender);

        emit CollateralSwapped(
            _amounts[0],
            collateralAmount,
            fees[1],
            fees[0],
            _indices[1],
            address(_tokenIn)
        );
    }

    /**
     * @notice Used to swap a a volatility token to another volatility token from another pool
     *
     * @param _tokens Addresses of the tokens { 0: tokenIn, 1: tokenOut }
     * @param _amounts Amounts of the volatility token and expected amount out { 0: amountIn, 1: expAmountOut }
     * @param _indices Indices of the pools and stablecoin to operate { 0: poolIn, 1: poolOut, 2: stablecoin }
     * { 0: ETHV, 1: BTCV } { 0: DAI, 1: USDC }
     */
    function swapBetweenPools(
        address[2] calldata _tokens,
        uint256[2] calldata _amounts,
        uint256[3] calldata _indices
    ) external whenNotPaused {
        IVolmexPool _pool = pools[_indices[0]];

        bool isInverse = _pool.tokens(1) == _tokens[0];

        _pool.reprice();
        // Array of swapAmount {0} and tokenAmountOut {1}
        uint256[2] memory tokenAmounts;
        (tokenAmounts[0], tokenAmounts[1], ) = _getSwappedAssetAmount(
            _tokens[0],
            _amounts[0],
            _pool,
            isInverse
        );

        // Pool and Protocol fee array { 0: Pool In, 1: Pool Out, 2: Protocol In Redeem, 3: Protocol Out Collateralize }
        uint256[4] memory fees;
        (tokenAmounts[1], fees[0]) = _pool.swapExactAmountIn(
            _tokens[0],
            tokenAmounts[0],
            isInverse
                ? _pool.tokens(0)
                : _pool.tokens(1),
            tokenAmounts[1],
            msg.sender,
            true
        );

        require(
            tokenAmounts[1] <= _amounts[0] - tokenAmounts[0],
            'VolmexController: Amount out limit exploit'
        );

        IERC20Modified(_tokens[0]).transferFrom(msg.sender, address(this), tokenAmounts[1]);
        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[2]];
        _protocol.redeem(tokenAmounts[1]);

        // Array of collateralAmount {0} and volatilityAmount {1}
        uint256[3] memory protocolAmounts;
        protocolAmounts[2] = _protocol.volatilityCapRatio();
        (protocolAmounts[0], fees[2]) = _calculateAssetQuantity(
            tokenAmounts[1] * protocolAmounts[2],
            _protocol.redeemFees(),
            false,
            protocolAmounts[2],
            precisionRatios[_indices[2]]
        );

        _protocol = protocols[_indices[1]][_indices[2]];
        _approveAssets(
            stableCoins[_indices[2]],
            protocolAmounts[0],
            address(this),
            address(_protocol)
        );
        _protocol.collateralize(protocolAmounts[0]);

        protocolAmounts[2] = _protocol.volatilityCapRatio();
        (protocolAmounts[1], fees[3]) = _calculateAssetQuantity(
            protocolAmounts[0],
            _protocol.issuanceFees(),
            true,
            protocolAmounts[2],
            precisionRatios[_indices[2]]
        );

        _pool = pools[_indices[1]];

        isInverse = _pool.tokens(0) != _tokens[1];
        address poolOutTokenIn = isInverse
            ? _pool.tokens(0)
            : _pool.tokens(1);

        _pool.reprice();
        (tokenAmounts[1], ) = _pool.getTokenAmountOut(
            poolOutTokenIn,
            protocolAmounts[1]
        );

        _approveAssets(
            IERC20Modified(poolOutTokenIn),
            protocolAmounts[1],
            address(this),
            address(this)
        );
        (tokenAmounts[1], fees[1]) = _pool.swapExactAmountIn(
            poolOutTokenIn,
            protocolAmounts[1],
            _tokens[1],
            tokenAmounts[1],
            address(this),
            true
        );

        require(
            protocolAmounts[1] + tokenAmounts[1] >= _amounts[1],
            'VolmexController: Insufficient expected volatility amount'
        );

        _transferAsset(
            IERC20Modified(_tokens[1]),
            protocolAmounts[1] + tokenAmounts[1],
            msg.sender
        );

        emit PoolSwapped(
            _amounts[0],
            protocolAmounts[1] + tokenAmounts[1],
            fees[2] + fees[3],
            [fees[0], fees[1]],
            _indices[2],
            _tokens
        );
    }

    /**
     * @notice Used to add liquidity in the pool
     *
     * @param _poolAmountOut Amount of pool token mint and transfer to LP
     * @param _maxAmountsIn Max amount of pool assets an LP can supply
     * @param _poolIndex Index of the pool in which user wants to add liquidity
     */
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external whenNotPaused {
        IVolmexPool _pool = pools[_poolIndex];

        _pool.joinPool(_poolAmountOut, _maxAmountsIn, msg.sender);
    }

    /**
     * @notice Used to remove liquidity from the pool
     *
     * @param _poolAmountIn Amount of pool token transfer to the pool
     * @param _minAmountsOut Min amount of pool assets an LP wish to redeem
     * @param _poolIndex Index of the pool in which user wants to add liquidity
     */
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external whenNotPaused {
        IVolmexPool _pool = pools[_poolIndex];

        _pool.exitPool(_poolAmountIn, _minAmountsOut, msg.sender);
    }

    /**
     * @notice Used to call flash loan on Pool
     *
     * @dev This method is for developers.
     * Make sure you call this method from a contract with the implementation
     * of IFlashLoanReceiver interface
     *
     * @param _assetToken Address of the token in need
     * @param _amount Amount of token in need
     * @param _params msg.data for verifying the loan
     * @param _poolIndex Index of the Pool
     */
    function makeFlashLoan(
        address _receiver,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params,
        uint256 _poolIndex
    ) external whenNotPaused {
        require(
            IERC165Upgradeable(_receiver).supportsInterface(_IFlashLoan_Receiver_ID),
            'VolmexPool: Repricer does not supports interface'
        );

        IVolmexPool _pool = pools[_poolIndex];
        _pool.flashLoan(_receiver, _assetToken, _amount, _params);
    }

    /**
     * @notice Used to swap the exact amount in
     *
     * @param _poolIndex Index of the pool to which interact
     * @param _tokenIn Address of the token in
     * @param _amountIn Value of token amount in to swap
     * @param _tokenOut Address of the token out
     * @param _amountOut Minimum expected value of token amount out
     */
    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external whenNotPaused {
        IVolmexPool _pool = pools[_poolIndex];

        _pool.swapExactAmountIn(_tokenIn, _amountIn, _tokenOut, _amountOut, msg.sender, false);
    }

    /**
     * @notice Used by VolmexPool contract to transfer the token amount to VolmexPool
     *
     * @param _token Address of the token contract
     * @param _account Address of the user/contract from balance transfer
     * @param _amount Amount of the token
     */
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        uint256 _amount
    ) external {
        require(isPool[msg.sender], 'VolmexController: Caller is not pool');
        _token.transferFrom(_account, msg.sender, _amount);
    }

    /**
     * @notice Used to get the volatility amount out
     *
     * @param _collateralAmount Amount of minimum expected collateral
     * @param _tokenOut Address of the token out
     * @param _indices Index of pool and stableCoin
     */
    function getCollateralToVolatility(
        uint256 _collateralAmount,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external view returns (uint256 volatilityAmount, uint256[2] memory fees) {
        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[1]];
        IVolmexPool _pool = pools[_indices[0]];

        uint256 _volatilityCapRatio = _protocol.volatilityCapRatio();
        (volatilityAmount, fees[1]) = _calculateAssetQuantity(
            _collateralAmount,
            _protocol.issuanceFees(),
            true,
            _volatilityCapRatio,
            precisionRatios[_indices[1]]
        );

        bool isInverse = _pool.tokens(1) == _tokenOut;

        uint256 tokenAmountOut;
        (tokenAmountOut, fees[0]) = _pool.getTokenAmountOut(
            isInverse
                ? _pool.tokens(0)
                : _pool.tokens(1),
            volatilityAmount
        );

        volatilityAmount += tokenAmountOut;
    }

    /**
     * @notice Used to get collateral amount, fees, left over amount while swapping volatility
     * to collateral/stablecoin
     *
     * @param _tokenIn Address of token in
     * @param _amount Value of amount wants to swap
     * @param _indices Index of pool and stableCoin
     * @param _isInverse Bool value of passed token in type
     */
    function getVolatilityToCollateral(
        address _tokenIn,
        uint256 _amount,
        uint256[2] calldata _indices,
        bool _isInverse
    ) external view returns (uint256 collateralAmount, uint256[2] memory fees) {
        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[1]];
        IVolmexPool _pool = pools[_indices[0]];

        uint256[2] memory amounts;
        uint256[2] memory fee; // 0: Pool fee, 1: Protocol fee
        (amounts[0], amounts[1], fee[0]) = _getSwappedAssetAmount(
            _tokenIn,
            _amount,
            _pool,
            _isInverse
        );
        uint256 _volatilityCapRatio = _protocol.volatilityCapRatio();
        (collateralAmount, fee[1]) = _calculateAssetQuantity(
            amounts[1] * _volatilityCapRatio,
            _protocol.redeemFees(),
            false,
            _volatilityCapRatio,
            precisionRatios[_indices[1]]
        );

        fees = [fee[0], fee[1]];
    }

    /**
     * @notice Used to get the token out amount of swap in between multiple pools
     *
     * @param _tokens Addresses of token in and out
     * @param _amountIn Value of amount in or change
     * @param _indices Array of indices of poolOut, poolIn and stable coin
     *
     * returns amountOut, and fees array {0: pool in fee, 1: pool out fee, 2: protocolFee}
     */
    function getSwapAmountBetweenPools(
        address[2] calldata _tokens,
        uint256 _amountIn,
        uint256[3] calldata _indices
    ) external view returns (uint256 amountOut, uint256[3] memory fees) {
        IVolmexPool _pool = IVolmexPool(pools[_indices[0]]);

        uint256 tokenAmountOut;
        uint256 fee;
        (, tokenAmountOut, fee) = _getSwappedAssetAmount(
            _tokens[0],
            _amountIn,
            _pool,
            _pool.tokens(1) == _tokens[0]
        );
        fees[0] = fee;

        IVolmexProtocol _protocol = protocols[_indices[0]][_indices[2]];
        uint256[3] memory protocolAmount;
        protocolAmount[2] = _protocol.volatilityCapRatio();
        (protocolAmount[0], fee) = _calculateAssetQuantity(
            tokenAmountOut * protocolAmount[2],
            _protocol.redeemFees(),
            false,
            protocolAmount[2],
            precisionRatios[_indices[2]]
        );
        fees[2] = fee;

        _protocol = protocols[_indices[1]][_indices[2]];
        protocolAmount[2] = _protocol.volatilityCapRatio();

        (protocolAmount[1], fee) = _calculateAssetQuantity(
            protocolAmount[0],
            _protocol.issuanceFees(),
            true,
            protocolAmount[2],
            precisionRatios[_indices[2]]
        );
        fees[2] += fee;

        _pool = pools[_indices[1]];

        (tokenAmountOut, fee) = _pool.getTokenAmountOut(
            _pool.tokens(0) != _tokens[1]
                ? _pool.tokens(0)
                : _pool.tokens(1),
            protocolAmount[1]
        );
        fees[1] += fee;

        amountOut = protocolAmount[1] + tokenAmountOut;
    }

    function _calculateAssetQuantity(
        uint256 _amount,
        uint256 _feePercent,
        bool _isVolatility,
        uint256 _volatilityCapRatio,
        uint256 _precisionRatio
    ) private pure returns (uint256 amount, uint256 protocolFee) {
        protocolFee = (_amount * _feePercent) / 10000;
        _amount = _amount - protocolFee;

        amount = _isVolatility ? (_amount / _volatilityCapRatio) * _precisionRatio : _amount / _precisionRatio;
    }

    function _transferAsset(
        IERC20Modified _token,
        uint256 _amount,
        address _receiver
    ) private {
        _token.transfer(_receiver, _amount);
    }

    function _approveAssets(
        IERC20Modified _token,
        uint256 _amount,
        address _owner,
        address _spender
    ) private {
        uint256 _allowance = _token.allowance(_owner, _spender);

        if (_amount <= _allowance) return;

        _token.approve(_spender, _amount);
    }

    function _volatilityAmountToSwap(
        uint256 _amount,
        IVolmexPool _pool,
        bool _isInverse,
        uint256 _fee
    ) private view returns (uint256 volatilityAmount) {
        (uint256 price, uint256 iPrice) = oracle.getVolatilityTokenPriceByIndex(
            _pool.volatilityIndex()
        );

        uint256 leverage = _pool.getLeverage(_pool.tokens(0));
        uint256 iLeverage = _pool.getLeverage(_pool.tokens(1));

        volatilityAmount = !_isInverse
            ? ((_amount * iPrice * iLeverage) * BONE) /
                (price * leverage * (BONE - _fee) + iPrice * iLeverage * BONE)
            : ((_amount * price * leverage) * BONE) /
                (iPrice * iLeverage * (BONE - _fee) + price * leverage * BONE);
    }

    function _getSwappedAssetAmount(
        address _tokenIn,
        uint256 _amount,
        IVolmexPool _pool,
        bool _isInverse
    )
        private
        view
        returns (
            uint256 swapAmount,
            uint256 amountOut,
            uint256 fee
        )
    {
        swapAmount = _volatilityAmountToSwap(_amount, _pool, _isInverse, 0);

        (, fee) = _pool.getTokenAmountOut(
            _tokenIn,
            swapAmount
        );

        swapAmount = _volatilityAmountToSwap(_amount, _pool, _isInverse, fee);

        (amountOut, fee) = _pool.getTokenAmountOut(
            _tokenIn,
            swapAmount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../libs/tokens/Token.sol';
import './IVolmexProtocol.sol';
import './IVolmexRepricer.sol';
import './IVolmexController.sol';

interface IVolmexPool is IERC20 {
    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut,
        uint256 fee,
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenLeverageIn,
        uint256 tokenLeverageOut
    );
    event Joined(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
    event Exited(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
    event Repriced(
        uint256 repricingBlock,
        uint256 balancePrimary,
        uint256 balanceComplement,
        uint256 leveragePrimary,
        uint256 leverageComplement,
        uint256 newLeveragePrimary,
        uint256 newLeverageComplement,
        uint256 estPricePrimary,
        uint256 estPriceComplement
    );
    event Called(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event Loaned(
        address indexed target,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );
    event FlashLoanPremiumUpdated(uint256 premium);
    event ControllerSet(address indexed controller);
    event FeeParamsSet(
        uint256 baseFee,
        uint256 maxFee,
        uint256 feeAmpPrimary,
        uint256 feeAmpComplement
    );

    // Getter methods
    function repricingBlock() external view returns (uint256);
    function baseFee() external view returns (uint256);
    function feeAmpPrimary() external view returns (uint256);
    function feeAmpComplement() external view returns (uint256);
    function maxFee() external view returns (uint256);
    function pMin() external view returns (uint256);
    function qMin() external view returns (uint256);
    function exposureLimitPrimary() external view returns (uint256);
    function exposureLimitComplement() external view returns (uint256);
    function protocol() external view returns (IVolmexProtocol);
    function repricer() external view returns (IVolmexRepricer);
    function volatilityIndex() external view returns (uint256);
    function finalized() external view returns (bool);
    function upperBoundary() external view returns (uint256);
    function adminFee() external view returns (uint256);
    function getLeverage(address _token) external view returns (uint256);
    function getBalance(address _token) external view returns (uint256);
    function tokens(uint256 _index) external view returns (address);
    function flashLoanPremium() external view returns (uint256);
    function getLeveragedBalance(Record memory r) external pure returns (uint256);
    function getTokenAmountOut(
        address _tokenIn,
        uint256 _tokenAmountIn
    ) external view returns (uint256, uint256);

    // Setter methods
    function setController(IVolmexController _controller) external;
    function updateFlashLoanPremium(uint256 _premium) external;
    function joinPool(uint256 _poolAmountOut, uint256[2] calldata _maxAmountsIn, address _receiver) external;
    function exitPool(uint256 _poolAmountIn, uint256[2] calldata _minAmountsOut, address _receiver) external;
    function pause() external;
    function unpause() external;
    function reprice() external;
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    ) external returns (uint256, uint256);
    function flashLoan(
        address _receiverAddress,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params
    ) external;
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external;
    function redeem(uint256 _positionTokenQty) external;
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external;
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexProtocol.sol';

interface IVolmexOracle {
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );

    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );

    event SymbolIndexUpdated(uint256 indexed _index);

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function indexCount() external view returns (uint256);

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (uint256, uint256);
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (uint256 volatilityTokenPrice, uint256 iVolatilityTokenPrice);
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IPausablePool {
    // Getter method
    function paused() external view returns (bool);

    // Setter methods
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';
import './IVolmexPool.sol';
import './IPausablePool.sol';
import './IVolmexProtocol.sol';
import './IVolmexOracle.sol';

interface IVolmexController {
    event AdminFeeUpdated(uint256 adminFee);
    event CollateralSwapped(
        uint256 volatilityInAmount,
        uint256 collateralOutAmount,
        uint256 protocolFee,
        uint256 poolFee,
        uint256 indexed stableCoinIndex,
        address indexed token
    );
    event PoolSwapped(
        uint256 volatilityInAmount,
        uint256 volatilityOutAmount,
        uint256 protocolFee,
        uint256[2] poolFee,
        uint256 indexed stableCoinIndex,
        address[2] tokens
    );
    event PoolAdded(uint256 indexed poolIndex, address indexed pool);
    event StableCoinAdded(uint256 indexed stableCoinIndex, address indexed stableCoin);
    event ProtocolAdded(uint256 poolIndex, uint256 stableCoinIndex, address indexed protocol);
    event PoolTokensCollected(address indexed owner, uint256 amount);

    // Getter methods
    function stableCoinIndex() external view returns (uint256);
    function poolIndex() external view returns (uint256);
    function pools(uint256 _index) external view returns (IVolmexPool);
    function stableCoins(uint256 _index) external view returns (IERC20Modified);
    function isPool(address _pool) external view returns (bool);
    function oracle() external view returns (IVolmexOracle);
    function protocols(
        uint256 _poolIndex,
        uint256 _stableCoinIndex
    ) external view returns (IVolmexProtocol);

    // Setter methods
    function addPool(IVolmexPool _pool) external;
    function addStableCoin(IERC20Modified _stableCoin) external;
    function pausePool(IPausablePool _pool) external;
    function unpausePool(IPausablePool _pool) external;
    function collect(IVolmexPool _pool) external;
    function addProtocol(
        uint256 _poolIndex,
        uint256 _stableCoinIndex,
        IVolmexProtocol _protocol
    ) external;
    function swapCollateralToVolatility(
        uint256[2] calldata _amounts,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external;
    function swapVolatilityToCollateral(
        uint256[2] calldata _amounts,
        uint256[2] calldata _indices,
        IERC20Modified _tokenIn
    ) external;
    function swapBetweenPools(
        address[2] calldata _tokens,
        uint256[2] calldata _amounts,
        uint256[3] calldata _indices
    ) external;
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external;
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external;
    function makeFlashLoan(
        address _receiver,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params,
        uint256 _poolIndex
    ) external;
    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external;
    function getCollateralToVolatility(
        uint256 _collateralAmount,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external view returns (uint256, uint256[2] memory);
    function getVolatilityToCollateral(
        address _tokenIn,
        uint256 _amount,
        uint256[2] calldata _indices,
        bool _isInverse
    ) external view returns (uint256, uint256[2] memory);
    function getSwapAmountBetweenPools(
        address[2] calldata _tokens,
        uint256 _amountIn,
        uint256[3] calldata _indices
    ) external view returns (uint256, uint256[3] memory);
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexPool.sol';

interface IFlashLoanReceiver {
    function executeOperation(
        address assetToken,
        uint256 amounts,
        uint256 premiums,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

contract Const {
    uint256 public constant BONE = 10**18;

    int256 public constant iBONE = int256(BONE);

    uint256 public constant MAX_IN_RATIO = BONE / 2;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../../maths/Num.sol';
import '../../interfaces/IERC20.sol';

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed _src, address indexed _dst, uint256 _amt);
    event Transfer(address indexed _src, address indexed _dst, uint256 _amt);

    function _mint(uint256 _amt) internal {
        _balance[address(this)] = _balance[address(this)] + _amt;
        _totalSupply = _totalSupply + _amt;
        emit Transfer(address(0), address(this), _amt);
    }

    function _burn(uint256 _amt) internal {
        require(_balance[address(this)] >= _amt, 'INSUFFICIENT_BAL');
        _balance[address(this)] = _balance[address(this)] - _amt;
        _totalSupply = _totalSupply - _amt;
        emit Transfer(address(this), address(0), _amt);
    }

    function _move(
        address _src,
        address _dst,
        uint256 _amt
    ) internal {
        require(_balance[_src] >= _amt, 'INSUFFICIENT_BAL');
        _balance[_src] = _balance[_src] - _amt;
        _balance[_dst] = _balance[_dst] + _amt;
        emit Transfer(_src, _dst, _amt);
    }

    function _push(address _to, uint256 _amt) internal {
        _move(address(this), _to, _amt);
    }

    function _pull(address _from, uint256 _amt) internal {
        _move(_from, address(this), _amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function approve(address _dst, uint256 _amt) external override returns (bool) {
        _allowance[msg.sender][_dst] = _amt;
        emit Approval(msg.sender, _dst, _amt);
        return true;
    }

    function increaseApproval(address _dst, uint256 _amt) external returns (bool) {
        _allowance[msg.sender][_dst] = _allowance[msg.sender][_dst] + _amt;
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function decreaseApproval(address _dst, uint256 _amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][_dst];
        if (_amt > oldValue) {
            _allowance[msg.sender][_dst] = 0;
        } else {
            _allowance[msg.sender][_dst] = oldValue - _amt;
        }
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function transfer(address _dst, uint256 _amt) external override returns (bool) {
        _move(msg.sender, _dst, _amt);
        return true;
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[_src][msg.sender];
        require(msg.sender == _src || _amt <= oldValue, 'TOKEN_BAD_CALLER');
        _move(_src, _dst, _amt);
        if (msg.sender != _src && oldValue != type(uint128).max) {
            _allowance[_src][msg.sender] = oldValue - _amt;
            emit Approval(msg.sender, _dst, _allowance[_src][msg.sender]);
        }
        return true;
    }

    function allowance(address _src, address _dst) external view override returns (uint256) {
        return _allowance[_src][_dst];
    }

    function balanceOf(address _whom) external view override returns (uint256) {
        return _balance[_whom];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _setName(string memory _poolName) internal {
        _name = _poolName;
    }

    function _setSymbol(string memory _poolSymbol) internal {
        _symbol = _poolSymbol;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexOracle.sol';

interface IVolmexRepricer {
    // Getter method
    function oracle() external view returns (IVolmexOracle);

    // Setter methods
    function sqrtWrapped(int256 value) external pure returns (int256);
    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './Const.sol';

contract Num is Const {
    function _subSign(uint256 _a, uint256 _b) internal pure returns (uint256, bool) {
        if (_a >= _b) {
            return (_a - _b, false);
        } else {
            return (_b - _a, true);
        }
    }

    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        uint256 c0 = _a * _b;
        uint256 c1 = c0 + (BONE / 2);
        c = c1 / BONE;
    }

    function _div(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, 'DIV_ZERO');
        uint256 c0 = _a * BONE;
        uint256 c1 = c0 + (_b / 2);
        c = c1 / _b;
    }

    function _min(uint256 _first, uint256 _second) internal pure returns (uint256) {
        if (_first < _second) {
            return _first;
        }
        return _second;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _whom) external view returns (uint256);
    function allowance(address _src, address _dst) external view returns (uint256);
    function approve(address _dst, uint256 _amt) external returns (bool);
    function transfer(address _dst, uint256 _amt) external returns (bool);
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external returns (bool);
}