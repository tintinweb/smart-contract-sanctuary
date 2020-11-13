pragma solidity 0.5.17;

import "../lib/SafeMath.sol";

// Storage for a GAMER token
contract GAMERTokenStorage {

    using SafeMath for uint256;

    /**
     * @dev Guard variable for re-entrancy checks. Not currently used
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Governor for this contract
     */
    address public gov;

    /**
     * @notice Pending governance for this contract
     */
    address public pendingGov;

    /**
     * @notice Approved rebaser for this contract
     */
    address public rebaser;

    /**
     * @notice Reserve address of GAMER protocol
     */
    address public incentivizer;

    /**
     * @notice stakingPool address of GAMER protocol
     */
    address public stakingPool;

    /**
     * @notice teamPool address of GAMER protocol
     */
    address public teamPool;

    /**
     * @notice dev address of GAMER protocol
     */
    address public dev;

    /**
     * @notice Total supply of GAMERs
     */
    uint256 internal _totalSupply;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public gamersScalingFactor;

    mapping (address => uint256) internal _gamerBalances;

    mapping (address => mapping (address => uint256)) internal _allowedFragments;

    uint256 public initSupply;

}
