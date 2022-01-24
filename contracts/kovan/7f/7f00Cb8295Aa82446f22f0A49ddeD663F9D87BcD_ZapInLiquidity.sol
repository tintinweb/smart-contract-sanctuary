// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "contracts/APWineZap.sol";
import "contracts/interfaces/ILPToken.sol";

contract ZapInLiquidity is APWineZap {
    using SafeERC20Upgradeable for IERC20;

    ILPToken public lpToken;

    /* Struct */
    struct Pair {
        address tokenAddress; // first is always PT
        uint256[2] weights;
        uint256[2] balances;
        bool liquidityIsInitialized;
    }

    event ZappedInPTUnderlyingPool(
        IAMM _amm,
        address _sender,
        uint256 _IBTAmount,
        uint256 _poolAmountOut,
        uint256 _fytBalanceOut
    );

    event ZappedInAllPool(
        IAMM _amm,
        address _sender,
        uint256 _amount,
        uint256[2] _poolAmountOut
    );

    function __init__(
        IController _controller,
        IAMMRouterV1 _router,
        IDepositorRegistry _depositorRegistry,
        ILPToken _lpToken
    ) public virtual initializer {
        super.initialize(_controller, _router, _depositorRegistry);
        lpToken = _lpToken;
    }

    function zapInPTUnderlyingPool(
        IAMM _amm,
        uint256 _maxAmountIn, // max underlying amount
        uint256 _poolAmountOut
    ) public virtual isValidAmm(_amm) returns (uint256) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        uint256[] memory amountRatio = new uint256[](2);

        (amountRatio[0], amountRatio[1]) = getUnderlyingRatioForPTPool(_amm);

        uint256[] memory maxAmountsIn = new uint256[](2);

        uint256 _amountIn = getAmountInPTUnderlyingPool(_amm, _poolAmountOut);
        require(_amountIn <= _maxAmountIn, "ZapInLiquidity: invalid amount in");
        maxAmountsIn[0] = (_amountIn * (amountRatio[0])) / UNIT;

        {
            IERC20 underlying = IERC20(_amm.getUnderlyingOfIBTAddress());
            underlying.transferFrom(msg.sender, address(this), maxAmountsIn[0]);

            uint256 IBTsIn =
                depositorRegistry
                    .ZapDepositorsPerAMM(address(_amm))
                    .depositInProtocolFrom(
                    address(underlying),
                    (_amountIn * (amountRatio[1])) / UNIT,
                    msg.sender
                );

            controller.deposit(address(future), IBTsIn);
        }

        IERC20 pt = IERC20(_amm.getPTAddress());
        maxAmountsIn[1] = pt.balanceOf(address(this));

        // IERC20 underlying = IERC20(_amm.getUnderlyingOfIBTAddress());
        // pt.approve(address(_amm), maxAmountsIn[0]);
        // underlying.approve(address(_amm), maxAmountsIn[1]);
        _amm.addLiquidity(0, _poolAmountOut, maxAmountsIn);

        {
            IERC20 fyt = IERC20(_amm.getFYTAddress());
            fyt.transfer(msg.sender, maxAmountsIn[1]);
        }

        // send LP Tokens
        uint256 lpTokenId = _getLPTokenForPair(_amm, 0);

        uint256 LPBalance = lpToken.balanceOf(address(this), lpTokenId);
        lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            lpTokenId,
            LPBalance,
            ""
        );

        emit ZappedInPTUnderlyingPool(
            _amm,
            msg.sender,
            _amountIn,
            _poolAmountOut,
            maxAmountsIn[1]
        );
        return maxAmountsIn[1];
    }

    function _getLPTokenForPair(IAMM _amm, uint256 _pairId)
        internal
        view
        returns (uint256)
    {
        uint64 ammId = _amm.ammId();
        uint256 periodIndex = _amm.currentPeriodIndex();
        return _amm.getLPTokenId(ammId, periodIndex, _pairId);
    }

    function getUnderlyingRatioForPTPool(IAMM _amm)
        public
        view
        virtual
        returns (uint256, uint256)
    {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());
        IAMM.Pair memory pair = _amm.getPairWithID(0);
        uint256 PT_UNIT = 10**(IERC20(future.getIBTAddress()).decimals());
        uint256 ptPerUnderlyingDeposited =
            future.getPTPerAmountDeposited(
                future.convertUnderlyingtoIBT(PT_UNIT)
            ); // has ibt decimals

        uint256 underlyingInPTSideWeight =
            (pair.weights[0] * (PT_UNIT)) / (ptPerUnderlyingDeposited);
        return (underlyingInPTSideWeight, UNIT - underlyingInPTSideWeight);
    }

    function getUnderlyingRatioForAllPools(IAMM _amm)
        public
        view
        virtual
        returns (uint256, uint256)
    {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());
        uint256 PT_UNIT = 10**(IERC20(future.getIBTAddress()).decimals());

        (uint256 underlyingRatio, uint256 ptRatio) =
            getUnderlyingRatioForPTPool(_amm);
        uint256 fytPTRatio = _amm.getSpotPrice(1, 1, 0);

        return ((underlyingRatio * (fytPTRatio)) / (PT_UNIT), fytPTRatio);
    }

    function zapInAllPool(
        IAMM _amm,
        uint256 _amountIn, // underlying amount
        uint256[2] calldata minAmountsOut
    ) public returns (uint256[] memory, uint256) {
        (uint256 lp0AmountOut, uint256 lp1AmountOut) =
            getAmountsOutForZappInAllPool(_amm, _amountIn);
        {
            uint256[] memory amountPoolRatio = new uint256[](2);
            (
                amountPoolRatio[0],
                amountPoolRatio[1]
            ) = getUnderlyingRatioForAllPools(_amm);
            uint256[] memory ptPoolRatio = new uint256[](2);
            (ptPoolRatio[0], ptPoolRatio[1]) = getUnderlyingRatioForPTPool(
                _amm
            );

            require(
                lp0AmountOut >= minAmountsOut[0] &&
                    lp1AmountOut >= minAmountsOut[1],
                "ZapInLiquidity: Invalid Amount out"
            );

            // deposit in protocol
            uint256 underlyingTotalRatioInPTPool =
                (amountPoolRatio[0] * (ptPoolRatio[1])) / (UNIT);

            uint256 underlyingToDeposit =
                (((amountPoolRatio[0] - (underlyingTotalRatioInPTPool)) +
                    (amountPoolRatio[1])) * (_amountIn)) / (UNIT);

            uint256 IBTsIn =
                depositorRegistry
                    .ZapDepositorsPerAMM(address(_amm))
                    .depositInProtocolFrom(
                    _amm.getUnderlyingOfIBTAddress(),
                    underlyingToDeposit,
                    msg.sender
                );
            controller.deposit(_amm.getFutureAddress(), IBTsIn);

            // deposit in pool 0
            uint256[] memory maxAmountsIn = new uint256[](2);
            maxAmountsIn[0] = MAX_UINT256;
            maxAmountsIn[1] = MAX_UINT256;
            _amm.addLiquidity(0, lp0AmountOut, maxAmountsIn);

            // deposit in pool 1
            _amm.addLiquidity(1, lp1AmountOut, maxAmountsIn);
        }

        // send LP Tokens
        uint256 lpTokenId0 = _getLPTokenForPair(_amm, 0);
        uint256 LPBalance0 = lpToken.balanceOf(address(this), lpTokenId0);
        uint256 lpTokenId1 = _getLPTokenForPair(_amm, 1);
        uint256 LPBalance1 = lpToken.balanceOf(address(this), lpTokenId1);
        require(
            LPBalance0 >= lp0AmountOut || LPBalance1 >= lp1AmountOut,
            "ZapInLiquidity: Invalid Amount out"
        );
        lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            lpTokenId0,
            LPBalance0,
            ""
        );

        lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            lpTokenId1,
            LPBalance1,
            ""
        );

        emit ZappedInAllPool(
            _amm,
            msg.sender,
            _amountIn,
            [LPBalance0, LPBalance1]
        );
    }

    function getAmountInPTUnderlyingPool(IAMM _amm, uint256 _poolAmountOut)
        public
        view
        isValidAmm(_amm)
        returns (uint256)
    {
        IAMM.Pair memory pair = _amm.getPairWithID(0);

        uint256 lpTokenId = _getLPTokenForPair(_amm, 0);

        uint256 poolRatio =
            (_poolAmountOut * UNIT) / _amm.getTotalSupplyWithTokenId(lpTokenId);

        (, uint256 underlyingRatio) = getUnderlyingRatioForPTPool(_amm);
        uint256 underlyingAmount = (pair.balances[1] * (poolRatio)) / UNIT;
        uint256 balanceAmount =
            (underlyingAmount * underlyingRatio) /
                (UNIT - underlyingRatio) +
                underlyingAmount;
        return balanceAmount;
    }

    function getAmountsOutForZappInAllPool(IAMM _amm, uint256 _amount)
        public
        view
        returns (uint256, uint256)
    {
        uint256[] memory amountPoolRatio = new uint256[](2);
        (
            amountPoolRatio[0],
            amountPoolRatio[1]
        ) = getUnderlyingRatioForAllPools(_amm);
        (, uint256 ptPoolRatio) = getUnderlyingRatioForPTPool(_amm);

        // deposit in protocol
        uint256 underlyingTotalRatioInPTPool =
            (amountPoolRatio[0] * (ptPoolRatio)) / (UNIT);

        uint256 underlyingToDeposit =
            (((amountPoolRatio[0] - (underlyingTotalRatioInPTPool)) +
                (amountPoolRatio[1])) * (_amount)) / (UNIT);

        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        // Compute lpTokens amounts
        uint256 underlyingInFirstPool = _amount - underlyingToDeposit;

        IAMM.Pair memory pair0 = _amm.getPairWithID(1);
        uint256 lp0Amount = (underlyingInFirstPool * UNIT) / pair0.balances[0];

        IAMM.Pair memory pair1 = _amm.getPairWithID(1);
        uint256 fytBalance =
            future.getPTPerAmountDeposited(
                future.convertUnderlyingtoIBT(underlyingToDeposit)
            );
        uint256 lp1Amount = (fytBalance * UNIT) / pair1.balances[1];
        return (lp0Amount, lp1Amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "contracts/interfaces/IController.sol";
import "contracts/interfaces/IAMMRouterV1.sol";
import "contracts/interfaces/IFutureVault.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/interfaces/IAMMRegistry.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IAMM.sol";
import "contracts/interfaces/IZapDepositor.sol";
import "contracts/interfaces/IDepositorRegistry.sol";

abstract contract APWineZap is Initializable {
    using SafeERC20Upgradeable for IERC20;
    uint256 internal constant UNIT = 10**18;
    uint256 internal constant MAX_UINT256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IAMMRegistry public registry;
    IController public controller;
    IAMMRouterV1 public router;
    IDepositorRegistry public depositorRegistry;

    modifier isValidAmm(IAMM _amm) {
        require(
            registry.isRegisteredAMM(address(_amm)),
            "AMMRouter: invalid amm address"
        );
        _;
    }

    event RegistrySet(IAMMRegistry _registry);
    event AllTokenApprovalUpdatedForAMM(IAMM _amm);
    event FYTApprovalUpdatedForAMM(IAMM _amm);
    event IBTApprovalUpdatedForDepositor(
        IAMM _amm,
        IZapDepositor _zapDepositor
    );

    function initialize(
        IController _controller,
        IAMMRouterV1 _router,
        IDepositorRegistry _depositorRegistry
    ) public virtual initializer {
        registry = _depositorRegistry.registry();
        controller = _controller;
        router = _router;
        depositorRegistry = _depositorRegistry;
    }

    function _getUnderlyingAndDepositToProtocol(IAMM _amm, uint256 _amount)
        internal
        returns (uint256)
    {
        address underlyingAddress = _amm.getUnderlyingOfIBTAddress();
        IERC20(underlyingAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); // get IBT from caller

        return
            depositorRegistry
                .ZapDepositorsPerAMM(address(_amm))
                .depositInProtocol(underlyingAddress, _amount);
    }

    function updateAllTokensApprovalForAMM(IAMM _amm)
        external
        isValidAmm(_amm)
    {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        IERC20(future.getIBTAddress()).approve(
            address(controller),
            MAX_UINT256
        ); // Approve controller for IBT

        IERC20(future.getPTAddress()).approve(address(router), MAX_UINT256); // Approve router for PT

        IERC20(future.getFYTofPeriod(future.getCurrentPeriodIndex())).approve(
            address(router),
            MAX_UINT256
        ); // Approve router for FYT
        emit AllTokenApprovalUpdatedForAMM(_amm);
    }

    function updateFYTApprovalForAMM(IAMM _amm) external isValidAmm(_amm) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());
        IERC20(future.getFYTofPeriod(future.getCurrentPeriodIndex())).approve(
            address(router),
            MAX_UINT256
        ); // Approve router for FYT
        emit FYTApprovalUpdatedForAMM(_amm);
    }

    function updateIBTApprovalForDepositor(IAMM _amm)
        external
        isValidAmm(_amm)
    {
        IZapDepositor zapDepositor =
            depositorRegistry.ZapDepositorsPerAMM(address(_amm));
        IERC20(_amm.getIBTAddress()).approve(
            address(zapDepositor),
            MAX_UINT256
        );

        emit IBTApprovalUpdatedForDepositor(_amm, zapDepositor);
    }
}

