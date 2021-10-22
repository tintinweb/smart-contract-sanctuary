/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// File: GLAStaking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




contract GLAStaking is Ownable {
    using SafeMath for uint256;
    struct Deposit {
        uint256 index;
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        mapping(uint256 => Deposit) deposits;
        uint256[] depositIdx;
        uint256 numberOfDeposits;
    }

    struct Plan {
        uint256 time;
        uint256 percent; //APY
        uint256 maxStake;
        uint256 currentStake;
    }

    struct DepositInfo {
        uint256 depositIndex;
        uint256 amountDeposit;
        uint8 plan;
        uint256 percent;
        uint256 amountGain;
        uint256 start;
        uint256 finish;
    }
    
    uint256 depositID = 0;
    uint256 constant TIME_STEP = 1 days;
    uint256 public constant MIN_STAKE_AMOUNT = 10**4 * 10**18;
    address public glaMinter;
    address public gameManager;
    uint256 public totalStaked;
    mapping(uint256 => Plan) internal plans;
    mapping(address => User) internal users;

    event NewDeposit(address indexed user, uint256 idx, uint8 plan, uint256 amount);
    event UnstakeBeforeMaturity( address indexed user, uint256 idx, uint256 withdrawalAmount, uint256 time);
    event UnstakeAfterMaturity(address indexed user, uint256 idx, uint256 withdrawalAmount, uint256 time);

    constructor(address _gameManager, address _minter) {
        plans[0] = Plan(30, 180, 50 * 10**6 * 10**18, 0);
        plans[1] = Plan(60, 240, 105 * 10**6 * 10**18, 0);
        plans[2] = Plan(90, 300, 155 * 10**6 * 10**18, 0);
        glaMinter = _minter;
        gameManager = _gameManager;
    }

    function stakeGLA(uint256 _amount, uint8 plan) public {
        require(msg.sender == tx.origin, "Hello, bot!");
        require(plan < 3, "Invalid plan");
        require(
            _amount >= MIN_STAKE_AMOUNT,
            "Stake amount must be greater than MIN_STAKE_AMOUNT"
        );
        require(
            plans[plan].currentStake + _amount < plans[plan].maxStake,
            "This pool is full"
        );
        address glaTokenAddress = IGameManager(gameManager).getContract(
            "GLAToken"
        );
        
        User storage user = users[msg.sender];
        IGLAToken(glaTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        
        IGLAMintOperator(glaMinter).mint(
            address(this),
            _amount.mul(plans[plan].percent).mul(plans[plan].time).div(100).div(365)
        );
        
        uint256 idx = depositID ;
        user.deposits[idx] = Deposit(
            idx,
            plan,
            _amount,
            block.timestamp
        );
        
        totalStaked = totalStaked.add(_amount);
        plans[plan].currentStake += _amount;
        user.numberOfDeposits += 1;
        user.depositIdx.push(idx);
        depositID += 1;
        emit NewDeposit(msg.sender, idx, plan, _amount);
    }
    
    function unstakeGLA(uint256 idx) public {
        bool mature = _afterMaturity(idx);
        
        if (mature){
            _unstakeAfterMaturity(idx);
        }
        else{
            _unstakeBeforeMaturity(idx);
        }
    }

    function _unstakeAfterMaturity(uint256 idx) internal {

        User storage user = users[msg.sender];
        Plan memory plan = plans[user.deposits[idx].plan];
        
        uint256 principal = user.deposits[idx].amount;
        uint256 reward = principal.mul(plan.percent)
                                    .mul(plan.time)
                                    .div(100)
                                    .div(365);

        uint256 withdrawalAmount = principal.add(reward); 

        totalStaked -= principal;
        plans[user.deposits[idx].plan].currentStake -= principal;
        delete users[msg.sender].deposits[idx];
        user.depositIdx = remove(idx, user.depositIdx);
        user.numberOfDeposits -= 1;

        require(withdrawalAmount > 0, "Nothing to unstake");

        address glaTokenAddress = IGameManager(gameManager).getContract("GLAToken");
        IGLAToken(glaTokenAddress).transfer(
            msg.sender,
            withdrawalAmount
        );

        emit UnstakeAfterMaturity(msg.sender, idx, withdrawalAmount, block.timestamp);
    }

    function _unstakeBeforeMaturity(uint256 idx) internal {
        User storage user = users[msg.sender];
        address glaTokenAddress = IGameManager(gameManager).getContract("GLAToken");
        Plan memory plan = plans[user.deposits[idx].plan];
        
        uint256 principal = user.deposits[idx].amount;
        uint256 intended_reward = principal.mul(plan.percent)
                                            .mul(plan.time)
                                            .div(100)
                                            .div(365);

        totalStaked -= principal;
        plans[user.deposits[idx].plan].currentStake -= principal;
        delete users[msg.sender].deposits[idx];
        user.depositIdx = remove(idx, user.depositIdx);
        
        require(principal > 0, "Nothing to unstake");
        IGLAToken(glaTokenAddress).burn(intended_reward);
        
        user.numberOfDeposits -= 1;

        IGLAToken(glaTokenAddress).transfer(
            msg.sender,
            principal
        );

        emit UnstakeBeforeMaturity(msg.sender, idx, principal, block.timestamp);
    }

    function _afterMaturity(uint256 idx) public view returns(bool) {
        User storage user = users[msg.sender];
        Plan memory plan = plans[user.deposits[idx].plan];

        return block.timestamp >= user.deposits[idx].start + plan.time.mul(TIME_STEP);
    }

    function adminEmergencyWithdraw() public onlyOwner {
        address glaTokenAddress = IGameManager(gameManager).getContract(
            "GLAToken"
        );
        IGLAToken(glaTokenAddress).transfer(
            msg.sender,
            IGLAToken(glaTokenAddress).balanceOf(address(this))
        );
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserNumberOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].numberOfDeposits;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].numberOfDeposits; i++) {
            uint256 idx = users[userAddress].depositIdx[i];
            amount = amount.add(users[userAddress].deposits[idx].amount);
        }
    }

    function getUserDepositInfo(address userAddress)
        public
        view
        returns (DepositInfo[] memory)
    {
        DepositInfo[] memory result = new DepositInfo[](
            users[userAddress].depositIdx.length
        );
        
        User storage user = users[userAddress];

        for (uint256 i; i < user.depositIdx.length; i++) {
            uint256 idx = user.depositIdx[i];
            result[i].depositIndex = user.deposits[idx].index;
            result[i].amountDeposit = user.deposits[idx].amount;
            result[i].plan = user.deposits[idx].plan;
            result[i].percent = plans[result[i].plan].percent;
            result[i].start = user.deposits[idx].start;
            result[i].finish = user.deposits[idx].start.add(
                plans[user.deposits[idx].plan].time.mul(TIME_STEP)
            );

            uint256 interestRate = block.timestamp < result[i].finish
                ? block.timestamp.sub(result[i].start).div(TIME_STEP)
                : plans[user.deposits[idx].plan].time;

            result[i].amountGain = user
                .deposits[idx]
                .amount
                .mul(result[i].percent)
                .mul(interestRate)
                .div(100)
                .div(365);
        }
        return result;
    }

    function remove(uint256 _valueToFindAndRemove, uint256[] memory _array) internal pure returns(uint256[] memory) {
        uint256[] memory auxArray = new uint256[](_array.length - 1);
        
        uint256 i = 0;
        uint256 j = 0;
        
        while(i<_array.length){
            if(_array[i] != _valueToFindAndRemove){
                auxArray[j] = _array[i];
                j += 1;
                i += 1;
            }
            else{
                i+=1;
            }
        }
        
        return auxArray;
    }
    
    
    function setGLAMinter(address _glaMinter) public onlyOwner {
        glaMinter = _glaMinter;
    }

    function setGameManager(address _gameManager) public onlyOwner {
        gameManager = _gameManager;
    }
}

interface IGLAToken is IERC20 {
    function burn(uint256 amount) external;
}

interface IGLAMintOperator {
    function mint(address to, uint256 amount) external;
}

interface IGameManager {
    function getContract(string memory contract_)
        external
        view
        returns (address);
}