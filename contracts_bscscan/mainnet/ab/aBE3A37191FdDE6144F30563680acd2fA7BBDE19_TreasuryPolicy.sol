/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol



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

// File: contracts/interfaces/ITreasuryPolicy.sol



pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ITreasuryPolicy {
    function minting_fee() external view returns (uint256);

    function redemption_fee() external view returns (uint256);

    function excess_collateral_safety_margin() external view returns (uint256);

    function idleCollateralUtilizationRatio() external view returns (uint256);

    function reservedCollateralThreshold() external view returns (uint256);
}

// File: contracts/TreasuryPolicy.sol



pragma solidity 0.8.4;





contract TreasuryPolicy is Ownable, Initializable, ITreasuryPolicy {
    address public treasury;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    uint256 public override idleCollateralUtilizationRatio; // ratio where idle collateral can be used for investment
    uint256 public constant IDLE_COLLATERAL_UTILIZATION_RATION_MAX = 950000; // no more than 95%

    uint256 public override reservedCollateralThreshold; // ratio of the threshold where collateral are reserved for redemption
    uint256 public constant RESERVE_COLLATERAL_THRESHOLD_MIN = 100000; // no less than 10%

    // fees
    uint256 public override redemption_fee; // 6 decimals of precision
    uint256 public constant REDEMPTION_FEE_MAX = 9000; // 0.9%

    uint256 public override minting_fee; // 6 decimals of precision
    uint256 public constant MINTING_FEE_MAX = 5000; // 0.5%

    uint256 public override excess_collateral_safety_margin;
    uint256 public constant EXCESS_COLLATERAL_SAFETY_MARGIN_MIN = 150000; // 15%

    /* ========== EVENTS ============= */

    event TreasuryChanged(address indexed newTreasury);

    function initialize(
        address _treasury,
        uint256 _redemption_fee,
        uint256 _minting_fee,
        uint256 _excess_collateral_safety_margin,
        uint256 _idleCollateralUtilizationRatio,
        uint256 _reservedCollateralThreshold
    ) external initializer onlyOwner {
        setTreasury(_treasury);
        setMintingFee(_minting_fee);
        setRedemptionFee(_redemption_fee);
        setExcessCollateralSafetyMargin(_excess_collateral_safety_margin);
        setIdleCollateralUtilizationRatio(_idleCollateralUtilizationRatio);
        setReservedCollateralThreshold(_reservedCollateralThreshold);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    function setRedemptionFee(uint256 _redemption_fee) public onlyOwner {
        require(_redemption_fee <= REDEMPTION_FEE_MAX, ">REDEMPTION_FEE_MAX");
        redemption_fee = _redemption_fee;
    }

    function setMintingFee(uint256 _minting_fee) public onlyOwner {
        require(_minting_fee <= MINTING_FEE_MAX, ">MINTING_FEE_MAX");
        minting_fee = _minting_fee;
    }

    function setExcessCollateralSafetyMargin(uint256 _excess_collateral_safety_margin) public onlyOwner {
        require(_excess_collateral_safety_margin >= EXCESS_COLLATERAL_SAFETY_MARGIN_MIN, "<EXCESS_COLLATERAL_SAFETY_MARGIN_MIN");
        excess_collateral_safety_margin = _excess_collateral_safety_margin;
    }

    function setIdleCollateralUtilizationRatio(uint256 _idleCollateralUtilizationRatio) public onlyOwner {
        require(_idleCollateralUtilizationRatio <= IDLE_COLLATERAL_UTILIZATION_RATION_MAX, ">IDLE_COLLATERAL_UTILIZATION_RATION_MAX");
        idleCollateralUtilizationRatio = _idleCollateralUtilizationRatio;
    }

    function setReservedCollateralThreshold(uint256 _reservedCollateralThreshold) public onlyOwner {
        require(_reservedCollateralThreshold >= RESERVE_COLLATERAL_THRESHOLD_MIN, "<RESERVE_COLLATERAL_THRESHOLD_MIN");
        reservedCollateralThreshold = _reservedCollateralThreshold;
    }
}