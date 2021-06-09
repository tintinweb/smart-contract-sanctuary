//SPDX-License-Identifier: Unlicense
import {KissaBase} from "./KissaBase.sol";
import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {IMintableERC20, AccessControlMixin, NativeMetaTransaction, ContextMixin} from "./BridgeHelpers.sol";

pragma solidity 0.8.4;

/* KISSA
 * 
 * By the Mittenz Team.
 *
 * Learn more at mittenz.tech. 
 *
 */


/**
 * @dev Implementation of KISSA as a non-mintable child token in Polygon Matic.
 * Adds extra logic to handle the MITTN-to-KISSA fractional reserve and
 * pegged exchange rate mechanism
 */
 contract Kissa is
    KissaBase,
    IMintableERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    using SafeERC20 for KissaBase;
    using SafeERC20 for IERC20;
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    // Amount of KISSA that can be minted by exchanging for MITTN.
    uint256 private constant _maxReserve = 1000000 * 10**18;

    // Pegged exchange rate.
    uint256 private constant _MittenzToKissaExRate = 400;

    // Number of KISSA that have actually been issued in exchange
    // for Mr Mittenz tokens using the PoS Bridge.
    uint256 private _floatingReserve;

    // KISSA that can currently be minted using the exchange
    uint256 private _availableReserve;

    // Mr Mittenz contract address.
    // address constant private _mittenzToken = 0x8Da04952f9e2c88fDE420cf8227BD6b259bD60d0;  //Ropsten
    address constant private _mittenzToken = 0x94a871F3107BE9f68C368828327b242fc691959E;  //Goerli
    // address constant private _mittenzToken = 0xb73F00feEAFc232C247516AA180261fEc0E909fc;  //Ethereum Mainnet

    // Conversion can start on 01 Oct 2021 at 00:00:00 UTC
    // (seconds since Unix epoch)
    // REAL
    // uint constant private _convertibilityStartTimeSecs = 1633046400;
    
    // TEST/DEBUG on Ropsten
    // For testing, set start time to 7 Jun 2021 at 22:00:00 UTC
    uint constant private _testConvertibilityStartTimeSecs = 1623103200;

    event Exchange(
        address indexed exchanger,
        address indexed fromToken,
        uint256 fromTokenAmount,
        address indexed toToken,
        uint256 toTokenAmount
    );

    constructor(
        address mintableERC20PredicateProxy
    ) KissaBase() {
        _setupContractId("Kissa");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, mintableERC20PredicateProxy);
        _initializeEIP712("Kissa");
        _floatingReserve = 0;
        _availableReserve = _maxReserve;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender() internal override view returns (address payable sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called to exchange Mittenz for Kissa
     * @param amountInMittenz abi encoded amount of Mittenz to lock
     * and exchange for Kissa.
     * @dev Performs deposit entry checks (deposit is within MITTN transaction limit,
     * amount of MITTN spend approved by user, and date and time is after the first 
     * allowed conversion time).
     * @dev Locks Mittenz.
     */
    function exchangeMittenzForKissa(uint256 amountInMittenz)
        external
    {
        // TEST/DEBUG on Ropsten
        require(block.timestamp > _testConvertibilityStartTimeSecs, "MITTN to KISSA conversion allowed starting 7 JUNE 2021 at 01:00 UTC.");
        // REAL
        // require(block.timestamp > _convertibilityStartTimeSecs, "MITTN to KISSA conversion allowed starting 1 OCT 2021 at 00:00 UTC.");
        require(amountInMittenz >= 400000, "Must convert at least 400,000 MITTN wei");
        require(amountInMittenz <= 40000 * 10**18,
            "MITTN to KISSA conversion: Conversion of more than 40,000 MITTN in a single transaction cannot proceed due to 40,000 MITTN transaction limit.");
        address payable depositor = _msgSender();
        uint256 mittenzAllowance = IERC20(_mittenzToken).allowance(depositor, address(this));
        require(mittenzAllowance >= amountInMittenz, "MITTN amount is above amount approved by user.");
        uint256 amountInKissa = amountInMittenz / _MittenzToKissaExRate;
        _floatingReserve += amountInKissa;
        IERC20(_mittenzToken).safeTransferFrom(depositor, address(this), amountInMittenz);
        _mint(depositor, amountInKissa);
        emit Exchange(depositor, _mittenzToken, amountInMittenz, address(this), amountInKissa);
    }

    /**
     * @notice called to exchange Kissa for Mittenz
     * @dev Should burn user's Kissa tokens.
     * @param amountInKissa amount of Kissa to convert to Mr Mittenz
     * @dev Performs withdrawal entry checks (withdrawal will be within MITTN transaction limit,
     * only up to floating reserve, and date and time is after the first allowed conversion time)
     * @dev Unlocks Mittenz.
     */
    function exchangeKissaForMittenz(uint256 amountInKissa) external {
        // TEST/DEBUG on Ropsten
        require(block.timestamp > _testConvertibilityStartTimeSecs, "KISSA to MITTN conversion allowed starting 7 JUNE 2021 at 01:00 UTC.");
        // REAL
        // require(block.timestamp > _convertibilityStartTimeSecs, "KISSA to MITTN conversion allowed starting 1 OCT 2021 at 00:00 UTC.");
        require(amountInKissa >= 1000, "Must convert at least 1,000 KISSA wei");
        require(amountInKissa <= 100 * 10**18,
            "KISSA to MITTN conversion: Conversion of more than 100 KISSA in a single transaction cannot proceed due to 40,000 MITTN transaction limit.");
        require(amountInKissa <= _floatingReserve, "KISSA to MITTN conversion: Amount exceeds MITTN reserves floating as KISSA.");
        uint256 amountInMittenz = amountInKissa * _MittenzToKissaExRate;
        _floatingReserve -= amountInKissa;
        address payable withdrawer = _msgSender();
        _burn(withdrawer, amountInKissa);
        IERC20(_mittenzToken).safeTransfer(withdrawer, amountInMittenz);
        emit Exchange(withdrawer, address(this), amountInKissa, _mittenzToken, amountInMittenz);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }
}