// SPDX-License-Identifier: BUSL-1.1

import "contracts/interfaces/IERC1155.sol";

pragma solidity 0.8.11;

interface ILPToken is IERC1155 {
    function amms(uint64 _ammId) external view returns (address);

    /**
     * @notice Getter for AMM id
     * @param _id the id of the LP Token
     * @return AMM id
     */
    function getAMMId(uint256 _id) external pure returns (uint64);

    /**
     * @notice Getter for PeriodIndex
     * @param _id the id of the LP Token
     * @return period index
     */
    function getPeriodIndex(uint256 _id) external pure returns (uint64);

    /**
     * @notice Getter for PairId
     * @param _id the index of the Pair
     * @return pair index
     */
    function getPairId(uint256 _id) external pure returns (uint32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IController {
    /* Getters */

    function STARTING_DELAY() external view returns (uint256);

    /* Future Settings Setters */

    /**
     * @notice Change the delay for starting a new period
     * @param _startingDelay the new delay (+-) to start the next period
     */
    function setPeriodStartingDelay(uint256 _startingDelay) external;

    /**
     * @notice Set the next period switch timestamp for the future with corresponding duration
     * @param _periodDuration the duration of a period
     * @param _nextPeriodTimestamp the next period switch timestamp
     */
    function setNextPeriodSwitchTimestamp(
        uint256 _periodDuration,
        uint256 _nextPeriodTimestamp
    ) external;

    /* User Methods */

    /**
     * @notice Deposit funds into ongoing period
     * @param _futureVault the address of the future to be deposit the funds in
     * @param _amount the amount to deposit on the ongoing period
     * @dev part of the amount depostied will be used to buy back the yield already generated proportionaly to the amount deposited
     */
    function deposit(address _futureVault, uint256 _amount) external;

    /**
     * @notice Withdraw deposited funds from APWine
     * @param _futureVault the address of the future to withdraw the IBT from
     * @param _amount the amount to withdraw
     */
    function withdraw(address _futureVault, uint256 _amount) external;

    /**
     * @notice Claim FYT of the msg.sender
     * @param _futureVault the future from which to claim the FYT
     */
    function claimFYT(address _futureVault) external;

    /**
     * @notice Getter for the registry address of the protocol
     * @return the address of the protocol registry
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the symbol of the PT of one future
     * @param _ibtSymbol the IBT of the external protocol
     * @param _platform the external protocol name
     * @param _periodDuration the duration of the periods for the future
     * @return the generated symbol of the PT
     */
    function getFutureIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) external pure returns (string memory);

    /**
     * @notice Getter for the symbol of the FYT of one future
     * @param _ptSymbol the PT symbol for this future
     * @param _periodDuration the duration of the periods for this future
     * @return the generated symbol of the FYT
     */
    function getFYTSymbol(string memory _ptSymbol, uint256 _periodDuration)
        external
        view
        returns (string memory);

    /**
     * @notice Getter for the period index depending on the period duration of the future
     * @param _periodDuration the periods duration
     * @return the period index
     */
    function getPeriodIndex(uint256 _periodDuration)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for beginning timestamp of the next period for the futures with a defined periods duration
     * @param _periodDuration the periods duration
     * @return the timestamp of the beginning of the next period
     */
    function getNextPeriodStart(uint256 _periodDuration)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the next performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the next performance fee factor of the futureVault
     */
    function getNextPerformanceFeeFactor(address _futureVault)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the performance fee factor of the futureVault
     */
    function getCurrentPerformanceFeeFactor(address _futureVault)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the list of future durations registered in the contract
     * @return the list of futures duration
     */
    function getDurations() external view returns (uint256[] memory);

    /**
     * @notice Register a newly created future in the registry
     * @param _futureVault the address of the new future
     */
    function registerNewFutureVault(address _futureVault) external;

    /**
     * @notice Unregister a future from the registry
     * @param _futureVault the address of the future to unregister
     */
    function unregisterFutureVault(address _futureVault) external;

    /**
     * @notice Start all the futures that have a defined periods duration to synchronize them
     * @param _periodDuration the periods duration of the futures to start
     */
    function startFuturesByPeriodDuration(uint256 _periodDuration) external;

    /**
     * @notice Getter for the futures by periods duration
     * @param _periodDuration the periods duration of the futures to return
     */
    function getFuturesWithDuration(uint256 _periodDuration)
        external
        view
        returns (address[] memory);

    /**
     * @notice Claim the FYTs of the corresponding futures
     * @param _user the address of the user
     * @param _futureVaults the addresses of the futures to claim the fyts from
     */
    function claimSelectedFYTS(address _user, address[] memory _futureVaults)
        external;

    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address); // OZ ACL getter

