pragma solidity ^0.8.0;

import "./Base.sol";

import "./Vault.sol";
import "./Storage.sol";

import "./handlers/UniswapV2.sol";
import "./handlers/BancorNetwork.sol";
import "./handlers/Curve.sol";
import "./handlers/InternalSwap.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

enum DEX {
    UNISWAPV2,
    SUSHISWAPV2,
    BANCOR,
    ZEROX,
    CURVE,
    INTERNAL
}

/**
 * @title A main DeFire ecosystem contract.
 * @notice This is a central point for placing, storing and executing orders.
 */
contract Main is
    Base,
    UniswapV2Handler,
    BancorNetworkHandler,
    CurveHandler,
    InternalSwapHandler
{
    using SafeERC20 for IERC20;

    event OrderCreated(address indexed creator, bytes32 hash);
    event OrderFill(
        bytes32 indexed hash,
        uint256 amountBase,
        uint256 amountQuote
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrderExpired(bytes32 indexed hash);
    event OrderChanged(bytes32 indexed hash);

    address internal storage_;

    mapping(address => bool) internal executors;

    bool public initialized = false; // used for initializer, to allow calling it only once

    /**
     * @dev Initializes the Main contract, since constructor cannot be used due to nature of EIP1967 standard.
     * @param _storage An address of storage contract.
     * @param _vault And address of vault contract.
     */
    function initialize(
        address _storage,
        address payable _vault,
        address _contractRegistry,
        address _initialExecutor,
        address _weth
    ) external {
        require(initialized == false, "Contract has already been initialized.");

        storage_ = _storage;
        vault = _vault;
        weth = _weth;

        StorageInstance = Storage(storage_);
        VaultInstance = Vault(vault);

        contractRegistry = IContractRegistry(_contractRegistry);

        executors[_initialExecutor] = true;

        initialized = true;
    }

    // this modifier checks if hash argument identifies existing order
    // this modifier will revert transaction if hash does not belong to existing order
    modifier orderExists(bytes32 hash) {
        require(
            _getVolume(hash) > 0,
            "Order does not exist or invalid order hash."
        ); // since baseToken in order cannot be zero address, we are comparing it to such

        _;
    }

    // this modifier checks if hash argument is one of the market order
    // this modifier will revert transaction if order is not market order
    modifier onlyMarketOrder(bytes32 hash) {
        require(
            _getOrderType(hash) == uint256(OrderType.MARKET_ORDER),
            "Invalid order type."
        );

        _;
    }

    // this modifier checks if hash argument belongs to limit order
    // this modifier will revert transaction if order type is not limit order
    modifier onlyLimitOrder(bytes32 hash) {
        require(
            _getOrderType(hash) == uint256(OrderType.LIMIT_ORDER),
            "Invalid order type."
        );

        _;
    }

    // this modifier checks if msg.sender has permission to execute certain order
    // only order creator or executor addresses are approved
    modifier onlyExecutorAndCreator(bytes32 hash) {
        require(
            (_getCreator(hash) == msg.sender || executors[msg.sender]),
            "Only executor and order creator can execute this order."
        );

        _;
    }

    modifier onlyOngoingOrders(bytes32 hash) {
        require(
            _getOrderStatus(hash) == uint256(OrderStatus.ONGOING),
            "Order is finished, this operation cannot be completed."
        );

        _;
    }

    modifier notExpired(bytes32 hash) {
        uint256 expTime = _getExpirationTime(hash);

        require(
            expTime == 0 || expTime >= block.timestamp,
            "Order is expired, it cannot be filled."
        );

        _;
    }

    // ADMINISTRATION LOGIC - START

    /**
     * @dev Returns true if passed address is executor, else returns false.
     * @param _addr Address to be tested.
     * @return Returns boolean type.
     */
    function isExecutor(address _addr) external view returns (bool) {
        return executors[_addr];
    }

    /**
     * @dev Sets another address as an executor.
     * @param _addr Address to be set as an executor.
     *
     * This function can only be called by an approved executor.
     */
    function approveExecutor(address _addr) external {
        require(
            executors[msg.sender],
            "Only approved executors can call this function."
        );

        executors[_addr] = true;
    }

    /**
     * @dev Revokes another executor address.
     * @param _addr Address to be revoked an executor permission.
     *
     * This function can only be called by an approved executor.
     */
    function revokeExecutor(address _addr) external {
        require(
            executors[msg.sender],
            "Only approved executors can call this function."
        );

        executors[_addr] = false;
    }

    // ADMINISTRATION LOGIC - END

    // ORDER CREATION, MANAGMENT AND EXECUTION LOGIC - START

    /**
     * @notice Creates a new market order.
     * @param baseToken Token to be sold.
     * @param quoteToken Token to be bought.
     * @param volume Amount of base token to be sold.
     * @param minimumReturns Minimum amount of quoteToken to be received.
     *
     * Function will fail if volume and minimum returns are less than or equal to zero.
     */
    function createMarketOrder(
        address baseToken,
        address quoteToken,
        uint256 volume,
        uint256 minimumReturns
    ) external {
        require(volume > 0, "Invalid volume provided.");
        require(minimumReturns > 0, "Invalid minimum returns provided.");

        bytes32 hash = keccak256(
            abi.encodePacked(
                baseToken,
                quoteToken,
                volume,
                msg.sender,
                block.timestamp,
                uint256(OrderType.MARKET_ORDER)
            )
        );

        _setUintForOrder(hash, "orderType", uint256(OrderType.MARKET_ORDER));
        _setAddressForOrder(hash, "baseToken", baseToken);
        _setAddressForOrder(hash, "quoteToken", quoteToken);
        _setUintForOrder(hash, "volume", volume);
        _setUintForOrder(hash, "minimumReturns", minimumReturns);
        _setAddressForOrder(hash, "creator", msg.sender);
        _setUintForOrder(hash, "status", uint256(OrderStatus.ONGOING));

        VaultInstance.moveToOrder(baseToken, volume, hash);

        emit OrderCreated(msg.sender, hash);
    }

    /**
     * @notice Creates a new market order.
     * @param baseToken Token to be sold.
     * @param quoteToken Token to be bought.
     * @param volume Amount of base token to be sold.
     * @param limitPrice Price of 10**18 quote tokens expressed in base token amount. How much of quote token will I get for 10**18 base tokens.
     * @param expirationTime Expiration time, must be 0 for no expiration time or larger than current time, elsewise function will revert.
     *
     * Function will fail if volume is less than or equal to zero, if limit price is less than or equal to 0 or if expiration time is invalid.
     */
    function createLimitOrder(
        address baseToken,
        address quoteToken,
        uint256 volume,
        uint256 limitPrice,
        uint256 expirationTime
    ) external {
        require(
            expirationTime == 0 || expirationTime > block.timestamp,
            "Invalid expiration time."
        );
        require(volume > 0, "Invalid volume provided.");
        require(limitPrice > 0, "Invalid limit price provided.");

        bytes32 hash = keccak256(
            abi.encodePacked(
                baseToken,
                quoteToken,
                volume,
                msg.sender,
                block.timestamp,
                uint256(OrderType.LIMIT_ORDER)
            )
        );

        _setUintForOrder(hash, "orderType", uint256(OrderType.LIMIT_ORDER));
        _setAddressForOrder(hash, "baseToken", baseToken);
        _setAddressForOrder(hash, "quoteToken", quoteToken);
        _setUintForOrder(hash, "volume", volume);
        _setUintForOrder(hash, "limitPrice", limitPrice);
        _setUintForOrder(hash, "expirationTime", expirationTime);
        _setAddressForOrder(hash, "creator", msg.sender);
        _setUintForOrder(hash, "status", uint256(OrderStatus.ONGOING));
        _setUintForOrder(hash, "filledBase", 0);

        VaultInstance.moveToOrder(baseToken, volume, hash);

        emit OrderCreated(msg.sender, hash);
    }

    /**
     * @notice Cancel ongoing non-expired order and return in-order funds to vault.
     * @param hash Hash of the order.
     *
     * Function will fail if order is expired, if order is finished or cancelled or if caller is not creator of the order.
     */
    function cancelOrder(bytes32 hash)
        external
        notExpired(hash)
        onlyOngoingOrders(hash)
    {
        require(
            msg.sender == _getCreator(hash),
            "Only order creator can cancel the order."
        );

        OrderType type_ = OrderType(_getOrderType(hash));

        uint256 amountLeft;

        if (type_ == OrderType.MARKET_ORDER) {
            amountLeft = _getVolume(hash);
        } else if (type_ == OrderType.LIMIT_ORDER) {
            amountLeft = _getVolume(hash) - _getFilledBase(hash);
        }

        VaultInstance.orderCancellation(_getBaseToken(hash), amountLeft, hash);

        _setUintForOrder(hash, "status", uint256(OrderStatus.CANCELLED));

        emit OrderCancelled(hash);
    }

    /**
     * @notice Reclaim funds from expired order.
     * @param hash Hash of the order.
     *
     * Function will fail if order is not expired, if order is finished or cancelled or if caller is not creator of the order nor the executor.
     */
    function reclaimExpiredFunds(bytes32 hash)
        external
        onlyExecutorAndCreator(hash)
        onlyLimitOrder(hash)
        onlyOngoingOrders(hash)
    {
        uint256 expTime = _getExpirationTime(hash);

        require(
            expTime < block.timestamp && expTime > 0,
            "Only expired orders can be reclaimed."
        );

        VaultInstance.orderExpiration(
            _getBaseToken(hash),
            (_getVolume(hash) - _getFilledBase(hash)),
            hash,
            _getCreator(hash)
        );

        _setUintForOrder(hash, "status", uint256(OrderStatus.EXPIRED));

        emit OrderExpired(hash);
    }

    /**
     * @notice Change expiration time for limit or stop loss order.
     * @param hash Hash of the order.
     * @param newTime New expiration time for the order.
     *
     * Function will fail if order is expired, if order is finished or cancelled, if caller is not creator of the order or if expiration time is invalid.
     */
    function prolongOrder(bytes32 hash, uint256 newTime)
        external
        onlyOngoingOrders(hash)
        notExpired(hash)
    {
        require(
            _getOrderType(hash) != uint256(OrderType.MARKET_ORDER),
            "Invalid order type."
        );
        require(
            msg.sender == _getCreator(hash),
            "Only creator of the order can prolong it."
        );
        require(
            newTime == 0 || newTime > block.timestamp,
            "Invalid expiration time provided."
        );

        _setUintForOrder(hash, "expirationTime", newTime);

        emit OrderChanged(hash);
    }

    /**
     * @dev Executes the order.
     * @param hash The hash of the order to be executed.
     * @param route An array of data that signals routes to be used for order execution, where each route is one dex.
     * @param routePairs An array with addresses of the Uniswap, Sushiswap and Curve StableSwap pools.
     * @return volume of base token filled in this execution, remaining order volume to be filled and total returns from this execution, total returns from this execution
     *
     * Route format is as follows -> [dex enum, amount of base token, minimum quote returns for this route, dex enum, amount of base token, minimum quote returns for this route...]
     * If route array contains Uniswap, Sushiswap or Curve dexs, then routePairs array should contain addresses of pool contracts for previous routes, in the same order the routes have been pushed to the route array.
     * Curve has 3 additional parameters added to route array. 4th and 5th parameters, those are the indexes of the base and quote tokens in that order, that are acquired from StableSwap pool contract (that is being used to execute route), via coins() array function getter.
     * 6th parameter is 0 or 1, and it signals wheter the StableSwap pool on which exhange will be executed returns returns or not. 0 means it does not return and 1 means it returns. If quote token on the pool is Compond CToken, but not in order, this flag must be set to 0 or else execution will revert.
     * Route for internal matching format is as follows -> [enum for internal matching, baseAmount, quoteAmount, secondOrderHash in uint256 format]
     * Transaction will revert if if order does not exist, if minimum returns for some route are not met, if sum or route volumes is greater than the total order volume, if route volume is less than or equal to zero, if one of pair contracts do not match order token pair, if caller is not executor, nor the creator of the order or if order is expired, finished or cancelled, if token indexes for Curve route are invalid in any way, if Curve route has 6th parameter set to 1, but quote asset is used as Compound CToken in this pair trade on Curve, but not in order.
     */
    function executeOrder(
        bytes32 hash,
        uint256[] memory route,
        address[] memory routePairs
    )
        internal
        orderExists(hash)
        onlyExecutorAndCreator(hash)
        onlyOngoingOrders(hash)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(route.length > 0, "Route cannot be empty.");

        uint256[8] memory localsU; // this is solution for too large stack
        // localsU[0] is r counter
        // localsU[1] is rp counter
        // localsU[2] is totalReturns
        // localsU[3] is filledVolume
        // localsU[4] is remainingVolume
        // localsU[5] is amount of ETH received in WETH
        // localsU[6] is local returns for each dex
        // localsU[7] pool type for curve handler

        address[3] memory localsA = [
            // another too deep stack workaround
            _getBaseToken(hash), // localsA[0] is base token address
            _getQuoteToken(hash), // locals[1] is quote token address
            _getCreator(hash) // localsA[2] is creator address
        ];

        {
            localsU[4] = _getVolume(hash);

            if (OrderType(_getOrderType(hash)) == OrderType.LIMIT_ORDER)
                localsU[4] -= _getFilledBase(hash);
        }

        while (localsU[0] < route.length) {
            // route volume amount must not be zero or less
            require(
                route[localsU[0] + 1] > 0,
                "Route volume must be greater than zero."
            );
            require(
                route[localsU[0] + 1] <= localsU[4],
                "Invalid route, route volume amount exceeds total or remaining order volume."
            );

            localsU[3] += route[localsU[0] + 1]; // increase filledVolume by current route volume
            localsU[4] -= route[localsU[0] + 1]; // reduce remainingVolume by current route volume

            if (
                route[localsU[0]] == uint256(DEX.UNISWAPV2) ||
                route[localsU[0]] == uint256(DEX.SUSHISWAPV2)
            ) {
                {
                    VaultInstance.orderFill_ReleaseFunds(
                        localsA[2],
                        localsA[0],
                        route[localsU[0] + 1],
                        hash,
                        payable(routePairs[localsU[1]]), // pair
                        (localsA[0] == address(0)) // if base token is ethereum, wrap it
                    );

                    localsU[6] = IERC20(
                        (localsA[1] == address(0) ? weth : localsA[1]) // if quote token is Ethereum, then use WETH as a reference point
                    ).balanceOf(vault);

                    executeUniV2Swap(
                        routePairs[localsU[1]], // pair
                        localsA[0],
                        localsA[1],
                        route[localsU[0] + 2] // amountOut
                    ); // this will send tokens to the vault, they will be credited later

                    localsU[6] =
                        IERC20((localsA[1] == address(0) ? weth : localsA[1]))
                            .balanceOf(vault) -
                        localsU[6]; // calculate returns (_after - _before)

                    if (localsA[1] == address(0)) localsU[5] += localsU[6]; // if route is filled in WETH, increase amount of WETH to be reedemed for ETH at the moment of Vault order fill

                    require(
                        localsU[6] >= route[localsU[0] + 2], // _return >= amountOut
                        string(
                            abi.encodePacked(
                                "Returns from ",
                                (
                                    (route[localsU[0]] ==
                                        uint256(DEX.UNISWAPV2))
                                        ? "UniswapV2"
                                        : "SushiswapV2"
                                ),
                                " route are too low."
                            )
                        )
                    ); // check if returns are acceptable

                    localsU[2] += localsU[6]; // credit returns to total returns
                }

                localsU[1]++; // increment route pair counter, since uniswap used one
            } else if (route[localsU[0]] == uint256(DEX.BANCOR)) {
                {
                    VaultInstance.orderFill_ReleaseFunds(
                        localsA[2],
                        localsA[0],
                        route[localsU[0] + 1],
                        hash,
                        payable(address(this)),
                        false
                    );
                    // having block if/else will make larger bytecode, but will save gas during execution, since we will avoid inline conditional for instantiating base ERC20 in dependence of base asset being Ether...
                    if (localsA[0] != address(0)) {
                        // base token is just a classic ERC20...
                        IERC20(localsA[0]).safeApprove( // approve ERC20 for Bancor to use...
                            contractRegistry.addressOf(bancorNetworkName),
                            route[localsU[0] + 1]
                        );
                        localsU[6] = executeBancorTrade( // save returns of the route trade
                            IERC20(localsA[0]),
                            IERC20(
                                (
                                    localsA[1] == address(0)
                                        ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                                        : localsA[1]
                                )
                            ),
                            route[localsU[0] + 1]
                        );
                    } else {
                        // base asset is Ether
                        localsU[6] = executeBancorTrade( // save returns of the route trade
                            IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                            IERC20(
                                (
                                    localsA[1] == address(0)
                                        ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                                        : localsA[1]
                                )
                            ),
                            route[localsU[0] + 1]
                        );
                    }

                    require(
                        localsU[6] >= route[localsU[0] + 2], // _return < amountOut
                        "Returns from Bancor route are too low."
                    ); // check if returns are acceptable

                    localsU[2] += localsU[6]; // credit returns to total returns
                }
            } else if (route[localsU[0]] == uint256(DEX.CURVE)) {
                VaultInstance.orderFill_ReleaseFunds(
                    localsA[2],
                    localsA[0],
                    route[localsU[0] + 1],
                    hash,
                    payable(address(this)),
                    false
                );

                if (localsA[0] != address(0))
                    IERC20(localsA[0]).safeApprove(
                        routePairs[localsU[1]],
                        route[localsU[0] + 1]
                    );

                if (localsA[1] != address(0)) {
                    localsU[6] = IERC20(localsA[1]).balanceOf(address(this));

                    executeCurveSwap(
                        routePairs[localsU[1]],
                        [route[localsU[0] + 3], route[localsU[0] + 4]],
                        localsA[0],
                        localsA[1],
                        route[localsU[0] + 1],
                        route[localsU[0] + 5]
                    );

                    localsU[6] =
                        IERC20(localsA[1]).balanceOf(address(this)) -
                        localsU[6];
                } else {
                    localsU[6] = executeCurveSwap(
                        routePairs[localsU[1]],
                        [route[localsU[0] + 3], route[localsU[0] + 4]],
                        localsA[0],
                        localsA[1],
                        route[localsU[0] + 1],
                        route[localsU[0] + 5]
                    );
                }

                require(
                    localsU[6] >= route[localsU[0] + 2], // _return < amountOut
                    "Returns from Curve route are too low."
                ); // check if returns are acceptable

                localsU[2] += localsU[6]; // credit returns to total returns
                localsU[0] += 3; // increment couter by 3, since curve has 3 additional route arguments
            } else if (route[localsU[0]] == uint256(DEX.INTERNAL)) {
                executeInternalSwap(
                    hash,
                    bytes32(route[localsU[0] + 3]),
                    route[localsU[0] + 1], // base amount
                    route[localsU[0] + 2] // quote amount
                );

                localsU[2] += route[localsU[0] + 2];
            } else revert("Invalid DEX identifier provided.");

            localsU[0] += 4;
        }

        require(
            localsU[2] >= _getMinimumReturns(hash),
            "Total returns too low."
        );

        VaultInstance.orderFill_Succeeded(
            localsA[2],
            localsA[1],
            localsU[2],
            hash,
            localsU[5]
        );

        emit OrderFill(hash, localsU[3], localsU[2]);

        return (localsU[3], localsU[4], localsU[2]);
    }

    /**
     * @notice Executes market order with provided routes. An external wrapper for executeOrder().
     * @dev Ideally should be called only from Executor component with the routes calculated by the Router component.
     * @param hash The hash of the order to be executed.
     * @param route An array of data that signals routes to be used for order execution, where each route is one dex.
     * @param routePairs An array with addresses of the pool used by Uniswap, Sushiswap and Curve based routes.
     *
     * For route and routePairs format, look into dev documentation for executeRoute().
     *
     * Transaction will revert if whole order is not filled or if order type is not market order. For additional revert cases, look into executeRoute() docs.
     */
    function executeMarketOrder(
        bytes32 hash,
        uint256[] calldata route,
        address[] calldata routePairs
    ) external onlyMarketOrder(hash) {
        (, uint256 _remainingVolume, ) = executeOrder(hash, route, routePairs);

        require(_remainingVolume == 0, "Market order must be filled 100%.");

        _setUintForOrder(hash, "status", uint256(OrderStatus.FINISHED));

        emit OrderFinished(hash);
    }

    /**
     * @notice Executes limit order with provided routes. An external wrapper for executeOrder().
     * @dev Ideally should be called only from Executor component with the routes calculated by the Router component.
     * @param hash The hash of the order to be executed.
     * @param route An array of data that signals routes to be used for order execution, where each route is one dex.
     * @param routePairs An array with addresses of the pool used by Uniswap, Sushiswap and Curve based routes.
     *
     * For route and routePairs format, look into dev documentation for executeRoute().
     *
     * Transaction will revert if order is expired or if order type is not limit order. For additional revert cases, look into executeRoute() docs.
     */
    function executeLimitOrder(
        bytes32 hash,
        uint256[] calldata route,
        address[] calldata routePairs
    ) external notExpired(hash) onlyLimitOrder(hash) {
        uint256 _filledVolume;
        uint256 _totalReturns;

        {
            uint256 _remainingVolume;

            (_filledVolume, _remainingVolume, _totalReturns) = executeOrder(
                hash,
                route,
                routePairs
            );

            {
                require(
                    _totalReturns >=
                        ((_getLimitPrice(hash) * _filledVolume) / (10**18)), // total returns of the fill must be greater or equal to (limitPrice * filled amount of base tokens / 10**18)
                    "Limit order returns are too low, according to limit price provided by the order creator."
                );
            }

            if (_remainingVolume == 0) {
                _setUintForOrder(hash, "status", uint256(OrderStatus.FINISHED));

                emit OrderFinished(hash);
            }
        }

        _setUintForOrder(
            hash,
            "filledBase",
            (_getFilledBase(hash) + _filledVolume)
        );
        _setUintForOrder(
            hash,
            "filledQuote",
            (_getFilledQuote(hash) + _totalReturns)
        );
    }

    // ORDER CREATION AND EXEUCTION LOGIC - END

    // INTERNAL STORAGE GETTERS - START

    /**
     * @dev Returns uint256 type number identifing order type per OrderType enumerator.
     * @param hash Hash of the order.
     * @return Number identifing order type per OrderType enumerator.
     */
    function _getOrderType(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "orderType"))
            );
    }

    /**
     * @dev Returns an address of the base token for the order.
     * @param hash Hash of the order.
     * @return An address of the base token.
     */
    function _getBaseToken(bytes32 hash)
        internal
        view
        override
        returns (address)
    {
        return
            StorageInstance.getAddress(
                keccak256(abi.encodePacked("orders", hash, "baseToken"))
            );
    }

    /**
     * @dev Returns an address of the quote token for the order.
     * @param hash Hash of the order.
     * @return An address of the quote token.
     */
    function _getQuoteToken(bytes32 hash)
        internal
        view
        override
        returns (address)
    {
        return
            StorageInstance.getAddress(
                keccak256(abi.encodePacked("orders", hash, "quoteToken"))
            );
    }

    /**
     * @dev Returns volume of the order in base token.
     * @param hash Hash of the order.
     * @return The volume of the order.
     */
    function _getVolume(bytes32 hash) internal view override returns (uint256) {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "volume"))
            );
    }

    /**
     * @dev Returns limit price of the order.
     * @param hash Hash of the order.
     * @return The limit price.
     */
    function _getLimitPrice(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "limitPrice"))
            );
    }

    function _getOrderCreator(bytes32 hash)
        internal
        view
        override
        returns (address)
    {
        return
            StorageInstance.getAddress(
                keccak256(abi.encodePacked("orders", hash, "creator"))
            );
    }

    /**
     * @dev Returns an expiration time of the order.
     * @param hash Hash of the order.
     * @return The expiration time.
     */
    function _getExpirationTime(bytes32 hash) internal view returns (uint256) {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "expirationTime"))
            );
    }

    /**
     * @dev Returns minimum returns of order.
     * @param hash Hash of the order.
     * @return The minimum returns of quote token for the order.
     */
    function _getMinimumReturns(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "minimumReturns"))
            );
    }

    /**
     * @dev Returns an address of order creator.
     * @param hash Hash of the order.
     * @return An address of the order creator.
     */
    function _getCreator(bytes32 hash) internal view returns (address) {
        return
            StorageInstance.getAddress(
                keccak256(abi.encodePacked("orders", hash, "creator"))
            );
    }

    /**
     * @dev Returns an uint256 representing OrderStatus enum.
     * @param hash Hash of the order.
     * @return Order status.
     */
    function _getOrderStatus(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "status"))
            );
    }

    /**
     * @dev Returns an uint256 representing filled base token.
     * @param hash Hash of the order.
     * @return Amount filled base token.
     */
    function _getFilledBase(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "filledBase"))
            );
    }

    /**
     * @dev Returns an uint256 representing filled quote token.
     * @param hash Hash of the order.
     * @return Amount filled quote token.
     */
    function _getFilledQuote(bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        return
            StorageInstance.getUint(
                keccak256(abi.encodePacked("orders", hash, "filledQuote"))
            );
    }

    // INTERNAL STORAGE GETTERS - END

    // ORDER INFO GETTERS FOR FRONTEND - START
    // These should not be used in contracts, but only on frontend.

    /**
     * @notice Returns order type based on the has of the order.
     * @param hash Hash of the order.
     * @return String identifying type of the order.
     *
     * This function will revert if order hash does not identify existing order.
     */
    function getOrderTypeByHash(bytes32 hash)
        external
        view
        orderExists(hash)
        returns (string memory)
    {
        if (_getOrderType(hash) == uint256(OrderType.MARKET_ORDER)) {
            return "MARKET_ORDER";
        } else return "LIMIT_ORDER";
    }

    /**
     * @notice Returns information about limit order.
     * @dev Passed hash must be the hash of the limit order or else function will fail.
     * @param hash Hash of the order.
     * @return base token address, quote token address, order volume, order limit price, order expiration time, amount of base token filled
     *
     * This function will fail if order does not exist or if order type is not limit order.
     */
    function getLimitOrder(bytes32 hash)
        external
        view
        orderExists(hash)
        onlyLimitOrder(hash)
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _getBaseToken(hash),
            _getQuoteToken(hash),
            _getVolume(hash),
            _getLimitPrice(hash),
            _getExpirationTime(hash),
            _getFilledBase(hash)
        );
    }

    /**
     * @notice Returns remaining information about limit order, that cannot be sent via getLimitOrder() function, bacause of EVM stack limitations.
     * @dev Passed hash must be the hash of the limit order or else function will fail.
     * @param hash Hash of the order.
     * @return amount of quote token filled
     *
     * This function will fail if order does not exist or if order type is not limit order.
     */
    function getLimitOrder_EXTENDED(bytes32 hash)
        external
        view
        orderExists(hash)
        onlyLimitOrder(hash)
        returns (uint256)
    {
        return _getFilledQuote(hash);
    }

    /**
     * @notice Returns information about market order.
     * @dev Passed hash must be the hash of the market order or else function will fail.
     * @param hash Hash of the order.
     * @return base token address, quote token address, order volume, total minimum returns of the order
     *
     * This function will fail if order does not exist or if order type is not market order.
     */
    function getMarketOrder(bytes32 hash)
        external
        view
        orderExists(hash)
        onlyMarketOrder(hash)
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        return (
            _getBaseToken(hash),
            _getQuoteToken(hash),
            _getVolume(hash),
            _getMinimumReturns(hash)
        );
    }

    /**
     * @notice Get the status of the order.
     * @param hash Hash of the order.
     * @return Returns string identifying current state/status of the order.
     *
     * This function will fail if order does not exist.
     * This function won't return EXPIRED order status if order is expried, that should be checked on frontend.
     */
    function getOrderStatus(bytes32 hash)
        external
        view
        orderExists(hash)
        returns (string memory)
    {
        if (_getOrderStatus(hash) == uint256(OrderStatus.ONGOING))
            return "ONGOING";
        if (_getOrderStatus(hash) == uint256(OrderStatus.FINISHED))
            return "FINISHED";
        if (_getOrderStatus(hash) == uint256(OrderStatus.CANCELLED))
            return "CANCELLED";
    }

    // ORDER INFO GETTERS FOR FRONTEND - START

    // OTHER EXTERNAL GETTERS - START

    function getStorageAddr() external view returns (address) {
        return storage_;
    }

    function getVaultAddr() external view returns (address) {
        return vault;
    }

    // OTHER EXTERNAL GETTERS - END

    // INTERNAL SETTERS - START

    function _setUintForOrder(
        bytes32 hash,
        string memory property,
        uint256 value
    ) internal {
        StorageInstance.setUint(
            keccak256(abi.encodePacked("orders", hash, property)),
            value
        );
    }

    function _setAddressForOrder(
        bytes32 hash,
        string memory property,
        address value
    ) internal {
        StorageInstance.setAddress(
            keccak256(abi.encodePacked("orders", hash, property)),
            value
        );
    }

    // INTERNAL SETTERS - END

    fallback() external payable {}
}

