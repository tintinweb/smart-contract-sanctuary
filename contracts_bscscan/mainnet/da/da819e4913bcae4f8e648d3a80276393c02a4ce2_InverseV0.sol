/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface IOracleWrapper {
    function getPrice(address _coinAddress, address pair) external view returns (uint256);
}





library PlanLibrary {
    
    struct PlanDetails { //check packing
        uint64 risk;
        uint64 reward;
        uint120 drop;
        bool isActive;
    }
    
    function setPlan(PlanDetails storage plan, uint256 _reward, uint256 _risk, uint256 _drop) internal {
        require(_risk >= 0 && _risk <= 100, "PlanLibrary : Invalid");
        require(_drop > 0 && _drop <= 100, "PlanLibrary : Invalid");
        
        plan.reward = uint64(_reward);
        plan.risk = uint64(_risk);
        plan.drop = uint120(_drop);
        plan.isActive = true;
    }
    
    function setReward(PlanDetails storage plan, uint256 _reward) internal {
        require(_reward > 0, "PlanLibrary : Invalid reward");
        
        plan.reward = uint64(_reward);
    }
    
    function setRisk(PlanDetails storage plan, uint256 _risk) internal {
        require(_risk >= 0 && _risk <= 100, "PlanLibrary : Invalid");
        
        plan.risk = uint64(_risk);
    }
    
    function setDrop(PlanDetails storage plan, uint256 _drop) internal {
        require(_drop > 0 && _drop <= 100, "PlanLibrary : Invalid");
        
        plan.drop = uint120(_drop);
        
    }
    
    function setStatus(PlanDetails storage plan, bool status) internal {
        
        if (plan.isActive != status) {
                plan.isActive = status;
            }
    }
}



library UserLibrary {
    
    struct UserDetails {
        uint256 lastBetIndex;
    }
   
}



library BettingLibrary {
    
    struct BettingDetailsOne { //check packing
        uint128 amount;
        uint120 status; //1 => Win, 2 => Loose
        bool isInverse;
        uint96 initialPrice;
        uint96 priceInXIV;
        address betTokenAddress;
        address coinAddress;
        
    }
    
    struct BettingDetailsTwo { //check packing
        uint64 reward;
        uint32 risk;
        uint32 dropValue;
        uint48 planType;
        uint32 startTime;
        uint32 endTime;
        bool isInToken;
        bool isClaimed;
    }

    function setBetDetailsOne(BettingDetailsOne storage bet, uint256 _amount, uint256 _initialPrice, uint256 _priceInXIV, address _coinAddress, address betToken, bool _isInverse) internal {
        bet.amount = uint128(_amount);
        bet.isInverse = _isInverse;
        bet.initialPrice = uint96(_initialPrice);
        bet.priceInXIV = uint96(_priceInXIV);
        bet.coinAddress = _coinAddress;
        bet.betTokenAddress = betToken;
    }
    
    function setBetDetailsTwo(BettingDetailsTwo storage bet, uint256 _reward, uint256 _riak, uint256 _drop, uint256 _planType, uint256 _startTime, uint256 _endTime) internal {
        bet.reward = uint64(_reward);
        bet.risk = uint32(_riak);
        bet.dropValue = uint32(_drop);
        bet.planType = uint48(_planType);
        bet.startTime = uint32(_startTime);
        bet.endTime = uint32(_endTime);
    }

    function changeClaimedStatus (BettingDetailsTwo storage bet) internal {
        if (bet.isClaimed == false) {
            bet.isClaimed = true;
        }
    }
    
    function declareBet(BettingDetailsOne storage bet, uint finalPrice, uint drop) internal returns (uint120) {
        uint256 initialPrice = uint256(bet.initialPrice);
        uint256 dip;

        if (bet.isInverse) {
            if (finalPrice < initialPrice) {
                dip = ((initialPrice - finalPrice) * 100) / initialPrice;
                if (dip >= drop) {
                    return bet.status = 1;
                }
            }    
        } else {
            if (finalPrice > initialPrice) {
                dip = (((finalPrice - initialPrice) * 100) / initialPrice);
                if (dip >= drop) {
                    return bet.status = 1;
                }
            }
        }

        return bet.status = 2;
    }
}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface InverseV0Events {

   event LPEvent(uint typeOfLP,address  userAddress,uint amount,uint timestamp);
   event Addcoins(uint coinType, uint planType, uint counter, bool status, address coinAddress);
   event CoinStatus(address coinAddress, uint coinType, uint planType, bool status);
   event IndexCoinStatus(uint coinType, uint planType, bool status);
   event NewBet(address indexed user, address coinAddress, address betCoin, uint indexed betIndex, uint planIndex, uint planDays, uint startTime, uint indexed endTime);
   event BetResolved(address indexed user, uint indexed index, uint indexed result, uint endTime);
   event BetClaimed(address indexed user, uint indexed betIndex, uint timeOfClaim, uint winningAmount);
   event UserPenalized(address indexed user, uint256 indexed betIndex, bool indexed isClaimed);
}







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

    constructor () {
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





/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);
    
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






