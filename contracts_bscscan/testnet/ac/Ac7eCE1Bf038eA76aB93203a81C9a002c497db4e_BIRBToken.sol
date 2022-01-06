/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//                .  .......
//             .DDDDNIIIINDDDN .
//           DDNIIII$$$$$Z$IIINDN.
//         ?D?II$$$$$$$$$$$$$$ZIDD
//        NDIIZ$$$$$$$$$,,,,,,?$$ID.
//        D7IZ$N$$DDDN,,,,,,,,,,,,$D.
//       NII$$$$$D.DDDD,,,,,,DDDN,,D+
//      .DII$$$$$DDDDDD,,,,D=:,::=DDD.
//      DDI$$$$$$,NDOD:,,,DI======:ND.
//      D8I$$$$$$,,,,,,,,D+========:DO
//     .DII$$$$$~,,,,,,,,DD??????I+=DD
//     .DII$$$$$,,,,,,,,,D=D88OOD,,DDD
//     NNI$$$$$$,,,,,,,,,N??=DDDDDD,D.
//    NDII$$$$$Z,,,,,,,,,,D???????D,D.
//   NIIZ$O$$$$,,,,,,,,,,,+N????ID,,D.
// .DII$$$$ONZ$,,,,,,,,,,,,,,DD$,,,DD.
//  II$$$$$$OD,,,,,,,,,,,,,,,,,,,,,DN
//   Z$$$$$$OOD,,,,,,,,,,,,,,,,,,,,D.
//    $$$$$$OOD,,,,,,,,,,,,,,,,,,,,D.
//     ,$$$$OOZD,,,,,,,,,,,,,,,,,,DD
//      .$$ZOOZD~,,,,,,,,,,,,,,,,,D.
//        .ZOOD=~~~,,,,,,,,,,,,,~DD
//          ..D~~~~~~~~=,,,~~~~~..
//                 .:~~~~~~~~~ .
//
//                     BIRB



/**
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

/**
 * @dev Interface of the BEP20 standard as defined in the BEP.
 */

interface IBEP20 {
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
     * desired value afterwards
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

/**
 * @dev Implementation of the {IBEP20} interface.
 */

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _totalSupply = 100000000000000000000000000;