    /**
     * @notice Getter for the future deposits state
     * @param _futureVault the address of the future
     * @return true is new deposits are paused, false otherwise
     */
    function isDepositsPaused(address _futureVault)
        external
        view
        returns (bool);

    /**
     * @notice Getter for the future withdrawals state
     * @param _futureVault the address of the future
     * @return true is new withdrawals are paused, false otherwise
     */
    function isWithdrawalsPaused(address _futureVault)
        external
        view
        returns (bool);

    /**
     * @notice Getter for the future period state
     * @param _futureVault the address of the future
     * @return true if the future is set to be terminated
     */
    function isFutureSetToBeTerminated(address _futureVault)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
import "./IAMM.sol";
import "./IAMMRegistry.sol";

/**
 * IAMMRouter is an on-chain router designed to batch swaps for the APWine AMM.
 * It can be used to facilitate swaps and save gas fees as opposed to executing multiple transactions.
 * Example: swap from pair 0 to pair 1, from token 0 to token 1 then token 1 to token 0.
 * One practical use-case would be swapping from FYT to underlying, which would otherwise not be possible natively.
 */
interface IAMMRouterV1 {
    /**
     * @dev execute a swapExactAmountIn given pair and token paths. Works just like the regular swapExactAmountIn from AMM.
     *
     * @param _amm the address of the AMM instance to execute the swap on
     * @param _pairPath a list of N pair indices, where N is the number of swaps to execute
     * @param _tokenPath a list of 2 * N token indices corresponding to the swaps path. For swap I, tokenIn = 2*I, tokenOut = 2*I + 1
     * @param _tokenAmountIn the exact input token amount
     * @param _minAmountOut the minimum amount of output tokens to receive, call will revert if not reached
     * @param _to the recipient address
     * @param _deadline the absolute deadline, in seconds, to prevent outdated swaps from being executed
     * @param _referralRecipient the recipient address for the referral
     */
    function swapExactAmountIn(
        IAMM _amm,
        uint256[] calldata _pairPath,
        uint256[] calldata _tokenPath,
        uint256 _tokenAmountIn,
        uint256 _minAmountOut,
        address _to,
        uint256 _deadline,
        address _referralRecipient
    ) external returns (uint256 tokenAmountOut);