import "./Vault.sol";
import "./Storage.sol";

enum OrderType {
    MARKET_ORDER,
    LIMIT_ORDER,
    STOP_LOSS_ORDER
}

enum OrderStatus {
    ONGOING,
    FINISHED,
    CANCELLED,
    EXPIRED
}

abstract contract Base {
    address payable internal vault;
    address internal weth;
    Vault VaultInstance;
    Storage StorageInstance;

    event OrderFinished(bytes32 indexed hash);

    function _getOrderType(bytes32 hash)
        internal
        view
        virtual
        returns (uint256);

    function _getBaseToken(bytes32 hash)
        internal
        view
        virtual
        returns (address);

    function _getQuoteToken(bytes32 hash)
        internal
        view
        virtual
        returns (address);

    function _getVolume(bytes32 hash) internal view virtual returns (uint256);

    function _getLimitPrice(bytes32 hash)
        internal
        view
        virtual
        returns (uint256);

    function _getMinimumReturns(bytes32 hash)
        internal
        view
        virtual
        returns (uint256);

    function _getOrderStatus(bytes32 hash)
        internal
        view
        virtual
        returns (uint256);

    function _getOrderCreator(bytes32 hash)
        internal
        view
        virtual
        returns (address);    

    function _getFilledBase(bytes32 hash) 
        internal 
        view 
        virtual 
        returns (uint256);    

    function _getFilledQuote(bytes32 hash) 
        internal 
        view 
        virtual 
        returns (uint256);     
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH.sol";
import "./MainProxy.sol";

/**
 * @title A vault contract for safe managment of deposited assets.
 * @notice A contract that tracks amount of assets (tokens and ether) deposited to the platform by the user and amount of assets locked in orders.
 * @dev Ether balances are kept in vaultBalances mapping and Ether amount is mapped to with the 0 address.
 */
contract Vault {
    using SafeERC20 for IERC20;

    address public mainProxy;
    MainProxy MainProxyInstance;

    address payable public weth;
    IWETH WETH;

    mapping(address => mapping(address => uint256)) internal vaultBalances;
    mapping(address => mapping(address => uint256)) internal inOrders;

    event Deposit(
        address from,
        address indexed to,
        address indexed asset,
        uint256 indexed amount
    );
    event Withdraw(
        address from,
        address indexed to,
        address indexed asset,
        uint256 indexed amount
    );
    event MovedToOrder(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address asset, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amount,
        bytes32 indexed order
    );
    event MovedFromOrder(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address asset, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amount,
        bytes32 indexed order
    );
    event FundsReleased(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address assetA, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amountA,
        address indexed destination,
        bytes32 indexed orderHash
    );
    event FillExecuted(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address assetB, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amountB,
        bytes32 indexed orderHash
    );
    event InternalMatchTransfer(
        bytes32 indexed orderA,
        bytes32 orderB, // no need to index second order
        uint256 indexed baseAmount,
        uint256 indexed quoteAmount
    ); // event doesn't contain baseToken and quoteToken addresses, since they can be retrieved via orderA hash and baseToken is always baseToken of orderA

    /**
     * @dev Constructs the Vault contract.
     * @param _mainProxy An address of the EIP1967 Upgradable Proxy for the Main.
     * @param _weth An address of Wrapped Ether contract.
     */
    constructor(address payable _mainProxy, address payable _weth) {
        mainProxy = _mainProxy;
        MainProxyInstance = MainProxy(_mainProxy);

        weth = _weth;
        WETH = IWETH(_weth);
    }

    // used for safe asset managment by the contracts ecosystem
    modifier onlyAllowed() {
        // sender must be either main proxy, current implementation or previous implementation that is a valid, non security risk version
        require(
            MainProxyInstance.isActiveImplementation(msg.sender) == true || msg.sender == mainProxy,
            "You are not allowed to call this function."
        );
        _;
    }

    /**
     * @notice Function called for depositing Ether. A value of the message will be the amount credited.
     * @param toUser An address of the account on the platform to which deposited Ether amount will be credited. In most cases this will be the sender.
     */
    function depositEther(address toUser) external payable {
        vaultBalances[toUser][address(0)] += msg.value;

        emit Deposit(msg.sender, toUser, address(0), msg.value);
    }

    /**
     * @notice Function called to withdraw Ether.
     * @dev The call will fail if vault balance of the sender is insufficient.
     * @param toAddress An address to which withdrawn Ether will be sent.
     * @param amount An amount of Ether to be withdrawn.
     */
    function withdrawEther(address payable toAddress, uint256 amount) external {
        require(
            amount <= vaultBalances[msg.sender][address(0)],
            "Insufficient amount of assets in vault."
        );

        vaultBalances[msg.sender][address(0)] -= amount;

        toAddress.transfer(amount);

        emit Withdraw(msg.sender, toAddress, address(0), amount);
    }

    /**
     * @notice Function called to deposit tokens. Sender must approve vault contract as a token spender for the amount to be deposited.
     * @dev The call will fail if token balance of the sender is insufficient or if approval for the vault contract is insufficient.
     * @param token An address of the token to be deposited.
     * @param amount An amount of token to be deposited.
     * @param toUser An address of the platform user to whom the funds will be credited.
     */
    function depositToken(
        address token,
        uint256 amount,
        address toUser
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        vaultBalances[toUser][token] += amount;

        emit Deposit(msg.sender, toUser, token, amount);
    }

    /**
     * @notice Function used to withdraw tokens.
     * @dev The call will fail if vault token balance of the sender is insufficient.
     * @param token An addess of the token to be withdrawn.
     * @param amount An amount of tokens to be withdrawn.
     * @param toAddress An address to which the tokens will be withdrawn.
     */
    function withdrawToken(
        address token,
        uint256 amount,
        address toAddress
    ) external {
        require(
            amount <= vaultBalances[msg.sender][token],
            "Insufficient amount assets in vault."
        );

        vaultBalances[msg.sender][token] -= amount;

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(msg.sender, toAddress, token, amount);
    }

    /**
     * @notice Function used to retrieve asset balance of specific address. This balance does not include amount locked in orders.
     * @dev To retrieve Ether balance, use 0 address for the asset parameter.
     * @param asset An addess of the asset (token address or 0 address for the Ether) to be checked.
     * @param user An address of the user whose balance should be checked.
     */
    function vaultBalanceOf(address asset, address user)
        external
        view
        returns (uint256 balance)
    {
        return vaultBalances[user][asset];
    }

    /**
     * @notice Function used to retrieve asset balance of specific address locked in order(s).
     * @dev To retrieve Ether balance, use 0 address for the asset parameter.
     * @param asset An addess of the asset (token address or 0 address for the Ether) to be checked.
     * @param user An address of the user whose balance should be checked.
     */
    function inOrderBalanceOf(address asset, address user)
        external
        view
        returns (uint256 balance)
    {
        return inOrders[user][asset];
    }

    /**
     * @dev Function used to allocate tokens in the order. The call will fail if vault token balance of the user is insufficient. To prevent malicious contracts from manipulating user funds without approval, this function requires that tx originates from the actual owner of the funds, i.e. tx.origin will be treated as user.
     * @param asset An addess of the asset to be added to the order (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into order.
     * @param orderHash A hash of the order that triggered allocation.
     */
    function moveToOrder(
        address asset,
        uint256 amount,
        bytes32 orderHash
    ) external onlyAllowed {
        require(
            amount <= vaultBalances[tx.origin][asset],
            "Insufficient vault balance."
        );

        vaultBalances[tx.origin][asset] -= amount;
        inOrders[tx.origin][asset] += amount;

        emit MovedToOrder(tx.origin, asset, amount, orderHash);
    }

    /**
     * @dev Function used to allocate tokens from order, back to the vault upon cancellation. The call will fail if in order token balance of the user is insufficient. To prevent malicious contracts from manipulating user funds without approval, this function requires that tx originates from the actual owner of the funds, i.e. tx.origin will be treated as user.
     * @param asset An addess of the asset to be removed from order balance (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into vault.
     * @param orderHash A hash of the order that triggered deallocation.
     */
    function orderCancellation(
        address asset,
        uint256 amount,
        bytes32 orderHash
    ) external onlyAllowed {
        require(
            amount <= inOrders[tx.origin][asset],
            "Insufficient in order balance."
        );

        inOrders[tx.origin][asset] -= amount;
        vaultBalances[tx.origin][asset] += amount;

        emit MovedFromOrder(tx.origin, asset, amount, orderHash);
    }

    /**
     * @dev Function used to allocate tokens from order, back to the vault upon expiration. The call will fail if in order token balance of the user is insufficient.
     * @param asset An addess of the asset to be removed from order balance (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into vault.
     * @param orderHash A hash of the order that triggered deallocation.
     * @param user An address of the user.
     */
    function orderExpiration(
        address asset,
        uint256 amount,
        bytes32 orderHash,
        address user
    ) external onlyAllowed {
        require(
            amount <= inOrders[user][asset],
            "Insufficient in order balance."
        );

        inOrders[user][asset] -= amount;
        vaultBalances[user][asset] += amount;

        emit MovedFromOrder(user, asset, amount, orderHash);
    }

    /**
     * @dev Function used to release funds to order module, to execute trade/swap.
     * @param user An address of the user.
     * @param assetA An addess of the asset to be released (i.e. token address or zero address for ether).
     * @param amountA An amount of tokens to be released.
     * @param orderHash The hash of the order being executed.
     * @param destination An address of the order module, that will execute the trade/swap.
     * @param wrap If true, will wrap Ether as WETH9 before release, if asset is zero address.
     */
    function orderFill_ReleaseFunds(
        address user,
        address assetA,
        uint256 amountA,
        bytes32 orderHash,
        address payable destination,
        bool wrap
    ) external onlyAllowed {
        require(
            amountA <= inOrders[user][assetA],
            "Insufficient in order balance."
        );

        if (assetA == address(0)) {
            if (wrap) {
                WETH.deposit{value: amountA}();

                IERC20(weth).safeTransfer(destination, amountA);
            } else destination.transfer(amountA);
        } else IERC20(assetA).safeTransfer(destination, amountA);

        inOrders[user][assetA] -= amountA;

        emit FundsReleased(user, assetA, amountA, destination, orderHash);
    }

    /**
     * @dev Function called after order fill had been successfull and balances need to be rebalanced. Funds must be sent to contract before triggering this function! IMPORTANT: Does no check if assets have been returned!
     * @param user An address of the user.
     * @param assetB An addess of the asset gotten from trade/swap.
     * @param amountB An amount of asset gotten from trade/swap.
     * @param orderHash The hash of the order that triggered this change.
	 * @param unwrap If order received and sent WETH to the Vault from handler, setting this to anything other than 0 will unwrap that amount of WETH.
     */
    function orderFill_Succeeded(
        address user,
        address assetB,
        uint256 amountB,
        bytes32 orderHash,
		uint256 unwrap
    ) external onlyAllowed {
		if (assetB == address(0) && unwrap > 0) WETH.withdraw(unwrap);

        vaultBalances[user][assetB] += amountB;

        emit FillExecuted(user, assetB, amountB, orderHash);
    }

    /**
     * @dev Function called to adjust the balance in Vault contract for the second order when internal match happens. A and B arguments are respective to the first order.
     * @param orderA Hash of the first order.
     * @param orderB Hash of the second order (order to be updated).
     * @param userA Creator of the first order.
     * @param userB Creator of the second order.
     * @param assetA Base asset of first order and quote asset of second order.
     * @param assetB Quote asset of first order and base asset of second order.
     * @param amountA Volume of base token taken from first order and received by the second order.
     * @param amountB Volume of quote token received in first order and taken from second order.
     */
    function internalMatch(
        bytes32 orderA,
        bytes32 orderB,
        address userA,
        address userB,
        address assetA,
        address assetB,
        uint256 amountA,
        uint256 amountB
    ) external onlyAllowed {
        vaultBalances[userB][assetA] += amountA;
        inOrders[userA][assetA] -= amountA;
        inOrders[userB][assetB] -= amountB;

        emit InternalMatchTransfer(orderA, orderB, amountA, amountB); // InternalMatchTransfer is equialent of FillExecuted
    }

    fallback() external payable {}
}

pragma solidity ^0.8.0;

import "./MainProxy.sol";

/**
 * @title A contract for permanent storage accros different implementations.
 * @notice A key-value based storage contract.
 * @dev All setter functions take bytes32 type as a first argument, and desired storage type as a second argument. First argument is a hash of a key for data to be stored, generated using keccak256 hashing algorithm and a second one is a value linked to that key in corresponding storage data type. All getter functions take only one argument in form of bytes32 type, which is a hash of the key, whose value needs to be retrieved, type of retrieved value is corresponding to the type that should be retrieved. All deleters take only one argument of type bytes32, representing the hash of the key for data to be delete.
 */
contract Storage {
    address payable public mainProxy;
    MainProxy MainProxyInstance;

    /**
     * @dev Constructs the Storage contract.
     * @param _mainProxy An address of the EIP1967 Upgradable Proxy for the Main.
     */
    constructor(address payable _mainProxy) {
        mainProxy = _mainProxy;
        MainProxyInstance = MainProxy(_mainProxy);
    }

    // key hash to value mappings by type
    mapping(bytes32 => uint256) uIntStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bytes32) bytes32Storage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => bool) boolStorage;

    // allows access to storage only to MainProxy, Main implementation and previous, valid & secure Main implementations
    modifier onlyAllowed() {
		// sender must be either main proxy, current implementation or previous implementation that is a valid, non security risk version
        require(MainProxyInstance.isActiveImplementation(msg.sender) == true || msg.sender == mainProxy,
        "You are not allowed to call this function.");
        _;
    }

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns (uint256) {
        return uIntStorage[_key];
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getBytes32(bytes32 _key) external view returns (bytes32) {
        return bytes32Storage[_key];
    }

    function getString(bytes32 _key) external view returns (string memory) {
        return stringStorage[_key];
    }

    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint256 _value) external onlyAllowed {
        uIntStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) external onlyAllowed {
        addressStorage[_key] = _value;
    }

    function setBytes32(bytes32 _key, bytes32 _value) external onlyAllowed {
        bytes32Storage[_key] = _value;
    }

    function setString(bytes32 _key, string memory _value)
        external
        onlyAllowed
    {
        stringStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) external onlyAllowed {
        boolStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external onlyAllowed {
        delete uIntStorage[_key];
    }

    function deleteAddress(bytes32 _key) external onlyAllowed {
        delete addressStorage[_key];
    }

    function deleteBytes32(bytes32 _key) external onlyAllowed {
        delete bytes32Storage[_key];
    }

    function deleteString(bytes32 _key) external onlyAllowed {
        delete stringStorage[_key];
    }

    function deleteBool(bytes32 _key) external onlyAllowed {
        delete boolStorage[_key];
    }
}

