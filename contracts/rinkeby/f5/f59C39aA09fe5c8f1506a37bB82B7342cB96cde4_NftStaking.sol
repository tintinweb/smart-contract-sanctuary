// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// BirdFarm is the master of RewardToken. He can make RewardToken and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once REWARD_TOKEN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

/// @title Farming service for pool tokens
/// @author Bird Money
/// @notice You can use this contract to deposit pool tokens and get rewards
/// @dev Admin can add a new Pool, users can deposit pool tokens, harvestReward, withdraw pool tokens
contract NftStaking is Ownable, ReentrancyGuard, IERC721Receiver {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many pool tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 reward; // Reward to be given to user
        //
        // We do some fancy math here. Basically, any point in time, the amount of REWARD_TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws pool tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC721 poolToken; // Address of pool token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. REWARD_TOKENs to distribute per block.
        uint256 lastRewardBlock; // Last block number that REWARD_TOKENs distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated REWARD_TOKENs per share, times 1e12. See below.
    }

    /// @dev The REWARD_TOKEN TOKEN!
    IERC20 public rewardToken =
        IERC20(0xEf44f26371BF874b5D4c8b49914af169336bc957);

    /// @dev Block number when bonus REWARD_TOKEN period ends.
    uint256 public bonusEndBlock = 0;

    /// @notice REWARD_TOKEN tokens created per block.
    /// @dev its equal to approx 1000 reward tokens per day
    uint256 public rewardPerBlock = 0.15 ether;

    // Bonus muliplier for early rewardToken makers.
    uint256 private constant BONUS_MULTIPLIER = 10;

    /// @dev Info of each pool.
    PoolInfo[] public poolInfo;

    /// @dev Info of each user that stakes pool tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(IERC721 => mapping(uint256 => address)) public nftOwnerOf;

    /// @dev Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// @dev The block number when REWARD_TOKEN mining starts.
    uint256 public startBlock = 0;

    /// @dev The block number when REWARD_TOKEN mining ends.
    uint256 public endBlock = 0;

    /// @notice user can get reward and unstake after this time only.
    /// @dev No unstake froze time initially, if needed it can be added and informed to community.
    uint256 public usersCanUnstakeAtTime = 0 seconds;

    /// @dev No reward froze time initially, if needed it can be added and informed to community.
    uint256 public usersCanHarvestAtTime = 0 seconds;

    mapping(IERC721 => bool) private uniqueTokenInPool;

    /// @dev when some one deposits pool tokens to contract
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @dev when some one withdraws pool tokens from contract
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @dev when some one harvests reward tokens from contract
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice gets total number of pools
    /// @return total number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice This adds a new pool. Can only be called by the owner.
    /// @dev Only adds unique pool token
    /// @param _allocPoint The weight of this pool. The more it is the more percentage of reward per block it will get for its users with respect to other pools. But the total reward per block remains same.
    /// @param _poolToken The Liquidity Pool Token of this pool
    /// @param _withUpdate if true then it updates the reward tokens to be given for each of the tokens staked
    function add(
        uint256 _allocPoint,
        IERC721 _poolToken,
        bool _withUpdate
    ) external onlyOwner {
        require(!uniqueTokenInPool[_poolToken], "Token already added");
        uniqueTokenInPool[_poolToken] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                poolToken: _poolToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardTokenPerShare: 0
            })
        );
    }

    /// @notice Update the given pool's REWARD_TOKEN pool weight. Can only be called by the owner.
    /// @dev it can change alloc point (weight of pool) with repect to other pools
    /// @param _pid pool id
    /// @param _allocPoint The weight of this pool. The more it is the more percentage of reward per block it will get for its users with respect to other pools. But the total reward per block remains same.
    /// @param _withUpdate if true then it updates the reward tokens to be given for each of the tokens staked
    function setAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            (poolInfo[_pid].allocPoint + _allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return number of blocks between _from to _to block which are applicable for reward tokens. if multiplier returns 10 blocks then 10 * reward per block = 50 coins to be given as reward. equally to community. with repect to pool weight.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        uint256 from = _from;
        uint256 to = _to;
        if (endBlock < from) from = endBlock;
        if (endBlock < to) to = endBlock;
        if (to < startBlock) return 0;
        if (from < startBlock && startBlock < to) from = startBlock;

        if (to <= bonusEndBlock) {
            return (to - from) * (BONUS_MULTIPLIER);
        } else if (from >= bonusEndBlock) {
            return to - from;
        } else {
            return
                (bonusEndBlock - from) *
                BONUS_MULTIPLIER +
                (to - bonusEndBlock);
        }
    }

    // get pid from token address
    function getPidOfToken(address _token) external view returns (uint256) {
        for (uint256 index = 0; index < poolInfo.length; index++) {
            if (address(poolInfo[index].poolToken) == _token) {
                return index;
            }
        }

        return type(uint256).max;
    }

    /// @notice get reward tokens to show on UI
    /// @dev calculates reward tokens of a user with repect to pool id
    /// @param _pid the pool id
    /// @param _user the user who is calls this function
    /// @return pending reward tokens of a user
    function pendingRewardToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 poolSupply = pool.poolToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && poolSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 rewardTokenReward = (multiplier *
                (rewardPerBlock) *
                (pool.allocPoint)) / (totalAllocPoint);
            accRewardTokenPerShare =
                accRewardTokenPerShare +
                ((rewardTokenReward * 1e12) / (poolSupply));
        }
        return
            user.reward +
            (((user.amount * accRewardTokenPerShare) / 1e12) -
                (user.rewardDebt));
    }

    /// @notice Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    uint256 private stakedTokens = 0;

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) public {
        if (stakedTokens == 0) configTheEndRewardBlock(); // to stop making reward when reward tokens are empty in BirdFarm

        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 poolSupply = pool.poolToken.balanceOf(address(this));
        if (poolSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward = (multiplier *
            (rewardPerBlock) *
            (pool.allocPoint)) / (totalAllocPoint);
        pool.accRewardTokenPerShare =
            pool.accRewardTokenPerShare +
            ((rewardTokenReward * (1e12)) / (poolSupply));
        pool.lastRewardBlock = block.number;
    }

    /// @notice deposit tokens to get rewards
    /// @dev deposit pool tokens to BirdFarm for reward tokens allocation.
    /// @param _pid pool id
    /// @param _tokenId how many tokens you want to stake
    function deposit(uint256 _pid, uint256 _tokenId) public {
        uint256 _amount = 1;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        nftOwnerOf[pool.poolToken][_tokenId] = msg.sender;
        require(_amount > 0, "Must deposit amount more than zero.");

        updatePool(_pid);

        uint256 pending = (user.amount * (pool.accRewardTokenPerShare)) /
            1e12 -
            user.rewardDebt;
        user.reward += pending;

        stakedTokens += _amount;
        user.amount = user.amount + (_amount);
        user.rewardDebt =
            (user.amount * (pool.accRewardTokenPerShare)) /
            (1e12);
        // addToList(msg.sender, _tokenId);
        pool.poolToken.transferFrom(
            address(msg.sender),
            address(this),
            _tokenId
        );
        emit Deposit(msg.sender, _pid, _tokenId);
    }

    function depositMany(uint256[] memory _pids, uint256[] memory _tokenIds)
        external
        
    {
        for (uint256 i = 0; i <= _tokenIds.length; i++) {
            deposit(_pids[i], _tokenIds[i]);
        }
    }

    /// @notice get the tokens back from BardFarm
    /// @dev withdraw or unstake pool tokens from BidFarm
    /// @param _pid pool id
    /// @param  _tokenId how many pool tokens you want to unstake
    function withdraw(uint256 _pid, uint256 _tokenId) public {
        uint256 _amount = 1;
        require(
            block.timestamp > usersCanUnstakeAtTime,
            "Can not withdraw/unstake at this time."
        );
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            nftOwnerOf[pool.poolToken][_tokenId] == msg.sender,
            "you are not owner"
        );

        require(
            user.amount >= _amount,
            "You do not have enough pool tokens staked."
        );
        updatePool(_pid);
        uint256 pending = (user.amount * (pool.accRewardTokenPerShare)) /
            1e12 -
            user.rewardDebt;

        user.reward += pending;

        stakedTokens -= _amount;
        user.amount = user.amount - (_amount);
        user.rewardDebt =
            (user.amount * (pool.accRewardTokenPerShare)) /
            (1e12);
        pool.poolToken.transferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );
        emit Withdraw(msg.sender, _pid, _tokenId);
    }

    function withdrawMany(uint256[] memory _pids, uint256[] memory _tokenIds)
        external
        nonReentrant
    {
        for (uint256 i = 0; i <= _tokenIds.length; i++) {
            withdraw(_pids[i], _tokenIds[i]);
        }
    }

    function depositWithdrawMany(
        uint256[] memory _pidsD,
        uint256[] memory _tokenIdsD,
        uint256[] memory _pidsW,
        uint256[] memory _tokenIdsW
    ) external nonReentrant {
        for (uint256 i = 0; i <= _tokenIdsD.length; i++) {
            deposit(_pidsD[i], _tokenIdsD[i]);
        }
        for (uint256 i = 0; i <= _tokenIdsW.length; i++) {
            deposit(_pidsW[i], _tokenIdsW[i]);
        }
    }

    /// @notice harvest reward tokens from BardFarm
    /// @dev harvest reward tokens from BidFarm and update pool variables
    /// @param _pid pool id
    function harvest(uint256 _pid) external {
        require(
            block.timestamp > usersCanHarvestAtTime,
            "Can not harvest at this time."
        );
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = (user.amount * (pool.accRewardTokenPerShare)) /
            1e12 -
            user.rewardDebt;

        user.reward += pending;
        uint256 rewardToGiveNow = user.reward;
        user.reward = 0;

        user.rewardDebt =
            (user.amount * (pool.accRewardTokenPerShare)) /
            (1e12);

        rewardToken.transfer(msg.sender, rewardToGiveNow);
        emit Harvest(msg.sender, _pid, pending);
    }

    function configTheEndRewardBlock() internal {
        endBlock =
            block.number +
            ((rewardToken.balanceOf(address(this)) / (rewardPerBlock)));
    }

    /// @notice owner puts reward tokens in contract
    /// @dev owner can add reward token to contract so that it can be distributed to users
    /// @param _amount amount of reward tokens
    function addRewardTokensToContract(uint256 _amount) external onlyOwner {
        uint256 rewardEndsInBlocks = _amount / (rewardPerBlock);

        uint256 lastEndBlock = endBlock == 0 ? block.number : endBlock;
        endBlock = lastEndBlock + rewardEndsInBlocks;

        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "Error in adding reward tokens in contract."
        );
        emit EndRewardBlockChanged(endBlock);
    }

    event AddedRewardTokensToContract(uint256 amount);

    /// @notice owner takes out any tokens in contract
    /// @dev owner can take out any locked tokens in contract
    /// @param _token the token owner wants to take out from contract
    /// @param _amount amount of tokens
    function withdrawAnyTokenFromContract(IERC20 _token, uint256 _amount)
        external
        onlyOwner
    {
        _token.transfer(msg.sender, _amount);
        emit OwnerWithdraw(_token, _amount);
    }

    event OwnerWithdraw(IERC20 token, uint256 amount);

    /// @notice owner can change reward token
    /// @dev owner can set reward token
    /// @param _rewardToken the token in which rewards are given
    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit RewardTokenChanged(_rewardToken);
    }

    /// @dev When reward token changes
    /// @param rewardToken the token in which rewards are given
    event RewardTokenChanged(IERC20 rewardToken);

    /// @notice owner can change unstake frozen time
    /// @dev owner can set unstake frozen time
    /// @param _usersCanUnstakeAtTime the block at which user can unstake
    function setUnstakeFrozenTime(uint256 _usersCanUnstakeAtTime)
        external
        onlyOwner
    {
        usersCanUnstakeAtTime = _usersCanUnstakeAtTime;
        emit UnstakeFrozenTimeChanged(_usersCanUnstakeAtTime);
    }

    /// @dev When Unstake Frozen Time Changed
    /// @param usersCanUnstakeAtTime after this time users can unstake
    event UnstakeFrozenTimeChanged(uint256 usersCanUnstakeAtTime);

    /// @notice owner can change reward frozen time
    /// @dev owner can set reward frozen time
    /// @param _usersCanHarvestAtTime the block at which user can harvest reward
    function setRewardFrozenTime(uint256 _usersCanHarvestAtTime)
        external
        onlyOwner
    {
        usersCanHarvestAtTime = _usersCanHarvestAtTime;
        emit RewardFrozenTimeChanged(_usersCanHarvestAtTime);
    }

    /// @dev When Reward Frozen Time Changed
    /// @param usersCanHarvestAtTime after this time users can harvest
    event RewardFrozenTimeChanged(uint256 usersCanHarvestAtTime);

    /// @notice owner can change reward token per block
    /// @dev owner can set reward token per block
    /// @param _rewardPerBlock rewards distributed per block to community or users
    function setRewardTokenPerBlock(uint256 _rewardPerBlock)
        external
        onlyOwner
    {
        rewardPerBlock = _rewardPerBlock;
        emit RewardTokenPerBlockChanged(_rewardPerBlock);
    }

    /// @dev When Reward Token Per Block is changed
    /// @param rewardPerBlock reward tokens made in each block
    event RewardTokenPerBlockChanged(uint256 rewardPerBlock);

    /// @notice owner can change start reward block
    /// @dev owner can set start reward block
    /// @param _startBlock the block at which reward token distribution starts
    function setStartRewardBlock(uint256 _startBlock) external onlyOwner {
        require(
            _startBlock <= endBlock,
            "Start block must be less or equal to end reward block."
        );
        startBlock = _startBlock;
        emit StartRewardBlockChanged(_startBlock);
    }

    /// @dev Start Reward Block Changed
    /// @param startRewardBlock block when rewards are distributed per block to community or users
    event StartRewardBlockChanged(uint256 startRewardBlock);

    /// @notice owner can change end reward block
    /// @dev owner can set end reward block
    /// @param _endBlock the block at which reward token distribution ends
    function setEndRewardBlock(uint256 _endBlock) external onlyOwner {
        require(
            startBlock <= _endBlock,
            "End reward block must be greater or equal to start reward block."
        );
        endBlock = _endBlock;
        emit EndRewardBlockChanged(_endBlock);
    }

    /// @dev End Reward Block Changed
    /// @param endBlock block when rewards are ended to be distributed per block to community or users
    event EndRewardBlockChanged(uint256 endBlock);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function GetNFTsForAddress(
        address _owner,
        address _nftAddress,
        uint256 _tokenIdFrom,
        uint256 _tokenIdTo,
        uint256 _maxNfts
    ) external view returns (uint256[] memory) {
        uint256 selectedTokenIds = 0;
        uint256[] memory selectedTokenIdsList = new uint256[](_maxNfts);

        IERC721 nft = IERC721(_nftAddress);

        for (uint256 i = _tokenIdFrom; i <= _tokenIdTo; i++) {
            try nft.ownerOf(i) returns (address owner) {
                if (owner == _owner) {
                    selectedTokenIdsList[selectedTokenIds] = i;
                    selectedTokenIds++;
                    if (selectedTokenIds >= _maxNfts) break;
                }
            } catch {}
        }

        return selectedTokenIdsList;
    }

    // get a list of token ids to check they belong to an address or not
    // return list of token ids that belong to this address
    function GetNFTsForAddress(
        address _owner,
        address _nftAddress,
        uint256[] memory _tokenIds,
        uint256 _maxNfts
    ) external view returns (uint256[] memory) {
        uint256 selectedTokenIds = 0;
        uint256[] memory selectedTokenIdsList = new uint256[](_maxNfts);

        IERC721 nft = IERC721(_nftAddress);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            try nft.ownerOf(_tokenIds[i]) returns (address owner) {
                if (owner == _owner) {
                    selectedTokenIdsList[selectedTokenIds] = _tokenIds[i];
                    selectedTokenIds++;
                    if (selectedTokenIds >= _maxNfts) break;
                }
            } catch {}
        }

        return selectedTokenIdsList;
    }

    function GetNFTsStakedForAddress(
        address _owner,
        uint256 _pid,
        uint256 _tokenIdFrom,
        uint256 _tokenIdTo,
        uint256 _maxNfts
    ) external view returns (uint256[] memory) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 selectedTokenIds = 0;
        uint256[] memory selectedTokenIdsList = new uint256[](_maxNfts);

        for (uint256 i = _tokenIdFrom; i <= _tokenIdTo; i++) {
            if (nftOwnerOf[pool.poolToken][i] == _owner) {
                selectedTokenIdsList[selectedTokenIds] = i;
                selectedTokenIds++;
                if (selectedTokenIds >= _maxNfts) break;
            }
        }

        return selectedTokenIdsList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}