    /**
     * @dev execute a swapExactAmountOut given pair and token paths. Works just like the regular swapExactAmountOut from AMM.
     *
     * @param _amm the address of the AMM instance to execute the swap on
     * @param _pairPath a list of N pair indices, where N is the number of swaps to execute
     * @param _tokenPath a list of 2 * N token indices corresponding to the swaps path. For swap I, tokenIn = 2*I, tokenOut = 2*I + 1
     * @param _maxAmountIn the maximum amount of input tokens needed to send, call will revert if not reached
     * @param _tokenAmountOut the exact out token amount
     * @param _to the recipient address
     * @param _deadline the absolute deadline, in seconds, to prevent outdated swaps from being executed
     * @param _referralRecipient the recipient address for the referral
     */
    function swapExactAmountOut(
        IAMM _amm,
        uint256[] calldata _pairPath,
        uint256[] calldata _tokenPath,
        uint256 _maxAmountIn,
        uint256 _tokenAmountOut,
        address _to,
        uint256 _deadline,
        address _referralRecipient
    ) external returns (uint256 tokenAmountIn);

    /**
     * @dev execute a getSpotPrice given pair and token paths. Works just like the regular getSpotPrice from AMM.
     *
     * @param _amm the address of the AMM instance to execute the spotPrice on
     * @param _pairPath a list of N pair indices, where N is the number of getSpotPrice to execute
     * @param _tokenPath a list of 2 * N token indices corresponding to the getSpotPrice path. For getSpotPrice I, tokenIn = 2*I, tokenOut = 2*I + 1
     */
    function getSpotPrice(
        IAMM _amm,
        uint256[] calldata _pairPath,
        uint256[] calldata _tokenPath
    ) external returns (uint256 spotPrice);