library StakingLibrary {
   
    struct StakingCycle {
        uint64 stakingTime;
        uint64 lastIndex;
        uint128 stakedAmount;
    }

    struct StakingReward {
        uint96 betEndStake;
        uint96 stakingReward;
        uint32 betEndTime;
        uint32 status;
    }
    
    struct ClaimDetails {
        uint128 lastStakedAmount;
        uint128 amountUnstaked;//check if this is required
        uint128 stakeResidual;
        uint128 profit;
        uint128 losses;
        uint32 lastStakedTime;
        uint32 lastClaimedBet;
        uint32 stakeCounter;
        uint32 lastUnstakeIndex;
    }

    function setStakingRewards(StakingReward storage stake, uint256 endStake, uint256 _stakingReward, uint256 result) internal {
        stake.betEndStake = uint96(endStake);
        stake.stakingReward = uint96(_stakingReward);
        stake.betEndTime = uint32(block.timestamp);
        stake.status = uint32(result);
    }
    
    function setStakeCycle(StakingCycle storage cycle, uint256 amount) internal {
        cycle.stakingTime = uint64(block.timestamp);
        cycle.stakedAmount = uint128(amount);
    }
    
    function setStakingDetails(ClaimDetails storage stake, uint256 amount) internal {
        stake.lastStakedAmount += uint128(amount);
        stake.lastStakedTime = uint32(block.timestamp);
        stake.stakeCounter++;
    }
    
    function setClaimDetails(ClaimDetails storage stake, uint256 balance, uint256 amount, uint256 claimedIndex) internal returns (uint256) {
        uint256 diff;
        if (stake.losses > stake.profit) {
            diff = uint256(stake.losses - stake.profit);
        }
        require(balance + uint256(stake.stakeResidual) >= (amount + diff), "StakingLibrary: Insufficient");
        require(uint256(stake.lastStakedAmount) >= (amount + diff), "StakingLibrary: Insufficient");
        
        uint256 residual = ((balance + uint256(stake.stakeResidual)) - (amount + diff));
        
        stake.stakeResidual = uint128(residual);
        
        if (diff > 0) {
            stake.profit = uint128(0);
            stake.losses = uint128(0);
        }
        
        stake.lastStakedTime = uint32(block.timestamp);
        
        if (stake.lastUnstakeIndex != uint32(claimedIndex)) {
            stake.lastUnstakeIndex = uint32(claimedIndex);
        }
        
        stake.amountUnstaked += uint128(amount + diff);
        stake.lastStakedAmount -= uint128(amount + diff);
        
        return (amount + diff);
        
    }
}












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
 * @title CustomOwnable
 * @dev This contract has the owner address providing basic authorization control
 */
contract CustomOwnable is Context  {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    // Owner of the contract
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "CustomOwnable: FORBIDDEN");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "CustomOwnable: FORBIDDEN");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}


