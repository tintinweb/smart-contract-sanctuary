/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IMonsterToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function burn(uint256 amount) external;

    function transferOwnership(address newOwner) external;
}

interface IMonsterReferral {
    function recordReferral(address user, address referrer) external;

    function referralsCount(address user) external view returns (uint256);

    function recordReferralCommission(address _referrer, uint256 _commission)
        external;
}

contract MonsterPresale {
    using SafeMath for uint256;

    IMonsterToken public token;
    IMonsterReferral public referral;

    bool public paused = false;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public blocksPerDay;
    uint256 public presaleTokensSold;
    uint256 public presaleDays;
    uint256 public initialRate = 0.488 ether;
    uint256 public multiplier = 0.012 ether;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 1000; // 10%

    mapping(address => uint256) private balances;

    address[] private investers;

    event Purchase(
        address indexed _address,
        uint256 _amount,
        uint256 _tokensAmount
    );
    event TransferBalance(address indexed _address, uint256 _amount);
    event Paused();
    event Started();
    event Finish();
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    address payable public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        IMonsterToken _token,
        IMonsterReferral _referral,
        uint256 _presaleDays,
        uint256 _blocksPerDay
    ) public {
        owner = payable(msg.sender);
        token = _token;
        referral = _referral;
        presaleDays = _presaleDays;
        blocksPerDay = _blocksPerDay;
        startBlock = block.number;
        endBlock = startBlock + (blocksPerDay * presaleDays);
    }

    receive() external payable {
        purchase(address(0));
    }

    function purchase(address referrer) public payable {
        require(!paused, "Presale: paused");
        uint256 stage = getStage();
        if (stage >= presaleDays + 1) {
            paused = true;
            emit Paused();
            return;
        }

        uint256 rate = currentRate();
        uint256 msgValue = msg.value;
        require(msgValue >= rate, "purchase: purchase amount limit");
        uint256 tokensAmount = calculateTokensAmount(msgValue, rate);

        address to = msg.sender;
        presaleTokensSold = presaleTokensSold.add(tokensAmount);
        balances[to] = balances[to].add(msgValue);

        if (referrer != address(0)) {
            referral.recordReferral(msg.sender, referrer);
            uint256 commissionAmount = tokensAmount
            .mul(referralCommissionRate)
            .div(10000);

            if (commissionAmount > 0) {
                require(
                    token.transfer(referrer, commissionAmount),
                    "purchase: failed transfer to referrer"
                );
                referral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(to, referrer, commissionAmount);
            }
        }
        require(
            token.transfer(msg.sender, tokensAmount),
            "purchase: failed transfer to sender"
        );
        emit Purchase(to, msgValue, tokensAmount);
    }

    function currentRate() public view returns (uint256) {
        return initialRate.add(multiplier.mul(getStage()));
    }

    function calculateTokensAmount(uint256 _amount, uint256 _rate)
        public
        pure
        returns (uint256)
    {
        return _amount.div(_rate.div(10_000)).mul(10**18).div(10_000);
    }

    function getStage() public view returns (uint256) {
        uint256 currentBlockNumber = block.number;
        return
            (currentBlockNumber < startBlock + blocksPerDay)
                ? 1
                : currentBlockNumber.sub(startBlock).div(blocksPerDay) + 1;
    }

    function getNativeTokenSpended(address _address)
        external
        view
        returns (uint256)
    {
        return balances[_address];
    }

    function transferBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Presale: balance must be greater than zero");
        owner.transfer(balance);
        emit TransferBalance(owner, balance);
    }

    function increaseOneMoreDay() external onlyOwner {
        presaleDays += 1;
        endBlock += blocksPerDay;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function start() external onlyOwner {
        paused = false;
        emit Started();
    }

    function finish() external onlyOwner {
        paused = true;
        token.transferOwnership(owner);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit Finish();
    }
}