    /**
     * @dev execute a getAmountIn given pair and token paths. Works just like the regular calcInAndSpotGivenOut from AMM.
     *
     * @param _amm the address of the AMM instance to execute the getAmountIn on
     * @param _pairPath a list of N pair indices, where N is the number of getAmountIn to execute
     * @param _tokenPath a list of 2 * N token indices corresponding to the getAmountIn path. For getAmountIn I, tokenIn = 2*I, tokenOut = 2*I + 1
     * @param _tokenAmountOut the exact out token amount
     */
    function getAmountIn(
        IAMM _amm,
        uint256[] calldata _pairPath,
        uint256[] calldata _tokenPath,
        uint256 _tokenAmountOut
    ) external view returns (uint256 tokenAmountIn);

    /**
     * @dev execute a getAmountOut given pair and token paths. Works just like the regular calcInAndSpotGivenOut from AMM.
     *
     * @param _amm the address of the AMM instance to execute the getAmountOut on
     * @param _pairPath a list of N pair indices, where N is the number of getAmountOut to execute
     * @param _tokenPath a list of 2 * N token indices corresponding to the getAmountOut path. For getAmountOut I, tokenIn = 2*I, tokenOut = 2*I + 1
     * @param _tokenAmountIn the exact input token amount
     */
    function getAmountOut(
        IAMM _amm,
        uint256[] calldata _pairPath,
        uint256[] calldata _tokenPath,
        uint256 _tokenAmountIn
    ) external view returns (uint256 tokenAmountOut);