contract InverseV0 is InverseV0Events, CustomOwnable, ReentrancyGuard {

    using StakingLibrary for StakingLibrary.StakingCycle;
    using StakingLibrary for StakingLibrary.StakingReward;
    using StakingLibrary for StakingLibrary.ClaimDetails;
    using BettingLibrary for BettingLibrary.BettingDetailsOne;
    using BettingLibrary for BettingLibrary.BettingDetailsTwo;
    using UserLibrary for UserLibrary.UserDetails;
    using PlanLibrary for PlanLibrary.PlanDetails;
    
    uint256 public SECONDS_IN_DAY;         // Seconds in a day


    bool internal isInitialized;
    uint256 public globalPool;         //total amount in pool
    uint256 public miniStakeAmount ;   // Min amount of token that user can stake 
    uint256 public maxStakeAmount ;   // Max amount of token that user can stake 
    uint256 public betFactorLP;               // this is the ratio according to which users can bet considering the amount staked..
    uint256 public miniBetAmount;             // min amount that user can bet on.
    uint256 public maxBetAmount;            // max amount that user can bet on.
    uint256 public defiCoinsCounter;          // Number of Defi plans
    uint256 public chainCoinsCounter;         // Number of Chain plans      
    uint256 public NFTCoinsCounter;           // Number of NFT plan
    uint256 public stakerIncentiveCounter;
    uint256 public planCounter;
    uint256 public planDaysCounter;
    uint256 public maxWalks;
    uint256 public bufferTime;
    uint256 public betFees;
    uint256 public threshold;
    uint256 public accumulatedXIV;
    bool public isMultiTokenActive;
    
    address public oracleAddress;
    address public revokeComissionAddress;

    IERC20 public XIV;
    IERC20 coin;
    IERC20 public usdt;
    IOracleWrapper public oracle;

    mapping(address => UserLibrary.UserDetails) public users;
    mapping(address => mapping (uint256 => StakingLibrary.StakingCycle)) public stakes;
    mapping(address => StakingLibrary.ClaimDetails) public stakeDetails;
    mapping(address => uint256) public betCounter;
    mapping(address => mapping(uint256 => mapping (uint256 => bool))) public coinStatus;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) public coins;
    mapping(address => mapping(address => bool)) public isEligibleForBet;
    mapping(address => mapping(uint256 => BettingLibrary.BettingDetailsOne)) public userBetsOne;
    mapping(address => mapping(uint256 => BettingLibrary.BettingDetailsTwo)) public userBetsTwo;
    mapping(uint256 => StakingLibrary.StakingReward) public stakerRewards;
    
    mapping(uint256 => PlanLibrary.PlanDetails) public plans;
    mapping(uint256 => uint256) public planDaysIndexed;
    mapping(uint256 => mapping(uint256 => uint256)) public penalty;
    
    modifier typeValidation(uint256 _coinType, uint256 planType) {
        require((_coinType == 1 || _coinType == 2 || _coinType == 3), "Invalid");
        require((planType == 1 || planType == 2), "Invalid PlanType");
        _;
    }
    
    modifier planValidation(uint256 coinType, uint256 planType) {
        require((coinType == 1 || coinType == 2 || coinType == 3), "Invalid");
        require((planType == 1 || planType == 2), "Invalid PlanType");
        _;
    }

    modifier validateBetArguments(address coinAddress, uint coinType, uint planType, address betToken)  {
        require(betToken != address(0), "Invalid");
        
        if (!isMultiTokenActive) {
            require(betToken == address(XIV), "Multi token inactive");
        }
        require(coinStatus[coinAddress][coinType][planType], "Not active");
        require(!isEligibleForBet[_msgSender()][coinAddress], "Bet already active");
        
        _;
    }
    
    modifier amountValidation(uint amount) {
        require(amount > 0, "Invalid");
        _;
    }
    
    modifier countValidation(uint256 count, uint256 counter) {
        require(count >= 0 && (count < counter), "Invalid");
        _;
    }
   

    function initialize(address _admin, address _XIVAddress, address _revokeComissionAddress, uint _miniStakeAmount, uint _betFactorLP, uint _miniBetAmount, uint _maxBetAmount, address _oracle, address _usdt) public {
        require(!isInitialized);
        isInitialized = true;
        miniStakeAmount  = _miniStakeAmount;
        maxStakeAmount = (100000 * 10**18);
        betFactorLP = _betFactorLP;
        miniBetAmount = _miniBetAmount;
        maxBetAmount = _maxBetAmount;
        bufferTime = 3600;
        XIV = IERC20(_XIVAddress);
        oracle = IOracleWrapper(_oracle);
        usdt = IERC20(_usdt);
        _setOwner(_admin);
        maxWalks = 100;
        SECONDS_IN_DAY = 86400;
        setPlanDetails([6,3,5,7], [300,50,100,200], [0,0,0,0]);
        planCounter = 4;
        betFees = 7;
        threshold = (10000 * 10**18);
        revokeComissionAddress = _revokeComissionAddress;
        
        planDaysIndexed[0] = 1;
        planDaysIndexed[1] = 1;
        planDaysIndexed[2] = 3;
        planDaysIndexed[3] = 7;
        
        penalty[1][0] = 7;
        penalty[3][0] = 7;
        penalty[3][1] = 7;
        penalty[3][2] = 7;
        penalty[7][0] = 7;
        penalty[7][1] = 7;
        penalty[7][2] = 7;
        penalty[7][3] = 7;
        penalty[7][4] = 7;
        penalty[7][5] = 7;
        penalty[7][6] = 7;
        
        
        planDaysCounter = 4;
    }
    
    receive() external payable {
        
    }
    
    function stakeTokens(uint256 amount) external nonReentrant {
        require(amount >= miniStakeAmount && amount <= maxStakeAmount, "Invalid");
        _updateRewards(_msgSender());
        StakingLibrary.ClaimDetails storage stake = stakeDetails[_msgSender()];
        require((stake.lastClaimedBet == stakerIncentiveCounter) || (stake.stakeCounter == uint32(0)), "Claim all bets");
        TransferHelper.safeTransferFrom(address(XIV), _msgSender(), address(this), amount);
        
        uint256 count = stake.stakeCounter;
        
        stakes[_msgSender()][count].setStakeCycle(amount);
        stake.setStakingDetails(amount);
        globalPool += amount;
    }
    
    function unstakeTokens(uint256 amount) external nonReentrant {
        _updateRewards(_msgSender());
        require(stakeDetails[_msgSender()].lastClaimedBet == stakerIncentiveCounter, "Claim all bets");
        (uint256 balance, uint256 claimedIndex) = amountToUnlock(_msgSender());
        
        uint256 unstakedAmount = stakeDetails[_msgSender()].setClaimDetails(balance, amount, claimedIndex);
        require(globalPool >= unstakedAmount, "Insufficient funds");
        require(globalPool >= amount, "Insufficient funds");
        globalPool -= unstakedAmount;
        TransferHelper.safeTransfer(address(XIV), _msgSender(), amount);
    }
    
    function amountToUnlock(address user) public view returns (uint256, uint256) {
        StakingLibrary.ClaimDetails storage stake = stakeDetails[user];
        uint256 count = uint256(stake.stakeCounter);
        uint256 lastIndex = uint256(stake.lastUnstakeIndex);
        uint256 balance;
        uint256 claimedIndex = lastIndex;
        
        require(count >= lastIndex, "Invalid");
        
        if (count > lastIndex) {
            for (uint256 i = lastIndex; i < count; i++) {
                StakingLibrary.StakingCycle storage cycle = stakes[user][i];
                
                balance += uint256(cycle.stakedAmount);
                claimedIndex = (i+1);
            }
        }
        
        return (balance, claimedIndex);
    }
    
    function updateRewards(address user) external nonReentrant {
        require(stakeDetails[user].lastClaimedBet < stakerIncentiveCounter, "Already updated");
        _updateRewards(user);
    }
    
    function _updateRewards(address user) internal returns (bool) {
        StakingLibrary.ClaimDetails storage stake = stakeDetails[user];
        
        if (stake.lastClaimedBet == stakerIncentiveCounter) {
            return true;
        }
        
        if (stake.stakeCounter == uint32(0)) {
            stake.lastClaimedBet = uint32(stakerIncentiveCounter);
            return true;
        }
        
        (uint256 rewards, uint256 loss, uint256 lastClaimed) = getRewards(user);
        
        stake.lastClaimedBet = uint32(lastClaimed);
        
        if (rewards == 0 && loss == 0) {
            return true;
        }
        
        if (rewards > 0) {
            stake.profit += uint128(rewards);
        }
        
        if (loss > 0) {
            stake.losses += uint128(loss);
        }
        
        if (lastClaimed == stakerIncentiveCounter) {
            return true;
        } else {
            return false;
        }
    }
    
    function claimRewards() external nonReentrant {
        _updateRewards(_msgSender());
        StakingLibrary.ClaimDetails storage stake = stakeDetails[_msgSender()];
        
        require(stake.profit > stake.losses, "No rewards");
        uint256 amount = (stake.profit - stake.losses);
        
        stake.profit = uint128(0);
        stake.losses = uint128(0);
        
        TransferHelper.safeTransfer(address(XIV), _msgSender(), amount);
    }
    
    function getRewards(address user) public view returns (uint256, uint256, uint256) {
        StakingLibrary.ClaimDetails storage stake = stakeDetails[user];
        uint256 start = uint256(stake.lastClaimedBet);
        uint256 time = uint256(stake.lastStakedTime);
        uint256 amount = uint256(stake.lastStakedAmount);
        uint256 incentive;
        uint256 loss;
        uint256 end;
        
        if (start + maxWalks >= stakerIncentiveCounter) {
            end = stakerIncentiveCounter;
        } else {
            end = start + maxWalks;
        }
        
        for (uint256 i = start; i < end; i++) {
            StakingLibrary.StakingReward storage reward = stakerRewards[i];
            
            if (reward.betEndTime > time) {
                if (uint256(reward.status) == 2) {
                    incentive += ((uint256(reward.stakingReward) * amount) / uint256(reward.betEndStake));
                } else if (uint256(reward.status) == 1) {
                    loss += ((uint256(reward.stakingReward) * amount) / uint256(reward.betEndStake));
                }
            }
        }
        
        return (incentive, loss, end);
    }
    
    function betFlexible(uint amount, uint coinType, address coinAddress, address betToken, uint index, uint _daysIndex, bool _isInverse) external payable validateBetArguments(coinAddress, coinType, 2, betToken) nonReentrant {
        uint256 planDays = planDaysIndexed[_daysIndex];
        
        require(((index > 0) && (index < planCounter)));
        require(planDays != 0, "Invalid");
        
        saveBetDetailsOne(_msgSender(), amount, coinAddress, betToken, _isInverse);
        saveBetDetailsTwo(_msgSender(), index, planDays, 2);
    }
    
    function betFixed(uint amount, uint coinType, address coinAddress, address betToken, bool _isInverse) external payable validateBetArguments(coinAddress, coinType, 1, betToken) nonReentrant {     
        saveBetDetailsOne(_msgSender(), amount, coinAddress, betToken, _isInverse);
        saveBetDetailsTwo(_msgSender(), 0, planDaysIndexed[0],  1);
    }
    
    function saveBetDetailsOne(address user, uint256 amount, address _coinAddress, address betToken, bool _isInverse) internal {
        uint256 fees = (amount * betFees) / 100;
        uint256 actualAmount = amount;
        amount = (amount - fees);
        uint256 priceInXIV;
        
        
        if (betToken != address(XIV)) {
            priceInXIV = getPriceInXIV(betToken);
            
            uint256 amountInXIV;
            
            if (betToken == address(1)) {
                require(msg.value == actualAmount, "Invalid");
                amountInXIV = (actualAmount  * priceInXIV) / (10 ** 18);
            } else {
                amountInXIV = (actualAmount  * priceInXIV) / (10 ** (IERC20(betToken).decimals()));
            }
            
            // check this condition
            if (XIV.balanceOf(address(this)) > globalPool) {
                require((betFactorLP * globalPool) >= ((XIV.balanceOf(address(this)) - globalPool) + amountInXIV), "Betfactor");
            }
            
            require(amountInXIV >= miniBetAmount && amountInXIV <= maxBetAmount ,"Invalid");
        } else {
            //check this condition
            if (XIV.balanceOf(address(this)) > globalPool) {
                require((betFactorLP * globalPool) >= ((XIV.balanceOf(address(this)) - globalPool) + actualAmount), "Betfactor");
            }
            
            require(actualAmount >= miniBetAmount && actualAmount <= maxBetAmount ,"Invalid");
        }

        BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[user][betCounter[user]];
        BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[user][betCounter[user]];

        if (msg.value == 0 && (betToken != address(1))) {
            TransferHelper.safeTransferFrom(betToken, user, address(this), actualAmount);
            
            if (fees > 0 && betToken != address(XIV)) {
                TransferHelper.safeTransfer(betToken, revokeComissionAddress, fees);
            } else if (fees > 0 && betToken == address(XIV)) {
                accumulatedXIV += fees;
                
                if (accumulatedXIV > threshold) {
                    stakerRewards[stakerIncentiveCounter].setStakingRewards(globalPool, accumulatedXIV, 2);
                    stakerIncentiveCounter++;
                    accumulatedXIV = 0;
                }
            }
            
            betTwo.isInToken = true;
        } else {
            require(betToken == address(1), "BetToken must be 0x1");
            if (fees > 0) {
                TransferHelper.safeTransferETH(revokeComissionAddress, fees);
            }
            
        }

        betOne.setBetDetailsOne(amount, oracle.getPrice(_coinAddress, address(usdt)), priceInXIV, _coinAddress, betToken, _isInverse);
    }
    
    function saveBetDetailsTwo(address user, uint256 planIndex, uint _days, uint _planType) internal {
        BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[user][betCounter[user]];
        BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[user][betCounter[user]];
        
        if (_planType == 1) {
            betTwo.setBetDetailsTwo((plans[planIndex].reward), (plans[planIndex].risk), (plans[planIndex].drop), _planType, block.timestamp, (block.timestamp + (_days * (SECONDS_IN_DAY / 2))));
        } else {
            betTwo.setBetDetailsTwo((plans[planIndex].reward), (plans[planIndex].risk), (plans[planIndex].drop), _planType, block.timestamp, (block.timestamp + (_days * SECONDS_IN_DAY)));
        }

        
        isEligibleForBet[user][betOne.coinAddress] = true;
        
        emit NewBet(user, betOne.coinAddress, betOne.betTokenAddress, betCounter[user], planIndex, _days, block.timestamp, (block.timestamp + (_days * SECONDS_IN_DAY)));
        betCounter[user]++;
    }

    function resolveBet(uint[] memory index, address[] memory user, bool timeCheck) external onlyOwner nonReentrant {
        require(index.length == user.length, "Length mismatch");
        
        for (uint256 i; i < index.length; i++) {
            require((index[i] < betCounter[user[i]]) ,"Invalid");
            BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[user[i]][index[i]];
            BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[user[i]][index[i]];
            require(betOne.status == 0, "Already resolved");
    
            if (timeCheck) {
                require(block.timestamp > betTwo.endTime && block.timestamp <= betTwo.endTime + bufferTime, "EndTime error");
            }
            
            uint currentPrice = oracle.getPrice(betOne.coinAddress, address(usdt));
    
            //Find the result
            uint256 result = betOne.declareBet(currentPrice, uint256(betTwo.dropValue));
            
            if(result == 2 || result == 1) {
                uint256 betRewards;
                uint256 amount = uint256(betOne.amount);
                uint256 priceInXIV = uint256(betOne.priceInXIV);
                uint256 risk;
                
                if (result == 2) {
                    risk = uint256(betTwo.risk);
                } else {
                    risk = uint256(betTwo.reward);
                }
                
                if (betOne.priceInXIV != 0 && (betOne.betTokenAddress != address(XIV))) {
                    if (betOne.betTokenAddress == address(1)) {
                        betRewards = (amount * priceInXIV * risk) / (10 ** 20);
                    } else {
                        betRewards = (amount * priceInXIV * risk) / (100 * (10 ** (IERC20(betOne.betTokenAddress).decimals())));
                    }
                } else {
                    betRewards = (amount * risk) / 100;
                }
                
                stakerRewards[stakerIncentiveCounter].setStakingRewards(globalPool, betRewards, result);
                stakerIncentiveCounter++;
            }
            
            isEligibleForBet[user[i]][betOne.coinAddress] = false;
            
            emit BetResolved(user[i], index[i], result, block.timestamp);
        }
    }

    function claimBets() external nonReentrant {
        
        uint256 amountInETH;
        uint256 amountInXIV;
        uint256 lossInXIV;
        uint256 claimedIndex;
        uint256 lastIndex = users[_msgSender()].lastBetIndex;
        
        require(betCounter[_msgSender()] > lastIndex, "No new bet");
        
        for(uint256 i = lastIndex; i < betCounter[_msgSender()]; i++) {
            BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[_msgSender()][i];
            BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[_msgSender()][i];
            
            if (!betTwo.isClaimed && (betOne.status != 0)) {
                uint256 amount = uint256(betOne.amount);
                uint256 reward = uint256(betTwo.reward);
                uint256 risk = uint256(betTwo.risk);
                uint256 winningAmount;
                
                if((betOne.status == 1)) {
                    if (betTwo.isInToken) {
                        if (betOne.betTokenAddress != address(XIV)) {
                            TransferHelper.safeTransfer(betOne.betTokenAddress, _msgSender(), amount);
                        } else {
                            amountInXIV += amount;
                        }
                    } else {
                        amountInETH += amount;
                    }

                    if ((betOne.betTokenAddress != address(XIV)) && (betOne.priceInXIV > 0)) {
                        if (betOne.betTokenAddress == address(1)) {
                            winningAmount = ((amount * uint256(betOne.priceInXIV) * reward) /  (10 ** 20));
                        } else {
                            winningAmount = ((amount * uint256(betOne.priceInXIV) * reward) / (100 * (10 ** IERC20(betOne.betTokenAddress).decimals())));
                        }
                        
                        amountInXIV += winningAmount;
                    } else {
                        winningAmount = (amount * reward) / 100;
                        amountInXIV += winningAmount;
                    }
                    
                    betTwo.changeClaimedStatus();
                    
                } else if (betOne.status == 2) {
                    require(risk <= 100, "Invalid");
                    
                    uint256 loss = (risk * amount) / 100;
                    uint256 balance = (amount - loss);
                        
                    if (betTwo.isInToken) {
                        if (betOne.betTokenAddress != address(XIV)) {
                            if (balance > 0) {
                                TransferHelper.safeTransfer(betOne.betTokenAddress, _msgSender(), balance);
                            }
                            
                        } else {
                            amountInXIV += balance;
                            lossInXIV += loss;
                        }
                        
                    } else {
                        amountInETH += balance;
                        
                        if (loss > 0) {
                            TransferHelper.safeTransferETH(revokeComissionAddress, loss);
                        }
                        
                    }
                    
                    betTwo.changeClaimedStatus();
                }
                
                emit BetClaimed(_msgSender(), i, block.timestamp, winningAmount);
            }
            
            claimedIndex = (i+1);
        }
        
        users[_msgSender()].lastBetIndex = uint64(claimedIndex);
        
        if (amountInETH > 0) {
            TransferHelper.safeTransferETH(_msgSender(), amountInETH);
        }
            
        if (amountInXIV > 0) {
            TransferHelper.safeTransfer(address(XIV), _msgSender(), amountInXIV);
        }
        
        if (lossInXIV > 0) {
            TransferHelper.safeTransfer(address(XIV), revokeComissionAddress, lossInXIV);
        }
    }
    
    function betPenalty(uint256 betIndex) external nonReentrant {
        require(betCounter[_msgSender()] > betIndex, "Invalid");
        BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[_msgSender()][betIndex];
        BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[_msgSender()][betIndex];
        require(!betTwo.isClaimed && uint256(betTwo.endTime) > block.timestamp, "EndTime");
        
        uint256 fine;
        uint256 claim;
        uint256 penaltyAmount;
        
        uint256 dayPassed = (block.timestamp - betTwo.startTime) / SECONDS_IN_DAY;
        uint256 planDaysIndex = uint256(betTwo.endTime - betTwo.startTime) / SECONDS_IN_DAY;
        fine = penalty[planDaysIndex][dayPassed];
        
        require(fine <= 100);
        
        penaltyAmount = (fine * uint256(betOne.amount)) / 100;
        claim = (uint256(betOne.amount) - penaltyAmount);
        
        
        if (claim > 0) {
            if (betTwo.isInToken) {
                TransferHelper.safeTransfer(betOne.betTokenAddress, _msgSender(), claim);
            } else {
                TransferHelper.safeTransferETH(_msgSender(), claim);
            }
        }
        
        if (penaltyAmount > 0) {
            if (betTwo.isInToken) {
                TransferHelper.safeTransfer(betOne.betTokenAddress, revokeComissionAddress, penaltyAmount);
            } else {
                TransferHelper.safeTransferETH(revokeComissionAddress, penaltyAmount);
            }
        }
        
        betTwo.isClaimed = true;
        isEligibleForBet[_msgSender()][betOne.coinAddress] = false;
        
        emit UserPenalized(_msgSender(), betIndex, betTwo.isClaimed);
    }
    
    function getBetRewards(address user) public view returns (uint256) {
        uint256 lastIndex = users[user].lastBetIndex;
        
        if (betCounter[user] == 0 || betCounter[user] == lastIndex) {
            return 0;
        }
        
        require(betCounter[user] > lastIndex, "No new bet");
        
        uint256 amountInXIV;
        
        for(uint256 i = lastIndex; i < betCounter[user]; i++) {
            BettingLibrary.BettingDetailsOne storage betOne = userBetsOne[user][i];
            BettingLibrary.BettingDetailsTwo storage betTwo = userBetsTwo[user][i];
            
            if (!betTwo.isClaimed && (block.timestamp > betTwo.endTime)) {
                uint256 amount = uint256(betOne.amount);
                uint256 reward = uint256(betTwo.reward);
                
                if((betOne.status == 1)) {
                    if ((betOne.betTokenAddress != address(XIV)) && (betOne.priceInXIV > 0)) {
                        if (betOne.betTokenAddress == address(1)) {
                            amountInXIV += ((amount * uint256(betOne.priceInXIV) * reward) / (10 ** 20));
                        } else {
                            amountInXIV += ((amount * uint256(betOne.priceInXIV) * reward) / (100 * (10 ** (IERC20(betOne.betTokenAddress).decimals()))));
                        }
                    } else {
                        amountInXIV += (amount * reward) / 100;
                    }
                }
            }
        }
        
        return amountInXIV;
    }

    function addCoins(uint _coinType, uint planType, address coinAddress) external onlyOwner typeValidation(_coinType, planType) {
        require(coinAddress != address(0), "Invalid");
        require(!coinStatus[coinAddress][_coinType][planType], "Already added");
        
        uint counter;

        if (_coinType == 1) {
            counter =  defiCoinsCounter;
            defiCoinsCounter++;
        } else if (_coinType == 2) {
            counter =  chainCoinsCounter;
            chainCoinsCounter++;
        } else {
            counter =  NFTCoinsCounter;
            NFTCoinsCounter++;
        }
    
        coins[_coinType][planType][counter] = coinAddress;
        coinStatus[coinAddress][_coinType][planType] = true;
        emit Addcoins(_coinType, planType, counter, true, coinAddress);
    }

    function changeCoinStaus(address coinAddress, uint coinType, uint planType, bool status) external onlyOwner planValidation(coinType, planType) {
        
        if (coinStatus[coinAddress][coinType][planType] != status) {
            coinStatus[coinAddress][coinType][planType] = status;
            emit CoinStatus(coinAddress, coinType, planType, status);
        }
    }

    function updateOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0));
        oracle = IOracleWrapper(_oracle);
    }
    
    function updateMiniStakeAmount(uint256 _miniStakeAmount ) external onlyOwner {
        miniStakeAmount  = _miniStakeAmount ;
    }
    
    function updateMaxStakeAmount(uint256 _maxStakeAmount ) external onlyOwner amountValidation(_maxStakeAmount) {
        maxStakeAmount  = _maxStakeAmount ;
    }

    function updateBetFactorLP(uint256 _betFactorLP) external onlyOwner amountValidation(_betFactorLP) {
        betFactorLP = _betFactorLP;
    }

    function updateMaxBetAmount(uint256 _maxBetAmount) external onlyOwner amountValidation(_maxBetAmount) {
        maxBetAmount = _maxBetAmount;
    }

    function updateMinBetAmount(uint256 _miniBetAmount) external onlyOwner {
        miniBetAmount = _miniBetAmount;
    }
    
    function setPlanDetails(uint8[4] memory drop, uint16[4] memory reward, uint8[4] memory risk) public onlyOwner {
        require(risk.length > 0 && risk.length == drop.length, "Invalid");
        
        for (uint256 i; i < drop.length; i++) {
            plans[i].setPlan(uint256(reward[i]), uint256(risk[i]), uint256(drop[i]));
        }
        
        planCounter = drop.length;
    }
    
    function setReward(uint256 count, uint _reward) external onlyOwner countValidation(count, planCounter) {
        plans[count].setReward(_reward);
    }
    
    function setRisk(uint256 count, uint _risk) external onlyOwner countValidation(count, planCounter) {
        plans[count].setRisk(_risk);
    }
    
    function setDropValue(uint256 count, uint _drop) external onlyOwner countValidation(count, planCounter) {
        plans[count].setDrop(_drop);
    }
    
    function setStatus(uint256 count, bool status) external onlyOwner countValidation(count, planCounter) {
        plans[count].setStatus(status);
    }
    
    function setMultiTokenStatus(bool status) external onlyOwner {
        if (isMultiTokenActive != status) {
            isMultiTokenActive = status;
        }
    }
    
    function setPlanDays(uint256 index, uint256 planDays) external onlyOwner {
        require(index >= 0 && (index <= planDaysCounter));
            
        if ((index == planDaysCounter) && (planDays != 0)) {
            planDaysIndexed[index] = planDays;
            planDaysCounter++;
        } else {
            planDaysIndexed[index] = planDays;
        }
    }
    
    function addPlan(uint256 _reward, uint256 _risk, uint256 _drop, bool status) external onlyOwner {
        uint256 count = planCounter;
        
        PlanLibrary.PlanDetails storage plan = plans[count];
        
        plan.setReward(_reward);
        plan.setRisk(_risk);
        plan.setDrop(_drop);
        plan.setStatus(status);
        planCounter++;
    }

    function checkCoinStatus(address _coin, uint256 _coinType, uint256 _planType) external view returns (bool) {
        return coinStatus[_coin][_coinType][_planType];
    }
    
    function setBufferTime(uint256 time) public onlyOwner {
        bufferTime = time;
    }
    
    function setPenalty(uint256 value, uint256 _days, uint256 planDaysIndex) external onlyOwner {
        require(value >= 0 && value <= 100);
        
        penalty[planDaysIndex][_days] = value;
        
    }
    
    function setRevokeComissionAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        revokeComissionAddress = newAddress;
    }
    
    function setMaxWalks(uint256 value) external onlyOwner amountValidation(value) {
        maxWalks = value;
    }
    
    function setBetFees(uint256 fees) external onlyOwner {
        require(fees >= 0 && fees <= 100);
        betFees = fees;
    }
    
    function setThreshold(uint256 value) external onlyOwner amountValidation(value) {
        threshold = value;
    }
    
    function getPriceInXIV(address betToken) public view returns (uint256 priceInXIV) {
        if (betToken == address(XIV)) {
            return priceInXIV = 1;
        }
        return priceInXIV = ((oracle.getPrice(betToken, address(usdt)) * (10 ** 18)) / oracle.getPrice(address(XIV), address(usdt)));
    }
}