pragma solidity ^0.8.0;

import "../Base.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "hardhat/console.sol";

/**
 * @title A contract used to execute a swap on Uniswap V2 DEX.
 */
abstract contract UniswapV2Handler is Base {
    /**
     * @dev Executes a single route/swap.
     * @param pair An address of the UniswapV2 pair contract.
     * @param baseToken An address of the base token.
     * @param quoteToken An address of the quote token.
     * @param quoteOut Expected return of quote token in this swap/trade.
     */
    function executeUniV2Swap(
        address pair,
        address baseToken,
        address quoteToken,
        uint256 quoteOut
    ) internal {
        IUniswapV2Pair Pair = IUniswapV2Pair(pair);

		if (baseToken == address(0)) baseToken = weth; 
		if (quoteToken == address(0)) quoteToken = weth; 

        require(
			(baseToken < quoteToken ? 
				(Pair.token0() == baseToken && Pair.token1() == quoteToken) : (Pair.token0() == quoteToken && Pair.token1() == baseToken)
			),
            "Uniswap handler: Tokens do not match the ones in the pair."
        ); // check if tokens match with pair

        // determine which token is quoted and setup the amounts out
        if (Pair.token0() == baseToken) Pair.swap(0, quoteOut, vault, ""); // execute swap
		if (Pair.token1() == baseToken) Pair.swap(quoteOut, 0, vault, ""); // execute swap
    }
}

