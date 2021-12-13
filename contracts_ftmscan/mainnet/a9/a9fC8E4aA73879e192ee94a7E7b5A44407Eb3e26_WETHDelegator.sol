pragma solidity 0.6.11;

import "IERC20.sol";
import "IWETH.sol";
import "IBorrowerOperations.sol";

contract WETHDelegator {
    IWETH public immutable WETH;
    IERC20 public immutable LUSD;
    IBorrowerOperations public immutable borrowerOperations;

    constructor(
        IWETH _weth,
        IERC20 _lusd,
        address _borrowerOperations
    ) public {
        _weth.approve(_borrowerOperations, uint256(-1));
        WETH = _weth;
        LUSD = _lusd;
        borrowerOperations = IBorrowerOperations(_borrowerOperations);
    }

    receive() external payable {}

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _collateralAmount,
        uint256 _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external payable {
        require(msg.value == _collateralAmount, "Invalid amount");

        WETH.deposit{value: msg.value}();
        borrowerOperations.openTrove(
            msg.sender,
            _maxFeePercentage,
            _collateralAmount,
            _LUSDAmount,
            _upperHint,
            _lowerHint
        );
        LUSD.transfer(msg.sender, _LUSDAmount);
    }

    function adjustTrove(
        uint256 _maxFeePercentage,
        uint256 _collDeposit,
        uint256 _collWithdrawal,
        uint256 _LUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable {
        require(msg.value == _collDeposit, "Invalid amount");

        if (_collDeposit > 0) {
            WETH.deposit{value: msg.value}();
        }
        if (!_isDebtIncrease && _LUSDChange > 0) {
            LUSD.transferFrom(msg.sender, address(this), _LUSDChange);
        }
        borrowerOperations.adjustTrove(
            msg.sender,
            _maxFeePercentage,
            _collDeposit,
            _collWithdrawal,
            _LUSDChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint
        );
        if (_collWithdrawal > 0) {
            WETH.withdraw(_collWithdrawal);
            msg.sender.transfer(_collWithdrawal);
        }
        if (_isDebtIncrease && _LUSDChange > 0) {
            LUSD.transfer(msg.sender, _LUSDChange);
        }
    }

    function closeTrove(uint256 _debt) external {
        LUSD.transferFrom(msg.sender, address(this), _debt);
        borrowerOperations.closeTrove(msg.sender);

        uint256 amount = WETH.balanceOf(address(this));
        WETH.withdraw(amount);
        msg.sender.transfer(amount);

        amount = LUSD.balanceOf(address(this));
        if (amount > 0) {
            LUSD.transfer(msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.6.11;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256) external;
    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

import "IERC20.sol";

pragma solidity 0.6.11;

// Common interface for the Trove Manager.
interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    function collateralToken() external view returns (IERC20);

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _lusdTokenAddress,
        address _lqtyStakingAddress,
        address _collateralStakingAddress
    ) external;

    function openTrove(address _account, uint _maxFee, uint _collateralAmount, uint _LUSDAmount, address _upperHint, address _lowerHint) external;

    function addColl(address _account, uint _collateralAmount, address _upperHint, address _lowerHint) external;

    function moveETHGainToTrove(uint _collateralAmount, address _user, address _upperHint, address _lowerHint) external;

    function withdrawColl(address _account, uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(address _account, uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(address _account, uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove(address _account) external;

    function adjustTrove(address _account, uint _maxFee, uint _collDeposit, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external;

    function claimCollateral(address _account) external;

    function getCompositeDebt(uint _debt) external view returns (uint);

    function minNetDebt() external view returns (uint);
}