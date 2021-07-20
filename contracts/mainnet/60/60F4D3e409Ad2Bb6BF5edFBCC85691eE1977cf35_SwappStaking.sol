/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

pragma solidity 0.8.0;

interface TokenInterface is IERC20 {
    function mintSupply(address _investorAddress, uint256 _amount) external;
	function burn(uint256 amount) external;
}

interface Minter {
    function mint(address to, uint256 amount) external;
}

interface SwappYieldFarm {
    function clearDurationBonus(address staker) external;
    function reduceDurationBonus(address staker, uint256 reduceMultiplier) external;
    function getUserLastEpochHarvested(address staker) external returns (uint);
}

interface Staking {
    function referrals(address staker) external returns (address);
}

contract SwappStaking is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint128;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);
    uint256 constant private CALC_MULTIPLIER = 1000000;

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public epoch1Start;

    // duration of each epoch
    uint256 public epochDuration;

    // holds the current balance of the user for each token
    mapping(address => mapping(address => uint256)) private balances;
    
    address constant private swapp = 0x8CB924583681cbFE487A62140a994A49F833c244;
	address constant private minter = 0xBC1f9993ea5eE2C77909bf43d7a960bB8dA8C9B9;
    address constant private staking = 0x245a551ee0F55005e510B239c917fA34b41B3461;
	address public farm;
    
    struct Pool {
        uint256 size;
        bool set;
    }

    // for each token, we store the total pool size
    mapping(address => mapping(uint256 => Pool)) private poolSize;

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    // balanceCheckpoints[user][token][]
    mapping(address => mapping(address => Checkpoint[])) private balanceCheckpoints;

    mapping(address => uint128) private lastWithdrawEpochId;


    //referrals
    uint256 public firstReferrerRewardPercentage;
    uint256 public secondReferrerRewardPercentage;

    struct Referrer {
        // uint256 totalReward;
        uint256 referralsCount;
        mapping(uint256 => address) referrals;
    }

    // staker to referrer
    mapping(address => address) public referrals;
    // referrer data
    mapping(address => Referrer) public referrers;

	uint256 constant public NR_OF_EPOCHS = 60;
	
	struct Topup {
	    uint256 totalTopups;
        mapping(uint256 => uint128) epochs;
        mapping(uint256 => uint256) amounts;
    }
	
	struct Stake {
		uint128 startEpoch;
		uint256 startTimestamp;
		uint128 endEpoch;
		uint128 duration;
		bool active;
	}
	
	mapping(address => Stake) public stakes;
    mapping(address => Topup) public topups;
	uint256 public stakedSwapp;
	
	modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can perfrom this action");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused(), "Staking: contract is paused");
        _;
    }

    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount, uint256 endEpoch);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount, uint256 penalty);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId, address[] tokens);
    event EmergencyWithdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event RegisteredReferer(address indexed referral, address indexed referrer, uint256 amount);
    event Penalty(address indexed staker, uint128 indexed epochId, uint256 amount);
    event PrepareMigration(address indexed staker, uint256 balance);

    address public _owner;
    address private _migration;
    bool private _paused = false;
    bool emergencyWithdrawAllowed = false;

    constructor () {
        epoch1Start = 1626652800;
        epochDuration = 2419200; // 28 days

        _owner = msg.sender;

        firstReferrerRewardPercentage = 1000;
        secondReferrerRewardPercentage = 500;
    }

    /*
     * Stores `amount` of `tokenAddress` tokens for the `user` into the vault
     */
    function deposit(address tokenAddress, uint256 amount, address referrer, uint128 endEpoch) public nonReentrant whenNotPaused {
        require(amount > 0, "Staking: Amount must be > 0");
		require(tokenAddress == swapp, "This pool accepts only Swapp token");
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Staking: Token allowance too small");
		
		uint128 currentEpoch = getCurrentEpoch();
        require(endEpoch > currentEpoch && endEpoch <= NR_OF_EPOCHS.add(1), "Staking: not acceptable end of stake");
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        TokenInterface(tokenAddress).burn(amount);
        stakedSwapp = stakedSwapp.add(amount);

        if (referrer != address(0)) {
            processReferrals(referrer, amount);
        }

        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].add(amount);
        
        handleStakeDuration(endEpoch, amount);

        // epoch logic
        uint128 currentMultiplier = currentEpochMultiplier();

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the next epoch pool size
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        
        pNextEpoch.size = stakedSwapp;
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];

        uint256 balanceBefore = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (checkpoints.length == 0) {
            checkpoints.push(Checkpoint(currentEpoch, currentMultiplier, 0, amount));

            // next epoch => multiplier is 1, epoch deposits is 0
            checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0));
        } else {
            uint256 last = checkpoints.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            if (checkpoints[last].epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    BASE_MULTIPLIER,
                    amount,
                    currentMultiplier
                );
                checkpoints.push(Checkpoint(currentEpoch, multiplier, getCheckpointBalance(checkpoints[last]), amount));
                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the previous epoch
            else if (checkpoints[last].epochId == currentEpoch) {
                checkpoints[last].multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    checkpoints[last].multiplier,
                    amount,
                    currentMultiplier
                );
                checkpoints[last].newDeposits = checkpoints[last].newDeposits.add(amount);

                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the current epoch
            else {
                if (last >= 1 && checkpoints[last - 1].epochId == currentEpoch) {
                    checkpoints[last - 1].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last - 1]),
                        checkpoints[last - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last - 1].newDeposits = checkpoints[last - 1].newDeposits.add(amount);
                }

                checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            }
        }

        uint256 balanceAfter = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.add(balanceAfter.sub(balanceBefore));

        emit Deposit(msg.sender, tokenAddress, amount, endEpoch);
    }
    
    function handleStakeDuration(uint128 endEpoch, uint256 amount) internal {
        Stake storage stake = stakes[msg.sender];
        uint128 currentEpoch = getCurrentEpoch();
        
		if (!stake.active) {
			stake.startEpoch = currentEpoch;
			stake.startTimestamp = block.timestamp;
			stake.endEpoch = endEpoch;
			stake.duration = endEpoch - currentEpoch;
			stake.active = true;
		}

        Topup storage topupData = topups[msg.sender];

        uint256 currentTopup = topupData.totalTopups + 1;
        topupData.totalTopups = currentTopup;
        topupData.epochs[currentTopup] = currentEpoch;
        topupData.amounts[currentTopup] = amount;
    }
    
    function getTopupById(address staker, uint256 id) public view returns (uint128 epochId, uint256 amount) {
        return (topups[staker].epochs[id], topups[staker].amounts[id]);
    }
    
    function calcDurationBonusMultiplier(uint128 epochId, address staker) external view returns (uint256) {
        Topup storage topupData = topups[staker];
        // only if there were topups
        if (topupData.totalTopups > 0) {
            uint256 dividend = 0;
            uint256 divider = 0;
            for (uint256 i = 1; i <= topupData.totalTopups; i++) {
                // Topup storage topup = topups[staker];
                uint128 startEpoch = topupData.epochs[i];
                uint256 amount = topupData.amounts[i];
                // correct multiplier only for epoch from topup starts
                if (epochId < startEpoch) {
                    continue;
                }
                // correct multiplier only for epoch from current stake starts
                if (epochId < stakes[msg.sender].startEpoch) {
                    continue;
                }
                
                dividend += epochId.sub(startEpoch).mul(CALC_MULTIPLIER).div(epochId) * amount;
                divider += amount;
            }

            if (divider > 0) {
                return dividend.div(divider);
            }
        }
        return 0;
    }
    
    function stakeData(address staker) external view returns (uint256 startEpoch, uint256 endEpoch, bool active) {
        Stake memory stake = stakes[staker];
        return (stake.startEpoch, stake.endEpoch, stake.active);
    }
    
    function setFarm(address _farm) external onlyOwner {
        farm = _farm;
    }

    // must be in bases point ( 1,5% = 150 bp)
    function updateReferrersPercentage(uint256 first, uint256 second) external onlyOwner {
        firstReferrerRewardPercentage = first;
        secondReferrerRewardPercentage = second;
    }
    
    function allowEmergencyWithdraw() external onlyOwner{
        emergencyWithdrawAllowed = true;
    }
    
    function disallowEmergencyWithdraw() external onlyOwner{
        emergencyWithdrawAllowed = false;
    }

    function processReferrals(address referrer, uint256 amount) internal {
        //get referrer from first staking pool
        address firstReferrer = Staking(staking).referrals(msg.sender);
        if(firstReferrer != address(0)) {
            referrer = firstReferrer;
        }
        
        //Return if sender has referrer alredy or referrer is contract or self ref
        if (hasReferrer(msg.sender) || !notContract(referrer) || referrer == msg.sender) {
            return;
        }

        //check cross refs 
        if (referrals[referrer] == msg.sender || referrals[referrals[referrer]] == msg.sender) {
            return;
        }
        
        //check if already has stake, do not add referrer if has
        if (balanceOf(msg.sender, swapp) > 0) {
            return;
        }

        referrals[msg.sender] = referrer;

        Referrer storage refData = referrers[referrer];

        refData.referralsCount = refData.referralsCount.add(1);
        refData.referrals[refData.referralsCount] = msg.sender;
        emit RegisteredReferer(msg.sender, referrer, amount);
    }

    function hasReferrer(address addr) public view returns(bool) {
        return referrals[addr] != address(0);
    }

    function getReferralById(address referrer, uint256 id) public view returns (address) {
        return referrers[referrer].referrals[id];
    }
    
    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `user`
     */
    function withdraw(address tokenAddress, uint256 amount) public nonReentrant whenNotPaused {
        require(balances[msg.sender][tokenAddress] >= amount, "Staking: balance too small");
        uint128 currentEpoch = getCurrentEpoch();
        Stake storage stake = stakes[msg.sender];
        require(currentEpoch > stake.startEpoch, "Staking: withdraw is not allowed on stake start epoch");
        
        if (currentEpoch < stake.endEpoch) {
            uint256 userLastEpochHarvested = SwappYieldFarm(farm).getUserLastEpochHarvested(msg.sender);
            require(userLastEpochHarvested == currentEpoch.sub(1), "Staking: withdraw allowed only after all epoch before current epoch are harvested");
        }
        
        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].sub(amount);
        
        if (balances[msg.sender][tokenAddress] == 0) {
    		if (stake.active) {
    			stake.active = false;
    		}
    		
    		if (currentEpoch < stake.endEpoch) {
    		    SwappYieldFarm(farm).clearDurationBonus(msg.sender);
    		}
        } else {
            if (currentEpoch < stake.endEpoch) {
                uint256 balanceBefore = balances[msg.sender][tokenAddress].add(amount);
                uint256 reduceMultiplier = balances[msg.sender][tokenAddress].mul(CALC_MULTIPLIER).div(balanceBefore);
    		    SwappYieldFarm(farm).reduceDurationBonus(msg.sender, reduceMultiplier);
    		}
        }
        
        uint256 penalty = calcPenalty(amount);
        uint256 amountToMint = amount.sub(penalty);
        stakedSwapp = stakedSwapp.sub(amount);
        
        if (penalty > 0) {
            emit Penalty(msg.sender, currentEpoch, penalty);
        }
        
        if (amountToMint > 0) {
		    Minter(minter).mint(msg.sender, amountToMint);
        }
        
        // epoch logic
        
        lastWithdrawEpochId[tokenAddress] = currentEpoch;

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        
        pNextEpoch.size = stakedSwapp;
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(Checkpoint(currentEpoch, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore.sub(currentEpochCheckpoint.startBalance).mul(BASE_MULTIPLIER).div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint.newDeposits.sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint.startBalance.sub(
                    amount.sub(currentEpochCheckpoint.newDeposits)
                );
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(balanceBefore.sub(balanceAfter));

            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
        }

        emit Withdraw(msg.sender, tokenAddress, amount, penalty);
    }
    
    function calcPenalty(uint256 amount) public view returns (uint256) {
        Stake memory stake = stakes[msg.sender];
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch >= stake.endEpoch) {
            return 0;
        } else {
            uint256 staked = currentEpoch - stake.startEpoch;
            uint256 promised = stake.duration;
            uint256 k = 10000 - staked * 10000 / promised; 
            return amount * k / 10000;
        }
    }
    
    function isStakeFinished(address staker) public view returns (bool) {
        Stake memory stake = stakes[staker];
        uint256 currentEpoch = getCurrentEpoch();
        
        return currentEpoch >= stake.endEpoch;
    }
    
    function stakeEndEpoch(address staker) external view returns (uint128) {
        return stakes[staker].endEpoch;
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(address[] memory tokens, uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");

        for (uint i = 0; i < tokens.length; i++) {
            Pool storage p = poolSize[tokens[i]][epochId];

            if (epochId == 0) {
                p.size = uint256(0);
                p.set = true;
            } else {
                require(!epochIsInitialized(tokens[i], epochId), "Staking: epoch already initialized");
                require(epochIsInitialized(tokens[i], epochId - 1), "Staking: previous epoch not initialized");

                p.size = poolSize[tokens[i]][epochId - 1].size;
                p.set = true;
            }
        }

        emit ManualEpochInit(msg.sender, epochId, tokens);
    }

    function emergencyWithdraw(address tokenAddress) public {
        require(emergencyWithdrawAllowed == true, "Emergency withdrawal not allowed");
        require((getCurrentEpoch() - lastWithdrawEpochId[tokenAddress]) >= 10, "At least 10 epochs must pass without success");

        uint256 totalUserBalance = balances[msg.sender][tokenAddress];
        require(totalUserBalance > 0, "Amount must be > 0");

        balances[msg.sender][tokenAddress] = 0;
        stakedSwapp = stakedSwapp - totalUserBalance;
        
		Minter(minter).mint(msg.sender, totalUserBalance);

        emit EmergencyWithdraw(msg.sender, tokenAddress, totalUserBalance);
    }

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, address token, uint128 epochId) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user][token];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint min = 0;
        uint max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token];
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(address tokenAddress, uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(tokenAddress, epochId)) {
            return poolSize[tokenAddress][epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(tokenAddress, 0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract
        return stakedSwapp;
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(timeLeft * BASE_MULTIPLIER / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(uint256 prevBalance, uint128 prevMultiplier, uint256 amount, uint128 currentMultiplier) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier = uint128(prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(prevBalance.add(amount)));

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(address token, uint128 epochId) public view returns (bool) {
        return poolSize[token][epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c) internal pure returns (uint256) {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c) internal pure returns (uint256) {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly { size := extcodesize(_addr) }
        return (size == 0);
    }
    
    function paused() public view returns (bool) {
        return _paused;
    }
    
    function pause() external onlyOwner {
        _paused = true;
    }
    
    function unpause() external onlyOwner {
        _paused = false;
    }
    
    function setMigration(address migration) external onlyOwner{
        _migration = migration;
    }
    
    function prepareMigration(address staker) public returns (uint256 balance) {
        require(_migration != address(0), "Migration is not initialised");
        require(msg.sender == _migration, "Only migration contract can perform this action");
        require(balances[staker][swapp] > 0, "Balance too small");
        
        uint256 _balance = balances[staker][swapp];
        balances[staker][swapp] = 0;
        stakedSwapp = stakedSwapp.sub(_balance);
        
        Stake storage stake = stakes[staker];
        stake.active = false;
        stake.endEpoch = getCurrentEpoch();
        
        emit PrepareMigration(staker, _balance);
        
        return _balance;
    }
}