    function registry() external view returns (IAMMRegistry);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "contracts/interfaces/IPT.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/interfaces/IFutureWallet.sol";

interface IFutureVault {
    /* Events */
    event NewPeriodStarted(uint256 _newPeriodIndex);
    event FutureWalletSet(address _futureWallet);
    event RegistrySet(IRegistry _registry);
    event FundsDeposited(address _user, uint256 _amount);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PTSet(IPT _pt);
    event LiquidityTransfersPaused();
    event LiquidityTransfersResumed();
    event DelegationCreated(
        address _delegator,
        address _receiver,
        uint256 _amount
    );
    event DelegationRemoved(
        address _delegator,
        address _receiver,
        uint256 _amount
    );

    /* Params */
    /**
     * @notice Getter for the PERIOD future parameter
     * @return returns the period duration of the future
     */
    function PERIOD_DURATION() external view returns (uint256);

    /**
     * @notice Getter for the PLATFORM_NAME future parameter
     * @return returns the platform of the future
     */
    function PLATFORM_NAME() external view returns (string memory);

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() external;

    /**
     * @notice Update the state of the user and mint claimable pt
     * @param _user user adress
     */
    function updateUserState(address _user) external;

    /**
     * @notice Send the user their owed FYT (and pt if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user, uint256 _amount) external;

    /**
     * @notice Deposit funds into ongoing period
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev part of the amount deposited will be used to buy back the yield already generated proportionally to the amount deposited
     */
    function deposit(address _user, uint256 _amount) external;

