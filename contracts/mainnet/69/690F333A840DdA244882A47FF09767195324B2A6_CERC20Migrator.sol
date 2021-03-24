// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

// Import Compound components
import "./external/compound/CERC20.sol";
import "./external/compound/CEther.sol";
import "./external/compound/Comptroller.sol";
import "./external/compound/UniswapAnchoredView.sol";

// Import AAVE components
import "./external/aave/FlashLoanReceiverBase.sol";
import "./external/aave/ILendingPoolAddressesProvider.sol";

// Import KeeperDAO components
import "./external/keeperdao/ILiquidityPool.sol";

import "./external/IWETH.sol";


contract CERC20Migrator is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;

    event Migrated(address indexed account, uint256 underlyingV1, uint256 underlyingV2);

    event GasUsed(address indexed account, uint256 gas, uint256 gasPrice, uint256 dollarsPerETH);

    address payable private constant KEEPER_LIQUIDITY_POOL = payable(0x35fFd6E268610E764fF6944d07760D0EFe5E40E5);
    address private constant KEEPER_BORROW_PROXY = 0xde92742213FEa5f78c6840B6EcBf214115ea8002;
    address private constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    Comptroller public immutable COMPTROLLER;

    UniswapAnchoredView public immutable PRICEORACLE;

    address public immutable UNDERLYING;

    address public immutable CTOKENV1;

    address public immutable CTOKENV2;

    receive() external payable {}

    constructor(ILendingPoolAddressesProvider _provider, Comptroller _comptroller, address _cTokenV1, address _cTokenV2) FlashLoanReceiverBase(_provider) {
        COMPTROLLER = _comptroller;
        PRICEORACLE = UniswapAnchoredView(_comptroller.oracle());

        address underlying = CERC20Storage(_cTokenV1).underlying();
        require(underlying == CERC20Storage(_cTokenV2).underlying(), "cTokens have different underlying ERC20s");
        UNDERLYING = underlying;
        CTOKENV1 = _cTokenV1;
        CTOKENV2 = _cTokenV2;

        // Enter the cETH market now so that we don't have to do it ad-hoc during KeeperDAO loans
        address[] memory markets = new address[](1);
        markets[0] = CETH;
        _comptroller.enterMarkets(markets);
    }

    modifier gasTracked() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft(); // don't account for msg.data.length, as that could be manipulated
        emit GasUsed(msg.sender, gasSpent, tx.gasprice, PRICEORACLE.price("ETH"));
    }

    /**
     * @notice Like `migrate()`, allows msg.sender to migrate collateral from v1 to v2,
     *      so long as msg.sender has already approved this contract to transfer their v1.
     *
     *      This version of the function returns early if it detects that msg.sender can't
     *      be migrated. It also looks for UNDERLYING dust after the transaction, and if any
     *      exists it will be sent back to msg.sender
     *
     * @param gasOptimized When true, borrow UNDERLYING directly (from AAVE, 0.09% fee).
     *      When false, get UNDERLYING indirectly (from KeeperDAO, higher gas usage).
     */
    function migrateWithExtraChecks(bool gasOptimized) external {
        if (CERC20(CTOKENV1).balanceOf(msg.sender) == 0) return;

        ( , , uint256 shortfall) = COMPTROLLER.getAccountLiquidity(msg.sender);
        if (shortfall != 0) return;

        address[] memory enteredMarkets = COMPTROLLER.getAssetsIn(msg.sender);
        for (uint256 i = 0; i < enteredMarkets.length; i++) {
            if (enteredMarkets[i] != CTOKENV2) continue;

            migrate(gasOptimized);

            uint256 dust = IERC20(UNDERLYING).balanceOf(address(this));
            if (dust != 0) IERC20(UNDERLYING).transfer(msg.sender, dust);
        }
    }

    /**
     * @notice Allows msg.sender to migrate collateral from v1 to v2, so long as msg.sender has
     *      already approved this contract to transfer their v1.
     *
     *      WARNING: This is made possible by AAVE flash loans, which means migration will incur
     *      a 0.09% loss in underlying UNDERLYING if gasOptimized=true
     *
     * @param gasOptimized When true, borrow UNDERLYING directly (from AAVE, 0.09% fee).
     *      When false, get UNDERLYING indirectly (from KeeperDAO, higher gas usage).
     */
    function migrate(bool gasOptimized) public gasTracked {
        uint256 supplyV1 = CERC20(CTOKENV1).balanceOf(msg.sender);
        require(supplyV1 > 0, "0 balance no migration needed");
        require(IERC20(CTOKENV1).allowance(msg.sender, address(this)) >= supplyV1, "Please approve for v1 cToken transfers");

        // fetch the flash loan premium from AAVE. (ex. 0.09% fee would show up as `9` here)
        uint256 premium = LENDING_POOL.FLASHLOAN_PREMIUM_TOTAL();
        uint256 exchangeRateV1 = CERC20(CTOKENV1).exchangeRateCurrent();

        uint supplyV2Underlying;

        if (gasOptimized) {
            supplyV2Underlying = supplyV1 * exchangeRateV1 * (10_000 - premium) / 1e22;
            bytes memory params = abi.encode(msg.sender, supplyV1);

            initiateAAVEFlashLoan(UNDERLYING, supplyV2Underlying, params);

        } else {
            supplyV2Underlying = supplyV1 * exchangeRateV1 / 1e18;
            ( , uint256 collatFact, ) = COMPTROLLER.markets(CETH);
            uint256 dollarsPerETH = PRICEORACLE.getUnderlyingPrice(CETH);
            uint256 dollarsPerBTC = PRICEORACLE.getUnderlyingPrice(CTOKENV1);
            uint256 requiredETH = supplyV2Underlying * 1e18 * dollarsPerBTC / dollarsPerETH / collatFact;
            supplyV2Underlying -= 1;

            initiateKeeperFlashloan(msg.sender, requiredETH, supplyV1, supplyV2Underlying);
        }
        
        emit Migrated(msg.sender, supplyV1 * exchangeRateV1 / 1e18, supplyV2Underlying);
    }

    /// @dev When this is called, contract's UNDERLYING balance should be _supplyV2Underlying. After this has run,
    ///      the contract's UNDERLYING balance will be _supplyV1 * exchangeRateV1.
    function flashloanInner(
        address _account,
        uint256 _supplyV1,
        uint256 _supplyV2Underlying
    ) internal {
        // Mint v2 tokens and send them to _account
        IERC20(UNDERLYING).approve(CTOKENV2, _supplyV2Underlying);
        require(CERC20(CTOKENV2).mint(_supplyV2Underlying) == 0, "Failed to mint v2 cToken");
        require(IERC20(CTOKENV2).transfer(_account, IERC20(CTOKENV2).balanceOf(address(this))), "Failed to send v2 cToken");

        // Pull and redeem v1 tokens from _account
        require(IERC20(CTOKENV1).transferFrom(_account, address(this), _supplyV1), "Failed to receive v1 cToken");
        require(CERC20(CTOKENV1).redeem(_supplyV1) == 0, "Failed to redeem v1 cToken");
    }

    /// @dev Meant to be called by AAVE Lending Pool, but be careful since anyone might call it
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(LENDING_POOL), "Flash loan initiated by outsider");
        require(initiator == address(this), "Flash loan initiated by outsider");
        (address account, uint256 supplyV1) = abi.decode(params, (address, uint256));

        // Execute main migration logic
        flashloanInner(account, supplyV1, amounts[0]);
        
        // Get ready to repay flashloan
        IERC20(UNDERLYING).approve(address(LENDING_POOL), amounts[0] + premiums[0]);
        // Finish up
        return true;
    }

    function initiateAAVEFlashLoan(address _token, uint256 _amount, bytes memory params) internal {
        address[] memory assets = new address[](1);
        assets[0] = _token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 = no debt, 1 = stable, 2 = variable

        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
    }

    /// @dev Meant to be called by KeeperDAO Borrow Proxy, but be careful since anyone might call it
    function keeperFlashloanCallback(address _account, uint256 _amountETH, uint256 _supplyV1, uint256 _supplyV2Underlying) external {
        require(msg.sender == KEEPER_BORROW_PROXY, "Flashloan initiated by outsider");

        // Use the borrowed ETH to get UNDERLYING
        CEther(CETH).mint{value: _amountETH}();
        require(CERC20(CTOKENV2).borrow(_supplyV2Underlying) == 0, "Failed to borrow UNDERLYING");

        // Execute main migration logic
        flashloanInner(_account, _supplyV1, _supplyV2Underlying);

        // Get ready to repay flashloan (get original ETH back)
        IERC20(UNDERLYING).approve(CTOKENV2, _supplyV2Underlying);
        require(CERC20(CTOKENV2).repayBorrow(_supplyV2Underlying) == 0, "Failed to repay UNDERLYING borrow");
        require(CEther(CETH).redeemUnderlying(_amountETH) == 0, "Failed to retrieve original ETH");
        // Finish up
        KEEPER_LIQUIDITY_POOL.send(_amountETH + 1);
    }

    function initiateKeeperFlashloan(address _account, uint256 _amountETH, uint256 _supplyV1, uint256 _supplyV2Underlying) internal {
        ILiquidityPool(KEEPER_LIQUIDITY_POOL).borrow(
            // Address of the token we want to borrow. Using this address
            // means that we want to borrow ETH.
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            // The amount of WEI that we will borrow. We have to return at least
            // more than this amount.
            _amountETH,
            // Encode the callback into calldata. This will be used to call a
            // function on this contract.
            abi.encodeWithSelector(
                // Function selector of the callback function.
                this.keeperFlashloanCallback.selector,
                // Function arguments
                _account,
                _amountETH,
                _supplyV1,
                _supplyV2Underlying
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint);
    function deposit() external payable;
    function transfer(address recipient, uint amount) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IFlashLoanReceiver.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    ILendingPool public immutable LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CERC20 {
    function accrueInterest() external returns (uint);
    function accrualBlockNumber() external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address collateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint error, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa);

    function comptroller() external view returns (address);
}

interface CERC20Storage {
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CEther {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function balanceOfUnderlying(address account) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Comptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function closeFactorMantissa() external view returns (uint);
    function liquidationIncentiveMantissa() external view returns (uint);

    function oracle() external view returns (address);

    function markets(address cTokenAddress) external view returns (bool, uint, bool);
    function getAllMarkets() external view returns (address[] memory);

    function seizeGuardianPaused() external view returns (bool);

    function redeemAllowed(address cTokenAddress, address account, uint amount) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface UniswapAnchoredView {
    function price(string calldata symbol) external view returns (uint);
    function getUnderlyingPrice(address cToken) external view returns (uint);
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external;

    function priceData() external view returns (address);
    function reporter() external view returns (address);

    function getTokenConfigByCToken(address _cToken) external view returns (
        address cToken,
        address underlying,
        bytes32 symbolHash,
        uint256 baseUnit,
        uint8 priceSource,
        uint256 fixedPrice,
        address uniswapMarket,
        bool isUniswapReversed
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev This interfaces defines the functions of the KeeperDAO liquidity pool
/// that our contract needs to know about. The only function we need is the
/// borrow function, which allows us to take flash loans from the liquidity
/// pool.
interface ILiquidityPool {
    /// @dev Borrow ETH/ERC20s from the liquidity pool. This function will (1)
    /// send an amount of tokens to the `msg.sender`, (2) call
    /// `msg.sender.call(_data)` from the KeeperDAO borrow proxy, and then (3)
    /// check that the balance of the liquidity pool is greater than it was
    /// before the borrow.
    ///
    /// @param _token The address of the ERC20 to be borrowed. ETH can be
    /// borrowed by specifying "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE".
    /// @param _amount The amount of the ERC20 (or ETH) to be borrowed. At least
    /// more than this amount must be returned to the liquidity pool before the
    /// end of the transaction, otherwise the transaction will revert.
    /// @param _data The calldata that encodes the callback to be called on the
    /// `msg.sender`. This is the mechanism through which the borrower is able
    /// to implement their custom keeper logic. The callback will be called from
    /// the KeeperDAO borrow proxy.
    function borrow(
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1337
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}