// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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


interface IPowerUser {
    function usePower(uint256 power) external returns (uint256);
    event PowerUsed(address indexed master, uint256 power, string purpose);
}


/**
 * @dev Fractal illusion of the ideal stable for the best of cows.
 *
 * Calmness, deep relaxation, concentration and absolute harmony. Cows just love this place.
 * There are rumours, that the place where the stable was built is in fact a source of the power.
 * I personally believe that this stable would be perfect for cows to give a lot of amazing milk!
 *
 * Even mathematics works here differently - cows are not counted like in habitual
 * world (like: 1 cow, 2 cows, 3 cows...), but instead they are somehow measured in strange
 * unusual large numbers called here "units". Maybe this is just another strange but a sweet dream?..
 */
contract Stable is Ownable {
    using SafeMath for uint256;

    // Stakeshot contains snapshot aggregated staking history.
    struct Stakeshot {
        uint256 _block;  // number of block stakeshooted
        uint256 _cows;   // amount of cows in the stable just after the "shoot" moment [units]
        uint256 _power;  // amount of currently accumulated power available in this block
    }

    // Precalculate TOTAL_UNITS used for conversion between tokens and units.
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_TOKENS = 21 * 10**6;
    uint256 private constant INITIAL_SUPPLY = INITIAL_TOKENS * 10**9;
    uint256 private constant TOTAL_UNITS = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);
    uint256 private constant COWS_TO_POWER_DELIMETER = 10**27;

    // COW token is hardcoded into the stable.
    IERC20 private _tokenCOW = IERC20(0xf0be50ED0620E0Ba60CA7FC968eD14762e0A5Dd3);

    // Amount of cows by masters and total amount of cows in the stable.
    mapping(address => uint256) private _cows;  // [units]
    uint256 private _totalCows;                 // [units]

    // Most actual stakeshots by masters.
    mapping(address => Stakeshot) private _stakeshots;
    uint256 private _totalPower;


    event CowsArrived(address indexed master, uint256 cows);
    event CowsLeaved(address indexed master, uint256 cows);


    function driveCowsInto(uint256 cows) external {
        address master = msg.sender;

        // Transport provided cows to the stable
        bool ok = _tokenCOW.transferFrom(master, address(this), cows);
        require(ok, "Stable: unable to transport cows to the stable");

        // Register each arrived cow
        uint256 unitsPerCow = TOTAL_UNITS.div(_tokenCOW.totalSupply());
        uint256 units = cows.mul(unitsPerCow);
        _cows[master] = _cows[master].add(units);
        _totalCows = _totalCows.add(units);

        // Recalculate power collected by the master
        _updateStakeshot(master);

        // Emit event to the logs so can be effectively used later
        emit CowsArrived(master, cows);
    }

    function driveCowsOut(address master, uint256 cows) external {

        // Transport requested cows from the stable
        bool ok = _tokenCOW.transfer(master, cows);
        require(ok, "Stable: unable to transport cows from the stable");

        // Unregister each leaving cow
        uint256 unitsPerCow = TOTAL_UNITS.div(_tokenCOW.totalSupply());
        uint256 units = cows.mul(unitsPerCow);
        _cows[master] = _cows[master].sub(units);
        _totalCows = _totalCows.sub(units);

        // Recalculate power collected by the master
        _updateStakeshot(master);

        // Emit event to the logs so can be effectively used later
        emit CowsLeaved(master, cows);
    }

    function token() public view returns (IERC20) {
        return _tokenCOW;
    }

    function cows(address master) public view returns (uint256) {
        uint256 unitsPerCow = TOTAL_UNITS.div(_tokenCOW.totalSupply());
        return _cows[master].div(unitsPerCow);
    }

    function totalCows() public view returns (uint256) {
        uint256 unitsPerCow = TOTAL_UNITS.div(_tokenCOW.totalSupply());
        return _totalCows.div(unitsPerCow);
    }

    function power(address master) public view returns (uint256, uint256) {
        return (_stakeshots[master]._block, _stakeshots[master]._power);
    }

    function totalPower() public view returns (uint256) {
        return _totalPower;
    }

    function stakeshot(address master) public view returns (uint256, uint256, uint256) {
        uint256 unitsPerCow = TOTAL_UNITS.div(_tokenCOW.totalSupply());
        Stakeshot storage s = _stakeshots[master];
        return (s._block, s._cows.div(unitsPerCow), s._power);
    }

    function _updateStakeshot(address master) private {
        Stakeshot storage s = _stakeshots[master];
        uint256 duration = block.number.sub(s._block);
        if (s._block > 0 && duration > 0) {
            // Recalculate collected power
            uint256 productivity = s._cows.div(COWS_TO_POWER_DELIMETER);
            uint256 powerGained = productivity.mul(duration);
            s._power = s._power.add(powerGained);
            _totalPower = _totalPower.add(powerGained);
        }
        s._block = block.number;
        s._cows = _cows[master];
    }
}