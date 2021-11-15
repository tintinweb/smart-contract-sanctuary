// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IERC900.sol";
import "./RewardStreamer.sol";
import "./StakingLib.sol";

/// @title A Staking smart contract
/// @author Valerio Leo @valerioHQ
contract Staking is Initializable, IERC900, OwnableUpgradeable, RewardStreamer {
	StakingLib.StakingInfo stakingInfo;

	mapping(address => StakingLib.UserStake[]) private _userStakes;

	/**
	 * Constructor
	 * @param _rewardToken The reward token address
	 * @param _ticket The raffle ticket address
	 * @param _locks The array with the locks durations values
	 * @param _rarityRegister The rarity register address
	 */
	function initialize (
		address _rewardToken,
		address _ticket,
		uint256[] memory _locks,
		uint256[] memory _locksMultiplier,
		uint256 _ticketsMintingRatio,
		uint256 _ticketsMintingChillPeriod,
		address _rarityRegister,
		address _defaultStaker
	) public initializer {
		require(_locks.length == _locksMultiplier.length, 'Stake: lock multiplier should have the same length ad locks');
		OwnableUpgradeable.__Ownable_init();

		super._setRewardToken(_rewardToken);

		// add the default staker. we need a default staker to neveer have 0 staking units
		_addStaker(_defaultStaker, 1 * 10**18, block.number + 1, 0);

		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits + (1 * 10 ** 18);
		stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked + (1 * 10 ** 18);

		stakingInfo.locks = _locks;
		stakingInfo.locksMultiplier = _locksMultiplier;
		stakingInfo.historyStartBlock = block.number;
		stakingInfo.historyEndBlock = block.number;

		setTicketsMintingChillPeriod(_ticketsMintingChillPeriod);
		setTicketsMintingRatio(_ticketsMintingRatio);
		setTicket(_ticket);
		setRarityRegister(_rarityRegister);

		RewardStreamer.rewardStreamInfo.deployedAtBlock = block.number;
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param periodBlockRate The reward per block
	* @param periodLastBlock The last block of the period
	*/
	function addRewardStream(uint256 rewardStreamIndex, uint256 periodBlockRate, uint256 periodLastBlock) public onlyOwner {
		super._addRewardStream(rewardStreamIndex, periodBlockRate, periodLastBlock);
	}

	/**
	* @notice Will add a new lock duration value
	* @param lockNumber the new lock duration value
	*/
	function addLockDuration(uint256 lockNumber, uint256 lockMultiplier) public onlyOwner {
		stakingInfo.locks.push(lockNumber);
		stakingInfo.locksMultiplier.push(lockMultiplier);

		emit LocksUpdated(stakingInfo.locks.length - 1, lockNumber, lockMultiplier);
	}

	event LocksUpdated(uint256 lockIndex, uint256 lockNumber, uint256 lockMultiplier);
	/**
	* @notice Will update an existing lock value
	* @param lockIndex the lock index
	* @param lockNumber the new lock duration value
	*/
	function updateLocks(uint256 lockIndex, uint256 lockNumber, uint256 lockMultiplier) public onlyOwner {
		stakingInfo.locks[lockIndex] = lockNumber;
		stakingInfo.locksMultiplier[lockIndex] = lockMultiplier;

		emit LocksUpdated(lockIndex, lockNumber, lockMultiplier);
	}

	event TicketMintingChillPeriodUpdated(uint256 newValue);

	/**
	* @notice Will update the ticketsMintingChillPeriod
	* @param newTicketsMintingChillPeriod the new value
	*/
	function setTicketsMintingChillPeriod(uint256 newTicketsMintingChillPeriod) public onlyOwner {
		require(newTicketsMintingChillPeriod > 0, "Staking: ticketsMintingChillPeriod can't be zero");
		stakingInfo.ticketsMintingChillPeriod = newTicketsMintingChillPeriod;

		emit TicketMintingChillPeriodUpdated(newTicketsMintingChillPeriod);
	}

	event TicketMintingRatioUpdated(uint256 newValue);
	/**
	* @notice Will update the numebr of staking units needed to earn one ticket
	* @param newTicketsMintingRatio the new value
	*/
	function setTicketsMintingRatio(uint256 newTicketsMintingRatio) public onlyOwner {
		stakingInfo.ticketsMintingRatio = newTicketsMintingRatio;

		emit TicketMintingRatioUpdated(newTicketsMintingRatio);
	}

	/**
	* @notice Will update the ticket address
	* @param ticketAddress the new value
	*/
	function setTicket(address ticketAddress) public onlyOwner {
		stakingInfo.ticket = ticketAddress;
	}


	event RarityRegisterUpdated(address rarityRegister);
	/**
	* @notice Will update the rarityRegister address
	* @param newRarityRegister the new value
	*/
	function setRarityRegister(address newRarityRegister) public onlyOwner {
		stakingInfo.rarityRegister = newRarityRegister;

		emit RarityRegisterUpdated(newRarityRegister);
	}


	/**
	* @notice Will calculate the total reward generated from start till now
	* @return (uint256) The the calculated reward
	*/
	function getTotalGeneratedReward() external view returns(uint256) {
		return RewardStreamerLib.unsafeGetRewardsFromRange(rewardStreamInfo, stakingInfo.historyStartBlock, block.number);
	}

	function historyStartBlock() public view returns (uint256) {return stakingInfo.historyStartBlock;}
	function historyEndBlock() public view returns (uint256) {return stakingInfo.historyEndBlock;}
	function historyAverageReward() public view returns (uint256) {return stakingInfo.historyAverageReward;}
	function historyRewardPot() public view returns (uint256) {return stakingInfo.historyRewardPot;}
	function totalCurrentlyStaked() public view returns (uint256) {return stakingInfo.totalCurrentlyStaked;}
	function totalStakingUnits() public view returns (uint256) {return stakingInfo.totalStakingUnits;}
	function totalDistributedRewards() public view returns (uint256) {return stakingInfo.totalDistributedRewards;}
	function ticketsMintingRatio() public view returns (uint256) {return stakingInfo.ticketsMintingRatio;}
	function ticketsMintingChillPeriod() public view returns (uint256) {return stakingInfo.ticketsMintingChillPeriod;}
	function rarityRegister() public view returns (address) {return stakingInfo.rarityRegister;}
	function locks(uint256 i) public view returns (uint256) {return stakingInfo.locks[i];}
	function locksMultiplier(uint256 i) public view returns (uint256) {return stakingInfo.locksMultiplier[i];}
	function userStakes(address staker, uint256 i) public view returns (StakingLib.UserStake memory) {
		StakingLib.UserStake memory s;

		return _userStakes[staker].length > i
			? _userStakes[staker][i]
			: s;
	}
	function userStakedTokens(address staker, uint256 stakeIndex) public view returns (StakingLib.UserStakedToken memory) {
		StakingLib.UserStakedToken memory s;

		return _userStakes[staker].length > stakeIndex
			? _userStakes[staker][stakeIndex].userStakedToken
			: s;
	}

	/**
	* @notice Will calculate the current period length
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength() public view returns(uint256) {
		return StakingLib.getCurrentPeriodLength(stakingInfo);
	}

	/**
	* @notice Will calculate the current period total reward
	* @return (uint256) The current period total reward
	*/
	function getTotalRewardInCurrentPeriod() public view returns(uint256) {
		return RewardStreamerLib.unsafeGetRewardsFromRange(rewardStreamInfo, stakingInfo.historyEndBlock, block.number);
	}

	/**
	* @notice Will calculate the current period average reward
	* @return (uint256) The current period average
	*/
	function getCurrentPeriodAverageReward() public view returns(uint256) {
		return StakingLib.getCurrentPeriodAverageReward(
			stakingInfo,
			getTotalRewardInCurrentPeriod(),
			false
		);
	}

	/**
	* @notice Will calculate the history length in blocks
	* @return (uint256) The history length
	*/
	function getHistoryLength() public view returns (uint256){
		return StakingLib.getHistoryLength(stakingInfo);
	}

	/**
	* @notice Will get the pool share for a specific stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The userPoolShare
	*/
	function getStakerPoolShare(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.userPoolShare(
			_userStakes[staker],
			stakeIndex,
			stakingInfo.totalStakingUnits
		);
	}


	/**
	* @notice Will get the reward of a stake for the current period
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The reward for current period
	*/
	function getStakerRewardFromCurrent(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerRewardFromCurrentPeriod(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return for how many block the stake has in history
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The number of blocks in history
	*/
	function getStakerTimeInHistory(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerTimeInHistory(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return what the history length was a the moment the stake was created
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The length of the history
	*/
	function getHistoryLengthBeforeStakerEntered(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getHistoryLengthBeforeStakerEntered(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return the history average for a stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The calculated history average
	*/
	function getHistoryAverageForStake(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getHistoryAverageForStaker(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @return (uint256) The number of all the stakes user has ever staked
	*/
	function getUserStakes(address staker) public view returns(uint256) {
		return _userStakes[staker].length;
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function getStakerReward(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate the rewards that user will get from history
	* @param staker the address of the staker you wish to get the rewards
	* @param stakeIndex the index of the stake
	* @return uint256 The amount of tokes user will get from history
	*/
	function getStakerRewardFromHistory(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerRewardFromHistory(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	function getClaimableTickets(address staker, uint256 stakeIndex) public view returns (uint256) {
		require(_userStakes[staker].length > stakeIndex, "Staking: stake does not exist");

		return StakingLib.getClaimableTickets(
			_userStakes[staker][stakeIndex]
		);
	}

	function claimTickets(uint256 stakeIndex) public {
		require(_userStakes[msg.sender].length > stakeIndex, "Staking: stake does not exist");

		StakingLib.claimTickets(
			stakingInfo.ticket,
			_userStakes[msg.sender][stakeIndex],
			msg.sender
		);
	}

	/**
	* @notice Creates a stake instance for the staker
	* @notice MUST trigger Staked event
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	* @param stakerAddress the address of the owner of the stake
	* @param amountStaked the number of tokens to be staked
	* @param blockNumber the block number at which the stake is created
	* @param lockDuration the duration for which the tokens will be locked
	*/
	function _addStaker(address stakerAddress, uint256 amountStaked, uint256 blockNumber, uint256 lockDuration) internal {
		_userStakes[stakerAddress].push(StakingLib.UserStake({
			amountStaked: amountStaked,
			stakingUnits: amountStaked,
			enteredAtBlock: blockNumber,
			historyAverageRewardWhenEntered: stakingInfo.historyAverageReward,
			ticketsMintingRatioWhenEntered: stakingInfo.ticketsMintingRatio,
			ticketsMintingChillPeriodWhenEntered: stakingInfo.ticketsMintingChillPeriod,
			lockedTill: blockNumber + lockDuration,
			rewardCredit: 0,
			ticketsMinted: 0,
			userStakedToken: StakingLib.UserStakedToken({
					tokenAddress: address(0),
					tokenId: 0
				})
			})
		);

		emit Staked(stakerAddress, amountStaked, stakingInfo.totalCurrentlyStaked, abi.encodePacked(_userStakes[stakerAddress].length - 1));
	}

	/**
	* @notice Allows user to stake tokens
	* @notice Optionaly user can stake an NFT token for extra reward
	* @dev Users wil be able to unstake only after the lock durationn has pased.
	* @dev The lock duration in the data bytes is required, its the index of the locks array
	* Should be the fist 32 bytes in the bytes array
	* @param amount the inumber of tokens to be staked
	* @param data the bytes containing extra information about the staking
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stake(uint256 amount, bytes calldata data) public override {
		StakingLib.stake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[msg.sender],
			msg.sender,
			amount,
			data
		);

		emit Staked(
			msg.sender,
			amount,
			stakingInfo.totalCurrentlyStaked,
			abi.encodePacked(_userStakes[msg.sender].length - 1)
		);
	}

	/**
	* @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
	* @notice MUST trigger Staked event
	* @param user the address the tokens are staked for
	* @param amount uint256 the amount of tokens to stake
	* @param data bytes aditional data for the stake and to include in the Stake event
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stakeFor(address user, uint256 amount, bytes calldata data) external override {
		StakingLib.stake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[user],
			user,
			amount,
			data
		);
		emit Staked(user, amount, stakingInfo.totalCurrentlyStaked, abi.encodePacked(_userStakes[user].length  - 1));
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The stake should exist
	* @dev when adding the NFT we need to simulate an untake/stake because we need to recalculate the
	* new historyAverageAmount, stakingInfo.totalStakingUnits and stakingInfo.historyRewardPot
	* @notice it MUST revert if the added token has no multiplier
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @param tokenAddress the address of the NFT
	* @param tokenId the id of the NFT token
	*/
	function addNftToStake(address staker, uint256 stakeIndex, address tokenAddress, uint256 tokenId) public {
		StakingLib.addNftToStake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex,
			tokenAddress,
			tokenId
		);
	}

	/**
	* @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
	* @notice MUST trigger Unstaked event
	* @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
	* @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
	*   transferred back to their account, and their personalStakeIndex will increment to the next active stake.
	* @param amount uint256 the amount of tokens to unstake
	* @param data bytes optional data to include in the Unstake event
	*/
	function unstake(uint256 amount, bytes calldata data) public override {
		uint256 stakerReward = StakingLib.unstake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[msg.sender],
			StakingLib.getStakeIndexFromCalldata(data)
		);

		emit Unstaked(
			msg.sender,
			stakerReward,
			stakingInfo.totalCurrentlyStaked,
			abi.encodePacked(StakingLib.getStakeIndexFromCalldata(data))
		);
	}

	/**
	* @notice This function offers a way to withdraw a ERC721 after using failsafeUnstakeERC20.
	* @notice If for any reason the ERC721 should function again, this function allows to withdraw it.
	* @param data bytes optional data to include in the Unstake event
	*/
	function unstakeERC721(bytes calldata data) external {
		uint256 stakeIndex = StakingLib.getStakeIndexFromCalldata(data);
		require(_userStakes[msg.sender][stakeIndex].lockedTill < block.number, "Staking: Stake is still locked");

		StakingLib.removeNftFromStake(
			_userStakes[msg.sender][stakeIndex].userStakedToken,
			msg.sender
		);
	}

	/**
	* @notice Returns the current total of tokens staked for an address
	* @param staker address The address to query
	* @return uint256 The number of tokens staked for the given address
	*/
	function totalStakedFor(address staker) external override view returns (uint256) {
		return StakingLib.getTotalStakedFor(_userStakes[staker]);
	}

	/**
	* @notice Returns the current total of tokens staked
	* @return uint256 The number of tokens staked in the contract
	*/
	function totalStaked() external override view returns (uint256) {
		return stakingInfo.totalCurrentlyStaked;
	}

	/**
	* @notice MUST return true if the optional history functions are implemented, otherwise false
	* @dev Since we don't implement the optional interface, this always returns false
	* @return bool Whether or not the optional history functions are implemented
	*/
	function supportsHistory() external override pure returns (bool) {
		return false;
	}

	/**
	* @notice Address of the token being used by the staking interface
	* @return address The address of the ERC20 token used for staking
	*/
	function token() external override view returns (address) {
		return address(rewardStreamInfo.rewardToken);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/* solium-disable */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC900 Simple Staking Interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
interface IERC900 {
	event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
	event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

	function stake(uint256 amount, bytes calldata data) external;
	function stakeFor(address user, uint256 amount, bytes calldata data) external;
	function unstake(uint256 amount, bytes calldata data) external;
	function totalStakedFor(address addr) external view returns (uint256);
	function totalStaked() external view returns (uint256);
	function token() external view returns (address);
	function supportsHistory() external pure returns (bool);

	// NOTE: Not implementing the optional functions
	// function lastStakedFor(address addr) public view returns (uint256);
	// function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
	// function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardStreamerLib.sol";


/// @title A Staking smart contract
/// @author Valerio Leo @valerioHQ
contract RewardStreamer {

	RewardStreamerLib.RewardStreamInfo public rewardStreamInfo;

	event RewardStreamAdded(uint256 rewardPerBlock, uint256 rewardLastBlock, uint256 rewardInStream);

	function rewardToken() public view returns (address) {return address(rewardStreamInfo.rewardToken);}

	/**
	* @notice Will setup the token to use for reward
	* @param rewardTokenAddress The reward token address
	*/
	function _setRewardToken(address rewardTokenAddress) internal {
		RewardStreamerLib.setRewardToken(rewardStreamInfo, rewardTokenAddress);
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param rewardPerBlock The amount of tokens rewarded per block
	* @param rewardLastBlock The last block of the period
	*/
	function _addRewardStream(uint256 rewardStreamIndex, uint256 rewardPerBlock, uint256 rewardLastBlock) internal {
		uint256 tokensInReward = RewardStreamerLib.addRewardStream(
			rewardStreamInfo,
			rewardStreamIndex,
			rewardPerBlock,
			rewardLastBlock
		);

		emit RewardStreamAdded(rewardPerBlock, rewardLastBlock, tokensInReward);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../NFTRarityRegister/INFTRarityRegister.sol";

import "../Raffle/IRaffleTicket.sol";
import "./RewardStreamerLib.sol";

import "./TokenHelper.sol";

library StakingLib {
  // **************************
	// **| StakingLib section |**
  // **************************

	struct StakingInfo {
		uint256 historyStartBlock; // this is set only when we deploy the contract
		uint256 historyEndBlock; // it starts and finishes in the same block (so length is 0)
		uint256 historyAverageReward; // how many reward tokens (in Wei) we give PER TOKEN STAKED PER BLOCK
		uint256 historyRewardPot; // the tokens unclaimed from history

		uint256 totalCurrentlyStaked; // the actual amount of $BURP tokens sent from users
		uint256 totalStakingUnits; // sum of all user stake shares

		uint256 totalDistributedRewards; // sum of all distributed rewards, mainly helpful for testing

		uint256[] locks;
		uint256[] locksMultiplier;

		uint256 ticketsMintingRatio;
		uint256 ticketsMintingChillPeriod;

		address ticket;
		address rarityRegister;
	}

	/**
	* @notice Will get the lock duration from the stake bytes data
	* @dev the bytes should contain the index of the lock in the first 32 bytes
	* @dev the index should be < locks.length
	* @param data bytes from the stake action
	* @return uint256 The duration of the lock (time for which the stake will be locked)
	*/
	function getLockDuration(StakingInfo storage stakingInfo, bytes memory data) public view returns (uint256, uint256) {
		require(data.length >= 32, 'Stake: data should by at least 32 bytes');

		uint256 lengthIndex = getStakeIndexFromCalldata(data);

		require(lengthIndex < stakingInfo.locks.length, 'Stake: lock index out of bounds');

		return (stakingInfo.locks[lengthIndex], lengthIndex);
	}

	/**
	* @notice Will calculate the current period length
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength(StakingInfo storage stakingInfo) public view returns(uint256) {
		return uint256(block.number) - stakingInfo.historyEndBlock;
	}

	/**
	* @notice Will calculate the current period length optionally including the last block
	* @param excludeLast a flag that indicates to include the last block or not
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength(StakingInfo storage stakingInfo, bool excludeLast) public view returns(uint256) {
		return excludeLast ? getCurrentPeriodLength(stakingInfo) - 1 : getCurrentPeriodLength(stakingInfo);
	}

	/**
	* @notice Will calculate the history length in blocks
	* @return (uint256) The history length
	*/
	function getHistoryLength(StakingInfo storage stakingInfo) public view returns (uint256){
		return stakingInfo.historyEndBlock - stakingInfo.historyStartBlock;
	}

	/**
	* @notice Calculate the average reward for the current period
	* @param stakingInfo the struct containing staking info
	* @param totalReward the total reward in current period
	* @param excludeLast whether or not exclude the last block
	* @return (uint256) number of blocks in history
	*/
	function getCurrentPeriodAverageReward(
		StakingInfo storage stakingInfo,
		uint256 totalReward,
		bool excludeLast
	)
		public
		view
		returns(uint256)
	{
		if (stakingInfo.totalStakingUnits == 0) {
			return 0;
		}

		uint256 currentPeriodLength = getCurrentPeriodLength(stakingInfo, excludeLast);
		if(currentPeriodLength == 0 ) {
			return 0;
		}

		return totalReward
			* (10**18)
			/ (stakingInfo.totalStakingUnits)
			/ (currentPeriodLength);
	}

	/**
	* @notice Calculate the total generated reward for a period
	* @param _block the current block
	* @param historyStartBlock the first history block
	* @param rewardPerBlock the amount of tokens rewarded per block
	* @return (uint256) number of blocks in history
	*/
	function totalGeneratedReward(uint256 _block, uint256 historyStartBlock, uint256 rewardPerBlock) public pure returns(uint256) {
		return (_block - historyStartBlock) * rewardPerBlock;
	}

	/**
	* @notice Calculate the reward from current period
	* @param totalRewardInCurrentPeriod the total reward from current period
	* @param totalStakingUnits sum of all user stake shares
	* @return (uint256) the calculated reward
	*/
	function _stakerRewardFromCurrentPeriod(
		uint256 totalRewardInCurrentPeriod,
		uint256 stakerBalance,
		uint256 totalStakingUnits
	)
		private
		pure
		returns(uint256)
	{
		return totalRewardInCurrentPeriod
			* stakerBalance
			/ totalStakingUnits;
	}

	/**
	* @notice Calculate the reward from current period
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromCurrentPeriod(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;
		uint256	totalRewardInCurrentPeriod = RewardStreamerLib.unsafeGetRewardsFromRange(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number
		);

		return _stakerRewardFromCurrentPeriod(
			totalRewardInCurrentPeriod,
			stakerBalance,
			stakingInfo.totalStakingUnits
		);
	}

	/**
	* @notice Calculate the reward from current period
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromCurrentPeriodAndUpdateCursor(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		private
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;
		uint256	totalRewardInCurrentPeriod = RewardStreamerLib.getRewardAndUpdateCursor(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number - 1
		);


		return _stakerRewardFromCurrentPeriod(
			totalRewardInCurrentPeriod,
			stakerBalance,
			stakingInfo.totalStakingUnits
		);
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function getStakerReward(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns (uint256)
	{
		uint256 currentPeriodReward = getStakerRewardFromCurrentPeriod(rewardStreamInfo, stakingInfo, userStakes, stakeIndex);
		uint256 historyPeriodReward = getStakerRewardFromHistory(stakingInfo, userStakes, stakeIndex);

		return currentPeriodReward + historyPeriodReward;
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function _getStakerReward(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		private
		returns (uint256)
	{
		uint256 currentPeriodReward = getStakerRewardFromCurrentPeriodAndUpdateCursor(rewardStreamInfo, stakingInfo, userStakes, stakeIndex);
		uint256 historyPeriodReward = getStakerRewardFromHistory(stakingInfo, userStakes, stakeIndex);

		return currentPeriodReward + historyPeriodReward;
	}

	/**
	* @notice Creates a stake instance for the staker
	* @notice MUST trigger Staked event
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	* @param amountStaked the number of tokens to be staked
	* @param blockNumber the block number at which the stake is created
	* @param lockDuration the duration for which the tokens will be locked
	*/
	function addStake(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 amountStaked,
		uint256 stakingUnits,
		uint256 blockNumber,
		uint256 lockDuration
	)
		private
	{
		userStakes.push(UserStake({
				amountStaked: amountStaked,
				stakingUnits: stakingUnits,
				enteredAtBlock: blockNumber,
				historyAverageRewardWhenEntered: stakingInfo.historyAverageReward,
				ticketsMintingRatioWhenEntered: stakingInfo.ticketsMintingRatio,
				ticketsMintingChillPeriodWhenEntered: stakingInfo.ticketsMintingChillPeriod,
				lockedTill: blockNumber + lockDuration,
				rewardCredit: 0,
				ticketsMinted: 0,
				userStakedToken: StakingLib.UserStakedToken({
					tokenAddress: address(0),
					tokenId: 0
				})
			})
		);
	}

	/**
	* @notice Allows user to stake tokens
	* @notice Optionally user can stake a NFT token for extra reward
	* @dev Users wil be able to unstake only after the lock durationn has pased.
	* @dev The lock duration in the data bytes is required, its the index of the locks array
	* Should be the fist 32 bytes in the bytes array
	* @param amount the inumber of tokens to be staked
	* @param data the bytes containing extra information about the staking
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		address staker,
		uint256 amount,
		bytes calldata data
	)
		public
	{
			(uint256 lockDuration, uint256 lockIndex) = getLockDuration(stakingInfo, data);

			TokenHelper.ERC20TransferFrom(address(rewardStreamInfo.rewardToken), msg.sender, address(this), amount);

			updateHistoryValues(rewardStreamInfo, stakingInfo);

			uint256 durationMultiplier = stakingInfo.locksMultiplier[lockIndex];

			// when staking without any multiplier, staking units and amount are identical
			stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits + applyPercent(amount, durationMultiplier);
			stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked + amount;

			addStake(stakingInfo, userStakes, amount, applyPercent(amount, durationMultiplier), block.number, lockDuration);

			if (data.length >= 84) { // [32, 20. 32] == [index, address, tokenId]
				addNftToStake(
					rewardStreamInfo,
					stakingInfo,
					userStakes,
					userStakes.length - 1,
					getTokenAddressFromCalldata(data),
					getTokenIdFromCalldata(data)
				);
			}
			claimTickets(
				stakingInfo.ticket,
				userStakes[userStakes.length - 1], // last stake just created
				staker
			);
	}

	/**
	* @notice Calculate the new history reward pot
	* @param oldHistoryRewardPot the old history reward pot
	* @param totalRewardInCurrentPeriod the total reward from current period
	* @param stakerReward the staker reward
	* @return (uint256) the new history reward pot
	*/
	function historyRewardPot(
		uint256 oldHistoryRewardPot,
		uint256 totalRewardInCurrentPeriod,
		uint256 stakerReward
	) public pure returns(uint256) {
		return oldHistoryRewardPot
			+ totalRewardInCurrentPeriod
			- stakerReward;
	}

	/**
	* @notice Will parse bytes data to get an uint256
	* @param data bytes data
	* @param from from where to start the parsing
	*/
	function parse32BytesToUint256(bytes memory data, uint256 from) public pure returns (uint256 parsed){
		assembly {parsed := mload(add(add(data, from), 32))}
	}

	/**
	* @notice Will parse bytes data to get an address
	* @param data bytes data
	* @param from from where to start the parsing
	*/
	function parseBytesToAddress(bytes memory data, uint256 from) public pure returns (address parsed){
		assembly {parsed := mload(add(add(data, from), 20))}
	}

	/**
	* @notice Will parse the stake bytes data to get the stake index
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (uint256) the parsed index
	*/
	function getStakeIndexFromCalldata(bytes memory data) public pure returns (uint256) {
		return parse32BytesToUint256(data, 0);
	}

	/**
	* @notice Will parse the stake bytes data to get the NFT address
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (address) the parsed address
	*/
	function getTokenAddressFromCalldata(bytes memory data) public pure returns (address) {
		return parseBytesToAddress(data, 32);
	}

	/**
	* @notice Will parse the stake bytes data to get the NFT tokeId
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (uint256) the parsed tokenId
	*/
	function getTokenIdFromCalldata(bytes memory data) public pure returns (uint256) {
		return parse32BytesToUint256(data, 52);
	}

	/**
	* @notice Will apply a percentage to a number
	* @param number The number to multiply
	* @param percent The percentage to apply
	* @return (uint256) the operation result
	*/
	function applyPercent(uint256 number, uint256 percent) public pure returns (uint256) {
		return number * percent / 100;
	}

	/**
	* @notice Calculates the new History Average Reward
	* @dev this is called **before** we update history end block
	* @return uint256 The calculated newHistoryAverageReward
	*/
	function getNewHistoryAverageReward(
		uint256 currentPeriodLength,
		uint256 currentPeriodAverageReward,
		uint256 currentHistoryLength,
		uint256 historyStartBlock,
		uint256 historyAverageReward
	) public view returns (uint256) {
		uint256 blockNumber = block.number;
		uint256 newHistoryLength = uint256(blockNumber)- 1 - historyStartBlock;

		uint256 fromCurrent = currentPeriodLength * currentPeriodAverageReward;
		uint256 fromHistory = currentHistoryLength * historyAverageReward;

		uint256 newHistoryAverageReward = (
			fromCurrent + fromHistory
		)
		/ newHistoryLength;

		return newHistoryAverageReward;
	}

	function updateHistoryValues(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo
	)
		public
	{
		uint256 totalRewardInCurrentPeriod = RewardStreamerLib.getRewardAndUpdateCursor(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number - 1
		);
		uint256 currentPeriodAverageReward = getCurrentPeriodAverageReward(
			stakingInfo,
			totalRewardInCurrentPeriod,
			true
		);

		// 1. we update the stakingInfo.historyAverageReward with the WEIGHTED average of history reward and current reward
		stakingInfo.historyAverageReward = getNewHistoryAverageReward(
			getCurrentPeriodLength(stakingInfo, true),
			currentPeriodAverageReward,
			getHistoryLength(stakingInfo),
			stakingInfo.historyStartBlock,
			stakingInfo.historyAverageReward
		);

		// 2. we push the currentPeriodReward in the history
		stakingInfo.historyRewardPot = historyRewardPot(
				stakingInfo.historyRewardPot,
				totalRewardInCurrentPeriod,
				0
			);

		// 3. we update the stakingInfo.historyEndBlock;
		stakingInfo.historyEndBlock = uint256(block.number) - 1;
	}

	function setTicketsMintingRatio(
		StakingInfo storage stakingInfo,
		uint256 mintingRatio
	)
		public
	{
		stakingInfo.ticketsMintingRatio = mintingRatio;
	}

  // *****************************
	// *** UserStakesLib section ***
	// *****************************

	struct UserStakedToken {
		address tokenAddress;
		uint256 tokenId;
	}

	struct UserStake {
		uint256 stakingUnits;
		uint256 amountStaked;
		uint256 enteredAtBlock;
		uint256 historyAverageRewardWhenEntered;
		uint256 ticketsMintingRatioWhenEntered;
		uint256 ticketsMintingChillPeriodWhenEntered;
		uint256 lockedTill;
		uint256 rewardCredit;
		uint256 ticketsMinted;
		UserStakedToken userStakedToken;
	}

	function getTotalStakedFor(
		UserStake[] storage userStakes
	)
		public
		view
		returns (uint256)
	{
		uint256 total;

		for (uint i = 0; i < userStakes.length; i++) {
			total = total + userStakes[i].amountStaked;
		}

		return total;
	}

		/**
	* @notice Calculate the staker time in history
	* @return (uint256) number of blocks in history
	*/
	function getStakerTimeInHistory(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length || userStakes[stakeIndex].enteredAtBlock == 0 || userStakes[stakeIndex].enteredAtBlock > stakingInfo.historyEndBlock) {
			return 0;
		}

		return stakingInfo.historyEndBlock - userStakes[stakeIndex].enteredAtBlock + 1;
	}

	/**
	* @notice Will calculate and return what the history length was a the moment the stake was created
	* @param stakeIndex the index of the stake
	* @return (uint256) The length of the history
	*/
	function getHistoryLengthBeforeStakerEntered(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns (uint256)
	{
		uint256 enteredAtBlock = userStakes[stakeIndex].enteredAtBlock;

		if (enteredAtBlock == 0) {
			return 0;
		}

		return enteredAtBlock - stakingInfo.historyStartBlock - 1;
	}

	/**
	* @notice Calculate the user share in the pool
	* @param totalStakingUnits sum of all user stake shares
	* @return (uint256) the calculated pool share
	*/
	function userPoolShare(
		UserStake[] storage userStakes,
		uint256 stakeIndex,
		uint256 totalStakingUnits
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length || userStakes[stakeIndex].stakingUnits == 0) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;

		return stakerBalance * (10**18) / totalStakingUnits;
	}

	/**
	* @notice Calculate the history average for staker
	* @return (uint256) the calculated average
	*/
	function getHistoryAverageForStaker(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 historyAverageRewardWhenEntered = userStakes[stakeIndex].historyAverageRewardWhenEntered;
		uint256 blocksParticipatedInHistory = getStakerTimeInHistory(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		if(blocksParticipatedInHistory == 0) {
			return 0;
		}
		uint256 historyLength = getHistoryLength(stakingInfo);

		uint256 historyLengthBeforeStakerEntered = getHistoryLengthBeforeStakerEntered(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		return (stakingInfo.historyAverageReward * historyLength - historyAverageRewardWhenEntered * historyLengthBeforeStakerEntered) / blocksParticipatedInHistory;

	}

	/**
	* @notice Calculate the stake reward from history
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromHistory(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakingUnits = userStakes[stakeIndex].stakingUnits;
		if (stakingUnits == 0) {
			return 0;
		}
		uint256 historyAverageForStaker = getHistoryAverageForStaker(
			stakingInfo,
			userStakes,
			stakeIndex
		);
		uint256 blocksParticipatedInHistory = getStakerTimeInHistory(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		return blocksParticipatedInHistory
			* historyAverageForStaker
			* stakingUnits
			/ (10 ** 18);
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	*/
	function _addNftToStakeAndApplyMultiplier(
		address rarityRegister,
		UserStake storage userStake,
		address tokenAddress,
		uint256 tokenId
	)
		private
	{
		uint256 rewardMultiplier = INFTRarityRegister(rarityRegister).getNftRarity(tokenAddress, tokenId);

		require(rewardMultiplier > 0, 'Staking: NFT not found in RarityRegister');
		require(rewardMultiplier >= 100, 'Staking: NFT multiplier must be at least 100');
		require(
			userStake.userStakedToken.tokenAddress == address(0),
			'Staking: Stake already has a token'
		);
		require(
			userStake.lockedTill > block.number,
			'Staking: cannot add NFT to unlocked stakes'
		);


		uint userStakingUnits = userStake.stakingUnits;

		bool success = TokenHelper.transferFrom(tokenAddress, tokenId, msg.sender, address(this));

		require(success, "Staking: could not add NFT to stake");

		userStake.userStakedToken.tokenAddress = tokenAddress;
		userStake.userStakedToken.tokenId = tokenId;

		userStake.stakingUnits = applyPercent(userStakingUnits, rewardMultiplier);
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The stake should exist
	* @dev when adding the NFT we need to simulate an unstake/stake because we need to recalculate the
	* new historyAverageAmount, stakingInfo.totalStakingUnits and stakingInfo.historyRewardPot
	* @notice it MUST revert if the added token has no multiplier
	*/
	function addNftToStake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
	{
		uint256 previousStakingUnits = userStakes[stakeIndex].stakingUnits; // this stays the same
		require(previousStakingUnits > 0, "Staking: Stake not found");

		uint256 stakerReward = _getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			userStakes,
			stakeIndex
		);


		_addNftToStakeAndApplyMultiplier(
			stakingInfo.rarityRegister,
			userStakes[stakeIndex],
			tokenAddress,
			tokenId
		);


		uint256 newStakingUnits = userStakes[stakeIndex].stakingUnits; // after we just update it

		updateHistoryValues(rewardStreamInfo, stakingInfo);

		// we bring the stake to the current time
		userStakes[stakeIndex].enteredAtBlock = block.number;
		userStakes[stakeIndex].historyAverageRewardWhenEntered = stakingInfo.historyAverageReward;
		userStakes[stakeIndex].rewardCredit = stakerReward;

		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits
			- previousStakingUnits
			+ newStakingUnits;

		stakingInfo.historyRewardPot = stakingInfo.historyRewardPot - stakerReward;
	}

	function _resetStake(UserStake storage userStake) private {
		userStake.stakingUnits = 0;
		userStake.rewardCredit = 0;
		userStake.amountStaked = 0;
		userStake.enteredAtBlock = 0;
		userStake.lockedTill = 0;
		userStake.ticketsMintingRatioWhenEntered = 0;
		userStake.historyAverageRewardWhenEntered = 0;
		userStake.ticketsMintingChillPeriodWhenEntered = 0;
	}


	/**
	* @notice Remove the previously staked NFT from the stake
	* @param staker the address of the owner of the stake
	*/
	function removeNftFromStake(
		UserStakedToken storage userStakedToken,
		address staker
	)
		public
	{
		if (userStakedToken.tokenAddress != address(0)) {
			uint256 tokenId = userStakedToken.tokenId;
			address tokenAddress = userStakedToken.tokenAddress;

			bool success = TokenHelper.transferFrom(tokenAddress, tokenId, address(this), staker);

			if(success) {
				delete userStakedToken.tokenId;
				delete userStakedToken.tokenAddress;
			}
		}
	}

		/**
	* @notice Allows user to unstake the staked tokens
	* @notice The tokens are allowed to be unstaked only after the lock duration has passed
	* @notice MUST trigger Unstaked event
	* @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
	* @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
	*   transferred back to their account, and their personalStakeIndex will increment to the next active stake.
	* @return uint256 The number of tokens unstaked
	*/
	function unstake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		returns (uint256)
	{
		require(stakeIndex < userStakes.length, 'Staking: Nothing to unstake');

		require(userStakes[stakeIndex].lockedTill < block.number, "Staking: Stake is still locked");
		require(userStakes[stakeIndex].amountStaked != 0, 'Staking: Nothing to unstake');

		uint256 stakerReward = _getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			userStakes,
			stakeIndex
		);


		// if for any reason the transfer fails, it will fail silently
		// and token can be withdrawn when error disappears
		removeNftFromStake(userStakes[stakeIndex].userStakedToken, msg.sender);


		uint256 totalAmount = stakerReward
			+ userStakes[stakeIndex].amountStaked
			+ userStakes[stakeIndex].rewardCredit;

		TokenHelper.ERC20Transfer(rewardStreamInfo.rewardToken, address(msg.sender), totalAmount);

		updateHistoryValues(rewardStreamInfo, stakingInfo);

		stakingInfo.totalDistributedRewards = stakingInfo.totalDistributedRewards + stakerReward + userStakes[stakeIndex].rewardCredit;
		stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked - userStakes[stakeIndex].amountStaked;
		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits - userStakes[stakeIndex].stakingUnits;

		claimTickets(stakingInfo.ticket, userStakes[stakeIndex], msg.sender);
		_resetStake(userStakes[stakeIndex]);

		stakingInfo.historyRewardPot = stakingInfo.historyRewardPot - stakerReward;

		return stakerReward;
	}

	function getClaimableTickets(
		UserStake storage userStake
	)
		public
	  view
		returns (uint256)
	{
		uint256 stakingUnits = userStake.stakingUnits;
		uint256 ticketsMintingChillPeriod = userStake.ticketsMintingChillPeriodWhenEntered;
		uint256 ticketsMintingRatio = userStake.ticketsMintingRatioWhenEntered;
		uint256 ticketsMinted = userStake.ticketsMinted;

		if(stakingUnits == 0 || ticketsMintingRatio == 0 || ticketsMintingChillPeriod == 0) {
			return 0;
		}
		// 2. get chilling period length
		// 3. check how many periods have passed
		uint256 enteredAtBlock = userStake.enteredAtBlock;
		uint256 lockedTill = userStake.lockedTill;
		// 4. prevent minting more tickets after stake is unlocked

		uint256 blocksDelta = Math.min(
			(uint256(block.number) - enteredAtBlock),
			(lockedTill - enteredAtBlock)
		) + ticketsMintingChillPeriod; // count as passed from day 0
		uint256 periodsPassed = blocksDelta / ticketsMintingChillPeriod;
		// 4. multiply tickets
		uint256 multipliedUnits = stakingUnits * periodsPassed;
		// 5. get printable tickets
		uint256 printableTickets = multipliedUnits / ticketsMintingRatio;
		// 6. subtract any previously minted
		uint256 netPrintableTickets = printableTickets - ticketsMinted;
		// 5. don't print more tickets after stake is unlocked
		return netPrintableTickets;
 	}

	/**
	* @notice Mint tickets to the staker
	* @notice The amount of tickets depends on the amount of tokens staked and the duration the tokens a locked for.
	* @param ticket the address of the ticket instance
	* @param userStake the stake to claim tickets from
	* @param staker the address fo the staker
	*/
	function claimTickets(
		address ticket,
		UserStake storage userStake,
		address staker
	)
		public
	{
		uint256 netPrintableTickets = getClaimableTickets(userStake);

		if(netPrintableTickets > 0) {
			 
			TokenHelper._mintTickets(ticket, staker, netPrintableTickets);
			userStake.ticketsMinted = userStake.ticketsMinted + netPrintableTickets;
		}
 	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TokenHelper.sol";

library RewardStreamerLib {
	struct RewardStreamInfo {
		RewardStream[] rewardStreams;
		uint256 deployedAtBlock;
		address rewardToken;
	}

	struct RewardStream {
		uint256[] periodRewards;
		uint256[] periodEnds;
		uint256 rewardStreamCursor;
	}

	/**
	* @notice Will setup the token to use for reward
	* @param rewardTokenAddress The reward token address
	*/
	function setRewardToken(RewardStreamInfo storage rewardStreamInfo, address rewardTokenAddress) public {
		rewardStreamInfo.rewardToken = address(rewardTokenAddress);
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param rewardPerBlock The amount of tokens rewarded per block
	* @param rewardLastBlock The last block of the period
	*/
	function addRewardStream(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint256 rewardPerBlock,
		uint256 rewardLastBlock
	)
		public
		returns (uint256)
	{
		// e.g. current length = 0
		require(rewardStreamIndex <= rewardStreamInfo.rewardStreams.length, "RewardStreamer: you cannot skip an index");

		uint256 tokensInReward;

		if(rewardStreamInfo.rewardStreams.length > rewardStreamIndex) {
			RewardStream storage rewardStream = rewardStreamInfo.rewardStreams[rewardStreamIndex];
			uint256[] storage periodEnds = rewardStream.periodEnds;

			uint periodStart = periodEnds.length == 0
				? rewardStreamInfo.deployedAtBlock
				: periodEnds[periodEnds.length - 1];

			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		} else {
			RewardStream memory rewardStream;

			uint periodStart = rewardStreamInfo.deployedAtBlock;
			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams.push(rewardStream);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		}

		TokenHelper.ERC20TransferFrom(address(rewardStreamInfo.rewardToken), msg.sender, address(this), tokensInReward);

		return tokensInReward;
	}

	/**
	* @notice Get the rewards for a period
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the total reward
	*/
	function unsafeGetRewardsFromRange(
		RewardStreamInfo storage rewardStreamInfo,
		uint fromBlock,
		uint toBlock
	)
		public
		view
		returns (uint256)
	{
		require(tx.origin == msg.sender, "StakingReward: unsafe function for contract call");

		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewards(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				0
			);
		}

		return currentReward;
	}

	/**
	* @notice Iterate the rewards
	* @param rewardStreamIndex the index of the reward stream
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @param rewardIndex the reward index
	* @return (uint256) the calculate reward
	*/
	function iterateRewards(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardIndex
	)
		public
		view
		returns (uint256)
	{
		// the start block is bigger than
		if(rewardIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex - 1];
		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;
			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			return iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		return totalReward;
	}

	/**
	* @notice Iterate the rewards and updates the cursor
	* @notice NOTE: once the cursor is updated, the next call will start from the cursor
	* @notice making it impossible to calculate twice the reward in a period
	* @param rewardStreamInfo the struct holding  current reward info
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the calculated reward
	*/
	function getRewardAndUpdateCursor (
		RewardStreamInfo storage rewardStreamInfo,
		uint256 fromBlock,
		uint256 toBlock
	)
		public
		returns (uint256)
	{
		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewardsWithCursor(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				rewardStreamInfo.rewardStreams[i].rewardStreamCursor
			);
		}

		return currentReward;
	}

	function bumpStreamCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex
	)
		public
	{
		// this step is important to avoid going out of index
		if(rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor < rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor = rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor + 1;
		}
	}

	function iterateRewardsWithCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardPeriodIndex
	)
		public
		returns (uint256)
	{
		if(rewardPeriodIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardPeriodIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardPeriodIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex - 1];

		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;

			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			// the fromBlock passed this reward period, we can start
			// skipping it for next reads
			bumpStreamCursor(rewardStreamInfo, rewardStreamIndex);

			return iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		return totalReward;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "../Raffle/IRaffleTicket.sol";

library TokenHelper {
	function ERC20Transfer(
		address token,
		address to,
		uint256 amount
	)
		public
	{
		(bool success, bytes memory data) =
				token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance');
	}

    function ERC20TransferFrom(
			address token,
			address from,
			address to,
			uint256 amount
    )
			public
		{
			(bool success, bytes memory data) =
					token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
			require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance or allowance');
    }

    function transferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    )
            public
            returns (bool)
        {
                (bool success,) = token.call(abi.encodeWithSelector(IERC721.transferFrom.selector, from, to, tokenId));

                // in the ERC721 the transfer doesn't return a bool. So we need to check explicitly.
                return success;
    }

    function _mintTickets(
        address ticket,
        address to,
        uint256 amount
    ) public {
        (bool success,) = ticket.call(abi.encodeWithSelector(IRaffleTicket.mint.selector, to, 0, amount));

        require(success, 'ERC1155: mint failed');
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


/// @title A mintable NFT ticket for Coinburp Raffle
/// @author Valerio Leo @valerioHQ
interface IRaffleTicket is IERC1155 {
	function mint(address to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Registry holding the rarity value of a given NFT.
/// @author Nemitari Ajienka @najienka
interface INFTRarityRegister {
	/**
	 * The Staking SC allows to stake Prizes won via lottery which can be used to increase the APY of
	 * staked tokens according to the rarity of NFT staked. For this reason,
	 * we need to hold a table that the Staking SC can query and get back the rarity value of a given
	 * NFT price (even the ones in the past).
	 */
	event NftRarityStored(
		address indexed tokenAddress,
		uint256 tokenId,
		uint256 rarityValue
	);

	/**
	 * @dev Store the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @param rarityValue The rarity of a given NFT address and id unique combination
	 */
	function storeNftRarity(address tokenAddress, uint256 tokenId, uint8 rarityValue) external;

	/**
	 * @dev Get the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @return The the rarity of a given NFT address and id unique combination and timestamp
	 */
	function getNftRarity(address tokenAddress, uint256 tokenId) external view returns (uint8);
}

