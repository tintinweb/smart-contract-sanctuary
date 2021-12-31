// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PPIEDelegator Contract
 * @notice PPIE which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PPIEDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param pPIEImplementation_ The address of the PPIEImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address pPIEImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pPIEImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                        underlying_,
                                                        registry_,
                                                        controller_,
                                                        interestRateModel_,
                                                        initialExchangeRateMantissa_,
                                                        initialReserveFactorMantissa_,
                                                        name_,
                                                        symbol_,
                                                        decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementationInternal(address implementation_) internal {
        implementation = implementation_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface RegistryInterface {

    /**
     *  Returns admin address for pToken contracts
     *  @return admin address
     */
    function admin() external view returns (address payable);

    /**
     *  Returns pToken factory address of protocol
     *  @return factory address
     */
    function factory() external view returns (address);

    /**
     *  Returns oracle address for protocol
     *  @return oracle address
     */
    function oracle() external view returns (address);

    /**
     *  Returns address of actual pToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    /**
     *  Returns address of actual pPIE token
     *  @return Address of contract
     */
    function pPIE() external view returns (address);

    /**
     *  Returns address of actual pETH token
     *  @return Address of contract
     */
    function pETH() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract ControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        CONTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        GUARDIAN_REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_GUARDIAN_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_FEE_FACTOR,
        SET_MAX_FEE_FACTOR,
        SET_BORROW_DELAY_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        CONTROLLER_REJECTION,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        TOKEN_INSUFFICIENT_CASH
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_CONTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_CONTROLLER_REJECTION,
        LIQUIDATE_CONTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_CONTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_CONTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_CONTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SET_CONTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_CONTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract OracleErrorReporter {
    enum Error {
        NO_ERROR,
        POOL_OR_COIN_EXIST,
        UNAUTHORIZED,
        UPDATE_PRICE
    }

    enum FailureInfo {
        ADD_POOL_OR_COIN,
        NO_PAIR,
        NO_RESERVES,
        PERIOD_NOT_ELAPSED,
        SET_NEW_IMPLEMENTATION,
        UPDATE_DATA
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract FactoryErrorReporter {
    enum Error {
        NO_ERROR,
        INVALID_POOL,
        MARKET_NOT_LISTED,
        UNAUTHORIZED
    }

    enum FailureInfo {
        CREATE_PETH_POOL,
        CREATE_PPIE_POOL,
        DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST,
        SET_MIN_LIQUIDITY_OWNER_CHECK,
        SET_NEW_CONTROLLER,
        SET_NEW_DECIMALS,
        SET_NEW_EXCHANGE_RATE,
        SET_NEW_INTEREST_RATE_MODEL,
        SET_NEW_RESERVE_FACTOR,
        SUPPORT_MARKET_BAD_RESULT,
        ADD_UNDERLYING_TO_BLACKLIST,
        REMOVE_UNDERLYING_FROM_BLACKLIST,
        UNDERLYING_IN_BLACKLIST
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract RegistryErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        SET_NEW_IMPLEMENTATION,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_NEW_FACTORY,
        SET_NEW_ORACLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}