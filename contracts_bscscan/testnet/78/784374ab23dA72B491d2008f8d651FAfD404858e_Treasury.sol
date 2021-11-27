// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../amm/interfaces/IPancakeRouter.sol";
import "./interfaces/IFXDX.sol";
import "../peripherals/interfaces/ITimelockTarget.sol";

contract Treasury is ReentrancyGuard, ITimelockTarget {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1000000;
    uint256 constant BASIS_POINTS_DIVISOR = 10000;

    bool public isInitialized;
    bool public isSwapActive = true;
    bool public isLiquidityAdded = false;

    address public fxdx;
    address public busd;
    address public router;
    address public fund;

    uint256 public fxdxPresalePrice;
    uint256 public fxdxListingPrice;
    uint256 public busdSlotCap;
    uint256 public busdHardCap;
    uint256 public busdBasisPoints;
    uint256 public unlockTime;

    uint256 public busdReceived;

    address public gov;

    mapping (address => uint256) public swapAmounts;
    mapping (address => bool) public swapWhitelist;

    modifier onlyGov() {
        require(msg.sender == gov, "Treasury: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address[] memory _addresses,
        uint256[] memory _values
    ) external onlyGov {
        require(!isInitialized, "Treasury: already initialized");
        isInitialized = true;

        fxdx = _addresses[0];
        busd = _addresses[1];
        router = _addresses[2];
        fund = _addresses[3];

        fxdxPresalePrice = _values[0];
        fxdxListingPrice = _values[1];
        busdSlotCap = _values[2];
        busdHardCap = _values[3];
        busdBasisPoints = _values[4];
        unlockTime = _values[5];
    }

    function setGov(address _gov) external override onlyGov nonReentrant {
        gov = _gov;
    }

    function setFund(address _fund) external onlyGov nonReentrant {
        fund = _fund;
    }

    function extendUnlockTime(uint256 _unlockTime) external onlyGov nonReentrant {
        require(_unlockTime > unlockTime, "Treasury: invalid _unlockTime");
        unlockTime = _unlockTime;
    }

    function addWhitelists(address[] memory _accounts) external onlyGov nonReentrant {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            swapWhitelist[account] = true;
        }
    }

    function removeWhitelists(address[] memory _accounts) external onlyGov nonReentrant {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            swapWhitelist[account] = false;
        }
    }

    function updateWhitelist(address prevAccount, address nextAccount) external onlyGov nonReentrant {
        require(swapWhitelist[prevAccount], "Treasury: invalid prevAccount");
        swapWhitelist[prevAccount] = false;
        swapWhitelist[nextAccount] = true;
    }

    function swap(uint256 _busdAmount) external nonReentrant {
        address account = msg.sender;
        require(swapWhitelist[account], "Treasury: forbidden");
        require(isSwapActive, "Treasury: swap is no longer active");
        require(_busdAmount > 0, "Treasury: invalid _busdAmount");

        busdReceived = busdReceived.add(_busdAmount);
        require(busdReceived <= busdHardCap, "Treasury: busdHardCap exceeded");

        swapAmounts[account] = swapAmounts[account].add(_busdAmount);
        require(swapAmounts[account] <= busdSlotCap, "Treasury: busdSlotCap exceeded");

        // receive BUSD
        uint256 busdBefore = IERC20(busd).balanceOf(address(this));
        IERC20(busd).transferFrom(account, address(this), _busdAmount);
        uint256 busdAfter = IERC20(busd).balanceOf(address(this));
        require(busdAfter.sub(busdBefore) == _busdAmount, "Treasury: invalid transfer");

        // send FXDX
        uint256 fxdxAmount = _busdAmount.mul(PRECISION).div(fxdxPresalePrice);
        IERC20(fxdx).transfer(account, fxdxAmount);
    }

    function addLiquidity() external onlyGov nonReentrant {
        require(!isLiquidityAdded, "Treasury: liquidity already added");
        isLiquidityAdded = true;

        uint256 busdAmount = busdReceived.mul(busdBasisPoints).div(BASIS_POINTS_DIVISOR);
        uint256 fxdxAmount = busdAmount.mul(PRECISION).div(fxdxListingPrice);

        IERC20(busd).approve(router, busdAmount);
        IERC20(fxdx).approve(router, fxdxAmount);

        IFXDX(fxdx).endMigration();

        IPancakeRouter(router).addLiquidity(
            busd, // tokenA
            fxdx, // tokenB
            busdAmount, // amountADesired
            fxdxAmount, // amountBDesired
            0, // amountAMin
            0, // amountBMin
            address(this), // to
            block.timestamp // deadline
        );

        IFXDX(fxdx).beginMigration();

        uint256 fundAmount = busdReceived.sub(busdAmount);
        IERC20(busd).transfer(fund, fundAmount);
    }

    function withdrawToken(address _token, address _account, uint256 _amount) external override onlyGov nonReentrant {
        require(block.timestamp > unlockTime, "Treasury: unlockTime not yet passed");
        IERC20(_token).transfer(_account, _amount);
    }

    function increaseBusdBasisPoints(uint256 _busdBasisPoints) external onlyGov nonReentrant {
        require(_busdBasisPoints > busdBasisPoints, "Treasury: invalid _busdBasisPoints");
        busdBasisPoints = _busdBasisPoints;
    }

    function endSwap() external onlyGov nonReentrant {
        isSwapActive = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFXDX {
    function beginMigration() external;
    function endMigration() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelockTarget {
    function setGov(address _gov) external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}