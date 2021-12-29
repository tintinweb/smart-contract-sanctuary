// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title HighStreet Nft Pool
 *
 */
contract HighStreetNftPool is ReentrancyGuard, ERC721Holder {

    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of reward with its amount and time interval
     */
    struct Deposit {
        // @dev reward amount
        uint256 rewardAmount;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
    }

    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked NFT amount
        uint256 tokenAmount;
        // @dev Total reward amount
        uint256 rewardAmount;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev An array of holder's nft
        uint16[] list;
        // @dev An array of holder's rewards
        Deposit[] deposits;
    }

    /// @dev Link to HIGH STREET ERC20 Token instance
    address public immutable HIGH;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool token instance, here is the Duck NFT 
    address public immutable poolToken;

    /// @dev Block number of the last yield distribution event
    uint256 public lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    uint256 public yieldRewardsPerToken;

    /// @dev Used to calculate yield rewards, tracking the token amount in the pool
    uint256 public usersLockingAmount;

    /// @dev HIGH/block determines yield farming reward
    uint256 public highPerBlock;

    /**
     * @dev End block is the last block when yield farming stops
     */
    uint256 public endBlock;

    /**
     * @dev Rewards per token are stored multiplied by 1e24, as integers
     */
    uint256 internal constant REWARD_PER_TOKEN_MULTIPLIER = 1e24;

    /**
     * @dev Define the size of each batch, see getDepositsBatch()
     */
    uint256 public constant DEPOSIT_BATCH_SIZE  = 20;

    /**
     * @dev Define the size of each batch, see getNftsBatch()
     */
    uint256 public constant NFT_BATCH_SIZE  = 100;

    /**
     * @dev Handle the nft id equal to zero
     */
    uint16 internal constant UINT_16_MAX = type(uint16).max;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     * @param nfts an array stored the NFT id that holder staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount, uint256[] nfts);

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     * @param nfts an array which stored the unstaked NFT id 
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount, uint256[] nfts);

    /**
     * @dev Fired in _unstakeReward() and unstakeReward()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of rewards unstaked
     */
    event UnstakedReward(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerToken updated yield rewards per token value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerToken, uint256 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev construct the pool
     *
     * @param _high HIGH ERC20 Token address
     * @param _poolToken token ERC721 the pool operates on, here is the Duck NFT
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _endBlock block number when farming stops and rewards cannot be updated anymore
     * @param _highPerBlock HIGH/block value for rewards
     */
    constructor(
        address _high,
        address _poolToken,
        uint256 _initBlock,
        uint256 _endBlock,
        uint256 _highPerBlock
    ) {
        // verify the inputs are set
        require(_high != address(0), "high token address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock >= blockNumber(), "Invalid init block");

        // save the inputs into internal state variables
        HIGH = _high;
        poolToken = _poolToken;
        highPerBlock = _highPerBlock;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker) external view returns (uint256) {
        // `newYieldRewardsPerToken` will store stored or recalculated value for `yieldRewardsPerToken`
        uint256 newYieldRewardsPerToken;

        // if smart contract state was not updated recently, `yieldRewardsPerToken` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingAmount != 0) {
            uint256 multiplier =
                blockNumber() > endBlock ? endBlock - lastYieldDistribution : blockNumber() - lastYieldDistribution;
            uint256 highRewards = multiplier * highPerBlock;

            // recalculated value for `yieldRewardsPerToken`
            newYieldRewardsPerToken = rewardToToken(highRewards, usersLockingAmount) + yieldRewardsPerToken;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerToken = yieldRewardsPerToken;
        }

        // based on the rewards per token value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = tokenToReward(user.tokenAmount, newYieldRewardsPerToken) - user.subYieldRewards;

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns the NFT id on the given index and address
     *
     * @dev See getNftListLength
     *
     * @param _user an address to query deposit for
     * @param _index zero-indexed ID for the address specified
     * @return nft id sotred
     */
    function getNftId(address _user, uint256 _index) external view returns (int32) {
        // read deposit at specified index and return
        uint16 value = users[_user].list[_index];
        if(value == 0) {
            return -1;
        } else if(value == UINT_16_MAX) {
            return  0;
        } else {
            return int32(uint32(value));
        }
    }

    /**
     * @notice Returns number of nfts for the given address. Allows iteration over nfts.
     *
     * @dev See getNftId
     *
     * @param _user an address to query deposit length for
     * @return number of nfts for the given address
     */
    function getNftsLength(address _user) external view returns (uint256) {
        // read deposits array length and return
        return users[_user].list.length;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    /**
     * @notice Returns a batch of deposits on the given pageId for the given address
     *
     * @dev We separate deposits into serveral of pages, and each page have DEPOSIT_BATCH_SIZE of item.
     *
     * @param _user an address to query deposit for
     * @param _pageId zero-indexed page ID for the address specified
     * @return deposits info as Deposit structure
     */
    function getDepositsBatch(address _user, uint256 _pageId) external view returns (Deposit[] memory) {
        uint256 pageStart = _pageId * DEPOSIT_BATCH_SIZE;
        uint256 pageEnd = (_pageId + 1) * DEPOSIT_BATCH_SIZE;
        uint256 pageLength = DEPOSIT_BATCH_SIZE;

        if(pageEnd > (users[_user].deposits.length - pageStart)) {
            pageEnd = users[_user].deposits.length;
            pageLength = pageEnd - pageStart;
        }

        Deposit[] memory deposits = new Deposit[](pageLength);
        for(uint256 i = pageStart; i < pageEnd; ++i) {
            deposits[i-pageStart] = users[_user].deposits[i];
        }
        return deposits;
    }

    /**
     * @notice Returns number of pages for the given address. Allows iteration over deposits.
     *
     * @dev See getDepositsBatch
     *
     * @param _user an address to query deposit length for
     * @return number of pages for the given address
     */
    function getDepositsBatchLength(address _user) external view returns (uint256) {
        if(users[_user].deposits.length == 0) {
            return 0;
        }
        return 1 + (users[_user].deposits.length - 1) / DEPOSIT_BATCH_SIZE;
    }


    /**
     * @notice Returns a batch of NFT id on the given pageId for the given address
     *
     * @dev We separate NFT id into serveral of pages, and each page have NFT_BATCH_SIZE of ids.
     *
     * @param _user an address to query deposit for
     * @param _pageId zero-indexed page ID for the address specified
     * @return nft ids that holder staked
     */
    function getNftsBatch(address _user, uint256 _pageId) external view returns (int32[] memory) {
        uint256 pageStart = _pageId * NFT_BATCH_SIZE;
        uint256 pageEnd = (_pageId + 1) * NFT_BATCH_SIZE;
        uint256 pageLength = NFT_BATCH_SIZE;

        if(pageEnd > (users[_user].list.length - pageStart)) {
            pageEnd = users[_user].list.length;
            pageLength = pageEnd - pageStart;
        }

        int32[] memory list = new int32[](pageLength);
        uint16 value;
        for(uint256 i = pageStart; i < pageEnd; ++i) {
            value = users[_user].list[i];
            if(value == 0) {
                list[i-pageStart] = -1;
            } else if(value == UINT_16_MAX) {
                list[i-pageStart] = 0;
            } else {
                list[i-pageStart] = int32(uint32(value));
            }
        }
        return list;
    }

    /**
     * @notice Returns number of pages for the given address. Allows iteration over nfts.
     *
     * @dev See getNftsBatch
     *
     * @param _user an address to query NFT id length for
     * @return number of pages for the given address
     */
    function getNftsBatchLength(address _user) external view returns (uint256) {
        if(users[_user].list.length == 0) {
            return 0;
        }
        return 1 + (users[_user].list.length - 1) / NFT_BATCH_SIZE;
    }

    /**
     * @notice Stakes specified NFT ids
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _nftIds array of NFTs to stake
     */
    function stake(
        uint256[] calldata _nftIds
    ) external nonReentrant {
        require(!isPoolDisabled(), "Pool disable");
        // delegate call to an internal function
        _stake(msg.sender, _nftIds);
    }

    /**
     * @notice Unstakes specified amount of NFTs, and pays pending yield rewards
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _listIds index ID to unstake from, zero-indexed
     */
    function unstake(
        uint256[] calldata _listIds
    ) external nonReentrant {
        // delegate call to an internal function
        _unstake(msg.sender, _listIds);
    }

    /**
     * @notice Unstakes specified amount of rewards
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     */
    function unstakeReward(
        uint256 _depositId
    ) external nonReentrant {
        // delegate call to an internal function
        User storage user = users[msg.sender];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
        _unstakeReward(msg.sender, _depositId);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after end block
     *      ), function doesn't throw and exits silently
     */
    function sync() external {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after end block
     *      ), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external virtual nonReentrant {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return tokenToReward(user.tokenAmount, yieldRewardsPerToken) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _nftIds array of NFTs staked
     */
    function _stake(
        address _staker,
        uint256[] calldata _nftIds
    ) internal virtual {
        require(_nftIds.length > 0, "zero amount");
        // limit the max nft transfer.
        require(_nftIds.length <= 40, "length exceeds limitation");

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        //looping transfer
        uint256 addedAmount;
        for(uint i; i < _nftIds.length; ++i) {
            IERC721(poolToken).safeTransferFrom(_staker, address(this), _nftIds[i]);
            if(_nftIds[i] == 0) {
                //if nft id ==0, then set it to uint16 max
                user.list.push(UINT_16_MAX);
            } else {
                user.list.push(uint16(_nftIds[i]));
            }
            addedAmount = addedAmount + 1;
        }

        user.tokenAmount += addedAmount;
        user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        usersLockingAmount += addedAmount;

        // emit an event
        emit Staked(msg.sender, _staker, addedAmount, _nftIds);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes NFT (which has staked some NFTs earlier)
     * @param _listIds index ID to unstake from, zero-indexed
     */
    function _unstake(
        address _staker,
        uint256[] calldata _listIds
    ) internal virtual {
        require(_listIds.length > 0, "zero amount");
        // limit the max nft transfer.
        require(_listIds.length <= 40, "length exceeds limitation");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        uint16[] memory list = user.list;
        uint256 amount = _listIds.length;
        require(user.tokenAmount >= amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // update user record
        user.tokenAmount -= amount;
        user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        usersLockingAmount = usersLockingAmount - amount;

        uint256 index;
        uint256[] memory nfts = new uint256[](_listIds.length);
        for(uint i; i < _listIds.length; ++i) {
            index = _listIds[i];
            if(UINT_16_MAX == list[index]) {
                nfts[i] = 0;
            } else {
                nfts[i] = uint256(list[index]);
            }
            IERC721(poolToken).safeTransferFrom(address(this), _staker, nfts[i]);
            if (user.tokenAmount  != 0) {
                delete user.list[index];
            }
        }

        if (user.tokenAmount  == 0) {
            delete user.list;
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, amount, nfts);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstakeReward()
     *
     * @param _staker an address to withraw the yield reward
     * @param _depositId deposit ID to unstake from, zero-indexed
     */
    function _unstakeReward(
        address _staker,
        uint256 _depositId
    ) internal virtual {

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        uint256 amount = stakeDeposit.rewardAmount;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(amount >= 0, "amount exceeds stake");

        // delete deposit if its depleted
        delete user.deposits[_depositId];

        // update user record
        user.rewardAmount -= amount;

        // transfer HIGH tokens as required
        SafeERC20.safeTransfer(IERC20(HIGH), _staker, amount);

        // emit an event
        emit UnstakedReward(msg.sender, _staker, amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerToken`, `lastYieldDistribution`)
     */
    function _sync() internal virtual {

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingAmount == 0) {
            lastYieldDistribution = blockNumber();
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;

        // calculate the reward
        uint256 highReward = blocksPassed * highPerBlock;

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerToken += rewardToToken(highReward, usersLockingAmount);
        lastYieldDistribution = currentBlock;

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerToken, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // create new HIGH deposit
        // and save it - push it into deposits array
        Deposit memory newDeposit =
            Deposit({
                rewardAmount: pendingYield,
                lockedFrom: uint64(now256()),
                lockedUntil: uint64(now256() + 365 days) // staking yield for 1 year
            });
        user.deposits.push(newDeposit);

        // update user record
        user.rewardAmount += pendingYield;

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }

    /**
     * @dev Converts stake token (not to be mixed with the pool token) to
     *      HIGH reward value, applying the 10^24 division on token
     *
     * @param _token stake token
     * @param _rewardPerToken HIGH reward per token
     * @return reward value normalized to 10^24
     */
    function tokenToReward(uint256 _token, uint256 _rewardPerToken) public pure returns (uint256) {
        // apply the formula and return
        return (_token * _rewardPerToken) / REWARD_PER_TOKEN_MULTIPLIER;
    }

    /**
     * @dev Converts reward HIGH value to stake token (not to be mixed with the pool token),
     *      applying the 10^24 multiplication on the reward
     *
     * @param _reward yield reward
     * @param _rewardPerToken staked token amount
     * @return reward/token
     */
    function rewardToToken(uint256 _reward, uint256 _rewardPerToken) public pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_TOKEN_MULTIPLIER) / _rewardPerToken;
    }

    /**
     * @notice The function to check pool state. pool is considered "disabled"
     *      once time reaches its "end block"
     *
     * @return true if pool is disabled (time has reached end block), false otherwise
     */
    function isPoolDisabled() public view returns (bool) {
        // verify the pool expiration condition and return the result
        return blockNumber() >= endBlock;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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