pragma solidity ^0.8.0;

import "../Base.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBancor.sol";

import "hardhat/console.sol";

/**
 * @title A contract used to execute trades on Bancor Network.
 */
abstract contract BancorNetworkHandler is Base {
	IContractRegistry contractRegistry;
    bytes32 constant bancorNetworkName = "BancorNetwork";

    function getBancorNetworkContract() public returns(IBancorNetwork) {
        return IBancorNetwork(contractRegistry.addressOf(bancorNetworkName));
    }

    //path and minReturn generated via SDK    
    function tradeWithInputs(
        address[] memory _path,
        uint _minReturn,
        uint _amount
    ) internal returns(uint returnAmount) {
        IBancorNetwork bancorNetwork = getBancorNetworkContract();
        returnAmount = bancorNetwork.convertByPath{value: msg.value}(
            _path,
            _amount,
            _minReturn,
            address(0),
            address(0),
            0
        );
    }

    // path and minReturn generated on chain 
	/**
     * @dev Executes a single trade.
     * @param _sourceToken An instance of base token.
     * @param _targetToken An instance of quote token.
     * @param _amount Amount of base token to trade.
     */   
    function executeBancorTrade(
        IERC20 _sourceToken, 
        IERC20 _targetToken, 
        uint _amount
    ) internal returns(uint returnAmount) {
        IBancorNetwork bancorNetwork = getBancorNetworkContract();

        address[] memory path = bancorNetwork.conversionPath(
            _sourceToken,
            _targetToken
        );

        uint minReturn = bancorNetwork.rateByPath(
            path,
            _amount
        );

        returnAmount = bancorNetwork.convertByPath{value: ((address(_sourceToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? _amount : 0)}(
            path,
            _amount,
            minReturn,
            vault, // benefiricary
            address(0),
            0
        );
    }

}

pragma solidity ^0.8.0;

import "../Base.sol";

import "../interfaces/ICurve.sol";
import "../interfaces/ICToken.sol";

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

enum PoolType {
    PLAIN,
    LENDING,
    META
}

/**
 * @title A contract used to execute a swap on Curve StableSwap pools.
 */
abstract contract CurveHandler is Base {
    /**
     * @dev Executes a single route/swap.
     * @param pair An address of the Curve pool contract.
     * @param indexes An array of indexes of the base and quote tokens respectively in Curve pool.
     * @param baseToken An address of the base token.
     * @param quoteToken An address of the quote token.
     * @param amount Amount of base token to be exchanged. May differ from the actual amount of base token for this route, if base token is Compound CToken on pool, but not in order.
     * @param poolType Type of pool to be exchanged on (Plain, Lending or Meta)
     *
     * This function will throw if token indexes are invalid in any way or if exhangeReturns flag is set to true, but quoteToken is used as Compound CToken in this pool, but not in order.
     */
    function executeCurveSwap(
        address pair,
        uint256 [2] memory indexes,
        address baseToken,
        address quoteToken,
        uint256 amount,
        uint256 poolType
    ) internal returns (uint256 _returns) {
        int128 baseTokenIndex = SafeCast.toInt128(SafeCast.toInt256(indexes[0]));
        int128 quoteTokenIndex = SafeCast.toInt128(SafeCast.toInt256(indexes[1]));

        if (baseToken == address(0))
            baseToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        if (quoteToken == address(0))
            quoteToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        if (poolType == uint256(PoolType.PLAIN)) {
            IStableSwap_PlainPool Pool = IStableSwap_PlainPool(pair);

            if (
                Pool.coins(uint256(int256(baseTokenIndex))) ==
                baseToken &&
                Pool.coins(uint256(int256(quoteTokenIndex))) == quoteToken
            ) {
                uint256 min_dy = Pool.get_dy(
                    baseTokenIndex,
                    quoteTokenIndex,
                    amount
                )/1000*992;

                if (quoteToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                    // Ether exists only in plain pools
                    _returns = IStableSwap_PlainPool_returnable(pair).exchange(baseTokenIndex, quoteTokenIndex, amount, min_dy);
                } else {
                    Pool.exchange{
                        value: (baseToken ==
                            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
                            ? amount
                            : 0
                    }(baseTokenIndex, quoteTokenIndex, amount, min_dy);
                }
            } else revert("Curve handler: Invalid indexes provided.");
        } else if (poolType == uint256(PoolType.LENDING)) {
            IStableSwap_LendingPool Pool = IStableSwap_LendingPool(pair);

            if (
                Pool.underlying_coins(
                    baseTokenIndex
                ) ==
                baseToken &&
                Pool.underlying_coins(
                    quoteTokenIndex
                ) ==
                quoteToken
            ) {
                uint256 min_dy = Pool.get_dy_underlying(
                    baseTokenIndex,
                    quoteTokenIndex,
                    amount
                )/1000*992;

                Pool.exchange_underlying(baseTokenIndex, quoteTokenIndex, amount, (min_dy / 100) * 99);
            } else if (
                Pool.coins(baseTokenIndex) ==
                baseToken &&
                Pool.coins(quoteTokenIndex) ==
                quoteToken
            ) {
                uint256 min_dy = Pool.get_dy(
                    baseTokenIndex,
                    quoteTokenIndex,
                    amount
                )/1000*992;

                Pool.exchange(baseTokenIndex, quoteTokenIndex, amount, (min_dy / 100) * 99);
            } else revert("Curve handler: Invalid indexes provided.");
        } else if (poolType >= uint256(PoolType.META)) {
            IStableSwap_MetaPool Pool = IStableSwap_MetaPool(pair);

            if (Pool.base_coins(uint256(int256(baseTokenIndex))) == baseToken && Pool.coins(0) == quoteToken) {
                uint256 min_dy = Pool.get_dy_underlying(
                    SafeCast.toInt128(SafeCast.toInt256(poolType)) - 2,
                    0,
                    amount
                )/1000*992;

                Pool.exchange_underlying(SafeCast.toInt128(SafeCast.toInt256(poolType)) - 2, 0, amount, (min_dy / 100) * 99);
            } else if (Pool.coins(0) == baseToken && Pool.base_coins(uint256(int256(quoteTokenIndex))) == quoteToken) {
                uint256 min_dy = Pool.get_dy_underlying(
                    0,
                    SafeCast.toInt128(SafeCast.toInt256(poolType)) - 2,
                    amount
                )/1000*992;

                Pool.exchange_underlying(baseTokenIndex, SafeCast.toInt128(SafeCast.toInt256(poolType)) - 2, amount, (min_dy / 100) * 99);
            } else if (
                Pool.coins(uint256(int256(baseTokenIndex))) == baseToken &&
                Pool.coins(uint256(int256(quoteTokenIndex))) == quoteToken
            ) {
                uint256 min_dy = Pool.get_dy(
                    baseTokenIndex,
                    quoteTokenIndex,
                    amount
                )/1000*992;

                Pool.exchange(baseTokenIndex, quoteTokenIndex, amount, (min_dy / 100) * 99);
            } else revert("Curve handler: Invalid indexes provided.");
        }
    }
}

pragma solidity ^0.8.0;

import "../Base.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Vault.sol";

/**
 * @title A contract used to handle logic behind Internal Swap concept.
 */
abstract contract InternalSwapHandler is Base {
    /**
     * @dev Executes internal swap beetwen two limit orders.
     * @param firstOrder Hash of the first order.
     * @param secondOrder Hash of the second order.
     * @param baseAmount Amount of base token to be swapped in first order and amount of quote token to be received in the second order.
     * @param quoteAmount Amount of quote token to be received in the first order and amount of base token to be swapped in second order.
     *
     * Function can fail if base and quote token are not mathcing, if returns for the second order are not acceptable, if any of two orders may run out of available volume or if one of two orders is not limit order.
     */
    function executeInternalSwap(
        bytes32 firstOrder,
        bytes32 secondOrder,
        uint256 baseAmount,
        uint256 quoteAmount
    ) internal {
        require(
            _getBaseToken(firstOrder) == _getQuoteToken(secondOrder) &&
                _getQuoteToken(firstOrder) == _getBaseToken(secondOrder),
                    "Internal matching: Provided order do not match by assets."
        ); // check if base and quote tokens are a match
        require(_getOrderStatus(secondOrder) == uint256(OrderStatus.ONGOING), "Internal matching: Second order is not active."); // do the check if second order is active, since there is no status check for second order

        address[4] memory locals; // this is solution for too large stack
        // locals[0] is firstUser
        // locals[1] is secondUser
        // locals[2] is assetA
        // locals[3] is assetB

        /*require(
            _getVolume(firstOrder) - _getFilledBase(firstOrder) >= baseAmount
        );*/ // check if base amount does not exceed available volume // this is already checked in Main: executeOrder...
        require(
            _getVolume(secondOrder) - _getFilledBase(secondOrder) >= quoteAmount,
            "Internal matching: Insufficient remaining volume in second order for match to execute."
        ); // check if quote amount does not exceed available volume
        /*require(
            _getMinimumReturns(firstOrder) <=
                _getVolume(secondOrder) - _getFilledBase(secondOrder) &&
                _getMinimumReturns(firstOrder) <= quoteAmount
        );*/ // check if minimum returns are met and if can be met // This is already handled by returns checks at the end of this handelr and Main: executeLimitOrder().

        locals[0] = _getOrderCreator(firstOrder);
        locals[1] = _getOrderCreator(secondOrder);

        locals[2] = _getBaseToken(firstOrder);
        locals[3] = _getQuoteToken(firstOrder);

        // since market to market order internal match is improbabble, therefore is not implemented to optimize for bytecode size
        // logic for market to limit is yet to be defined, so its left out
        require(
            _getOrderType(firstOrder) == uint256(OrderType.LIMIT_ORDER) &&
                _getOrderType(secondOrder) == uint256(OrderType.LIMIT_ORDER),
            "Internal swap works only with limit orders."
        );

        // do return checks for the second order
        // base of first order is quote of second and quote of first order is base of second order
        // therefore quote (base) volume received from trade should be >= than limit price * base (quote) volume
        require(
            baseAmount >=
                ((_getLimitPrice(secondOrder) * quoteAmount) / (10**18)),
            "Internal mathcing: Returns are too low for the second order."
        );

        VaultInstance.internalMatch(
            firstOrder,
            secondOrder,
            locals[0],
            locals[1],
            locals[2],
            locals[3],
            baseAmount,
            quoteAmount
        );

        // update second order info (post fill)

        // if second order remainingvolume == 0, then change it to finished
        if ((_getVolume(secondOrder) - quoteAmount) == 0) {
            StorageInstance.setUint(
                keccak256(abi.encodePacked("orders", secondOrder, "status")),
                uint256(OrderStatus.FINISHED)
            );

            emit OrderFinished(secondOrder);
        }

        // update filled base and filled quote for second order

        StorageInstance.setUint(
            keccak256(abi.encodePacked("orders", secondOrder, "filledBase")),
            (_getFilledBase(secondOrder) + quoteAmount)
        );

        StorageInstance.setUint(
            keccak256(abi.encodePacked("orders", secondOrder, "filledQuote")),
            (_getFilledQuote(secondOrder) + baseAmount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// taken from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title A transparent EIP1967 based upgradable proxy for Main.
 * @dev This contract allows for upgrades of Main contract and manages balances for DeFire users.
 *
 * Take a look at https://docs.openzeppelin.com/contracts/3.x/api/proxy#TransparentUpgradeableProxy[this link] for more details about the mechanics of the underlying contract architecture.
 */
contract MainProxy is TransparentUpgradeableProxy {
    mapping(address => bool) internal previousVersions;

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {
        previousVersions[_logic] = true;
    }

    /**
     * @notice Returns an address of the current implementation.
     *
     * @return An address of the current implementation.
     */
    function getImplementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @notice Checks if certain address is an active implementation that can be used.
     *
     * @return Returns true if provided address is an active implementation, else returns false.
     */
    function isActiveImplementation(address _impl)
        external
        view
        returns (bool)
    {
        return previousVersions[_impl];
    }

    /**
     * @dev Sets new implementation. Must be used instead of 'upgradeTo()' and 'upgradeToAndCall()'! Can only be called by admin.
     * @param _impl An address of new implementation.
     */
    function newImplementation(address _impl) external ifAdmin {
        _upgradeToAndCall(_impl, bytes(""), false);

        previousVersions[_impl] = true;
    }

    /**
     * @dev Revokes previous implementation, due to it being unsecure, inefficient, etc.
     * @param _impl An address of the implementation to be revoked.
     * @param _sub Substitute address, if the version being revoked is the newest one.
     */
    function revokeImplementation(address _impl, address _sub)
        external
        ifAdmin
    {
        if (_implementation() == _impl) {
            _upgradeToAndCall(_sub, bytes(""), false);

            previousVersions[_sub] = true;
        }

        previousVersions[_impl] = false;
    }

	function _fallback() internal override {
        _delegate(_implementation());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IContractRegistry {
    function addressOf(
        bytes32 contractName
    ) external returns(address);
}

interface IBancorNetwork {
    function convertByPath(
        address[] memory _path, 
        uint256 _amount, 
        uint256 _minReturn, 
        address _beneficiary, 
        address _affiliateAccount, 
        uint256 _affiliateFee
    ) external payable returns (uint256);

    function rateByPath(
        address[] memory _path, 
        uint256 _amount
    ) external view returns (uint256);

    function conversionPath(
        IERC20 _sourceToken, 
        IERC20 _targetToken
    ) external view returns (address[] memory); 
}

pragma solidity ^0.8.0;

interface IStableSwap_PlainPool {
    function coins(uint256 i) external returns (address);
    function get_dy(int128 i, int128 j, uint256 _dx) view external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external;
}

interface IStableSwap_PlainPool_returnable {
    function coins(uint256 i)  external returns (address);
    function get_dy(int128 i, int128 j, uint256 _dx) view external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external returns (uint256);
}

interface IStableSwap_LendingPool {
    function coins(int128 i) external returns (address);
    function underlying_coins(int128 i) external returns (address);
    function get_dy(int128 i, int128 j, uint256 _dx) view external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external;
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external;
    function get_dy_underlying(int128 i, int128 j, uint256 dx) view external returns (uint256);
}

interface IStableSwap_MetaPool {
    function coins(uint256 i) external returns (address);
    function base_coins(uint256 i) external returns (address);
    function get_dy(int128 i, int128 j, uint256 _dx) view external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external returns(uint256);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 min_dy) payable external returns(uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx) view external returns (uint256);
}

abstract contract ICERC20 {
	bool public isCToken;
	
	address public underlying;

	function balanceOf(address owner) external view returns (uint256 balance) {}

    function redeem(uint redeemTokens) external returns (uint) {} // reedem ctoken to underlying asset
	function mint(uint mintAmount) external returns (uint) {} // get ctoken in exchange for underlying asset
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}