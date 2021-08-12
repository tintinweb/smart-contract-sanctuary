/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// Part: OpenZeppelin/[email protected]/Context

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// Part: Roles

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: PauserRole

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// Part: PoolTokenWrapper

contract PoolTokenWrapper {
    using SafeMath for uint256;
    IERC20 public token;

    constructor(IERC20 _erc20Address) public {
        token = IERC20(_erc20Address);
    }

    uint256 private _totalSupply;
    // Objects balances [id][address] => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => uint256) private _accountBalances;
    mapping(uint256 => uint256) private _poolBalances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOfAccount(address account) public view returns (uint256) {
        return _accountBalances[account];
    }

    function balanceOfPool(uint256 id) public view returns (uint256) {
        return _poolBalances[id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _balances[id][account];
    }

    function stake(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _poolBalances[id] = _poolBalances[id].add(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].add(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _poolBalances[id] = _poolBalances[id].sub(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
    }

    function transfer(
        uint256 fromId,
        uint256 toId,
        uint256 amount
    ) public virtual {
        _poolBalances[fromId] = _poolBalances[fromId].sub(amount);
        _balances[fromId][msg.sender] = _balances[fromId][msg.sender].sub(
            amount
        );

        _poolBalances[toId] = _poolBalances[toId].add(amount);
        _balances[toId][msg.sender] = _balances[toId][msg.sender].add(amount);
    }
}

// Part: Pausable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: MemeXStaking.sol

contract MemeXStaking is PoolTokenWrapper, Ownable, Pausable {
    using SafeMath for uint256;

    struct Card {
        uint256 points;
        uint256 releaseTime;
        uint256 mintFee;
    }

    struct Pool {
        uint256 periodStart;
        uint256 maxStake;
        uint256 rewardRate; // 11574074074000, 1 point per day per staked MEME
        uint256 feesCollected;
        uint256 spentPineapples;
        uint256 controllerShare;
        address artist;
        mapping(address => uint256) lastUpdateTime;
        mapping(address => uint256) points;
        mapping(uint256 => Card) cards;
    }

    address public controller;
    address public rescuer;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(uint256 => Pool) public pools;

    event UpdatedArtist(uint256 poolId, address artist);
    event PoolAdded(
        uint256 poolId,
        address artist,
        uint256 periodStart,
        uint256 rewardRate,
        uint256 maxStake
    );
    event CardAdded(
        uint256 poolId,
        uint256 cardId,
        uint256 points,
        uint256 mintFee,
        uint256 releaseTime
    );
    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 poolId, uint256 amount);
    event Transferred(
        address indexed user,
        uint256 fromPoolId,
        uint256 toPoolId,
        uint256 amount
    );

    modifier updateReward(address account, uint256 id) {
        if (account != address(0)) {
            pools[id].points[account] = earned(account, id);
            pools[id].lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    modifier poolExists(uint256 id) {
        require(pools[id].rewardRate > 0, "pool does not exists");
        _;
    }

    constructor(address _controller, IERC20 _tokenAddress)
        public
        PoolTokenWrapper(_tokenAddress)
    {
        controller = _controller;
    }

    function cardMintFee(uint256 pool, uint256 card)
        public
        view
        returns (uint256)
    {
        return pools[pool].cards[card].mintFee;
    }

    function cardReleaseTime(uint256 pool, uint256 card)
        public
        view
        returns (uint256)
    {
        return pools[pool].cards[card].releaseTime;
    }

    function cardPoints(uint256 pool, uint256 card)
        public
        view
        returns (uint256)
    {
        return pools[pool].cards[card].points;
    }

    function earned(address account, uint256 pool)
        public
        view
        returns (uint256)
    {
        Pool storage p = pools[pool];
        uint256 blockTime = block.timestamp;
        return
            balanceOf(account, pool)
                .mul(blockTime.sub(p.lastUpdateTime[account]).mul(p.rewardRate))
                .div(1e8)
                .add(p.points[account]);
    }

    // override PoolTokenWrapper's stake() function
    function stake(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
        whenNotPaused
    {
        Pool storage p = pools[pool];

        require(block.timestamp >= p.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, pool)) <= p.maxStake,
            "stake exceeds max"
        );

        super.stake(pool, amount);
        emit Staked(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's withdraw() function
    function withdraw(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
    {
        require(amount > 0, "cannot withdraw 0");

        super.withdraw(pool, amount);
        emit Withdrawn(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's transfer() function
    function transfer(
        uint256 fromPool,
        uint256 toPool,
        uint256 amount
    )
        public
        override
        poolExists(fromPool)
        poolExists(toPool)
        updateReward(msg.sender, fromPool)
        updateReward(msg.sender, toPool)
        whenNotPaused
    {
        Pool storage toP = pools[toPool];

        require(block.timestamp >= toP.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, toPool)) <= toP.maxStake,
            "stake exceeds max"
        );

        super.transfer(fromPool, toPool, amount);
        emit Transferred(msg.sender, fromPool, toPool, amount);
    }

    function transferAll(uint256 fromPool, uint256 toPool) external {
        transfer(fromPool, toPool, balanceOf(msg.sender, fromPool));
    }

    function exit(uint256 pool) external {
        withdraw(pool, balanceOf(msg.sender, pool));
    }

    function setArtist(uint256 pool, address artist) public onlyOwner {
        uint256 amount = pendingWithdrawals[artist];
        pendingWithdrawals[artist] = 0;
        pendingWithdrawals[artist] = pendingWithdrawals[artist].add(amount);
        pools[pool].artist = artist;

        emit UpdatedArtist(pool, artist);
    }

    function setController(address _controller) public onlyOwner {
        uint256 amount = pendingWithdrawals[controller];
        pendingWithdrawals[controller] = 0;
        pendingWithdrawals[_controller] = pendingWithdrawals[_controller].add(
            amount
        );
        controller = _controller;
    }

    function setRescuer(address _rescuer) public onlyOwner {
        rescuer = _rescuer;
    }

    function setControllerShare(uint256 pool, uint256 _controllerShare)
        public
        onlyOwner
        poolExists(pool)
    {
        pools[pool].controllerShare = _controllerShare;
    }

    function addCard(
        uint256 pool,
        uint256 id,
        uint256 points,
        uint256 mintFee,
        uint256 releaseTime
    ) public onlyOwner poolExists(pool) {
        Card storage c = pools[pool].cards[id];
        c.points = points;
        c.releaseTime = releaseTime;
        c.mintFee = mintFee;
        emit CardAdded(pool, id, points, mintFee, releaseTime);
    }

    function createPool(
        uint256 id,
        uint256 periodStart,
        uint256 maxStake,
        uint256 rewardRate,
        uint256 controllerShare,
        address artist
    ) public onlyOwner returns (uint256) {
        require(pools[id].rewardRate == 0, "pool exists");

        Pool storage p = pools[id];

        p.periodStart = periodStart;
        p.maxStake = maxStake;
        p.rewardRate = rewardRate;
        p.controllerShare = controllerShare;
        p.artist = artist;

        emit PoolAdded(id, artist, periodStart, rewardRate, maxStake);
    }

    function withdrawFee() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function isLiquidityProvider(address _address) public view returns (bool) {
        return false;
    }
}