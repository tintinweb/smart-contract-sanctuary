pragma solidity ^0.5.16;

import "./ComptrollerInterface.sol";

contract USXUnitrollerAdminStorage {
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
    address public usxControllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingUSXControllerImplementation;
}

contract USXControllerStorageG1 is USXUnitrollerAdminStorage {
    ComptrollerInterface public comptroller;

    struct ThermoUSXState {
        /// @notice The last updated thermoUSXMintIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The Thermo USX state
    ThermoUSXState public thermoUSXState;

    /// @notice The Thermo USX state initialized
    bool public isThermoUSXInitialized;

    /// @notice The Thermo USX minter index as of the last time they accrued TMX
    mapping(address => uint) public thermoUSXMinterIndex;
}

contract USXControllerStorageG2 is USXControllerStorageG1 {
    /// @notice Treasury Guardian address
    address public treasuryGuardian;

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Fee percent of accrued interest with decimal 18
    uint256 public treasuryPercent;

    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;
}

pragma solidity ^0.5.16;

contract ComptrollerInterfaceG1 {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata sTokens) external returns (uint[] memory);
    function exitMarket(address sToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address sToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address sToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address sToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address sToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address sToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address sToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address sToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address sToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address sTokenBorrowed,
        address sTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address sTokenBorrowed,
        address sTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address sTokenCollateral,
        address sTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address sTokenCollateral,
        address sTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address sToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address sToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address sTokenBorrowed,
        address sTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
    function setMintedUSXOf(address owner, uint amount) external returns (uint);
}

contract ComptrollerInterfaceG2 is ComptrollerInterfaceG1 {
    function liquidateUSXCalculateSeizeTokens(
        address sTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}

contract ComptrollerInterface is ComptrollerInterfaceG2 {
}

interface IUSXVault {
    function updatePendingRewards() external;
}

interface IComptroller {
    /*** Treasury Data ***/
    function treasuryAddress() external view returns (address);
    function treasuryPercent() external view returns (uint);
}