    /**
     * @notice Sender unlocks the locked funds corresponding to their pt holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdraw(address _user, uint256 _amount) external;

    /**
     * @notice Create a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to delegate
     */
    function createFYTDelegationTo(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Remove a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to remove from the delegation
     */
    function withdrawFYTDelegationFrom(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /* Getters */

    /**
     * @notice Getter the total number of FYTs on address is delegating
     * @param _delegator the delegating address
     * @return totalDelegated the number of FYTs delegated
     */
    function getTotalDelegated(address _delegator)
        external
        view
        returns (uint256 totalDelegated);

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for current period index
     * @return current period index
     * @dev index starts at 1
     */
    function getCurrentPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for the amount of pt that the user can claim
     * @param _user user to check the check the claimable pt of
     * @return the amount of pt claimable by the user
     */
    function getClaimablePT(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount (in underlying) of premium redeemable with the corresponding amount of fyt/pt to be burned
     * @param _user user adress
     * @return premiumLocked the premium amount unlockage at this period (in underlying), amountRequired the amount of pt/fyt required for that operation
     */
    function getUserEarlyUnlockablePremium(address _user)
        external
        view
        returns (uint256 premiumLocked, uint256 amountRequired);

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodIndex period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodIndex)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the yield currently generated by one pt for the current period
     * @return the amount of yield (in IBT) generated during the current period
     */
    function getUnrealisedYieldPerPT() external view returns (uint256);

    /**
     * @notice Getter for the number of pt that can be minted for an amoumt deposited now
     * @param _amount the amount to of IBT to deposit
     * @return the number of pt that can be minted for that amount
     */
    function getPTPerAmountDeposited(uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for premium in underlying tokens that can be redeemed at the end of the period of the deposit
     * @param _amount the amount of underlying deposited
     * @return the number of underlying of the ibt deposited that will be redeemable
     */
    function getPremiumPerUnderlyingDeposited(uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for total underlying deposited in the vault
     * @return the total amount of funds deposited in the vault (in underlying)
     */
    function getTotalUnderlyingDeposited() external view returns (uint256);

    /**
     * @notice Getter for the total yield generated during one period
     * @param _periodID the period id
     * @return the total yield in underlying value
     */
    function getYieldOfPeriod(uint256 _periodID)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() external view returns (address);

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for future pt address
     * @return pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex)
        external
        view
        returns (address);

    /**
     * @notice Getter for the terminated state of the future
     * @return true if this vault is terminated
     */
    function isTerminated() external view returns (bool);

    /**
     * @notice Getter for the performance fee factor of the current period
     * @return the performance fee factor of the futureVault
     */
    function getPerformanceFeeFactor() external view returns (uint256);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the vault
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllVaultRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemVaultRewards(address _rewardToken) external;

    /**
     * @notice Add a token to the list of reward tokens
     * @param _token the reward token to add to the list
     * @dev the token must be different than the ibt
     */
    function addRewardsToken(address _token) external;

    /**
     * @notice Getter to check if a token is in the reward tokens list
     * @param _token the token to check if it is in the list
     * @return true if the token is a reward token
     */
    function isRewardToken(address _token) external view returns (bool);

    /**
     * @notice Getter for the reward token at an index
     * @param _index the index of the reward token in the list
     * @return the address of the token at this index
     */
    function getRewardTokenAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for the size of the list of reward tokens
     * @return the number of token in the list
     */
    function getRewardTokensCount() external view returns (uint256);

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;

    /* Admin functions */

    /**
     * @notice Set futureWallet address
     */
    function setFutureWallet(IFutureWallet _futureWallet) external;

    /**
     * @notice Set Registry
     */
    function setRegistry(IRegistry _registry) external;

    /**
     * @notice Pause liquidity transfers
     */
    function pauseLiquidityTransfers() external;

    /**
     * @notice Resume liquidity transfers
     */
    function resumeLiquidityTransfers() external;

    /**
     * @notice Convert an amount of IBTs in its equivalent in underlying tokens
     * @param _amount the amount of IBTs
     * @return the corresponding amount of underlying
     */
    function convertIBTToUnderlying(uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @notice Convert an amount of underlying tokens in its equivalent in IBTs
     * @param _amount the amount of underlying tokens
     * @return the corresponding amount of IBTs
     */
    function convertUnderlyingtoIBT(uint256 _amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

interface IRegistry {
    /* Setters */
    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) external;

    /**
     * @notice Setter for the APWine IBT logic address
     * @param _PTLogic the address of the new APWine IBT logic
     */
    function setPTLogic(address _PTLogic) external;

    /**
     * @notice Setter for the APWine FYT logic address
     * @param _FYTLogic the address of the new APWine FYT logic
     */
    function setFYTLogic(address _FYTLogic) external;

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Getter for the token factory address
     * @return the token factory address
     */
    function getTokensFactoryAddress() external view returns (address);

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getPTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() external view returns (address);

    /* Futures */
    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFutureVault(address _future) external;

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFutureVault(address _future) external;

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFutureVault(address _future)
        external
        view
        returns (bool);

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureVaultAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future registered
     * @return the number of future registered
     */
    function futureVaultCount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

/**
 * @title AMM Registry interface
 * @notice Keeps a record of all Future / Pool pairs
 */
interface IAMMRegistry {
    /**
     * @notice Initializer of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(address _admin) external;

    /* Setters */

    /**
     * @notice Setter for the AMM pools
     * @param _futureVaultAddress the future vault address
     * @param _ammPool the AMM pool address
     */
    function setAMMPoolByFuture(address _futureVaultAddress, address _ammPool)
        external;

    /**
     * @notice Register the AMM pools
     * @param _ammPool the AMM pool address
     */
    function setAMMPool(address _ammPool) external;

    /**
     * @notice Remove an AMM Pool from the registry
     * @param _ammPool the address of the pool to remove from the registry
     */
    function removeAMMPool(address _ammPool) external;

    /* Getters */
    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getFutureAMMPool(address _futureVaultAddress)
        external
        view
        returns (address);

    function isRegisteredAMM(address _ammAddress) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20 is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

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

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

interface IAMM {
    /* Struct */
    struct Pair {
        address tokenAddress; // first is always PT
        uint256[2] weights;
        uint256[2] balances;
        bool liquidityIsInitialized;
    }

    /**
     * @notice finalize the initialization of the amm
     * @dev must be called during the first period the amm is supposed to be active
     */
    function finalize() external;

    /**
     * @notice switch period
     * @dev must be called after each new period switch
     * @dev the switch will auto renew part of the tokens and update the weights accordingly
     */
    function switchPeriod() external;

    /**
     * @notice toggle amm pause for pausing/resuming all user functionalities
     */
    function togglePauseAmm() external;

    /**
     * @notice Withdraw expired LP tokens
     */
    function withdrawExpiredToken(address _user, uint256 _lpTokenId) external;

    /**
     * @notice Getter for redeemable expired tokens info
     * @param _user the address of the user to check the redeemable tokens of
     * @param _lpTokenId the lp token id
     * @return the amount, the period id and the pair id of the expired tokens of the user
     */
    function getExpiredTokensInfo(address _user, uint256 _lpTokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function swapExactAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        address _to
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
     * @notice Create liquidity on the pair setting an initial price
     */
    function createLiquidity(uint256 _pairID, uint256[2] memory _tokenAmounts)
        external;

    function addLiquidity(
        uint256 _pairID,
        uint256 _poolAmountOut,
        uint256[] calldata _maxAmountsIn
    ) external;

    function removeLiquidity(
        uint256 _pairID,
        uint256 _poolAmountIn,
        uint256[] calldata _minAmountsOut
    ) external;

    function joinSwapExternAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinSwapPoolAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _poolAmountOut,
        uint256 _maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitSwapPoolAmountIn(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _poolAmountIn,
        uint256 _minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitSwapExternAmountOut(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function setSwappingFees(uint256 _swapFee) external;

    /* Getters */
    function calcOutAndSpotGivenIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut
    ) external view returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function calcInAndSpotGivenOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut
    ) external view returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
     * @notice Getter for the spot price of a pair
     * @param _pairID the id of the pair
     * @param _tokenIn the id of the tokens sent
     * @param _tokenOut the id of the tokens received
     * @return the sport price of the pair
     */
    function getSpotPrice(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenOut
    ) external view returns (uint256);

    /**
     * @notice Getter for the address of the corresponding future vault
     * @return the address of the future vault
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice Getter for the pt address
     * @return the pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for the address of the underlying token of the ibt
     * @return the address of the underlying token of the ibt
     */
    function getUnderlyingOfIBTAddress() external view returns (address);

    /**
     * @notice Getter for the fyt address
     * @return the fyt address
     */
    function getFYTAddress() external view returns (address);

    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for the PT weight in the first pair (0)
     * @return the weight of the pt
     */
    function getPTWeightInPair() external view returns (uint256);

    function getPairWithID(uint256 _pairID) external view returns (Pair memory);

    function getLPTokenId(
        uint256 _ammId,
        uint256 _periodIndex,
        uint256 _pairID
    ) external pure returns (uint256);

    function ammId() external view returns (uint64);

    function currentPeriodIndex() external view returns (uint256);

    function getTotalSupplyWithTokenId(uint256 _tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

interface IZapDepositor {
    /**
     * @notice Deposit a defined underling in the depositor protocol
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @return the amount ibt generated and sent back to the caller
     */
    function depositInProtocol(address _token, uint256 _underlyingAmount)
        external
        returns (uint256);

    /**
     * @notice Deposit a defined underling in the depositor protocol from the caller adderss
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @param _from the address from which the underlying need to be pulled
     * @return the amount ibt generated
     */
    function depositInProtocolFrom(
        address _token,
        uint256 _underlyingAmount,
        address _from
    ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "contracts/interfaces/IZapDepositor.sol";
import "contracts/interfaces/IAMM.sol";
import "contracts/interfaces/IAMMRegistry.sol";

interface IDepositorRegistry {
    event ZapDepositorSet(address _amm, IZapDepositor _zapDepositor);

    function ZapDepositorsPerAMM(address _address)
        external
        view
        returns (IZapDepositor);

    function registry() external view returns (IAMMRegistry);

    function setZapDepositor(address _amm, IZapDepositor _zapDepositor)
        external;

    function isRegisteredZap(address _zapAddress) external view returns (bool);

    function addZap(address _zapAddress) external returns (bool);

    function removeZap(address _zapAddress) external returns (bool);

    function zapLength() external view returns (uint256);

    function zapAt(uint256 _index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "contracts/interfaces/IERC20.sol";

interface IPT is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @notice Returns the current balance of one user (without the claimable amount)
     * @param account the address of the account to check the balance of
     * @return the current pt balance of this address
     */
    function recordedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the current balance of one user including the pt that were not claimed yet
     * @param account the address of the account to check the balance of
     * @return the total pt balance of one address
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256);

    /**
     * @notice Getter for the future vault link to this pt
     * @return the address of the future vault
     */
    function futureVault() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IFutureWallet {
    /* Events */

    event YieldRedeemed(address _user, uint256 _periodIndex);
    event WithdrawalsPaused();
    event WithdrawalsResumed();

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) external;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) external;

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _user the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _user)
        external
        view
        returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureVaultAddress() external view returns (address);

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() external view returns (address);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the future wallet
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllWalletRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemWalletRewards(address _rewardToken) external;

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function grantRole(bytes32 role, address account) external;

    function MINTER_ROLE() external view returns (bytes32);

    function mint(
        address to,
        uint64 _ammId,
        uint64 _periodIndex,
        uint32 _pairId,
        uint256 amount,
        bytes memory data
    ) external returns (uint256 id);

    function burnFrom(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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