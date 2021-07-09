/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @api3-dao/api3-voting/interfaces/v0.8.4/[email protected]

pragma solidity 0.8.4;

interface IApi3Voting {
     enum VoterState { Absent, Yea, Nay }

    function votesLength()
        external
        view
        returns (uint256);

    function getVote(uint256 _voteId)
        external
        view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower,
            bytes memory script
        );

    function getVoterState(uint256 _voteId, address _voter)
        external
        view
        returns (VoterState);

    function minAcceptQuorumPct()
        external
        view
        returns (uint64);

    function voteTime()
        external
        view
        returns (uint64);
}


// File contracts/interfaces/IApi3PoolExtended.sol

pragma solidity 0.8.4;

interface IApi3PoolExtended {
    function api3Token()
        external
        view
        returns (address);

    function agentAppPrimary()
        external
        view
        returns (address);

    function agentAppSecondary()
        external
        view
        returns (address);

    function votingAppPrimary()
        external
        view
        returns (address);

    function votingAppSecondary()
        external
        view
        returns (address);

    function apr()
        external
        view
        returns (uint256);

    function totalStake()
        external
        view
        returns (uint256);

    function stakeTarget()
        external
        view
        returns (uint256);

    function proposalVotingPowerThreshold()
        external
        view
        returns (uint256);

    function totalShares()
        external
        view
        returns (uint256);

    function userStake(address userAddress)
        external
        view
        returns (uint256);

    function getUser(address userAddress)
        external
        view
        returns (
            uint256 unstaked,
            uint256 vesting,
            uint256 unstakeShares,
            uint256 unstakeAmount,
            uint256 unstakeScheduledFor,
            uint256 lastDelegationUpdateTimestamp,
            uint256 lastProposalTimestamp
            );

    function userLocked(address userAddress)
        external
        view
        returns (uint256);

    function userVotingPowerAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns (uint256);

    function userVotingPower(address userAddress)
        external
        view
        returns (uint256);

    function delegatedToUser(address userAddress)
        external
        view
        returns (uint256);

    function userDelegateAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns (address);

    function userDelegate(address userAddress)
        external
        view
        returns (address);
}


// File contracts/Convenience.sol

pragma solidity 0.8.4;