        _beforeTokenTransfer(address(0), msg.sender, _totalSupply);
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the BEP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
contract Ownable is Context {
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


interface IPancakePair  {
    function sync() external;
}

interface IPancakeFactory  {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BIRBToken is BEP20, Ownable {
    using SafeMath for uint256;

    uint256 public lastHatchTime;

    uint256 public totalHatched;

    uint256 public constant HATCH_RATE = 5;

    uint256 public constant HATCH_REWARD = 1;

    uint256 public constant POOL_REWARD = 48;

    uint256 public lastRewardTime;

    uint256 public rewardNest;

    mapping (address => uint256) public claimedRewards;

    mapping (address => uint256) public unclaimedRewards;

    mapping (uint256 => address) public topHolder;

    uint256 public constant MAX_TOP_HOLDERS = 250;

    uint256 internal totalTopHolders;

    address public pauser;

    bool public paused;

    BEP20 internal WBNB = BEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    IPancakeFactory public pancakeSwapFactory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    address public pancakeSwapPool;

    modifier onlyPauser() {
        require(pauser == _msgSender(), "BIRB: Caller is not the pauser.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "BIRB: paused");
        _;
    }

    modifier when3DaysBetweenLastSnapshot() {
        require((block.timestamp - lastRewardTime) >= 3 days, "BIRB: Not enough days since last snapshot taken.");
        _;
    }
    event MintNewSupply(address user, uint newSupply);
    event PoolHatched(address user, uint256 hatchAmount, uint256 newTotalSupply, uint256 newPancakeSwapPoolSupply, uint256 userReward, uint256 newNestReward);
    event UnclaimedRewardsDistribution(uint256 totalTopHolders, uint256 totalPayout, uint256 snapshot);
    event RewardClaimed(address indexed topHolderAddress, uint256 claimedReward);

    event PancakePoolCreated(address pancakeSwapPoole, address WETH, address createdBy);
    event newPauserAdded(address newPauserAddress, address updatedBy);
    event contractPaused(bool status, address updatedBy);
    event contractUnPaused(bool status, uint256 lastHatchTime, uint256 lastRewardTime, uint256 rewardNest, address updatedBy);


    constructor()
    public
    Ownable()
    BEP20("Birb", "BIRB")
    {
        setPauser(msg.sender);
        paused = true;
    }

    function setPancakeSwapPool() external onlyOwner {
        require(pancakeSwapPool == address(0), "BIRB: Pool already created");
        pancakeSwapPool = pancakeSwapFactory.createPair(address(WBNB), address(this));

        emit PancakePoolCreated(pancakeSwapPool, address(WBNB), msg.sender);
    }

    function setPauser(address newPauser) public onlyOwner {
        require(newPauser != address(0), "BIRB: Pauser is the zero address.");
        pauser = newPauser;

        emit newPauserAdded(newPauser, msg.sender);
    }

    function unpause() external onlyPauser {
        paused = false;

        lastHatchTime = block.timestamp;
        lastRewardTime = block.timestamp;
        rewardNest = 0;

        emit contractUnPaused(paused, lastHatchTime, lastRewardTime, rewardNest, msg.sender);
    }

    function pause() external onlyPauser {
        paused = true;

        emit contractPaused(paused, msg.sender);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused || msg.sender == pauser, "BIRB: Token transfer while paused and not pauser role.");
    }

    function getInfoFor(address addr) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            balanceOf(addr),
            claimedRewards[addr],
            balanceOf(pancakeSwapPool),
            _totalSupply,
            totalHatched,
            getHatchAmount(),
            lastHatchTime,
            lastRewardTime,
            rewardNest
        );
    }

    function hatchNest() external {
        uint256 hatchAmount = getHatchAmount();
        require(hatchAmount >= 1 ether, "hatchNest: min hatch amount not reached.");

        lastHatchTime = block.timestamp;

        uint256 userReward = hatchAmount.mul(HATCH_REWARD).div(100);
        uint256 poolReward = hatchAmount.mul(POOL_REWARD).div(100);
        uint256 finalHatch = hatchAmount.sub(userReward).sub(poolReward);

        _totalSupply = _totalSupply.sub(finalHatch);
        _balances[pancakeSwapPool] = _balances[pancakeSwapPool].sub(hatchAmount);

        totalHatched = totalHatched.add(finalHatch);
        rewardNest = rewardNest.add(poolReward);

        _balances[msg.sender] = _balances[msg.sender].add(userReward);

        IPancakePair(pancakeSwapPool).sync();

        emit PoolHatched(msg.sender, hatchAmount, _totalSupply, balanceOf(pancakeSwapPool), userReward, poolReward);
    }

    function getHatchAmount() public view returns (uint256) {
        if (paused) return 0;
        require((block.timestamp - lastHatchTime) >= 86400, "BIRB: Already Hatched");
        uint256 tokensInPancakeSwap = balanceOf(pancakeSwapPool);
        return (tokensInPancakeSwap.mul(HATCH_RATE).div(100));
    }

    function updateTopHolders(address[] calldata holders) external onlyOwner when3DaysBetweenLastSnapshot {
        delete totalTopHolders;
        require(holders.length > 0, "BIRB: No Holder addresses found");
        totalTopHolders = holders.length < MAX_TOP_HOLDERS ? holders.length : MAX_TOP_HOLDERS;

        uint256 toPayout = rewardNest.div(totalTopHolders);
        uint256 totalPayoutSent = rewardNest;
        for (uint256 i = 0; i < totalTopHolders; i++) {
            topHolder[i] = holders[i];
            unclaimedRewards[holders[i]] = unclaimedRewards[holders[i]].add(toPayout);
        }

        lastRewardTime = block.timestamp;
        rewardNest = 0;

        emit UnclaimedRewardsDistribution(totalTopHolders, totalPayoutSent, block.timestamp);
    }

    function claimRewards() external {
        require(paused == false, "BIRB: Contract is paused");
        require(unclaimedRewards[msg.sender] > 0, "BIRB: Nothing left to claim.");

        uint256 unclaimedReward = unclaimedRewards[msg.sender];
        unclaimedRewards[msg.sender] = 0;
        claimedRewards[msg.sender] = claimedRewards[msg.sender].add(unclaimedReward);
        _balances[msg.sender] = _balances[msg.sender].add(unclaimedReward);

        emit RewardClaimed(msg.sender, unclaimedReward);
    }
}