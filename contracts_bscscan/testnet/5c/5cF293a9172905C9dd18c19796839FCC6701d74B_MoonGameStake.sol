pragma solidity ^0.8.0;

import { IDividendDistributor } from "./IDividendDistributor.sol";
import { SafeMath } from './SafeMath.sol';
import { Auth } from "./Auth.sol";
import { Pausable } from "./Pausable.sol";
import "./IReflectionPool.sol";
import "./ReflectionLocker02.sol";
import "./IMoonGame.sol";

contract MoonGameStake is IReflectionPool, Auth, Pausable {
    using SafeMath for uint256;

    IBEP20 public rewardsToken;
    address public rewardWallet;
    uint256 public rewardPerBlock;
    uint256 public BONUS_MULTIPLIER = 1;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    mapping (address => bool) excludeSwapperRole;
    mapping (address => ReflectionLocker02) public lockers;

    ReflectionLocker02[] public lockersArr;
    IDividendDistributor distributor;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IMoonGame moonGame;

    uint public lunchTime;

    struct TokenPool {
        uint totalShares;
        uint totalDividends;
        uint totalDistributed;
        uint dividendsPerShare;
        IBEP20 stakingToken;
    }

    TokenPool public tokenPool;

    //Shares by token vault
    mapping ( address => Share) public shares;
    uint public duration = 14 days;
    uint public stakeMinDuration = 15 days;
    mapping(address=>uint) stakingTime;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    constructor (address _stakingToken, address _rewardsToken, address _rewardWallet, uint _startBlock) Auth (msg.sender) {
        rewardsToken = IBEP20(_rewardsToken);
        tokenPool.stakingToken = IBEP20(_stakingToken);
        moonGame = IMoonGame(_stakingToken);
        rewardWallet = _rewardWallet;
        lunchTime = block.timestamp;
        distributor = IDividendDistributor(moonGame.distributorAddress());
        startBlock = _startBlock;
        lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    }

    function lunch() external authorized {
        lunchTime = block.timestamp;
    }

    function setDuration(uint256 _duration) external onlyOwner{
        duration = _duration;
    }

    function setMinDuration(uint _stakeMinDuration) external onlyOwner{
        stakeMinDuration = _stakeMinDuration;
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner{
        rewardWallet = _rewardWallet;
    }

    function setRewardPerBlock(uint _amount) external onlyOwner{
        rewardPerBlock = _amount;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function releaseAt(address _user) external returns(uint) {
        if(stakingTime[_user] == 0){
            return 0;
        }
        return stakingTime[_user].add(stakeMinDuration);
    }

    // Lets you stake token A. Creates a reflection locker to handle the reflections in an efficient way.
    function enterStaking(uint256 amount) external whenNotPaused {
        if (amount == 0)
            amount = tokenPool.stakingToken.balanceOf(msg.sender);

        require(amount <= tokenPool.stakingToken.balanceOf(msg.sender), "Insufficient balance to enter staking");
        require(tokenPool.stakingToken.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        updatePool();
        // Transfer the tokens to the staking contract
        moonGame.setIsFeeExempt(msg.sender, true);
        bool success = tokenPool.stakingToken.transferFrom(msg.sender, address(this), amount);
        moonGame.setIsFeeExempt(msg.sender, false);

        require(success, "Failed to fetch tokens towards the staking contract");
        stakingTime[msg.sender] = block.timestamp;
        // Create a reflection locker for type A pool
        if (address(tokenPool.stakingToken) == address(moonGame)) {
            bool lockerExists = address(lockers[msg.sender]) == address (0);

            ReflectionLocker02 locker;
            if (!lockerExists) {
                locker = lockers[msg.sender];
            } else {
                locker = new ReflectionLocker02(msg.sender, tokenPool.stakingToken, moonGame.distributorAddress());
                lockersArr.push(locker); //Stores locker in array
                lockers[msg.sender] = locker; //Stores it in a mapping
                address lockerAdd = address(lockers[msg.sender]);
                moonGame.setIsFeeExempt(lockerAdd, true);

                emit ReflectionLockerCreated(lockerAdd);
            }
            tokenPool.stakingToken.transfer(address(locker), amount);
        }

        // Give out rewards if already staking
        if (shares[msg.sender].amount > 0) {
            giveStakingReward(msg.sender);
        }

        addShareHolder(msg.sender, amount);
        emit EnterStaking(msg.sender, amount);
    }

    function reflectionsInLocker(address holder) public view returns (uint) {
        return address(lockers[holder]).balance + distributor.getUnpaidEarnings(address(lockers[holder]));
    }

    function releaseTime(address holder) external view returns(uint){
        if(stakingTime[holder]!=0){
            return stakingTime[holder] + stakeMinDuration;
        }else{
            return 0;
        }
    }

    function leaveStaking(uint amt) external {
        require(shares[msg.sender].amount > 0, "You are not currently staking.");
        require(block.timestamp >= stakingTime[msg.sender].add(stakeMinDuration), "Staking min duration require");
        updatePool();
        // Pay native token rewards.
        if (getUnpaidEarnings(msg.sender) > 0) {
            giveStakingReward(msg.sender);
        }
        uint amtMoonClaimed = 0;
        // Get rewards from locker
        if (address(tokenPool.stakingToken) == address(moonGame)) {
            lockers[msg.sender].claimTokens(amt);
            amtMoonClaimed = lockers[msg.sender].claimReflections();
        } else {
            // Get rewards from contract
            tokenPool.stakingToken.transfer(msg.sender, shares[msg.sender].amount);
        }
        if (amt == 0) {
            amt = shares[msg.sender].amount;
            removeShareHolder();
        } else {
            _removeShares(amt);
        }

        emit LeaveStaking(msg.sender, amt, amtMoonClaimed);
    }

    function giveStakingReward(address shareholder) internal {
        require(shares[shareholder].amount > 0, "You are not currently staking");

        uint256 amount = getUnpaidEarnings(shareholder);

        if(amount > 0){
            tokenPool.totalDistributed = tokenPool.totalDistributed.add(amount);
            rewardsToken.transfer(shareholder, amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function harvest() external whenNotPaused {
        updatePool();
        require(getUnpaidEarnings(msg.sender) > 0 || reflectionsInLocker(msg.sender) > 0, "No earnings yet ser");
        uint unpaid = getUnpaidEarnings(msg.sender);
        require(isLiquid(unpaid), "rewardsToken's insufficient");
        uint amtMoonClaimed = lockers[msg.sender].claimReflections();
        giveStakingReward(msg.sender);
        emit Harvest(msg.sender, unpaid, amtMoonClaimed);
    }

    function isLiquid(uint amount) internal view returns (bool){
        return rewardsToken.balanceOf(address(this)) >= amount;
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function pendingReward(address _user) external view returns (uint256) {
        uint256 dividendsPerShare = tokenPool.dividendsPerShare;
        uint256 lpSupply = tokenPool.totalShares;
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 moonGameReward = multiplier.mul(rewardPerBlock);
            dividendsPerShare = dividendsPerShare.add(moonGameReward.mul(dividendsPerShareAccuracyFactor).div(lpSupply));
        }
        return shares[_user].amount.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor).sub(shares[_user].totalExcluded);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 lpSupply = tokenPool.totalShares;
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 moonGameReward = multiplier.mul(rewardPerBlock);
        rewardsToken.transferFrom(rewardWallet, address(this), moonGameReward);
        if (!excludeSwapperRole[msg.sender]) {
            setShares(moonGameReward);
        }
    }

    // function deposit(uint amount) external onlyOwner {
    //     require(!paused(), "Contract has been paused.");
    //     require(block.timestamp < (lunchTime + duration), "Contract has ended.");
    //     require(rewardsToken.balanceOf(_msgSender()) >= amount, "rewardsToken's amount insufficient");
    //     require(rewardsToken.allowance(_msgSender(), address(this))>=amount, "rewardsToken's allowance insufficient");
    //     rewardsToken.transferFrom(_msgSender(), address(this), amount);
    //     if (!excludeSwapperRole[msg.sender]) {
    //         setShares(amount);
    //     }
    // }

    // Update pool shares and user data
    function addShareHolder(address shareholder, uint amount) internal {
        tokenPool.totalShares = tokenPool.totalShares.add(amount);
        shares[shareholder].amount = shares[shareholder].amount + amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function removeShareHolder() internal {
        tokenPool.totalShares = tokenPool.totalShares.sub(shares[msg.sender].amount);
        shares[msg.sender].amount = 0;
        shares[msg.sender].totalExcluded = 0;
    }

    function _removeShares(uint amt) internal {
        tokenPool.totalShares = tokenPool.totalShares.sub(amt);
        shares[msg.sender].amount = shares[msg.sender].amount.sub(amt);
        shares[msg.sender].totalExcluded = getCumulativeDividends(shares[msg.sender].amount);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(tokenPool.dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function setShares(uint amount) internal returns (uint) {
        tokenPool.totalDividends = tokenPool.totalDividends.add(amount);
        tokenPool.dividendsPerShare = tokenPool.dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(tokenPool.totalShares));
        return amount;
    }

    function setSwapperExcluded(address _add, bool _excluded) external authorized {
        excludeSwapperRole[_add] = _excluded;
    }

    function emergencyWithdraw() external {
        if (address(tokenPool.stakingToken) == address(moonGame)) {
            uint amtClaimed = lockers[msg.sender].claimTokens(0);
            moonGame.transfer(msg.sender, amtClaimed);
        } else {
            tokenPool.stakingToken.transfer(msg.sender, shares[msg.sender].amount);
        }
        removeShareHolder();
    }

    function pause(bool _pauseStatus) external authorized {
        if (_pauseStatus) {
            _pause();
        } else {
            _unpause();
        }
    }

    //Events
    event ReflectionLockerCreated(address);
    event EnterStaking(address, uint);
    event LeaveStaking(address, uint, uint);
    event Harvest(address, uint, uint);
    event PoolLiquified(uint, uint);
}

// SPDX-License-Identifier: MIT

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

import "./IDividendDistributor.sol";
import "./IReflectionLocker.sol";
import "./IReflectionPool.sol";
import "./IBEP20.sol";

contract ReflectionLocker02 is IReflectionLocker {
    IBEP20 moonGame;
    IReflectionPool rblo;
    IDividendDistributor distributor;
    address lockOwner;

    constructor (address _lockOwner, IBEP20 stakingToken, address dividendDistributor) public {
        lockOwner = _lockOwner;
        rblo = IReflectionPool(msg.sender);
        moonGame = stakingToken;
        distributor = IDividendDistributor(dividendDistributor);
    }

    receive() external payable {
        
    }

    modifier onlyLockOwner {
        require(tx.origin == lockOwner || msg.sender == address(rblo) || msg.sender == address (this), "Fuck off.");
        _;
    }

    function unstakeAmount(uint amt) public onlyLockOwner {
        if (amt == 0)
            amt = moonGame.balanceOf(address(this));
        uint tokensClaimed = claimTokens(amt);
        emit Unstake(tokensClaimed);
    }

    function claimBNB() public onlyLockOwner {
        claimReflections();
    }

    // Amt 0 is claim all
    function claimTokens(uint amt) public override onlyLockOwner returns (uint) {
        require(moonGame.balanceOf(address (this)) >= amt, "Not enough tokens");
        if (amt == 0) {
            amt = moonGame.balanceOf(address(this));
            moonGame.transfer(lockOwner, amt);
        }
        else {
            moonGame.transfer(lockOwner, amt);
        }
        return amt;
    }

    function claimReflections() public override onlyLockOwner returns (uint) {
        _getFromDistributor();
        uint balance = address(this).balance;
        _transferBNB(lockOwner);
        emit ClaimReflections(balance);
        return balance;
    }

    function claimAll() public override onlyLockOwner returns (uint, uint) {
        _getFromDistributor();
        uint amtBNB = address(this).balance;
        _transferBNB(lockOwner);
        uint amtMoonGame = moonGame.balanceOf(address(this));
        moonGame.transfer(lockOwner, amtMoonGame);
        emit ClaimAll(amtMoonGame, amtBNB);
        return (amtMoonGame, amtBNB);
    }

    function _getFromDistributor() internal {
        try distributor.claimDividend() {

        } catch {

        }
    }

    function _transferBNB(address to) internal {
        if (address(this).balance > 0){
            (bool success, ) = to.call{value: address(this).balance}("");
            require(success, "Not successful");
        }            
    }

    function emergencyWithdraw() external onlyLockOwner {
        uint amt = moonGame.balanceOf(address(this));
        moonGame.transfer(msg.sender, amt);
    }

    event ClaimAll(uint indexed amtMoonGame, uint indexed amtBNB);
    event ClaimReflections(uint indexed amtBNB);
    event Unstake(uint indexed amt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IReflectionPool {

}

interface IReflectionLocker {
    function claimTokens(uint) external returns (uint);
    function claimReflections() external returns (uint);
    function claimAll() external returns (uint, uint);

}

interface IMoonGame {
    function setIsFeeExempt(address holder, bool exempt) external;
    function distributorAddress() external returns(address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend() external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}