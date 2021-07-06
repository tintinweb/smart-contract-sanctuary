/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-07
*/

// File: contracts/ErrorReporter.sol

pragma solidity ^0.5.16;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        INSUFFICIENT_BALANCE_FOR_BAI
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
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK,
        SET_BAI_MINT_RATE_CHECK,
        SET_BAICONTROLLER_OWNER_CHECK,
        SET_MINTED_BAI_REJECTION,
        SET_TREASURY_OWNER_CHECK
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
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED,
        TOKEN_PRICE_ERROR
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_ABAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_ABAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
        TOKEN_GET_UNDERLYING_PRICE_ERROR,
        REPAY_BAI_COMPTROLLER_REJECTION,
        REPAY_BAI_FRESHNESS_CHECK,
        BAI_MINT_EXCHANGE_CALCULATION_FAILED,
        SFT_MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_FEE_CALCULATION_FAILED
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

contract BAIControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        REJECTION,
        SNAPSHOT_ERROR,
        PRICE_ERROR,
        MATH_ERROR,
        INSUFFICIENT_BALANCE_FOR_BAI
    }

    enum FailureInfo {
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_COMPTROLLER_OWNER_CHECK,
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        BAI_MINT_REJECTION,
        BAI_BURN_REJECTION,
        BAI_LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        BAI_LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        BAI_LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        BAI_LIQUIDATE_COMPTROLLER_REJECTION,
        BAI_LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        BAI_LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        BAI_LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        BAI_LIQUIDATE_FRESHNESS_CHECK,
        BAI_LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        BAI_LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        BAI_LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        BAI_LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        BAI_LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        BAI_LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        BAI_LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_FEE_CALCULATION_FAILED,
        SET_TREASURY_OWNER_CHECK
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

// File: contracts/ComptrollerInterface.sol

pragma solidity ^0.5.16;

contract ComptrollerInterfaceG1 {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata bTokens) external returns (uint[] memory);
    function exitMarket(address bToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address bToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address bToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address bToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address bToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address bToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address bToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address bToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address bToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address bTokenBorrowed,
        address bTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address bTokenBorrowed,
        address bTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address bTokenCollateral,
        address bTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address bTokenCollateral,
        address bTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address bToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address bToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address bTokenBorrowed,
        address bTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
    function setMintedBAIOf(address owner, uint amount) external returns (uint);
}

contract ComptrollerInterfaceG2 is ComptrollerInterfaceG1 {
    function liquidateBAICalculateSeizeTokens(
        address bTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}

contract ComptrollerInterface is ComptrollerInterfaceG2 {
}

interface IBAIVault {
    function updatePendingRewards() external;
}

interface IComptroller {
    /*** Treasury Data ***/
    function treasuryAddress() external view returns (address);
    function treasuryPercent() external view returns (uint);
}

// File: contracts/BAIControllerStorage.sol

pragma solidity ^0.5.16;


contract BAIUnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public baiControllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingBAIControllerImplementation;
}

contract BAIControllerStorageG1 is BAIUnitrollerAdminStorage {
    ComptrollerInterface public comptroller;

    struct BidaoBAIState {
        /// @notice The last updated bidaoBAIMintIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The Bidao BAI state
    BidaoBAIState public bidaoBAIState;

    /// @notice The Bidao BAI state initialized
    bool public isBidaoBAIInitialized;

    /// @notice The Bidao BAI minter index as of the last time they accrued XBID
    mapping(address => uint) public bidaoBAIMinterIndex;
}

contract BAIControllerStorageG2 is BAIControllerStorageG1 {
    /// @notice Treasury Guardian address
    address public treasuryGuardian;

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Fee percent of accrued interest with decimal 18
    uint256 public treasuryPercent;

    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;
}

// File: contracts/BAIUnitroller.sol

pragma solidity ^0.5.16;



contract BAIUnitroller is BAIUnitrollerAdminStorage, BAIControllerErrorReporter {

    /**
      * @notice Emitted when pendingBAIControllerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingBAIControllerImplementation is accepted, which means comptroller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingBAIControllerImplementation;

        pendingBAIControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingBAIControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation
        if (msg.sender != pendingBAIControllerImplementation) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = baiControllerImplementation;
        address oldPendingImplementation = pendingBAIControllerImplementation;

        baiControllerImplementation = pendingBAIControllerImplementation;

        pendingBAIControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, baiControllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingBAIControllerImplementation);

        return uint(Error.NO_ERROR);
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () external payable {
        // delegate all other functions to current implementation
        (bool success, ) = baiControllerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}