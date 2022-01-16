/**
 *Submitted for verification at FtmScan.com on 2022-01-16
*/

// Dependency file: contracts/interfaces/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: contracts/interfaces/IApeToken.sol

// pragma solidity 0.8.4;

// import "contracts/interfaces/ERC20/IERC20.sol";

interface IApeToken is IERC20 {
    function burn(uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
}


// Dependency file: contracts/interfaces/ITreasury.sol

// pragma solidity 0.8.4;

interface ITreasury {
    function amountToMint(address _pair, uint256 _amount) external view returns (uint256);

    function mintRewards() external;

    function mintBonus(
        address _token,
        uint256 _principal,
        uint256 _bonus
    ) external returns (uint256);
}


// Dependency file: contracts/interfaces/IApeStaking.sol

// pragma solidity 0.8.4;

// import "contracts/interfaces/ERC20/IERC20.sol";

interface IApeStaking is IERC20 {
    function apeBalance(address _account) external view returns (uint256);

    function sApeForApe(uint256 _sApeAmount) external view returns (uint256);

    function apeForSApe(uint256 _apeAmount) external view returns (uint256);

    function burn(uint256 _amount) external;

    function mint(uint256 _amount) external;
}


// Dependency file: contracts/interfaces/ICalculator.sol

// pragma solidity 0.8.4;

interface ICalculator {
    function capture(address _pair) external view returns (uint256);

    function valuation(address _pair, uint256 _amount) external view returns (uint256);
}


// Dependency file: contracts/interfaces/IAllocator.sol

// pragma solidity 0.8.4;

interface IAllocator {
    function allocate(address _lpToken, uint256 _amount) external;

    function treasuryWithdraw(address _lpToken) external;

    event PoolUpdated(uint256 indexed pid, address indexed lpToken, bool indexed enabled);
    event Allocated(address indexed token, address indexed depositor, uint256 indexed amount);
}


// Dependency file: contracts/libraries/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Root file: contracts/Treasury.sol

pragma solidity 0.8.4;

// import "contracts/interfaces/IApeToken.sol";
// import "contracts/interfaces/ITreasury.sol";
// import "contracts/interfaces/IApeStaking.sol";
// import "contracts/interfaces/ICalculator.sol";
// import "contracts/interfaces/IAllocator.sol";
// import "contracts/interfaces/ERC20/IERC20.sol";
// import "contracts/libraries/math/SafeMath.sol";

contract HominidTreasury is ITreasury {
    using SafeMath for uint256;

    // APE Token
    address public APE;
    // APE_FTM Token
    address public APE_FTM;
    // DAO address
    address public DAO;
    // policy address
    address public policy;
    // staking
    address public staking;
    // bonding
    address public bonding;
    // calculator
    address public calculator;
    // allocator
    address public allocator;
    // reward rate
    uint256 public rewardRate;

    modifier onlyStaking() {
        require(msg.sender == staking, "only staking");
        _;
    }

    modifier onlyBonding() {
        require(msg.sender == bonding, "only bonding");
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == policy, "only policy");
        _;
    }

    function initialize(
        address _APE,
        address _APE_FTM,
        address _DAO
    ) external {
        require(APE == address(0), "already initialized");

        APE = _APE;
        APE_FTM = _APE_FTM;
        DAO = _DAO;

        policy = msg.sender;
        rewardRate = 1_000; // 0.1% - 1_000_000
    }

    function setContracts(
        address _staking,
        address _bonding,
        address _allocator,
        address _calculator
    ) external onlyPolicy {
        staking = _staking;
        bonding = _bonding;
        allocator = _allocator;
        calculator = _calculator;
    }

    function setPolicy(address _policy) external onlyPolicy {
        policy = _policy;
    }

    function setRewardRate(uint256 _rewardRate) external onlyPolicy {
        require(_rewardRate <= 10_000, "too large");
        rewardRate = _rewardRate;
    }

    function amountToMint(address _pair, uint256 _amount) public view override returns (uint256 amount_) {
        uint256 pairValueInFTM = ICalculator(calculator).valuation(_pair, _amount);
        uint256 apeValueInFTM = ICalculator(calculator).capture(APE_FTM);
        amount_ = pairValueInFTM.mul(1e18).div(apeValueInFTM);
    }

    function mintRewards() external override onlyStaking {
        uint256 mintAmount = rewardRate.mul(IERC20(APE).totalSupply()).div(1_000_000);
        IApeToken(APE).mint(msg.sender, mintAmount);
        uint256 daoAmount = mintAmount.div(10);
        IApeToken(APE).mint(DAO, daoAmount);
    }

    function mintBonus(
        address _token,
        uint256 _principal,
        uint256 _bonus
    ) external override onlyBonding returns (uint256 amountStake_) {
        IERC20(_token).transferFrom(msg.sender, address(this), _principal);

        if (allocator != address(0)) {
            IERC20(_token).approve(allocator, 0);
            IERC20(_token).approve(allocator, _principal);
            IAllocator(allocator).allocate(_token, _principal);
        }

        uint256 totalAmount = _principal.add(_bonus);

        uint256 apeAmount = amountToMint(_token, totalAmount);
        IApeToken(APE).mint(address(this), apeAmount);

        IERC20(APE).approve(staking, 0);
        IERC20(APE).approve(staking, apeAmount);
        IApeStaking(staking).mint(apeAmount);

        amountStake_ = IERC20(staking).balanceOf(address(this));
        IERC20(staking).transfer(msg.sender, amountStake_);

        uint256 daoAmount = totalAmount.div(10);
        IApeToken(APE).mint(DAO, daoAmount);
    }
}