/// @title Convenience contract used to make batch view calls to DAO contracts
contract Convenience is Ownable  {
    enum VotingAppType { Primary, Secondary }

    /// @notice Governance token of the DAO
    IERC20Metadata public immutable api3Token;
    /// @notice Staking pool of the DAO
    IApi3PoolExtended public immutable api3Pool;
    /// @notice List of ERC20 addresses that will be displayed in the DAO
    /// treasury. The ETH balance will also be displayed by default.
    /// @dev These are set by the owner of this contract
    address[] public erc20Addresses;
    /// @notice Links to the discussion venues for each vote
    /// @dev These are set by the owner of this contract, for example by
    /// running a bot that automatically creates a forum thread with the vote
    /// type and ID and writes its URL to the chain
    mapping(VotingAppType => mapping(uint256 => string)) public votingAppTypeToVoteIdToDiscussionUrl;

    event SetErc20Addresses(address[] erc20Addresses);

    event SetDiscussionUrl(
        VotingAppType indexed votingAppType,
        uint256 indexed voteId,
        string discussionUrl
        );

    /// @param api3PoolAddress Staking pool address of the DAO 
    constructor(address api3PoolAddress)
    {
        api3Pool = IApi3PoolExtended(api3PoolAddress);
        api3Token = IERC20Metadata(address(IApi3PoolExtended(api3PoolAddress).api3Token()));
    }

    /// @notice Called by the owner to update the addresses of the contract
    /// addresses of the ERC20 tokens that will be displayed in the treasury
    /// @dev The owner privileges here do not pose a serious security risk, the
    /// worst that can happen is that the treasury display will malfunction
    /// @param _erc20Addresses ERC20 addresses
    function setErc20Addresses(address[] calldata _erc20Addresses)
        external
        onlyOwner()
    {
        erc20Addresses = _erc20Addresses;
        emit SetErc20Addresses(_erc20Addresses);
    }

    /// @notice Called by the owner to update the discussion URL of a specific
    /// vote to be displayed on the DAO dashboard
    /// @dev The owner privileges here do not pose a serious security risk, the
    /// worst that can happen is that the discussion URL will malfunction
    /// @param votingAppType Enumerated voting app type (primary or secondary)
    /// @param voteId Vote ID for which discussion URL will be updated
    /// @param discussionUrl Discussion URL
    function setDiscussionUrl(
        VotingAppType votingAppType,
        uint256 voteId,
        string calldata discussionUrl
        )
        external
        onlyOwner()
    {
        votingAppTypeToVoteIdToDiscussionUrl[votingAppType][voteId] = discussionUrl;
        emit SetDiscussionUrl(votingAppType, voteId, discussionUrl);
    }

    /// @notice Used by the DAO dashboard client to retrieve user staking data
    /// @param userAddress User address
    /// @return apr Staking reward APR
    /// @return api3Supply API3 total supply
    /// @return totalStake Total amount staked at the pool
    /// @return totalShares Total pool shares (also represents total voting
    /// power)
    /// @return stakeTarget Pool stake target in percentages
    /// @return userApi3Balance User API3 balance
    /// @return userStaked Amount of staked tokens the user has at the pool
    /// @return userUnstaked Amount of non-staked tokens the user has at the
    /// pool
    /// @return userVesting Amount of tokens not yet vested to the user (it is
    /// not withdrawable, similar to `userLocked`)
    /// @return userUnstakeAmount Amount of tokens the user scheduled to
    /// unstake
    /// @return userUnstakeShares Amount of shares the user gave up to schedule
    /// the unstaking
    /// @return userUnstakeScheduledFor Time when the scheduled unstake will
    /// mature
    /// @return userLocked Amount of rewards the user has received that are not
    /// withdrawable yet
    function getUserStakingData(address userAddress)
        external
        view
        returns (
            uint256 apr,
            uint256 api3Supply,
            uint256 totalStake,
            uint256 totalShares,
            uint256 stakeTarget,
            uint256 userApi3Balance,
            uint256 userStaked,
            uint256 userUnstaked,
            uint256 userVesting,
            uint256 userUnstakeAmount,
            uint256 userUnstakeShares,
            uint256 userUnstakeScheduledFor,
            uint256 userLocked
            )
    {
        apr = api3Pool.apr();
        api3Supply = api3Token.totalSupply();
        totalStake = api3Pool.totalStake();
        totalShares = api3Pool.totalShares();
        stakeTarget = api3Pool.stakeTarget();
        userApi3Balance = api3Token.balanceOf(userAddress);
        userStaked = api3Pool.userStake(userAddress);
        (
            userUnstaked,
            userVesting,
            userUnstakeAmount,
            userUnstakeShares,
            userUnstakeScheduledFor,
            , // lastDelegationUpdateTimestamp
            // lastProposalTimestamp
            ) = api3Pool.getUser(userAddress);
        userLocked = api3Pool.userLocked(userAddress);
    }

    /// @notice Used by the DAO dashboard client to retrieve the treasury and
    /// user delegation data
    /// @dev In addition to the ERC20 tokens, it returns the ETH balances of
    /// the treasuries
    /// @param userAddress User address
    /// @return names ERC20 (+ Ethereum) names
    /// @return symbols ERC20 (+ Ethereum) symbols
    /// @return decimals ERC20 (+ Ethereum) decimals
    /// @return balancesOfPrimaryAgent ERC20 (+ Ethereum) balances of the
    /// primary agent
    /// @return balancesOfSecondaryAgent ERC20 (+ Ethereum) balances of the
    /// secondary agent
    /// @return proposalVotingPowerThreshold Proposal voting power threshold in
    /// percentages
    /// @return userVotingPower Voting power of the user, including delegations
    /// @return delegatedToUser Voting power delegated to user
    /// @return delegate Address that the user has delegated to
    /// @return lastDelegationUpdateTimestamp When the user has last updated
    /// their delegation
    /// @return lastProposalTimestamp When the user has last made a proposal
    function getTreasuryAndUserDelegationData(address userAddress)
        external
        view
        returns (
            string[] memory names,
            string[] memory symbols,
            uint8[] memory decimals,
            uint256[] memory balancesOfPrimaryAgent,
            uint256[] memory balancesOfSecondaryAgent,
            uint256 proposalVotingPowerThreshold,
            uint256 userVotingPower,
            uint256 delegatedToUser,
            address delegate,
            uint256 lastDelegationUpdateTimestamp,
            uint256 lastProposalTimestamp
            )
    {
        names = new string[](erc20Addresses.length + 1);
        symbols = new string[](erc20Addresses.length + 1);
        decimals = new uint8[](erc20Addresses.length + 1);
        balancesOfPrimaryAgent = new uint256[](erc20Addresses.length + 1);
        balancesOfSecondaryAgent = new uint256[](erc20Addresses.length + 1);
        for (uint256 i = 0; i < erc20Addresses.length; i++)
        {
            IERC20Metadata erc20 = IERC20Metadata(erc20Addresses[i]);
            names[i] = erc20.name();
            symbols[i] = erc20.symbol();
            decimals[i] = erc20.decimals();
            balancesOfPrimaryAgent[i] = erc20.balanceOf(api3Pool.agentAppPrimary());
            balancesOfSecondaryAgent[i] = erc20.balanceOf(api3Pool.agentAppSecondary());
        }
        names[erc20Addresses.length] = "Ethereum";
        symbols[erc20Addresses.length] = "ETH";
        decimals[erc20Addresses.length] = 18;
        balancesOfPrimaryAgent[erc20Addresses.length] = address(api3Pool.agentAppPrimary()).balance;
        balancesOfSecondaryAgent[erc20Addresses.length] = address(api3Pool.agentAppSecondary()).balance;
        proposalVotingPowerThreshold = api3Pool.proposalVotingPowerThreshold();
        userVotingPower = api3Pool.userVotingPower(userAddress);
        delegatedToUser = api3Pool.delegatedToUser(userAddress);
        delegate = api3Pool.userDelegate(userAddress);   
        (
            , // unstaked
            , // vesting
            , // unstakeAmount
            , // unstakeShares
            , // unstakeScheduledFor
            lastDelegationUpdateTimestamp,
            lastProposalTimestamp
            ) = api3Pool.getUser(userAddress);
    }

    /// @notice Used by the DAO dashboard client to retrieve static vote data
    /// @dev `discussionUrl` is not actually static but can be treated as such
    /// @param votingAppType Enumerated voting app type (primary or secondary)
    /// @param userAddress User address
    /// @param voteIds Array of vote IDs for which data will be retrieved
    /// @return startDate Start date of the vote
    /// @return supportRequired Support required for the vote to pass in
    /// percentages
    /// @return minAcceptQuorum Minimum acceptance quorum required for the vote
    /// to pass in percentages
    /// @return votingPower Total voting power at the time the vote was created
    /// @return script The EVMScript that will be run if the vote passes
    /// @return userVotingPowerAt User's voting power at the time the vote was
    /// created
    /// @return discussionUrl Discussion URL set for the vote by the contract
    /// owner
    function getStaticVoteData(
        VotingAppType votingAppType,
        address userAddress,
        uint256[] calldata voteIds
        )
        external
        view
        returns (
            uint64[] memory startDate,
            uint64[] memory supportRequired,
            uint64[] memory minAcceptQuorum,
            uint256[] memory votingPower,
            bytes[] memory script,
            uint256[] memory userVotingPowerAt,
            string[] memory discussionUrl
            )
    {
        IApi3Voting api3Voting;
        if (votingAppType == VotingAppType.Primary)
        {
            api3Voting = IApi3Voting(api3Pool.votingAppPrimary());
        }
        else
        {
            api3Voting = IApi3Voting(api3Pool.votingAppSecondary());
        }
        startDate = new uint64[](voteIds.length);
        supportRequired = new uint64[](voteIds.length);
        minAcceptQuorum = new uint64[](voteIds.length);
        votingPower = new uint256[](voteIds.length);
        script = new bytes[](voteIds.length);
        userVotingPowerAt = new uint256[](voteIds.length);
        discussionUrl = new string[](voteIds.length);
        for (uint256 i = 0; i < voteIds.length; i++)
        {
            uint64 snapshotBlock;
            (
                , // open
                , // executed
                startDate[i],
                snapshotBlock,
                supportRequired[i],
                minAcceptQuorum[i],
                , // yea
                , // nay
                votingPower[i],
                script[i]
                ) = api3Voting.getVote(voteIds[i]);
            userVotingPowerAt[i] = api3Pool.userVotingPowerAt(userAddress, snapshotBlock);
            discussionUrl[i] = votingAppTypeToVoteIdToDiscussionUrl[votingAppType][voteIds[i]];
        }
    }

    /// @notice Used by the DAO dashboard client to retrieve dynamic vote data
    /// @dev `delegateAt` is actually static but we already have to fetch it
    /// to fetch the related dynamic data so we also return it in this mtehod
    /// @param votingAppType Enumerated voting app type (primary or secondary)
    /// @param userAddress User address
    /// @param voteIds Array of vote IDs for which data will be retrieved
    /// @return executed If the vote has been executed
    /// @return yea Total voting power voted for "For"
    /// @return nay Total voting power voted for "Against"
    /// @return voterState Vote cast by the user
    /// @return delegateAt Address the user has delegated to at the time the
    /// vote was created
    /// @return delegateState Vote cast by the delegate of the user
    function getDynamicVoteData(
        VotingAppType votingAppType,
        address userAddress,
        uint256[] calldata voteIds
        )
        external
        view
        returns (
            bool[] memory executed,
            uint256[] memory yea,
            uint256[] memory nay,
            IApi3Voting.VoterState[] memory voterState,
            address[] memory delegateAt,
            IApi3Voting.VoterState[] memory delegateState
            )
    {
        IApi3Voting api3Voting;
        if (votingAppType == VotingAppType.Primary)
        {
            api3Voting = IApi3Voting(api3Pool.votingAppPrimary());
        }
        else
        {
            api3Voting = IApi3Voting(api3Pool.votingAppSecondary());
        }
        executed = new bool[](voteIds.length);
        yea = new uint256[](voteIds.length);
        nay = new uint256[](voteIds.length);
        voterState = new IApi3Voting.VoterState[](voteIds.length);
        delegateAt = new address[](voteIds.length);
        delegateState = new IApi3Voting.VoterState[](voteIds.length);
        for (uint256 i = 0; i < voteIds.length; i++)
        {
            uint64 snapshotBlock;
            (
                , // open
                executed[i],
                , // startDate
                snapshotBlock,
                , // supportRequired
                , // minAcceptQuorum
                yea[i],
                nay[i],
                , // votingPower
                // script
                ) = api3Voting.getVote(voteIds[i]);
            delegateAt[i] = api3Pool.userDelegateAt(userAddress, snapshotBlock);
            if (delegateAt[i] == address(0))
            {
                voterState[i] = api3Voting.getVoterState(voteIds[i], userAddress);
            }
            else
            {
                delegateState[i] = api3Voting.getVoterState(voteIds[i], delegateAt[i]);
            }
        }
    }

    /// @notice Used by the DAO dashboard client to retrieve the IDs of the
    /// votes that are currently open
    /// @param votingAppType Enumerated voting app type (primary or secondary)
    /// @return voteIds Array of vote IDs for which data will be retrieved
    function getOpenVoteIds(VotingAppType votingAppType)
        external
        view
        returns (uint256[] memory voteIds)
    {
        IApi3Voting api3Voting;
        if (votingAppType == VotingAppType.Primary)
        {
            api3Voting = IApi3Voting(api3Pool.votingAppPrimary());
        }
        else
        {
            api3Voting = IApi3Voting(api3Pool.votingAppSecondary());
        }
        uint256 votesLength = api3Voting.votesLength();
        if (votesLength == 0)
        {
            return new uint256[](0);
        }
        uint256 countOpenVote = 0;
        for (uint256 i = votesLength; i > 0; i--)
        {
            (
                bool open,
                , // executed
                uint64 startDate,
                , //snapshotBlock
                , // supportRequired
                , // minAcceptQuorum
                , // yea
                , // nay
                , // votingPower
                // script
                ) = api3Voting.getVote(i - 1);
            if (open)
            {
                countOpenVote++;
            }
            if (startDate < block.timestamp - api3Voting.voteTime())
            {
                break;
            }
        }
        if (countOpenVote == 0)
        {
            return new uint256[](0);
        }
        voteIds = new uint256[](countOpenVote);
        uint256 countAddedVote = 0;
        for (uint256 i = votesLength; i > 0; i--)
        {
            if (countOpenVote == countAddedVote)
            {
                break;
            }
            (
                bool open,
                , // executed
                , // startDate
                , // snapshotBlock
                , // supportRequired
                , // minAcceptQuorum
                , // yea
                , // nay
                , // votingPower
                // script
                ) = api3Voting.getVote(i - 1);
            if (open)
            {
                voteIds[countAddedVote] = i - 1;
                countAddedVote++;
            }
        }
    }
}