//SourceUnit: IERC20.sol

pragma solidity ^0.5.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


//SourceUnit: Migrations.sol

pragma solidity ^0.5.4;

contract Migrations {
    address public owner;
    uint256 public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.4;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: USDT_TCC_Swap.sol

pragma solidity ^0.5.4;

import "./IERC20.sol";
import "./SafeMath.sol";

contract USDT_TCC_Swap {
    using SafeMath for uint256;

    address private _owner;
    address private _newOwner;
    address private _usdt;
    address private _tcc;
    uint8 private _usdtDecimals;
    uint8 private _tccDecimals;
    uint8 private _rateDecimals;
    uint256 private _feePermille;
    uint256 private _tccSwapUsdtRate;
    uint256 private _usdtSwapTccRate;

    constructor() public {
        _owner = msg.sender;
        _usdt = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C; // TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t
        _tcc = 0xFf241d67339B467681B1fE0A8B7d73F273D27B27; // TZEGaHByWwdDyUsvMewxrHWbu7hJF4K1qE
        _usdtDecimals = 6; // usdt decimals: 10^6
        _tccDecimals = 8; // tcc decimals: 10^8
        _rateDecimals = 6; // rate decimals: 10^6
        _feePermille = 5; // swap fee permille: 5‰
        _tccSwapUsdtRate = 10000000; // 1TCC = 10USDT
        _usdtSwapTccRate = 100000; // 1USDT = 0.1TCC
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "USDT_TCC_Swap: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "USDT_TCC_Swap: new owner is the zero address");
        _newOwner = newOwner;

        return true;
    }

    function acceptOwnership() public returns (bool) {
        require(msg.sender == _newOwner, "USDT_TCC_Swap: caller is not the new owner");
        _owner = _newOwner;
        _newOwner = address(0);

        return true;
    }

    function usdtAddress() public view returns (address) {
        return _usdt;
    }

    function usdtBalance() public view returns (uint256) {
        return IERC20(_usdt).balanceOf(address(this));
    }

    function withdrawUsdt(uint256 _usdtAmount) public onlyOwner returns (bool) {
        require(usdtBalance() >= _usdtAmount, "USDT_TCC_Swap: withdraw amount exceeds balance");
        IERC20(_usdt).transfer(_owner, _usdtAmount);

        return true;
    }

    function tccAddress() public view returns (address) {
        return _tcc;
    }

    function tccBalance() public view returns (uint256) {
        return IERC20(_tcc).balanceOf(address(this));
    }

    function withdrawTcc(uint256 _tccAmount) public onlyOwner returns (bool) {
        require(tccBalance() >= _tccAmount, "USDT_TCC_Swap: withdraw amount exceeds balance");
        require(IERC20(_tcc).transfer(_owner, _tccAmount), "USDT_TCC_Swap: withdraw TCC fail");

        return true;
    }

    function feePermille() public view returns (uint256) {
        return _feePermille;
    }

    function setFeePermille(uint256 newFeePermille) public onlyOwner returns (bool) {
        require(newFeePermille >= 0, "USDT_TCC_Swap: new fee permille should be greater than or equal to zero");
        require(newFeePermille <= 1000, "USDT_TCC_Swap: new fee permille should be less than or equal to 1000");
        _feePermille = newFeePermille;

        return true;
    }

    function rateDecimals() public view returns (uint8) {
        return _rateDecimals;
    }

    function tccSwapUsdtRate() public view returns (uint256) {
        return _tccSwapUsdtRate;
    }

    function setTccSwapUsdtRate(uint256 _newRate) public onlyOwner returns (bool) {
        require(_newRate > 0, "USDT_TCC_Swap: new rate should be greater than zero");
        _tccSwapUsdtRate = _newRate;
        _usdtSwapTccRate = (10**uint256(_rateDecimals * 2)).div(_newRate);

        return true;
    }

    function tccSwapUsdtCalc(uint256 _tccAmount) public view returns (uint256) {
        uint256 _usdtAmount = _tccAmount
        .mul(_tccSwapUsdtRate)
        .mul(10**uint256(_usdtDecimals))
        .mul(1000 - _feePermille)
        .div(10**uint256(_tccDecimals + _rateDecimals + 3));

        return _usdtAmount;
    }

    function tccSwapUsdt(uint256 _tccAmount) public returns (bool) {
        address caller = address(msg.sender);
        require(IERC20(_tcc).transferFrom(caller, address(this), _tccAmount), "USDT_TCC_Swap: transfer TCC from caller fail");
        uint256 _usdtAmount = tccSwapUsdtCalc(_tccAmount);
        IERC20(_usdt).transfer(caller, _usdtAmount);

        return true;
    }

    function usdtSwapTccRate() public view returns (uint256) {
        return _usdtSwapTccRate;
    }

    function usdtSwapTccCalc(uint256 _usdtAmount) public view returns (uint256) {
        uint256 _tccAmount = _usdtAmount
        .mul(_usdtSwapTccRate)
        .mul(10**uint256(_tccDecimals))
        .mul(1000 - _feePermille)
        .div(10**uint256(_usdtDecimals + _rateDecimals + 3));

        return _tccAmount;
    }

    function usdtSwapTcc(uint256 _usdtAmount) public returns (bool) {
        address caller = address(msg.sender);
        require(IERC20(_usdt).transferFrom(caller, address(this), _usdtAmount), "USDT_TCC_Swap: transfer USDT from caller fail");
        uint256 _tccAmount = usdtSwapTccCalc(_usdtAmount);
        require(IERC20(_tcc).transfer(caller, _tccAmount), "USDT_TCC_Swap: transfer TCC to caller fail");

        return true;
    }
}