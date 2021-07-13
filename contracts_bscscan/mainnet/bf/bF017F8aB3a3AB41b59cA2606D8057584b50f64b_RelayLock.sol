//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IBalanceKeeperV2.sol";

/// @title Airdrop
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract Airdrop {

    IBalanceKeeperV2 public balanceKeeper;

    constructor(IBalanceKeeperV2 _balanceKeeper) {
        balanceKeeper = _balanceKeeper;
    }

    function airdrop(address[] memory users, uint256 amount) external {
        for (uint256 i = 0; i < users.length; i++) {
            balanceKeeper.add("EVM", abi.encodePacked(users[i]), amount);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IShares.sol";

/// @title The interface for Graviton balance keeper
/// @notice BalanceKeeper tracks governance balance of users
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IBalanceKeeperV2 is IShares {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if `user` is allowed to open new governance balances
    function canOpen(address user) external view returns (bool);

    /// @notice Look up if `user` is allowed to add to governance balances
    function canAdd(address user) external view returns (bool);

    /// @notice Look up if `user` is allowed to subtract from governance balances
    function canSubtract(address user) external view returns (bool);

    /// @notice Sets `opener` permission to open new governance balances to `_canOpen`
    /// @dev Can only be called by the current owner.
    function setCanOpen(address opener, bool _canOpen) external;

    /// @notice Sets `adder` permission to open new governance balances to `_canAdd`
    /// @dev Can only be called by the current owner.
    function setCanAdd(address adder, bool _canAdd) external;

    /// @notice Sets `subtractor` permission to open new governance balances to `_canSubtract`
    /// @dev Can only be called by the current owner.
    function setCanSubtract(address subtractor, bool _canSubtract) external;

    /// @notice The number of open governance balances
    function totalUsers() external view override returns (uint256);

    /// @notice The sum of all governance balances
    function totalBalance() external view returns (uint256);

    /// @notice Look up if the `userId` has an associated governance balance
    /// @param userId unique id of the user
    function isKnownUser(uint256 userId) external view returns (bool);

    /// @notice Look up if the blockchain-address pair has an associated governance balance
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function isKnownUser(string calldata userChain, bytes calldata userAddress)
        external
        view
        returns (bool);

    /// @notice Look up the type of blockchain associated with `userId`
    /// @param userId unique id of the user
    function userChainById(uint256 userId)
        external
        view
        returns (string memory);

    /// @notice Look up the blockchain-specific address associated with `userId`
    /// @param userId unique id of the user
    function userAddressById(uint256 userId)
        external
        view
        returns (bytes calldata);

    /// @notice Look up the blockchain-address pair associated with `userId`
    /// @param userId unique id of the user
    function userChainAddressById(uint256 userId)
        external
        view
        returns (string calldata, bytes calldata);

    /// @notice Look up the unique id associated with the blockchain-address pair
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function userIdByChainAddress(
        string calldata userChain,
        bytes calldata userAddress
    ) external view returns (uint256);

    /// @notice The amount of governance tokens owned by the user
    /// @param userId unique id of the user
    function balance(uint256 userId) external view returns (uint256);

    /// @notice The amount of governance tokens owned by the user
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function balance(string calldata userChain, bytes calldata userAddress)
        external
        view
        returns (uint256);

    /// @notice Opens a new user governance balance associated with the blockchain-address pair
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function open(string calldata userChain, bytes calldata userAddress)
        external;

    /// @notice Adds `amount` of governance tokens to the user balance
    /// @param userId unique id of the user
    /// @param amount the number of governance tokens
    function add(uint256 userId, uint256 amount) external;

    /// @notice Adds `amount` of governance tokens to the user balance
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    /// @param amount the number of governance tokens
    function add(
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Subtracts `amount` of governance tokens from the user balance
    /// @param userId unique id of the user
    /// @param amount the number of governance tokens
    function subtract(uint256 userId, uint256 amount) external;

    /// @notice Subtracts `amount` of governance tokens from the user balance
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address
    /// @param amount the number of governance tokens
    function subtract(
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `opener` permission is updated via `#setCanOpen`
    /// @param owner The owner account at the time of change
    /// @param opener The account whose permission to open governance balances was updated
    /// @param newBool Updated permission
    event SetCanOpen(
        address indexed owner,
        address indexed opener,
        bool indexed newBool
    );

    /// @notice Event emitted when the `adder` permission is updated via `#setCanAdd`
    /// @param owner The owner account at the time of change
    /// @param adder The account whose permission to add to governance balances was updated
    /// @param newBool Updated permission
    event SetCanAdd(
        address indexed owner,
        address indexed adder,
        bool indexed newBool
    );

    /// @notice Event emitted when the `subtractor` permission is updated via `#setCanSubtract`
    /// @param owner The owner account at the time of change
    /// @param subtractor The account whose permission
    /// to subtract from governance balances was updated
    /// @param newBool Updated permission
    event SetCanSubtract(
        address indexed owner,
        address indexed subtractor,
        bool indexed newBool
    );

    /// @notice Event emitted when a new `userId` is opened
    /// @param opener The account that opens `userId`
    /// @param userId The user account that was opened
    event Open(address indexed opener, uint256 indexed userId);

    /// @notice Event emitted when the `amount` of governance tokens
    /// is added to `userId` balance via `#add`
    /// @param adder The account that added to the balance
    /// @param userId The account whose governance balance was updated
    /// @param amount The amount of governance tokens
    event Add(address indexed adder, uint256 indexed userId, uint256 amount);

    /// @notice Event emitted when the `amount` of governance tokens
    /// is subtracted from `userId` balance via `#subtract`
    /// @param subtractor The account that subtracted from the balance
    /// @param userId The account whose governance balance was updated
    /// @param amount The amount of governance token
    event Subtract(
        address indexed subtractor,
        uint256 indexed userId,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton Shares
/// @notice Tracks the shares of users in a farming campaign
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IShares {
    /// @notice User's share in the farming campaign
    function shareById(uint256 userId) external view returns (uint256);

    /// @notice The total number of shares in the farming campaign
    function totalShares() external view returns (uint256);

    /// @notice The total number of users in the farming campaign
    function totalUsers() external view returns (uint256);

    /// @notice Unique identifier of nth user
    function userIdByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../ClaimGTONV2.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalanceKeeperV2.sol";
import "../interfaces/IVoterV2.sol";

// used for testing time dependent behavior
contract MockTimeClaimGTONV2 is ClaimGTONV2 {
    constructor(
        IERC20 _governanceToken,
        address _wallet,
        IBalanceKeeperV2 _balanceKeeper,
        IVoterV2 _voter
    ) ClaimGTONV2(_governanceToken, _wallet, _balanceKeeper, _voter) {}

    // Monday, October 5, 2020 9:00:00 AM GMT-05:00
    uint256 public time = 1601906400;

    function advanceTime(uint256 by) external {
        time += by;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IClaimGTONV2.sol";

/// @title ClaimGTONV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract ClaimGTONV2 is IClaimGTONV2 {
    /// @inheritdoc IClaimGTONV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IClaimGTONV2
    IERC20 public override governanceToken;
    /// @inheritdoc IClaimGTONV2
    IBalanceKeeperV2 public override balanceKeeper;
    /// @inheritdoc IClaimGTONV2
    IVoterV2 public override voter;
    /// @inheritdoc IClaimGTONV2
    address public override wallet;

    /// @inheritdoc IClaimGTONV2
    bool public override claimActivated;
    /// @inheritdoc IClaimGTONV2
    bool public override limitActivated;

    /// @inheritdoc IClaimGTONV2
    mapping(address => uint256) public override lastLimitTimestamp;
    /// @inheritdoc IClaimGTONV2
    mapping(address => uint256) public override limitMax;

    constructor(
        IERC20 _governanceToken,
        address _wallet,
        IBalanceKeeperV2 _balanceKeeper,
        IVoterV2 _voter
    ) {
        owner = msg.sender;
        governanceToken = _governanceToken;
        wallet = _wallet;
        balanceKeeper = _balanceKeeper;
        voter = _voter;
    }

    /// @inheritdoc IClaimGTONV2
    function setOwner(address _owner) public override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IClaimGTONV2
    function setWallet(address _wallet) public override isOwner {
        address walletOld = wallet;
        wallet = _wallet;
        emit SetWallet(walletOld, _wallet);
    }

    /// @inheritdoc IClaimGTONV2
    function setVoter(IVoterV2 _voter) public override isOwner {
        IVoterV2 voterOld = voter;
        voter = _voter;
        emit SetVoter(voterOld, _voter);
    }

    /// @inheritdoc IClaimGTONV2
    function setClaimActivated(bool _claimActivated) public override isOwner {
        claimActivated = _claimActivated;
    }

    /// @inheritdoc IClaimGTONV2
    function setLimitActivated(bool _limitActivated) public override isOwner {
        limitActivated = _limitActivated;
    }

    /// @dev Returns the block timestamp. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IClaimGTONV2
    function claim(uint256 amount) public override {
        require(claimActivated, "C1");
        uint256 balance = balanceKeeper.balance(
            "EVM",
            abi.encodePacked(msg.sender)
        );
        require(balance >= amount, "C2");
        if (limitActivated) {
            if ((_blockTimestamp() - lastLimitTimestamp[msg.sender]) > 86400) {
                lastLimitTimestamp[msg.sender] = _blockTimestamp();
                limitMax[msg.sender] = balance / 2;
            }
            require(amount <= limitMax[msg.sender], "C3");
            limitMax[msg.sender] -= amount;
        }
        balanceKeeper.subtract("EVM", abi.encodePacked(msg.sender), amount);
        voter.checkVoteBalances(
            balanceKeeper.userIdByChainAddress(
                "EVM",
                abi.encodePacked(msg.sender)
            )
        );
        governanceToken.transferFrom(wallet, msg.sender, amount);
        emit Claim(msg.sender, msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBalanceKeeperV2.sol";

/// @title The interface for Graviton voting contract
/// @notice Tracks voting rounds according to governance balances of users
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IVoterV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice Look up if the account can cast votes on behalf of other users
    function canCastVotes(address user) external view returns (bool);

    /// @notice Look up if the account can check voting balances when governance balances diminish
    function canCheck(address user) external view returns (bool);

    /// @notice Sets the permission to cast votes on behalf of other users
    /// @dev Can only be called by the current owner.
    function setCanCastVotes(address caster, bool _canCastVotes) external;

    /// @notice Sets the permission to check voting balances when governance balances diminish
    /// @dev Can only be called by the current owner.
    function setCanCheck(address checker, bool _canCheck) external;

    /// @notice The total number of voting rounds
    function totalRounds() external view returns (uint256);

    /// @notice Look up the unique id of one of the active voting rounds
    function activeRounds(uint256 index)
        external
        view
        returns (uint256 roundId);

    /// @notice Look up the unique id of one of the finalized voting rounds
    function finalizedRounds(uint256 index)
        external
        view
        returns (uint256 roundId);

    /// @notice Look up the name of a voting round
    function roundName(uint256 roundId) external view returns (string memory);

    /// @notice Look up the name of an option in a voting round
    function optionName(uint256 roundId, uint256 optionId)
        external
        view
        returns (string memory);

    /// @notice Look up the total amount of votes for an option in a voting round
    function votesForOption(uint256 roundId, uint256 optionId)
        external
        view
        returns (uint256);

    /// @notice Look up the amount of votes user sent in a voting round
    function votesInRoundByUser(uint256 roundId, uint256 userId)
        external
        view
        returns (uint256);

    /// @notice Look up the amount of votes user sent for an option in a voting round
    function votesForOptionByUser(
        uint256 roundId,
        uint256 optionId,
        uint256 userId
    ) external view returns (uint256);

    /// @notice Look up if user voted in a voting round
    function userVotedInRound(uint256 roundId, uint256 userId)
        external
        view
        returns (bool);

    /// @notice Look up if user voted or an option in a voting round
    function userVotedForOption(
        uint256 roundId,
        uint256 optionId,
        uint256 userId
    ) external view returns (bool);

    /// @notice The total number of users that voted in a voting round
    function totalUsersInRound(uint256 roundId) external view returns (uint256);

    /// @notice The total number of users that voted for an option in a voting round
    function totalUsersForOption(uint256 roundId, uint256 optionId)
        external
        view
        returns (uint256);

    /// @notice The total number of votes in a voting round
    function votesInRound(uint256 roundId) external view returns (uint256);

    /// @notice The number of active voting rounds
    function totalActiveRounds() external view returns (uint256);

    /// @notice The number of finalized voting rounds
    function totalFinalizedRounds() external view returns (uint256);

    /// @notice The number of options in a voting round
    function totalRoundOptions(uint256 roundId) external returns (uint256);

    /// @notice Look up if a voting round is active
    function isActiveRound(uint256 roundId) external view returns (bool);

    /// @notice Look up if a voting round is finalized
    function isFinalizedRound(uint256 roundId) external view returns (bool);

    /// @notice Starts a voting round
    /// @param _roundName voting round name, i.e. "Proposal"
    /// @param optionNames an array of option names, i.e. ["Approve", "Reject"]
    function startRound(string memory _roundName, string[] memory optionNames)
        external;

    /// @notice Finalized a voting round
    function finalizeRound(uint256 roundId) external;

    /// @notice Records votes according to userId governance balance
    /// @param roundId unique id of the voting round
    /// @param votes an array of votes for each option in a voting round, i.e. [7,12]
    /// @dev Can only be called by the account allowed to cast votes on behalf of others
    function castVotes(
        uint256 userId,
        uint256 roundId,
        uint256[] memory votes
    ) external;

    /// @notice Records votes according to sender's governance balance
    /// @param roundId unique id of the voting round
    /// @param votes an array of votes for each option in a voting round, i.e. [7,12]
    function castVotes(uint256 roundId, uint256[] memory votes) external;

    /// @notice Decreases votes of `user` when their balance is depleted, preserving proportions
    function checkVoteBalances(uint256 userId) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `caster` permission is updated via `#setCanCastVotes`
    /// @param owner The owner account at the time of change
    /// @param caster The account whose permission to cast votes was updated
    /// @param newBool Updated permission
    event SetCanCastVotes(
        address indexed owner,
        address indexed caster,
        bool indexed newBool
    );

    /// @notice Event emitted when the `checker` permission is updated via `#setCanCheck`
    /// @param owner The owner account at the time of change
    /// @param checker The account whose permission to check voting balances was updated
    /// @param newBool Updated permission
    event SetCanCheck(
        address indexed owner,
        address indexed checker,
        bool indexed newBool
    );

    /// @notice Event emitted when a voting round is started via `#startRound`
    /// @param owner The owner account at the time of change
    /// @param totalRounds The total number of voting rounds after the voting round is started
    /// @param roundName The voting round name, i.e. "Proposal"
    /// @param optionNames The array of option names, i.e. ["Approve", "Reject"]
    event StartRound(
        address indexed owner,
        uint256 totalRounds,
        string roundName,
        string[] optionNames
    );

    /// @notice Event emitted when a voting round is finalized via `#finalizeRound`
    /// @param owner The owner account at the time of change
    /// @param roundId Unique id of the voting round
    event FinalizeRound(address indexed owner, uint256 indexed roundId);

    /// @notice Event emitted when a user sends votes via `#castVotes`
    /// @param caster The account that cast votes
    /// @param roundId Unique id of the voting round
    /// @param userId The account that cast votes
    /// @param votes Array of votes for each option in the round
    event CastVotes(
        address indexed caster,
        uint256 indexed roundId,
        uint256 indexed userId,
        uint256[] votes
    );

    /// @notice Event emitted when a `checker` decreases a voting balance preserving proportions via `#checkVoteBalances`
    /// @param checker The account that checked the voting balance
    /// @param userId The account whose voting balance was checked
    /// @param newBalance The voting balance after checking
    event CheckVoteBalance(
        address indexed checker,
        uint256 indexed userId,
        uint256 newBalance
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IBalanceKeeperV2.sol";
import "./IVoterV2.sol";

/// @title The interface for Graviton claim
/// @notice Settles claims of tokens according to the governance balance of users
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IClaimGTONV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Address of the governance token
    function governanceToken() external view returns (IERC20);

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice Address of the voting contract
    function voter() external view returns (IVoterV2);

    /// @notice Address of the wallet from which to withdraw governance tokens
    function wallet() external view returns (address);

    /// @notice Look up if claiming is allowed
    function claimActivated() external view returns (bool);

    /// @notice Look up if the limit on claiming has been activated
    function limitActivated() external view returns (bool);

    /// @notice Look up the beginning the limit term for the `user`
    /// @dev Equal to 0 before the user's first claim
    function lastLimitTimestamp(address user) external view returns (uint256);

    /// @notice The maximum amount of tokens the `user` can claim until the limit term is over
    /// @dev Equal to 0 before the user's first claim
    /// @dev Updates to 50% of user's balance at the start of the new limit term
    function limitMax(address user) external view returns (uint256);

    /// @notice Sets the address of the voting contract
    function setVoter(IVoterV2 _voter) external;

    /// @notice The maximum amount of tokens available for claiming until the limit term is over
    function setWallet(address _wallet) external;

    /// @notice Sets the permission to claim to `_claimActivated`
    function setClaimActivated(bool _claimActivated) external;

    /// @notice Sets the limit to `_limitActivated`
    function setLimitActivated(bool _limitActivated) external;

    /// @notice Transfers `amount` of governance tokens to the caller
    function claim(uint256 amount) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the voter changes via `#setVoter`.
    /// @param voterOld The previous voting contract
    /// @param voterNew The new voting contract
    event SetVoter(IVoterV2 indexed voterOld, IVoterV2 indexed voterNew);

    /// @notice Event emitted when the wallet changes via `#setWallet`.
    /// @param walletOld The previous wallet
    /// @param walletNew The new wallet
    event SetWallet(address indexed walletOld, address indexed walletNew);

    /// @notice Event emitted when the `sender` claims `amount` of governance tokens
    /// @param sender The account from whose governance balance tokens were claimed
    /// @param receiver The account to which governance tokens were transferred
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of governance tokens claimed
    event Claim(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IVoterV2.sol";

/// @title VoterV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract VoterV2 is IVoterV2 {
    /// @inheritdoc IVoterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IVoterV2
    IBalanceKeeperV2 public override balanceKeeper;

    /// @inheritdoc IVoterV2
    mapping(address => bool) public override canCastVotes;
    /// @inheritdoc IVoterV2
    mapping(address => bool) public override canCheck;

    struct Option {
        string name;
        mapping(uint256 => uint256) votes;
    }

    struct Round {
        string name;
        uint256 totalOptions;
        mapping(uint256 => Option) options;
    }

    mapping(uint256 => Round) internal rounds;
    mapping(uint256 => bool) userVoted;
    uint256[] users;

    /// @inheritdoc IVoterV2
    uint256 public override totalRounds;
    /// @inheritdoc IVoterV2
    uint256[] public override activeRounds;
    /// @inheritdoc IVoterV2
    uint256[] public override finalizedRounds;

    constructor(IBalanceKeeperV2 _balanceKeeper) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
    }

    /// @inheritdoc IVoterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IVoterV2
    function setCanCastVotes(address caster, bool _canCastVotes)
        external
        override
        isOwner
    {
        canCastVotes[caster] = _canCastVotes;
        emit SetCanCastVotes(msg.sender, caster, canCastVotes[caster]);
    }

    /// @inheritdoc IVoterV2
    function setCanCheck(address checker, bool _canCheck)
        external
        override
        isOwner
    {
        canCheck[checker] = _canCheck;
        emit SetCanCheck(msg.sender, checker, canCheck[checker]);
    }

    /// @dev getter functions with parameter names
    /// @inheritdoc IVoterV2
    function roundName(uint256 roundId)
        external
        view
        override
        returns (string memory)
    {
        require(roundId < totalRounds, "V1");
        return rounds[roundId].name;
    }

    /// @inheritdoc IVoterV2
    function optionName(uint256 roundId, uint256 optionId)
        external
        view
        override
        returns (string memory)
    {
        require(roundId < totalRounds, "V1");
        require(optionId < rounds[roundId].totalOptions, "V2");
        return rounds[roundId].options[optionId].name;
    }

    /// @inheritdoc IVoterV2
    function totalRoundOptions(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        return rounds[roundId].totalOptions;
    }

    /// @inheritdoc IVoterV2
    function votesForOptionByUser(
        uint256 roundId,
        uint256 optionId,
        uint256 userId
    ) public view override returns (uint256) {
        return rounds[roundId].options[optionId].votes[userId];
    }

    /// @inheritdoc IVoterV2
    function votesInRoundByUser(uint256 roundId, uint256 userId)
        public
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < rounds[roundId].totalOptions; i++) {
            sum += votesForOptionByUser(roundId, i, userId);
        }
        return sum;
    }

    /// @inheritdoc IVoterV2
    function userVotedInRound(uint256 roundId, uint256 userId)
        public
        view
        override
        returns (bool)
    {
        return votesInRoundByUser(roundId, userId) > 0;
    }

    /// @inheritdoc IVoterV2
    function userVotedForOption(
        uint256 roundId,
        uint256 optionId,
        uint256 userId
    ) public view override returns (bool) {
        return votesForOptionByUser(roundId, optionId, userId) > 0;
    }

    /// @inheritdoc IVoterV2
    function totalUsersInRound(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i; i < users.length; i++) {
            if (userVotedInRound(roundId, i)) {
                sum++;
            }
        }
        return sum;
    }

    /// @inheritdoc IVoterV2
    function totalUsersForOption(uint256 roundId, uint256 optionId)
        external
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i; i < users.length; i++) {
            if (userVotedForOption(roundId, optionId, i)) {
                sum++;
            }
        }
        return sum;
    }

    /// @inheritdoc IVoterV2
    function votesForOption(uint256 roundId, uint256 optionId)
        public
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < users.length; i++) {
            sum += votesForOptionByUser(roundId, optionId, users[i]);
        }
        return sum;
    }

    /// @inheritdoc IVoterV2
    function votesInRound(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i; i < rounds[roundId].totalOptions; i++) {
            sum += votesForOption(roundId, i);
        }
        return sum;
    }

    /// @inheritdoc IVoterV2
    function totalActiveRounds() external view override returns (uint256) {
        return activeRounds.length;
    }

    /// @inheritdoc IVoterV2
    function totalFinalizedRounds() external view override returns (uint256) {
        return finalizedRounds.length;
    }

    /// @inheritdoc IVoterV2
    function isActiveRound(uint256 roundId)
        public
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < activeRounds.length; i++) {
            if (activeRounds[i] == roundId) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IVoterV2
    function isFinalizedRound(uint256 roundId)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < finalizedRounds.length; i++) {
            if (finalizedRounds[i] == roundId) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IVoterV2
    function startRound(string memory _roundName, string[] memory optionNames)
        external
        override
        isOwner
    {
        rounds[totalRounds].name = _roundName;
        for (uint256 i = 0; i < optionNames.length; i++) {
            rounds[totalRounds].options[i].name = optionNames[i];
            rounds[totalRounds].totalOptions++;
        }
        activeRounds.push(totalRounds);
        totalRounds++;
        emit StartRound(msg.sender, totalRounds, _roundName, optionNames);
    }

    // @dev move roundId from activeRounds to finalizedRounds
    /// @inheritdoc IVoterV2
    function finalizeRound(uint256 roundId) external override isOwner {
        uint256[] memory filteredRounds = new uint256[](
            activeRounds.length - 1
        );
        uint256 j = 0;
        for (uint256 i = 0; i < activeRounds.length; i++) {
            if (activeRounds[i] == roundId) {
                continue;
            }
            filteredRounds[j] = activeRounds[i];
            j++;
        }
        activeRounds = filteredRounds;
        finalizedRounds.push(roundId);
        emit FinalizeRound(msg.sender, roundId);
    }

    /// @inheritdoc IVoterV2
    function castVotes(
        uint256 userId,
        uint256 roundId,
        uint256[] memory votes
    ) external override {
        require(canCastVotes[msg.sender], "ACV");
        _castVotes(userId, roundId, votes);
    }

    /// @inheritdoc IVoterV2
    function castVotes(uint256 roundId, uint256[] memory votes)
        external
        override
    {
        uint256 userId = balanceKeeper.userIdByChainAddress(
            "EVM",
            abi.encodePacked(msg.sender)
        );
        _castVotes(userId, roundId, votes);
    }

    function _castVotes(
        uint256 userId,
        uint256 roundId,
        uint256[] memory votes
    ) internal {
        // @dev fail if roundId is not an active vote
        require(isActiveRound(roundId), "V3");

        // @dev fail if votes doesn't match number of options in roundId
        require(votes.length == rounds[roundId].totalOptions, "V4");

        uint256 sum;
        for (uint256 optionId = 0; optionId < votes.length; optionId++) {
            sum += votes[optionId];
        }

        // @dev fail if balance of sender is smaller than the sum of votes
        require(balanceKeeper.balance(userId) >= sum, "V5");

        // @dev overwrite userId votes
        for (uint256 i = 0; i < votes.length; i++) {
            rounds[roundId].options[i].votes[userId] = votes[i];
        }
        if (!userVoted[userId] && sum > 0) {
            users.push(userId);
            userVoted[userId] = true;
        }

        emit CastVotes(msg.sender, roundId, userId, votes);
    }

    function checkVoteBalance(uint256 roundId, uint256 userId) internal {
        uint256 newBalance = balanceKeeper.balance(userId);
        // @dev return if newBalance is still larger than the number of votes
        // @dev return if user didn't vote
        if (
            newBalance > votesInRoundByUser(roundId, userId) ||
            !userVotedInRound(roundId, userId)
        ) {
            return;
        }
        uint256 oldSum = votesInRoundByUser(roundId, userId);
        for (uint256 i = 0; i < rounds[roundId].totalOptions; i++) {
            uint256 oldVoteBalance = rounds[roundId].options[i].votes[userId];
            uint256 newVoteBalance = (oldVoteBalance * newBalance) / oldSum;
            rounds[roundId].options[i].votes[userId] = newVoteBalance;
        }
        emit CheckVoteBalance(msg.sender, userId, newBalance);
    }

    /// @inheritdoc IVoterV2
    function checkVoteBalances(uint256 userId) external override {
        require(canCheck[msg.sender], "ACC");
        for (uint256 i = 0; i < activeRounds.length; i++) {
            checkVoteBalance(activeRounds[i], userId);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/IVoter.sol";

/// @title ClaimGTON
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract ClaimGTON {
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    IERC20 public governanceToken;
    IBalanceKeeper public balanceKeeper;
    IVoter public voter;
    address public wallet;

    bool public claimActivated;
    bool public limitActivated;

    event Claim(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
    event SetOwner(address ownerOld, address ownerNew);

    constructor(
        IERC20 _governanceToken,
        address _wallet,
        IBalanceKeeper _balanceKeeper,
        IVoter _voter
    ) {
        owner = msg.sender;
        governanceToken = _governanceToken;
        wallet = _wallet;
        balanceKeeper = _balanceKeeper;
        voter = _voter;
    }

    function setOwner(address _owner) public isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    function setWallet(address _wallet) public isOwner {
        wallet = _wallet;
    }

    function setVoter(IVoter _voter) public isOwner {
        voter = _voter;
    }

    function setGovernanceToken(IERC20 _governanceToken) public isOwner {
        governanceToken = _governanceToken;
    }

    function setBalanceKeeper(IBalanceKeeper _balanceKeeper) public isOwner {
        balanceKeeper = _balanceKeeper;
    }

    function setClaimActivated(bool _claimActivated) public isOwner {
        claimActivated = _claimActivated;
    }

    function setLimitActivated(bool _limitActivated) public isOwner {
        limitActivated = _limitActivated;
    }

    /// @dev Returns the block timestamp. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    mapping(address => uint256) public lastLimitTimestamp;
    mapping(address => uint256) public limitMax;

    function claim(uint256 amount, address to) public {
        require(claimActivated, "can't claim");
        uint256 balance = balanceKeeper.userBalance(msg.sender);
        require(balance >= amount, "not enough money");
        if (limitActivated) {
            if ((_blockTimestamp() - lastLimitTimestamp[msg.sender]) > 86400) {
                lastLimitTimestamp[msg.sender] = _blockTimestamp();
                limitMax[msg.sender] = balance / 2;
            }
            require(amount <= limitMax[msg.sender], "exceeded daily limit");
            limitMax[msg.sender] -= amount;
        }
        balanceKeeper.subtract(msg.sender, amount);
        voter.checkVoteBalances(msg.sender);
        governanceToken.transferFrom(wallet, to, amount);
        emit Claim(msg.sender, to, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBalanceKeeper {
    function add(address user, uint256 value) external;

    function subtract(address user, uint256 value) external;

    function userBalance(address user) external returns (uint256);

    function users(uint256 id) external returns (address);

    function totalBalance() external returns (uint256);

    function totalUsers() external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton voting contract
/// @notice Tracks voting rounds according to governance balances of users
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IVoter {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (address);

    /// @notice Look up if `user` can check voting balances when governance balances diminish
    function canCheck(address user) external view returns (bool);

    /// @notice Sets the permission to check voting balances when governance balances diminish
    /// @dev Can only be called by the current owner.
    function setCanCheck(address checker, bool _canCheck) external;

    /// @notice The total number of voting rounds
    function totalRounds() external view returns (uint256);

    /// @notice Look up the unique id of one of the active voting rounds
    function activeRounds(uint256 index)
        external
        view
        returns (uint256 roundId);

    /// @notice Look up the unique id of one of the finalized voting rounds
    function finalizedRounds(uint256 index)
        external
        view
        returns (uint256 roundId);

    /// @notice Look up the name of a voting round
    function roundName(uint256 roundId) external view returns (string memory);

    /// @notice Look up the name of an option in a voting round
    function roundOptions(uint256 roundId, uint256 optionId)
        external
        view
        returns (string memory);

    /// @notice Look up the total amount of votes for an option in a voting round
    function votesForOption(uint256 roundId, uint256 optionId)
        external
        view
        returns (uint256);

    /// @notice Look up the amount of votes user sent in a voting round
    function votesInRoundByUser(uint256 roundId, address user)
        external
        view
        returns (uint256);

    /// @notice Look up the amount of votes user sent for an option in a voting round
    function votesForOptionByUser(
        uint256 roundId,
        address user,
        uint256 optionId
    ) external view returns (uint256);

    /// @notice Look up if user voted in a voting round
    function userVotedInRound(uint256 roundId, address user)
        external
        view
        returns (bool);

    /// @notice Look up if user voted or an option in a voting round
    function userVotedForOption(
        uint256 roundId,
        uint256 optionId,
        address user
    ) external view returns (bool);

    /// @notice The total number of users that voted in a voting round
    function totalUsersInRound(uint256 roundId) external view returns (uint256);

    /// @notice The total number of users that voted for an option in a voting round
    function totalUsersForOption(uint256 roundId, uint256 optionId)
        external
        view
        returns (uint256);

    /// @notice The total number of votes in a voting round
    function votesInRound(uint256 roundId) external view returns (uint256);

    /// @notice The number of active voting rounds
    function totalActiveRounds() external view returns (uint256);

    /// @notice The number of finalized voting rounds
    function totalFinalizedRounds() external view returns (uint256);

    /// @notice The number of options in a voting round
    function totalRoundOptions(uint256 roundId) external returns (uint256);

    /// @notice Look up if a voting round is active
    function isActiveRound(uint256 roundId) external view returns (bool);

    /// @notice Look up if a voting round is finalized
    function isFinalizedRound(uint256 roundId) external view returns (bool);

    /// @notice Starts a voting round
    /// @param name voting round name, i.e. "Proposal"
    /// @param options an array of option names, i.e. ["Approve", "Reject"]
    function startRound(string memory name, string[] memory options) external;

    /// @notice Finalized a voting round
    function finalizeRound(uint256 roundId) external;

    /// @notice Records votes according to sender's governance balance
    /// @param roundId unique id of the voting round
    /// @param votes an array of votes for each option in a voting round, i.e. [7,12]
    function castVotes(uint256 roundId, uint256[] memory votes) external;

    /// @notice Decreases votes of `user` when their balance is depleted, preserving proportions
    function checkVoteBalances(address user) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/IVoter.sol";

/// @title Voter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract Voter is IVoter {
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    address public override balanceKeeper;

    uint256 public override totalRounds;
    uint256[] public override activeRounds;
    uint256[] public override finalizedRounds;
    mapping(uint256 => string) internal _roundName;
    mapping(uint256 => string[]) internal _roundOptions;

    mapping(uint256 => uint256[]) internal _votesForOption;

    mapping(uint256 => mapping(address => uint256))
        internal _votesInRoundByUser;
    mapping(uint256 => mapping(address => uint256[]))
        internal _votesForOptionByUser;

    mapping(uint256 => mapping(address => bool)) internal _userVotedInRound;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        internal _userVotedForOption;

    mapping(uint256 => uint256) internal _totalUsersInRound;
    mapping(uint256 => mapping(uint256 => uint256))
        internal _totalUsersForOption;

    mapping(address => bool) public override canCheck;

    event CastVotes(address indexed voter, uint256 indexed roundId);
    event StartRound(
        address indexed owner,
        uint256 totalRounds,
        string name,
        string[] options
    );
    event SetCanCheck(
        address indexed owner,
        address indexed checker,
        bool indexed newBool
    );
    event CheckVoteBalances(
        address indexed checker,
        address indexed user,
        uint256 newBalance
    );
    event FinalizeRound(address indexed owner, uint256 roundId);
    event SetOwner(address ownerOld, address ownerNew);

    constructor(address _balanceKeeper) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
    }

    // getter functions with parameter names
    function roundName(uint256 roundId)
        public
        view
        override
        returns (string memory)
    {
        return _roundName[roundId];
    }

    function roundOptions(uint256 roundId, uint256 optionId)
        public
        view
        override
        returns (string memory)
    {
        return _roundOptions[roundId][optionId];
    }

    function votesForOption(uint256 roundId, uint256 optionId)
        public
        view
        override
        returns (uint256)
    {
        return _votesForOption[roundId][optionId];
    }

    function votesInRoundByUser(uint256 roundId, address user)
        public
        view
        override
        returns (uint256)
    {
        return _votesInRoundByUser[roundId][user];
    }

    function votesForOptionByUser(
        uint256 roundId,
        address user,
        uint256 optionId
    ) public view override returns (uint256) {
        return _votesForOptionByUser[roundId][user][optionId];
    }

    function userVotedInRound(uint256 roundId, address user)
        public
        view
        override
        returns (bool)
    {
        return _userVotedInRound[roundId][user];
    }

    function userVotedForOption(
        uint256 roundId,
        uint256 optionId,
        address user
    ) public view override returns (bool) {
        return _userVotedForOption[roundId][optionId][user];
    }

    function totalUsersInRound(uint256 roundId)
        public
        view
        override
        returns (uint256)
    {
        return _totalUsersInRound[roundId];
    }

    function totalUsersForOption(uint256 roundId, uint256 optionId)
        public
        view
        override
        returns (uint256)
    {
        return _totalUsersForOption[roundId][optionId];
    }

    // sum of all votes in a round
    function votesInRound(uint256 roundId)
        public
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (
            uint256 optionId = 0;
            optionId < _votesForOption[roundId].length;
            optionId++
        ) {
            sum += _votesForOption[roundId][optionId];
        }
        return sum;
    }

    // number of сurrently active rounds
    function totalActiveRounds() public view override returns (uint256) {
        return activeRounds.length;
    }

    // number of finalized finalized rounds
    function totalFinalizedRounds() public view override returns (uint256) {
        return finalizedRounds.length;
    }

    // number of options in a round
    function totalRoundOptions(uint256 roundId)
        public
        view
        override
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < _roundOptions[roundId].length; i++) {
            sum++;
        }
        return sum;
    }

    function setOwner(address _owner) public override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    function startRound(string memory name, string[] memory options)
        public
        override
        isOwner
    {
        _roundName[totalRounds] = name;
        _roundOptions[totalRounds] = options;
        _votesForOption[totalRounds] = new uint256[](options.length);
        activeRounds.push(totalRounds);
        totalRounds++;
        emit StartRound(msg.sender, totalRounds, name, options);
    }

    function isActiveRound(uint256 roundId)
        public
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < activeRounds.length; i++) {
            if (activeRounds[i] == roundId) {
                return true;
            }
        }
        return false;
    }

    function isFinalizedRound(uint256 roundId) public view override returns (bool) {
        for (uint256 i = 0; i < finalizedRounds.length; i++) {
            if (finalizedRounds[i] == roundId) {
                return true;
            }
        }
        return false;
    }

    function castVotes(uint256 roundId, uint256[] memory votes)
        public
        override
    {
        // fail if roundId is not an active vote
        require(isActiveRound(roundId), "roundId is not an active vote");

        // fail if votes doesn't match number of options in roundId
        require(
            votes.length == _roundOptions[roundId].length,
            "number of votes doesn't match number of options"
        );

        // fail if balance of sender is smaller than the sum of votes
        uint256 sum;
        for (uint256 optionId = 0; optionId < votes.length; optionId++) {
            sum += votes[optionId];
        }
        require(
            IBalanceKeeper(balanceKeeper).userBalance(msg.sender) >= sum,
            "balance is smaller than the sum of votes"
        );

        // if msg.sender already voted in roundId, erase their previous votes
        if (_votesInRoundByUser[roundId][msg.sender] != 0) {
            uint256[] memory oldVotes = _votesForOptionByUser[roundId][
                msg.sender
            ];
            for (uint256 optionId = 0; optionId < oldVotes.length; optionId++) {
                _votesForOption[roundId][optionId] -= oldVotes[optionId];
            }
        }

        // update sender's votes
        _votesForOptionByUser[roundId][msg.sender] = votes;

        for (uint256 optionId = 0; optionId < votes.length; optionId++) {
            if (
                !_userVotedForOption[roundId][optionId][msg.sender] &&
                votes[optionId] != 0
            ) {
                _userVotedForOption[roundId][optionId][msg.sender] = true;
                _totalUsersForOption[roundId][optionId]++;
            }

            if (
                _userVotedForOption[roundId][optionId][msg.sender] &&
                votes[optionId] == 0
            ) {
                _userVotedForOption[roundId][optionId][msg.sender] = false;
                _totalUsersForOption[roundId][optionId]--;
            }

            _votesForOption[roundId][optionId] += votes[optionId];
        }

        _votesInRoundByUser[roundId][msg.sender] = sum;

        if (!_userVotedInRound[roundId][msg.sender] && sum != 0) {
            _userVotedInRound[roundId][msg.sender] = true;
            _totalUsersInRound[roundId]++;
        }
        if (_userVotedInRound[roundId][msg.sender] && sum == 0) {
            _userVotedInRound[roundId][msg.sender] = false;
            _totalUsersInRound[roundId]--;
        }

        emit CastVotes(msg.sender, roundId);
    }

    // allow/forbid oracle to check votes
    function setCanCheck(address checker, bool _canCheck)
        public
        override
        isOwner
    {
        canCheck[checker] = _canCheck;
        emit SetCanCheck(msg.sender, checker, canCheck[checker]);
    }

    // decrease votes when the balance is depleted, preserve proportions
    function checkVoteBalance(
        uint256 roundId,
        address user,
        uint256 newBalance
    ) internal {
        // return if newBalance is still larger than the number of votes
        // return if user didn't vote
        if (
            newBalance > _votesInRoundByUser[roundId][user] ||
            _votesInRoundByUser[roundId][user] == 0
        ) {
            return;
        }
        uint256[] storage oldVotes = _votesForOptionByUser[roundId][user];
        uint256 newSum;
        for (uint256 optionId = 0; optionId < oldVotes.length; optionId++) {
            uint256 oldVoteBalance = oldVotes[optionId];
            uint256 newVoteBalance = (oldVoteBalance * newBalance) /
                _votesInRoundByUser[roundId][user];
            _votesForOption[roundId][optionId] -= (oldVoteBalance -
                newVoteBalance);
            _votesForOptionByUser[roundId][user][optionId] = newVoteBalance;
            newSum += newVoteBalance;
        }
        _votesInRoundByUser[roundId][user] = newSum;
    }

    // decrease votes when the balance is depleted, preserve proportions
    function checkVoteBalances(address user) public override {
        require(
            canCheck[msg.sender],
            "sender is not allowed to check balances"
        );
        uint256 newBalance = IBalanceKeeper(balanceKeeper).userBalance(
            msg.sender
        );
        for (uint256 i = 0; i < activeRounds.length; i++) {
            checkVoteBalance(activeRounds[i], user, newBalance);
        }
        emit CheckVoteBalances(msg.sender, user, newBalance);
    }

    // move roundId from activeRounds to finalizedRounds
    function finalizeRound(uint256 roundId) public override isOwner {
        uint256[] memory filteredRounds = new uint256[](
            activeRounds.length - 1
        );
        uint256 j = 0;
        for (uint256 i = 0; i < activeRounds.length; i++) {
            if (activeRounds[i] == roundId) {
                continue;
            }
            filteredRounds[j] = activeRounds[i];
            j++;
        }
        activeRounds = filteredRounds;
        finalizedRounds.push(roundId);
        emit FinalizeRound(msg.sender, roundId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/ILPKeeper.sol";
import "../interfaces/IOracleRouter.sol";

/// @title OracleRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract OracleRouter is IOracleRouter {
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    IBalanceKeeper public balanceKeeper;
    ILPKeeper public lpKeeper;
    bytes32 public gtonAddTopic;
    bytes32 public gtonSubTopic;
    bytes32 public lpAddTopic;
    bytes32 public lpSubTopic;

    mapping(address => bool) public canRoute;

    event SetCanRoute(
        address indexed owner,
        address indexed parser,
        bool indexed newBool
    );
    event GTONAdd(
        bytes16 uuid,
        string chain,
        address emiter,
        address token,
        address sender,
        address receiver,
        uint256 amount
    );
    event GTONSub(
        bytes16 uuid,
        string chain,
        address emiter,
        address token,
        address sender,
        address receiver,
        uint256 amount
    );
    event LPAdd(
        bytes16 uuid,
        string chain,
        address emiter,
        address token,
        address sender,
        address receiver,
        uint256 amount
    );
    event LPSub(
        bytes16 uuid,
        string chain,
        address emiter,
        address token,
        address sender,
        address receiver,
        uint256 amount
    );
    event SetOwner(address ownerOld, address ownerNew);

    constructor(
        IBalanceKeeper _balanceKeeper,
        ILPKeeper _lpKeeper,
        bytes32 _gtonAddTopic,
        bytes32 _gtonSubTopic,
        bytes32 _lpAddTopic,
        bytes32 _lpSubTopic
    ) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
        lpKeeper = _lpKeeper;
        gtonAddTopic = _gtonAddTopic;
        gtonSubTopic = _gtonSubTopic;
        lpAddTopic = _lpAddTopic;
        lpSubTopic = _lpSubTopic;
    }

    function setGTONAddTopic(bytes32 newTopic) public isOwner {
        gtonAddTopic = newTopic;
    }

    function setGTONSubTopic(bytes32 newTopic) public isOwner {
        gtonSubTopic = newTopic;
    }

    function setLPAddTopic(bytes32 newTopic) public isOwner {
        lpAddTopic = newTopic;
    }

    function setLPSubTopic(bytes32 newTopic) public isOwner {
        lpSubTopic = newTopic;
    }

    // permit/forbid a parser to send data to router
    function setCanRoute(address parser, bool _canRoute) public isOwner {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function routeValue(
        bytes16 uuid,
        string calldata chain,
        address emiter,
        bytes32 topic0,
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "not allowed to route value");

        if (equal(topic0, gtonAddTopic)) {
            balanceKeeper.add(receiver, amount);
            emit GTONAdd(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, gtonSubTopic)) {
            balanceKeeper.subtract(sender, amount);
            emit GTONSub(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, lpAddTopic)) {
            lpKeeper.add(token, receiver, amount);
            emit LPAdd(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, lpSubTopic)) {
            lpKeeper.subtract(token, sender, amount);
            emit LPSub(uuid, chain, emiter, token, sender, receiver, amount);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILPKeeper {
    function add(
        address lptoken,
        address user,
        uint256 amount
    ) external;

    function subtract(
        address lptoken,
        address user,
        uint256 amount
    ) external;

    function userBalance(address lptoken, address user)
        external
        returns (uint256);

    function totalBalance(address lptoken) external returns (uint256);

    function totalUsers(address lptoken) external returns (uint256);

    function users(address lptoken, uint256 userId) external returns (address);

    function totalLPTokens() external returns (uint256);

    function lpTokens(uint256 tokenId) external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracleRouter {
    function routeValue(
        bytes16 uuid,
        string calldata chain,
        address emiter,
        bytes32 topic0,
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IOracleRouter.sol";

/// @title OracleParser
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract OracleParser {
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    address public nebula;

    modifier isNebula() {
        require(msg.sender == nebula, "Caller is not nebula");
        _;
    }

    IOracleRouter public oracleRouter;

    mapping(bytes16 => bool) public uuidIsProcessed;

    event AttachValue(
        address nebula,
        bytes16 uuid,
        string chain,
        address emiter,
        bytes32 topic0,
        address token,
        address sender,
        address receiver,
        uint256 amount
    );
    event SetOwner(address ownerOld, address ownerNew);
    event SetNebula(address nebulaOld, address nebulaNew);

    constructor(
        IOracleRouter _oracleRouter,
        address _nebula
    ) {
        owner = msg.sender;
        oracleRouter = _oracleRouter;
        nebula = _nebula;
    }

    function setOwner(address _owner) public isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    function setNebula(address _nebula) public isOwner {
        address nebulaOld = nebula;
        nebula = _nebula;
        emit SetNebula(nebulaOld, _nebula);
    }

    function setOracleRouter(IOracleRouter _oracleRouter) public isOwner {
        oracleRouter = _oracleRouter;
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) public pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        public
        pure
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        public
        pure
        returns (bytes32)
    {
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    function bytesToBytes16(bytes memory b, uint256 offset)
        public
        pure
        returns (bytes16)
    {
        bytes16 out;
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    function attachValue(bytes calldata impactData) external isNebula {
        if (impactData.length != 200) {
            return;
        } // ignore data with unexpected length

        bytes16 uuid = bytesToBytes16(impactData, 0); // [  0: 16]
        if (uuidIsProcessed[uuid]) {
            return;
        } // parse data only once
        uuidIsProcessed[uuid] = true;
        string memory chain = string(abi.encodePacked(impactData[16:19])); // [ 16: 19]
        address emiter = deserializeAddress(impactData, 19); // [ 19: 39]
        bytes1 topics = bytes1(impactData[39]); // [ 39: 40]
        if (
            keccak256(abi.encodePacked(topics)) != // ignore data with unexpected number of topics
            keccak256(
                abi.encodePacked(bytes1(abi.encodePacked(uint256(4))[31]))
            )
        ) {
            return;
        }
        bytes32 topic0 = bytesToBytes32(impactData, 40); // [ 40: 72]
        address token = deserializeAddress(impactData[72:], 12); // [ 72:104][12:32]
        address sender = deserializeAddress(impactData[104:], 12); // [104:136][12:32]
        address receiver = deserializeAddress(impactData[136:], 12); // [136:168][12:32]
        uint256 amount = deserializeUint(impactData, 168, 32); // [168:200]

        oracleRouter.routeValue(
            uuid,
            chain,
            emiter,
            topic0,
            token,
            sender,
            receiver,
            amount
        );

        emit AttachValue(
            msg.sender,
            uuid,
            chain,
            emiter,
            topic0,
            token,
            sender,
            receiver,
            amount
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ILPKeeper.sol";

/// @title LPKeeper
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LPKeeper is ILPKeeper {
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    address[] public override lpTokens;
    mapping(address => bool) public isKnownLPToken;
    mapping(address => uint256) public override totalBalance;

    mapping(address => address[]) public override users;
    mapping(address => mapping(address => bool)) public isKnownUser;

    mapping(address => mapping(address => uint256)) public override userBalance;

    // oracles for changing user lp balances
    mapping(address => bool) public canAdd;
    mapping(address => bool) public canSubtract;

    event SetCanAdd(
        address indexed owner,
        address indexed adder,
        bool indexed newBool
    );
    event SetCanSubtract(
        address indexed owner,
        address indexed subtractor,
        bool indexed newBool
    );
    event Add(
        address indexed adder,
        address indexed lptoken,
        address indexed user,
        uint256 amount
    );
    event Subtract(
        address indexed subtractor,
        address indexed lptoken,
        address indexed user,
        uint256 amount
    );
    event SetOwner(address ownerOld, address ownerNew);

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) public isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    function totalLPTokens() public view override returns (uint256) {
        return lpTokens.length;
    }

    function totalUsers(address lptoken)
        public
        view
        override
        returns (uint256)
    {
        return users[lptoken].length;
    }

    // permit/forbid an oracle to add user balances
    function setCanAdd(address adder, bool _canAdd) public isOwner {
        canAdd[adder] = _canAdd;
        emit SetCanAdd(msg.sender, adder, canAdd[adder]);
    }

    // permit/forbid an oracle to subtract user balances
    function setCanSubtract(address subtractor, bool _canSubtract)
        public
        isOwner
    {
        canSubtract[subtractor] = _canSubtract;
        emit SetCanSubtract(msg.sender, subtractor, canSubtract[subtractor]);
    }

    function add(
        address lptoken,
        address user,
        uint256 amount
    ) public override {
        require(canAdd[msg.sender], "not allowed to add");
        if (!isKnownLPToken[lptoken]) {
            lpTokens.push(lptoken);
            isKnownLPToken[lptoken] = true;
        }
        if (!isKnownUser[lptoken][user]) {
            users[lptoken].push(user);
            isKnownUser[lptoken][user] = true;
        }
        userBalance[lptoken][user] += amount;
        totalBalance[lptoken] += amount;
        emit Add(msg.sender, lptoken, user, amount);
    }

    function subtract(
        address lptoken,
        address user,
        uint256 amount
    ) public override {
        require(canSubtract[msg.sender], "not allowed to subtract");
        userBalance[lptoken][user] -= amount;
        totalBalance[lptoken] -= amount;
        emit Subtract(msg.sender, lptoken, user, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IBalanceKeeper.sol";

/// @title BalanceKeeper
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceKeeper is IBalanceKeeper {
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // oracles for changing user balances
    mapping(address => bool) public canAdd;
    mapping(address => bool) public canSubtract;

    address[] public override users;
    mapping(address => bool) public isKnownUser;
    mapping(address => uint256) public override userBalance;
    uint256 public override totalBalance;

    event Add(
        address indexed adder,
        address indexed user,
        uint256 indexed amount
    );
    event Subtract(
        address indexed subtractor,
        address indexed user,
        uint256 indexed amount
    );
    event SetCanAdd(
        address indexed owner,
        address indexed adder,
        bool indexed newBool
    );
    event SetCanSubtract(
        address indexed owner,
        address indexed subtractor,
        bool indexed newBool
    );
    event SetOwner(address ownerOld, address ownerNew);

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) public isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    function totalUsers() public view override returns (uint256) {
        return users.length;
    }

    // permit/forbid an oracle to add user balances
    function setCanAdd(address adder, bool _canAdd) public isOwner {
        canAdd[adder] = _canAdd;
        emit SetCanAdd(msg.sender, adder, canAdd[adder]);
    }

    // permit/forbid an oracle to subtract user balances
    function setCanSubtract(address subtractor, bool _canSubtract)
        public
        isOwner
    {
        canSubtract[subtractor] = _canSubtract;
        emit SetCanSubtract(msg.sender, subtractor, canSubtract[subtractor]);
    }

    // add user balance
    function add(address user, uint256 amount) public override {
        require(canAdd[msg.sender], "not allowed to add");
        if (!isKnownUser[user]) {
            isKnownUser[user] = true;
            users.push(user);
        }
        userBalance[user] += amount;
        totalBalance += amount;
        emit Add(msg.sender, user, amount);
    }

    // subtract user balance
    function subtract(address user, uint256 amount) public override {
        require(canSubtract[msg.sender], "not allowed to subtract");
        userBalance[user] -= amount;
        totalBalance -= amount;
        emit Subtract(msg.sender, user, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IFarm.sol";
import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/IBalanceAdder.sol";

/// @title BalanceAdderStaking
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceAdderStaking is IBalanceAdder {
    // early birds emission data
    IFarm public farm;
    IBalanceKeeper public balanceKeeper;

    uint256 public lastUser;
    uint256 public totalUsers;
    uint256 public lastPortion;
    uint256 public currentPortion;
    uint256 public totalBalance;
    uint256 public totalUnlocked;

    constructor(IFarm _farm, IBalanceKeeper _balanceKeeper) {
        farm = _farm;
        balanceKeeper = _balanceKeeper;
    }

    function increaseUserStakeValue(address user) internal {
        require(totalBalance > 0, "there is no balance available for staking");
        uint256 prevBalance = balanceKeeper.userBalance(user);
        uint256 add = (currentPortion * prevBalance) / totalBalance;
        balanceKeeper.add(user, add);
    }

    function processBalances(uint256 step) public override {
        if (lastUser == 0) {
            totalUsers = balanceKeeper.totalUsers();
            totalUnlocked = farm.totalUnlocked();
            currentPortion = totalUnlocked - lastPortion;
            totalBalance = balanceKeeper.totalBalance();
        }
        uint256 fromUser = lastUser;
        uint256 toUser = lastUser + step;

        if (toUser > totalUsers) {
            toUser = totalUsers;
        }

        for (uint256 i = fromUser; i < toUser; i++) {
            address user = balanceKeeper.users(i);
            increaseUserStakeValue(user);
        }

        if (toUser == totalUsers) {
            lastUser = 0;
            lastPortion = totalUnlocked;
        } else {
            lastUser = toUser;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton farm
/// @notice Calculates the number of governance tokens
/// available for distribution in a farming campaign
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IFarm {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice The amount of governance tokens available for the farming campaign
    function totalUnlocked() external view returns (uint256);

    /// @notice Look up if the farming campaign has been started
    function farmingStarted() external view returns (bool);

    /// @notice Look up if the farming campaign has been stopped
    function farmingStopped() external view returns (bool);

    /// @notice Look up when the farming has started
    function startTimestamp() external view returns (uint256);

    /// @notice Look up the last time when the farming was calculated
    function lastTimestamp() external view returns (uint256);

    /// @notice Starts the farming campaign
    function startFarming() external;

    /// @notice Stops the farming campaign
    function stopFarming() external;

    /// @notice Calculates the amount of governance tokens available for the farming campaign
    /// @dev Can only be called after the farming has started
    /// @dev Can only be called before the farming has stopped
    function unlockAsset() external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBalanceAdder {
    function processBalances(uint256 step) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IFarm.sol";
import "../interfaces/IImpactKeeper.sol";
import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/IBalanceAdder.sol";

/// @title BalanceAdderEB
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceAdderEB is IBalanceAdder {
    // early birds emission data
    IFarm public farm;
    IImpactKeeper public impactEB;

    IBalanceKeeper public balanceKeeper;

    uint256 public lastUser;
    uint256 public totalUsers;

    mapping(address => uint256) public lastPortion;

    constructor(
        IFarm _farm,
        IImpactKeeper _impactEB,
        IBalanceKeeper _balanceKeeper
    ) {
        farm = _farm;
        impactEB = _impactEB;
        balanceKeeper = _balanceKeeper;
        totalUsers = impactEB.userCount();
    }

    function addEB(address user) internal {
        uint256 currentPortion = (farm.totalUnlocked() *
            impactEB.impact(user)) / impactEB.totalSupply();
        uint256 add = currentPortion - lastPortion[user];
        lastPortion[user] = currentPortion;
        balanceKeeper.add(user, add);
    }

    function processBalances(uint256 step) public override {
        uint256 toUser = lastUser + step;
        uint256 fromUser = lastUser;

        if (toUser > totalUsers) {
            toUser = totalUsers;
        }

        for (uint256 i = fromUser; i < toUser; i++) {
            address user = impactEB.users(i);
            addEB(user);
        }

        if (toUser == totalUsers) {
            lastUser = 0;
        } else {
            lastUser = toUser;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton impact keeper
/// @notice Tracks the amount of stable coins deposited in the early birds campaign
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IImpactKeeper {
    /// @notice The amount of stable coins that `user` deposited in the early birds campaign
    function impact(address user) external returns (uint256);

    /// @notice The total amount of stable coins deposited in the early birds campaign
    function totalSupply() external returns (uint256);

    /// @notice Look up the address of the user
    /// @param id index of the user
    function users(uint256 id) external returns (address);

    /// @notice The number of users in the early birds campaign
    function userCount() external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IImpactKeeper.sol";

/// @title ImpactKeeper
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
abstract contract ImpactKeeper is IImpactKeeper {
    event Transfer(
        address token,
        address user,
        uint256 value,
        uint256 id,
        uint256 action
    );

    // priveleged addresses
    address public owner;
    address public nebula;

    // total locked usd amount
    uint256 public override totalSupply;
    // tokens that are allowed to be processed
    mapping(address => bool) public allowedTokens;

    // users impact and amounts
    mapping(address => uint256) public override impact;
    mapping(address => uint256) public pendingAmounts;
    // for token airdrop
    mapping(uint256 => address) public override users;
    uint256 public override userCount;
    // balance pools
    uint256 public currentBP;
    uint256 public lastBP;
    uint256 public lastEmissionProcessed;

    // for processing mass transfers
    uint256 public final_value;

    // for migration
    uint256 private last;
    bool private notDeprecated = true;

    bool public claimAllowance;

    // processed data array
    mapping(uint256 => bool) public dataId;

    constructor(
        address _owner,
        address _nebula,
        address[] memory _allowedTokens
    ) {
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            allowedTokens[_allowedTokens[i]] = true;
        }
        owner = _owner;
        nebula = _nebula;
        claimAllowance = false;
    }

    // farm transfer
    function setClaimingAllowance(bool _claimAllowance) public isOwner {
        claimAllowance = _claimAllowance;
    }

    // owner control functions
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function transferOwnership(address newOwnerAddress) public isOwner {
        owner = newOwnerAddress;
    }

    // nebula control functions
    modifier isNebula() {
        require(msg.sender == nebula, "Caller is not nebula");
        _;
    }

    function transferNebula(address newNebulaAddress) public isOwner {
        nebula = newNebulaAddress;
    }

    // nebula methods
    function addNewToken(address newTokenAddress) public isOwner {
        allowedTokens[newTokenAddress] = true;
    }

    function removeToken(address newTokenAddress) public isOwner {
        allowedTokens[newTokenAddress] = false;
    }

    function getPendingAmount(address usr) public view returns (uint256) {
        return pendingAmounts[usr];
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) external pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        external
        view
        returns (address)
    {
        return address(uint160(this.deserializeUint(b, startPos, 20)));
    }

    // called from gravity to add impact to users
    function attachValue(bytes calldata impactData) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ImpactKeeper.sol";

/// @title BirdsEB
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract ImpactEB is ImpactKeeper {
    constructor(
        address _owner,
        address _nebula,
        address[] memory _allowedTokens
    ) ImpactKeeper(_owner, _nebula, _allowedTokens) {
        withdrawAllowance = false;
        attachAllowance = true;
    }

    event withdrawEvent(address user, uint256 amount);
    bool public withdrawAllowance;
    bool public attachAllowance;

    function toggleWithdraw(bool allowance) public isOwner {
        withdrawAllowance = allowance;
    }

    function toggleAttach(bool allowance) public isOwner {
        attachAllowance = allowance;
    }

    function withdraw(uint256 amount) public {
        require(withdrawAllowance, "withdraw not allowed");
        require(amount <= impact[msg.sender], "you don't have so much impact");
        impact[msg.sender] -= amount;
        totalSupply -= amount;
        emit withdrawEvent(msg.sender, amount);
    }

    // called from gravity to add impact to users
    function attachValue(bytes calldata impactData) external override isNebula {
        if (!attachAllowance) {
            return;
        } // do nothing if attach is no longer allowed (early birds is over)
        address lockTokenAddress = this.deserializeAddress(impactData, 0);
        address depositerAddress = this.deserializeAddress(impactData, 20);
        uint256 amount = this.deserializeUint(impactData, 40, 32);
        uint256 id = this.deserializeUint(impactData, 72, 32);
        uint256 action = this.deserializeUint(impactData, 104, 32);
        if (dataId[id] == true) {
            return;
        } // do nothing if data has already been processed
        dataId[id] = true;
        emit Transfer(lockTokenAddress, depositerAddress, amount, id, action);

        if (!allowedTokens[lockTokenAddress]) {
            return;
        } // do nothing if this token is not supported by treasury
        if (impact[depositerAddress] == 0) {
            users[userCount] = depositerAddress;
            userCount += 1;
        }
        impact[depositerAddress] += amount;
        totalSupply += amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../v1/ImpactKeeper.sol";

contract ImpactKeeperTest is ImpactKeeper {
    constructor(
        address _owner,
        address _nebula,
        address[] memory allowedTokens
    ) ImpactKeeper(_owner, _nebula, allowedTokens) {}

    function attachValue(bytes calldata impactData)
        external
        override
        isNebula
    {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IShares.sol";
import "./IBalanceKeeperV2.sol";
import "./IImpactKeeper.sol";

/// @title The interface for Graviton early birds shares
/// @notice Tracks shares of early birds
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ISharesEB is IShares {
    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice Address of the contract that tracks early birds impact
    function impactEB() external view returns (IImpactKeeper);

    /// @notice Look up early birds share of `userId`
    function impactById(uint256 userId) external view returns (uint256);

    /// @notice The total amount of early birds shares
    function totalSupply() external view returns (uint256);

    /// @notice Index of the user to migrate early birds impact
    function currentUser() external view returns (uint256);

    /// @notice Copies impact data for `step` users from the previous early birds contract
    function migrate(uint256 step) external;

    /// @notice Event emitted when data is routed
    /// @param user Address of the user whose impact was migrated
    /// @param userId Unique id of the user whose impact was migrated
    /// @param impact The amount of stable coins the user deposited in the early birds campaign
    event Migrate(address indexed user, uint256 indexed userId, uint256 impact);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ISharesEB.sol";

/// @title SharesEB
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract SharesEB is ISharesEB {
    /// @inheritdoc ISharesEB
    IBalanceKeeperV2 public override balanceKeeper;
    /// @inheritdoc ISharesEB
    IImpactKeeper public override impactEB;

    /// @inheritdoc ISharesEB
    mapping(uint256 => uint256) public override impactById;
    /// @inheritdoc ISharesEB
    uint256 public override totalSupply;
    /// @inheritdoc ISharesEB
    uint256 public override currentUser;
    /// @inheritdoc IShares
    uint256 public override totalUsers;
    mapping(uint256 => uint256) internal _userIdByIndex;

    constructor(IBalanceKeeperV2 _balanceKeeper, IImpactKeeper _impactEB) {
        balanceKeeper = _balanceKeeper;
        impactEB = _impactEB;
    }

    /// @inheritdoc ISharesEB
    function migrate(uint256 step) external override {
        uint256 toUser = currentUser + step;
        if (toUser > impactEB.userCount()) {
            toUser = impactEB.userCount();
        }
        for (uint256 i = currentUser; i < toUser; i++) {
            address user = impactEB.users(i);
            bytes memory userAddress = abi.encodePacked(user);
            if (!balanceKeeper.isKnownUser("EVM", userAddress)) {
                balanceKeeper.open("EVM", userAddress);
            }
            uint256 userId = balanceKeeper.userIdByChainAddress(
                "EVM",
                userAddress
            );
            impactById[userId] = impactEB.impact(user);
            _userIdByIndex[totalUsers] = userId;
            totalUsers++;
            emit Migrate(user, userId, impactById[userId]);
        }
        // @dev moved here from the constructor to test different impactEB states
        totalSupply = impactEB.totalSupply();
        currentUser = toUser;
    }

    /// @inheritdoc IShares
    function shareById(uint256 userId)
        external
        view
        override
        returns (uint256)
    {
        return impactById[userId];
    }

    /// @inheritdoc IShares
    function totalShares() external view override returns (uint256) {
        return totalSupply;
    }

    /// @inheritdoc IShares
    function userIdByIndex(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(index < totalUsers, "EBI");
        return _userIdByIndex[index];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IShares.sol";
import "./ILPKeeperV2.sol";

/// @title The interface for Graviton lp-token shares
/// @notice Tracks shares of locked lp-tokens
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ISharesLP is IShares {
    /// @notice Address of the contract that tracks lp-token balances
    function lpKeeper() external view returns (ILPKeeperV2);

    /// @notice Unique id of the lp-token for which to track user shares
    function tokenId() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBalanceKeeperV2.sol";

/// @title The interface for Graviton lp-token keeper
/// @notice Tracks the amount of locked liquidity provision tokens for each user
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILPKeeperV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if `user` is allowed to open new governance balances
    function canOpen(address user) external view returns (bool);

    /// @notice Look up if `user` is allowed to add to governance balances
    function canAdd(address user) external view returns (bool);

    /// @notice Look up if `user` is allowed to subtract from governance balances
    function canSubtract(address user) external view returns (bool);

    /// @notice Sets `opener` permission to open new governance balances to `_canOpen`
    /// @dev Can only be called by the current owner.
    function setCanOpen(address opener, bool _canOpen) external;

    /// @notice Sets `adder` permission to open new governance balances to `_canAdd`
    /// @dev Can only be called by the current owner.
    function setCanAdd(address adder, bool _canAdd) external;

    /// @notice Sets `subtractor` permission to open new governance balances to `_canSubtract`
    /// @dev Can only be called by the current owner.
    function setCanSubtract(address subtractor, bool _canSubtract) external;

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice The number of lp-tokens
    function totalTokens() external view returns (uint256);

    /// @notice Look up if the `tokenId` has an associated set of user balances
    /// @param tokenId unique id of the token
    function isKnownToken(uint256 tokenId) external view returns (bool);

    /// @notice Look up if the blockchain-address pair has an associated set of user balances
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    function isKnownToken(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view returns (bool);

    /// @notice Look up the type of blockchain associated with `tokenId`
    /// @param tokenId unique id of the token
    function tokenChainById(uint256 tokenId)
        external
        view
        returns (string calldata);

    /// @notice Look up the blockchain-specific address associated with `tokenId`
    /// @param tokenId unique id of the token
    function tokenAddressById(uint256 tokenId)
        external
        view
        returns (bytes calldata);

    /// @notice Look up the blockchain-address pair associated with `tokenId`
    /// @param tokenId unique id of the token
    function tokenChainAddressById(uint256 tokenId)
        external
        view
        returns (string calldata, bytes calldata);

    /// @notice Look up the unique id associated with the blockchain-address pair
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    function tokenIdByChainAddress(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view returns (uint256);

    /// @notice Look up the unique id of the user associated with `userIndex` in the token
    /// @param tokenId unique id of the token
    function tokenUser(uint256 tokenId, uint256 userIndex)
        external
        view
        returns (uint256);

    /// @notice Look up the unique id of the user associated with `userIndex` in the token
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    function tokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userIndex
    ) external view returns (uint256);

    /// @notice Look up if the user has an associated balance of the lp-token
    /// @param tokenId unique id of the token
    /// @param userId unique id of the user
    function isKnownTokenUser(uint256 tokenId, uint256 userId)
        external
        view
        returns (bool);

    /// @notice Look up if the user has an associated balance of the lp-token
    /// @param tokenId unique id of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function isKnownTokenUser(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress
    ) external view returns (bool);

    /// @notice Look up if the user has an associated balance of the lp-token
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userId unique id of the user
    function isKnownTokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId
    ) external view returns (bool);

    /// @notice Look up if the user has an associated balance of the lp-token
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function isKnownTokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress
    ) external view returns (bool);

    /// @notice The number of users that have associated balances of the lp-token
    /// @param tokenId unique id of the token
    function totalTokenUsers(uint256 tokenId) external view returns (uint256);

    /// @notice The number of users that have associated balances of the lp-token
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    function totalTokenUsers(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view returns (uint256);

    /// @notice The amount of lp-tokens locked by the user
    /// @param tokenId unique id of the token
    /// @param userId unique id of the user
    function balance(uint256 tokenId, uint256 userId)
        external
        view
        returns (uint256);

    /// @notice The amount of lp-tokens locked by the user
    /// @param tokenId unique id of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function balance(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress
    ) external view returns (uint256);

    /// @notice The amount of lp-tokens locked by the user
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userId unique id of the user
    function balance(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId
    ) external view returns (uint256);

    /// @notice The amount of lp-tokens locked by the user
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function balance(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress
    ) external view returns (uint256);

    /// @notice The total amount of lp-tokens of a given type locked by the users
    /// @param tokenId unique id of the token
    function totalBalance(uint256 tokenId) external view returns (uint256);

    /// @notice The total amount of lp-tokens of a given type locked by the users
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    function totalBalance(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view returns (uint256);

    /// @notice Opens a set of user balances for the lp-token
    /// associated with the blockchain-address pair
    function open(string calldata tokenChain, bytes calldata tokenAddress)
        external;

    /// @notice Adds `amount` of lp-tokens to the user balance
    /// @param tokenId unique id of the token
    /// @param userId unique id of the user
    function add(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) external;

    /// @notice Adds `amount` of lp-tokens to the user balance
    /// @param tokenId unique id of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function add(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Adds `amount` of lp-tokens to the user balance
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userId unique id of the user
    function add(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId,
        uint256 amount
    ) external;

    /// @notice Adds `amount` of lp-tokens to the user balance
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function add(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Subtracts `amount` of lp-tokens from the user balance
    /// @param tokenId unique id of the token
    /// @param userId unique id of the user
    function subtract(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) external;

    /// @notice Subtracts `amount` of lp-tokens from the user balance
    /// @param tokenId unique id of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function subtract(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Subtracts `amount` of lp-tokens from the user balance
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userId unique id of the user
    function subtract(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId,
        uint256 amount
    ) external;

    /// @notice Subtracts `amount` of lp-tokens from the user balance
    /// @param tokenChain the type of blockchain that the token address belongs to, i.e "EVM"
    /// @param tokenAddress blockchain-specific address of the token
    /// @param userChain the type of blockchain that the user address belongs to, i.e "EVM"
    /// @param userAddress blockchain-specific address of the user
    function subtract(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `opener` permission is updated via `#setCanOpen`
    /// @param owner The owner account at the time of change
    /// @param opener The account whose permission to open token balances was updated
    /// @param newBool Updated permission
    event SetCanOpen(
        address indexed owner,
        address indexed opener,
        bool indexed newBool
    );

    /// @notice Event emitted when the `adder` permission is updated via `#setCanAdd`
    /// @param owner The owner account at the time of change
    /// @param adder The account whose permission to add to lp-token balances was updated
    /// @param newBool Updated permission
    event SetCanAdd(
        address indexed owner,
        address indexed adder,
        bool indexed newBool
    );

    /// @notice Event emitted when the `subtractor` permission is updated via `#setCanSubtract`
    /// @param owner The owner account at the time of change
    /// @param subtractor The account whose permission
    /// to subtract from lp-token balances was updated
    /// @param newBool Updated permission
    event SetCanSubtract(
        address indexed owner,
        address indexed subtractor,
        bool indexed newBool
    );

    /// @notice Event emitted when a new `tokenId` is opened
    /// @param opener The account that opens `tokenId`
    /// @param tokenId The token account that was opened
    event Open(address indexed opener, uint256 indexed tokenId);

    /// @notice Event emitted when the `amount` of `tokenId` lp-tokens
    /// is added to `userId` balance via `#add`
    /// @param adder The account that added to the balance
    /// @param tokenId The lp-token that was added
    /// @param userId The account whose lp-token balance was updated
    /// @param amount The amount of lp-tokens
    event Add(
        address indexed adder,
        uint256 indexed tokenId,
        uint256 indexed userId,
        uint256 amount
    );

    /// @notice Event emitted when the `amount` of `tokenId` lp-tokens
    /// is subtracted from `userId` balance via `#subtract`
    /// @param subtractor The account that subtracted from the balance
    /// @param tokenId The lp-token that was subtracted
    /// @param userId The account whose lp-token balance was updated
    /// @param amount The amount of lp-tokens
    event Subtract(
        address indexed subtractor,
        uint256 indexed tokenId,
        uint256 indexed userId,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ISharesLP.sol";

/// @title SharesLP
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract SharesLP is ISharesLP {
    /// @inheritdoc ISharesLP
    ILPKeeperV2 public override lpKeeper;

    /// @inheritdoc ISharesLP
    uint256 public override tokenId;

    constructor(ILPKeeperV2 _lpKeeper, uint256 _tokenId) {
        lpKeeper = _lpKeeper;
        require(lpKeeper.isKnownToken(_tokenId), "SL1");
        tokenId = _tokenId;
    }

    /// @inheritdoc IShares
    function shareById(uint256 userId)
        external
        view
        override
        returns (uint256)
    {
        return lpKeeper.balance(tokenId, userId);
    }

    /// @inheritdoc IShares
    function totalShares() external view override returns (uint256) {
        return lpKeeper.totalBalance(tokenId);
    }

    /// @inheritdoc IShares
    function totalUsers() external view override returns (uint256) {
        return lpKeeper.totalTokenUsers(tokenId);
    }

    /// @inheritdoc IShares
    function userIdByIndex(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        return lpKeeper.tokenUser(tokenId, index);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILPKeeperV2.sol";

/// @title LPKeeperV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LPKeeperV2 is ILPKeeperV2 {
    /// @inheritdoc ILPKeeperV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILPKeeperV2
    IBalanceKeeperV2 public override balanceKeeper;

    /// @inheritdoc ILPKeeperV2
    mapping(address => bool) public override canAdd;
    /// @inheritdoc ILPKeeperV2
    mapping(address => bool) public override canSubtract;
    /// @inheritdoc ILPKeeperV2
    mapping(address => bool) public override canOpen;

    mapping(uint256 => string) internal _tokenChainById;
    mapping(uint256 => bytes) internal _tokenAddressById;
    // @dev chain code => in chain address => user id;
    mapping(string => mapping(bytes => uint256))
        internal _tokenIdByChainAddress;
    mapping(string => mapping(bytes => bool)) internal _isKnownToken;

    /// @inheritdoc ILPKeeperV2
    uint256 public override totalTokens;
    mapping(uint256 => uint256) internal _totalUsers;
    mapping(uint256 => uint256) internal _totalBalance;
    mapping(uint256 => mapping(uint256 => uint256)) internal _balance;
    mapping(uint256 => mapping(uint256 => uint256)) internal _tokenUser;
    mapping(uint256 => mapping(uint256 => bool)) internal _isKnownTokenUser;

    constructor(IBalanceKeeperV2 _balanceKeeper) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
    }

    /// @inheritdoc ILPKeeperV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILPKeeperV2
    function setCanOpen(address opener, bool _canOpen)
        external
        override
        isOwner
    {
        canOpen[opener] = _canOpen;
        emit SetCanOpen(msg.sender, opener, canOpen[opener]);
    }

    /// @inheritdoc ILPKeeperV2
    function setCanAdd(address adder, bool _canAdd) external override isOwner {
        canAdd[adder] = _canAdd;
        emit SetCanAdd(msg.sender, adder, canAdd[adder]);
    }

    /// @inheritdoc ILPKeeperV2
    function setCanSubtract(address subtractor, bool _canSubtract)
        external
        override
        isOwner
    {
        canSubtract[subtractor] = _canSubtract;
        emit SetCanSubtract(msg.sender, subtractor, canSubtract[subtractor]);
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownToken(uint256 tokenId) public view override returns (bool) {
        return tokenId < totalTokens;
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownToken(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) public view override returns (bool) {
        return _isKnownToken[tokenChain][tokenAddress];
    }

    /// @inheritdoc ILPKeeperV2
    function tokenChainById(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(isKnownToken(tokenId), "LK1");
        return _tokenChainById[tokenId];
    }

    /// @inheritdoc ILPKeeperV2
    function tokenAddressById(uint256 tokenId)
        external
        view
        override
        returns (bytes memory)
    {
        require(isKnownToken(tokenId), "LK1");
        return _tokenAddressById[tokenId];
    }

    /// @inheritdoc ILPKeeperV2
    function tokenChainAddressById(uint256 tokenId)
        external
        view
        override
        returns (string memory, bytes memory)
    {
        require(isKnownToken(tokenId), "LK1");
        return (_tokenChainById[tokenId], _tokenAddressById[tokenId]);
    }

    /// @inheritdoc ILPKeeperV2
    function tokenIdByChainAddress(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) public view override returns (uint256) {
        require(isKnownToken(tokenChain, tokenAddress), "LK1");
        return _tokenIdByChainAddress[tokenChain][tokenAddress];
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownTokenUser(uint256 tokenId, uint256 userId)
        external
        view
        override
        returns (bool)
    {
        return _isKnownTokenUser[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownTokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId
    ) external view override returns (bool) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return false;
        }
        uint256 tokenId = _tokenIdByChainAddress[tokenChain][tokenAddress];
        return _isKnownTokenUser[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownTokenUser(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress
    ) external view override returns (bool) {
        if (!balanceKeeper.isKnownUser(userChain, userAddress)) {
            return false;
        }
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        return _isKnownTokenUser[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function isKnownTokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress
    ) external view override returns (bool) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return false;
        }
        uint256 tokenId = _tokenIdByChainAddress[tokenChain][tokenAddress];
        if (!balanceKeeper.isKnownUser(userChain, userAddress)) {
            return false;
        }
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        return _isKnownTokenUser[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function tokenUser(uint256 tokenId, uint256 userIndex)
        external
        view
        override
        returns (uint256)
    {
        require(isKnownToken(tokenId), "LK1");
        require(totalTokenUsers(tokenId) > 0, "LK2");
        require(userIndex < totalTokenUsers(tokenId), "LK3");
        return _tokenUser[tokenId][userIndex];
    }

    /// @inheritdoc ILPKeeperV2
    function tokenUser(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userIndex
    ) external view override returns (uint256) {
        require(isKnownToken(tokenChain, tokenAddress), "LK1");
        uint256 tokenId = _tokenIdByChainAddress[tokenChain][tokenAddress];
        require(totalTokenUsers(tokenId) > 0, "LK2");
        require(userIndex < totalTokenUsers(tokenId), "LK3");
        return _tokenUser[tokenId][userIndex];
    }

    /// @inheritdoc ILPKeeperV2
    function totalTokenUsers(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return _totalUsers[tokenId];
    }

    /// @inheritdoc ILPKeeperV2
    function totalTokenUsers(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view override returns (uint256) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return 0;
        }
        return _totalUsers[_tokenIdByChainAddress[tokenChain][tokenAddress]];
    }

    /// @inheritdoc ILPKeeperV2
    function balance(uint256 tokenId, uint256 userId)
        external
        view
        override
        returns (uint256)
    {
        return _balance[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function balance(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress
    ) external view override returns (uint256) {
        if (!balanceKeeper.isKnownUser(userChain, userAddress)) {
            return 0;
        }
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        return _balance[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function balance(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId
    ) external view override returns (uint256) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return 0;
        }
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        return _balance[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function balance(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress
    ) external view override returns (uint256) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return 0;
        }
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        if (!balanceKeeper.isKnownUser(userChain, userAddress)) {
            return 0;
        }
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        return _balance[tokenId][userId];
    }

    /// @inheritdoc ILPKeeperV2
    function totalBalance(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _totalBalance[tokenId];
    }

    /// @inheritdoc ILPKeeperV2
    function totalBalance(
        string calldata tokenChain,
        bytes calldata tokenAddress
    ) external view override returns (uint256) {
        if (!isKnownToken(tokenChain, tokenAddress)) {
            return 0;
        }
        return _totalBalance[_tokenIdByChainAddress[tokenChain][tokenAddress]];
    }

    /// @inheritdoc ILPKeeperV2
    function open(string calldata tokenChain, bytes calldata tokenAddress)
        external
        override
    {
        require(canOpen[msg.sender], "ACO");
        if (!isKnownToken(tokenChain, tokenAddress)) {
            uint256 tokenId = totalTokens;
            _tokenChainById[tokenId] = tokenChain;
            _tokenAddressById[tokenId] = tokenAddress;
            _tokenIdByChainAddress[tokenChain][tokenAddress] = tokenId;
            _isKnownToken[tokenChain][tokenAddress] = true;
            totalTokens++;
            emit Open(msg.sender, tokenId);
        }
    }

    /// @inheritdoc ILPKeeperV2
    function add(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) external override {
        require(canAdd[msg.sender], "ACA");
        require(isKnownToken(tokenId), "LK1");
        require(balanceKeeper.isKnownUser(userId), "LK4");
        _add(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function add(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canAdd[msg.sender], "ACA");
        require(isKnownToken(tokenId), "LK1");
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        _add(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function add(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId,
        uint256 amount
    ) external override {
        require(canAdd[msg.sender], "ACA");
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        require(balanceKeeper.isKnownUser(userId), "LK4");
        _add(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function add(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canAdd[msg.sender], "ACA");
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        _add(tokenId, userId, amount);
    }

    function _add(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) internal {
        if (!_isKnownTokenUser[tokenId][userId] && amount > 0) {
            _isKnownTokenUser[tokenId][userId] = true;
            _tokenUser[tokenId][_totalUsers[tokenId]] = userId;
            _totalUsers[tokenId]++;
        }
        _balance[tokenId][userId] += amount;
        _totalBalance[tokenId] += amount;
        emit Add(msg.sender, tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function subtract(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) external override {
        require(canSubtract[msg.sender], "ACS");
        require(isKnownToken(tokenId), "LK1");
        require(balanceKeeper.isKnownUser(userId), "LK4");
        _subtract(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function subtract(
        uint256 tokenId,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canSubtract[msg.sender], "ACS");
        require(isKnownToken(tokenId), "LK1");
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        _subtract(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function subtract(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        uint256 userId,
        uint256 amount
    ) external override {
        require(canSubtract[msg.sender], "ACS");
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        require(balanceKeeper.isKnownUser(userId), "LK4");
        _subtract(tokenId, userId, amount);
    }

    /// @inheritdoc ILPKeeperV2
    function subtract(
        string calldata tokenChain,
        bytes calldata tokenAddress,
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canSubtract[msg.sender], "ACS");
        uint256 tokenId = tokenIdByChainAddress(tokenChain, tokenAddress);
        uint256 userId = balanceKeeper.userIdByChainAddress(
            userChain,
            userAddress
        );
        _subtract(tokenId, userId, amount);
    }

    function _subtract(
        uint256 tokenId,
        uint256 userId,
        uint256 amount
    ) internal {
        _balance[tokenId][userId] -= amount;
        _totalBalance[tokenId] -= amount;
        emit Subtract(msg.sender, tokenId, userId, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockUnlockLP.sol";
import "./interfaces/ILPKeeperV2.sol";
import "./interfaces/IBalanceKeeperV2.sol";

/// @title LockUnlockLPOnchain
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockUnlockLPOnchain is ILockUnlockLP {
    /// @inheritdoc ILockUnlockLP
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockUnlockLP
    mapping(address => bool) public override isAllowedToken;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override lockLimit;
    mapping(address => mapping(address => uint256)) internal _balance;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override tokenSupply;
    /// @inheritdoc ILockUnlockLP
    uint256 public override totalSupply;

    /// @inheritdoc ILockUnlockLP
    bool public override canLock;

    IBalanceKeeperV2 public balanceKeeper;
    ILPKeeperV2 public lpKeeper;

    constructor(
        address[] memory allowedTokens,
        IBalanceKeeperV2 _balanceKeeper,
        ILPKeeperV2 _lpKeeper
    ) {
        owner = msg.sender;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            isAllowedToken[allowedTokens[i]] = true;
        }
        balanceKeeper = _balanceKeeper;
        lpKeeper = _lpKeeper;
    }

    /// @inheritdoc ILockUnlockLP
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockUnlockLP
    function setIsAllowedToken(address token, bool _isAllowedToken)
        external
        override
        isOwner
    {
        isAllowedToken[token] = _isAllowedToken;
        emit SetIsAllowedToken(owner, token, _isAllowedToken);
    }

    /// @inheritdoc ILockUnlockLP
    function setLockLimit(address token, uint256 _lockLimit)
        external
        override
        isOwner
    {
        lockLimit[token] = _lockLimit;
        emit SetLockLimit(owner, token, _lockLimit);
    }

    /// @inheritdoc ILockUnlockLP
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockUnlockLP
    function balance(address token, address depositer)
        external
        view
        override
        returns (uint256)
    {
        return _balance[token][depositer];
    }

    /// @inheritdoc ILockUnlockLP
    function lock(address token, uint256 amount) external override {
        require(canLock, "LP1");
        require(isAllowedToken[token], "LP2");
        require(amount >= lockLimit[token], "LP3");
        _balance[token][msg.sender] += amount;
        tokenSupply[token] += amount;
        totalSupply += amount;
        bytes memory tokenBytes = abi.encodePacked(token);
        bytes memory receiverBytes = abi.encodePacked(msg.sender);
        if (!balanceKeeper.isKnownUser("EVM", receiverBytes)) {
            balanceKeeper.open("EVM", receiverBytes);
        }
        if (!lpKeeper.isKnownToken("EVM", tokenBytes)) {
            lpKeeper.open("EVM", tokenBytes);
        }
        lpKeeper.add("EVM", tokenBytes, "EVM", receiverBytes, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Lock(token, msg.sender, msg.sender, amount);
    }

    /// @inheritdoc ILockUnlockLP
    function unlock(address token, uint256 amount) external override {
        require(_balance[token][msg.sender] >= amount, "LP4");
        _balance[token][msg.sender] -= amount;
        tokenSupply[token] -= amount;
        totalSupply -= amount;
        bytes memory tokenBytes = abi.encodePacked(token);
        bytes memory receiverBytes = abi.encodePacked(msg.sender);
        lpKeeper.subtract("EVM", tokenBytes, "EVM", receiverBytes, amount);
        IERC20(token).transfer(msg.sender, amount);
        emit Unlock(token, msg.sender, msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @title The interface for Graviton lp-token lock-unlock
/// @notice Locks liquidity provision tokens
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILockUnlockLP {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if locking is allowed
    function canLock() external view returns (bool);

    /// @notice Sets the permission to lock to `_canLock`
    function setCanLock(bool _canLock) external;

    /// @notice Look up if the locking of `token` is allowed
    function isAllowedToken(address token) external view returns (bool);

    /// @notice Look up if the locking of `token` is allowed
    function lockLimit(address token) external view returns (uint256);

    /// @notice Sets minimum lock amount limit for `token` to `_lockLimit`
    function setLockLimit(address token, uint256 _lockLimit) external;

    /// @notice The total amount of locked `token`
    function tokenSupply(address token) external view returns (uint256);

    /// @notice The total amount of all locked lp-tokens
    function totalSupply() external view returns (uint256);

    /// @notice Sets permission to lock `token` to `_isAllowedToken`
    function setIsAllowedToken(address token, bool _isAllowedToken) external;

    /// @notice The amount of `token` locked by `depositer`
    function balance(address token, address depositer)
        external
        view
        returns (uint256);

    /// @notice Transfers `amount` of `token` from the caller to LockUnlockLP
    function lock(address token, uint256 amount) external;

    /// @notice Transfers `amount` of `token` from LockUnlockLP to the caller
    function unlock(address token, uint256 amount) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `sender` locks `amount` of `token` lp-tokens
    /// @param token The address of the lp-token
    /// @param sender The account that locked lp-token
    /// @param receiver The account to whose lp-token balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of lp-tokens locked
    event Lock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the `sender` unlocks `amount` of `token` lp-tokens
    /// @param token The address of the lp-token
    /// @param sender The account that locked lp-token
    /// @param receiver The account to whose lp-token balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of lp-tokens unlocked
    event Unlock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the permission to lock token is updated via `#setIsAllowedToken`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param newBool Updated permission
    event SetIsAllowedToken(
        address indexed owner,
        address indexed token,
        bool indexed newBool
    );

    /// @notice Event emitted when the minimum lock amount limit updated via `#setLockLimit`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param _lockLimit New minimum lock amount limit
    event SetLockLimit(
        address indexed owner,
        address indexed token,
        uint256 indexed _lockLimit
    );

    /// @notice Event emitted when the permission to lock is updated via `#setCanLock`
    /// @param owner The owner account at the time of change
    /// @param newBool Updated permission
    event SetCanLock(address indexed owner, bool indexed newBool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockUnlockLP.sol";

/// @title LockUnlockLP
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockUnlockLP is ILockUnlockLP {
    /// @inheritdoc ILockUnlockLP
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockUnlockLP
    mapping(address => bool) public override isAllowedToken;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override lockLimit;
    mapping(address => mapping(address => uint256)) internal _balance;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override tokenSupply;
    /// @inheritdoc ILockUnlockLP
    uint256 public override totalSupply;

    /// @inheritdoc ILockUnlockLP
    bool public override canLock;

    constructor(address[] memory allowedTokens) {
        owner = msg.sender;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            isAllowedToken[allowedTokens[i]] = true;
        }
    }

    /// @inheritdoc ILockUnlockLP
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockUnlockLP
    function setIsAllowedToken(address token, bool _isAllowedToken)
        external
        override
        isOwner
    {
        isAllowedToken[token] = _isAllowedToken;
        emit SetIsAllowedToken(owner, token, _isAllowedToken);
    }

    /// @inheritdoc ILockUnlockLP
    function setLockLimit(address token, uint256 _lockLimit)
        external
        override
        isOwner
    {
        lockLimit[token] = _lockLimit;
        emit SetLockLimit(owner, token, _lockLimit);
    }

    /// @inheritdoc ILockUnlockLP
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockUnlockLP
    function balance(address token, address depositer)
        external
        view
        override
        returns (uint256)
    {
        return _balance[token][depositer];
    }

    /// @inheritdoc ILockUnlockLP
    function lock(address token, uint256 amount) external override {
        require(canLock, "LP1");
        require(isAllowedToken[token], "LP2");
        require(amount >= lockLimit[token], "LP3");
        _balance[token][msg.sender] += amount;
        tokenSupply[token] += amount;
        totalSupply += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Lock(token, msg.sender, msg.sender, amount);
    }

    /// @inheritdoc ILockUnlockLP
    function unlock(address token, uint256 amount) external override {
        require(_balance[token][msg.sender] >= amount, "LP4");
        _balance[token][msg.sender] -= amount;
        tokenSupply[token] -= amount;
        totalSupply -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit Unlock(token, msg.sender, msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBalanceKeeperV2.sol";
import "./ILPKeeperV2.sol";
import "./IOracleRouterV2.sol";

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILockRouter is IOracleRouterV2 {

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice Address of the contract that tracks lp-token balances
    function lpKeeper() external view returns (ILPKeeperV2);

    /// @notice Look up topic0 of the event associated with adding governance tokens
    function gtonAddTopic() external view returns (bytes32);

    /// @notice Look up topic0 of the event associated with subtracting governance tokens
    function gtonSubTopic() external view returns (bytes32);

    /// @notice Look up topic0 of the event associated with adding lp-tokens
    function lpAddTopic() external view returns (bytes32);

    /// @notice Look up topic0 of the event associated with subtracting lp-tokens
    function lpSubTopic() external view returns (bytes32);

    /// @notice Sets topic0 of the event associated with subtracting lp-tokens
    function setGTONAddTopic(bytes32 _gtonAddTopic) external;

    /// @notice Sets topic0 of the event associated with subtracting governance tokens
    function setGTONSubTopic(bytes32 _gtonSubTopic) external;

    /// @notice Sets topic0 of the event associated with adding lp-tokens
    function setLPAddTopic(bytes32 _lpAddTopic) external;

    /// @notice Sets topic0 of the event associated with subtracting lp-tokens
    function setLPSubTopic(bytes32 _lpSubTopic) external;

    /// @notice Event emitted when the GTONAddTopic is set via '#setGTONAddTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetGTONAddTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the GTONSubTopic is set via '#setGTONSubTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetGTONSubTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the LPAddTopic is set via '#setLPAddTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetLPAddTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the LPSubTopic is set via '#setLPSubTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetLPSubTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the data is routed to add to a governance balance
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event GTONAdd(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the data is routed to subtract from a governance balance
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event GTONSub(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes token,
        bytes sender,
        bytes receiver,
        uint256 amount
    );

    /// @notice Event emitted when the data is routed to add to an lp-token balance
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event LPAdd(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the data is routed to subtract from an lp-token balance
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event LPSub(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IOracleRouterV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if `user` can route data to balance keepers
    function canRoute(address user) external view returns (bool);

    /// @notice Sets the permission to route data to balance keepers
    /// @dev Can only be called by the current owner.
    function setCanRoute(address parser, bool _canRoute) external;

    /// @notice Routes value to balance keepers according to the type of event associated with topic0
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param topic0 Unique identifier of the event
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via #setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `parser` permission is updated via `#setCanRoute`
    /// @param owner The owner account at the time of change
    /// @param parser The account whose permission to route data was updated
    /// @param newBool Updated permission
    event SetCanRoute(
        address indexed owner,
        address indexed parser,
        bool indexed newBool
    );

    /// @notice Event emitted when data is routed
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event RouteValue(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockRouter.sol";

/// @title LockRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockRouter is ILockRouter {
    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockRouter
    IBalanceKeeperV2 public override balanceKeeper;
    /// @inheritdoc ILockRouter
    ILPKeeperV2 public override lpKeeper;
    /// @inheritdoc ILockRouter
    bytes32 public override gtonAddTopic;
    /// @inheritdoc ILockRouter
    bytes32 public override gtonSubTopic;
    /// @inheritdoc ILockRouter
    bytes32 public override lpAddTopic;
    /// @inheritdoc ILockRouter
    bytes32 public override lpSubTopic;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    constructor(
        IBalanceKeeperV2 _balanceKeeper,
        ILPKeeperV2 _lpKeeper,
        bytes32 _gtonAddTopic,
        bytes32 _gtonSubTopic,
        bytes32 _lpAddTopic,
        bytes32 _lpSubTopic
    ) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
        lpKeeper = _lpKeeper;
        gtonAddTopic = _gtonAddTopic;
        gtonSubTopic = _gtonSubTopic;
        lpAddTopic = _lpAddTopic;
        lpSubTopic = _lpSubTopic;
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockRouter
    function setGTONAddTopic(bytes32 _gtonAddTopic) external override isOwner {
        bytes32 topicOld = gtonAddTopic;
        gtonAddTopic = _gtonAddTopic;
        emit SetGTONAddTopic(topicOld, _gtonAddTopic);
    }

    /// @inheritdoc ILockRouter
    function setGTONSubTopic(bytes32 _gtonSubTopic) external override isOwner {
        bytes32 topicOld = gtonSubTopic;
        gtonSubTopic = _gtonSubTopic;
        emit SetGTONSubTopic(topicOld, _gtonSubTopic);
    }

    /// @inheritdoc ILockRouter
    function setLPAddTopic(bytes32 _lpAddTopic) external override isOwner {
        bytes32 topicOld = lpAddTopic;
        lpAddTopic = _lpAddTopic;
        emit SetLPAddTopic(topicOld, _lpAddTopic);
    }

    /// @inheritdoc ILockRouter
    function setLPSubTopic(bytes32 _lpSubTopic) external override isOwner {
        bytes32 topicOld = lpSubTopic;
        lpSubTopic = _lpSubTopic;
        emit SetLPSubTopic(topicOld, _lpSubTopic);
    }

    /// @inheritdoc IOracleRouterV2
    function setCanRoute(address parser, bool _canRoute)
        external
        override
        isOwner
    {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @inheritdoc IOracleRouterV2
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "ACR");

        if (equal(topic0, gtonAddTopic)) {
            if (!balanceKeeper.isKnownUser("EVM", receiver)) {
                balanceKeeper.open("EVM", receiver);
            }
            balanceKeeper.add("EVM", receiver, amount);
            emit GTONAdd(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, gtonSubTopic)) {
            balanceKeeper.subtract("EVM", sender, amount);
            emit GTONSub(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, lpAddTopic)) {
            if (!balanceKeeper.isKnownUser("EVM", receiver)) {
                balanceKeeper.open("EVM", receiver);
            }
            if (!lpKeeper.isKnownToken("EVM", token)) {
                lpKeeper.open("EVM", token);
            }
            lpKeeper.add("EVM", token, "EVM", receiver, amount);
            emit LPAdd(uuid, chain, emiter, token, sender, receiver, amount);
        }
        if (equal(topic0, lpSubTopic)) {
            lpKeeper.subtract("EVM", token, "EVM", sender, amount);
            emit LPSub(uuid, chain, emiter, token, sender, receiver, amount);
        }

        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IOracleRouterV2.sol";

interface IRelayRouter is IOracleRouterV2 {
    function relayTopic() external view returns (bytes32);

    function wallet() external view returns (address);

    function gton() external view returns (IERC20);

    function setWallet(address _wallet) external;

    function setRelayTopic(bytes32 _relayTopic) external;

    event DeliverRelay(address user, uint256 amount);

    event SetRelayTopic(bytes32 topicOld, bytes32 topicNew);

    event SetWallet(address walletOld, address walletNew);
}

interface WNative {
     function deposit() external payable;

     function withdraw(uint wad) external;
}
interface V2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

/// @title RelayRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayRouter is IRelayRouter {
    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IRelayRouter
    bytes32 public override relayTopic;
    /// @inheritdoc IRelayRouter
    address public override wallet;
    /// @inheritdoc IRelayRouter
    IERC20 public override gton;
    WNative wnative;
    V2Router router;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    constructor(
        address _wallet,
        IERC20 _gton,
        bytes32 _relayTopic,
        WNative _wnative,
        V2Router _router
    ) {
        owner = msg.sender;
        wallet = _wallet;
        gton = _gton;
        relayTopic = _relayTopic;
        wnative = _wnative;
        router = _router;
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IRelayRouter
    function setWallet(address _wallet) public override isOwner {
        address walletOld = wallet;
        wallet = _wallet;
        emit SetWallet(walletOld, _wallet);
    }

    /// @inheritdoc IOracleRouterV2
    function setCanRoute(address parser, bool _canRoute)
        external
        override
        isOwner
    {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    /// @inheritdoc IRelayRouter
    function setRelayTopic(bytes32 _relayTopic) external override isOwner {
        bytes32 topicOld = relayTopic;
        relayTopic = _relayTopic;
        emit SetRelayTopic(topicOld, _relayTopic);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) internal pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        internal
        pure
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    /// @inheritdoc IOracleRouterV2
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "ACR");

        if (equal(topic0, relayTopic)) {
            // TODO: transfer gton from wallet
            gton.transferFrom(wallet, address(this), amount);
            // TODO: swap gton for native on DEX
            address[] memory path = new address[](2);
            path[0] = address(gton);
            path[1] = address(wnative);
            uint[] memory amounts = router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp+3600);
            // TODO: withdraw native from wrapped
            wnative.withdraw(amounts[0]);
            // TODO: transfer native to receiver
            address payable user = payable(deserializeAddress(receiver, 0));
            user.transfer(amounts[0]);
            // TODO: throw event
            emit DeliverRelay(user, amounts[0]);
        }

        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IOracleRouterV2.sol";

/// @title The interface for Graviton oracle parser
/// @notice Parses oracle data about crosschain locking/unlocking events
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IOracleParserV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice User that can send oracle data
    function nebula() external view returns (address);

    /// @notice Sets address of the user that can send oracle data to `_nebula`
    /// @dev Can only be called by the current owner.
    function setNebula(address _nebula) external;

    /// @notice Address of the contract that routes parsed data to balance keepers
    function router() external view returns (IOracleRouterV2);

    /// @notice Sets address of the oracle router to `_router`
    function setRouter(IOracleRouterV2 _router) external;

    /// @notice TODO
    function isEVM(string calldata chain) external view returns (bool);

    /// @notice TODO
    /// @param chain TODO
    /// @param newBool TODO
    function setIsEVM(string calldata chain, bool newBool) external;

    /// @notice Look up if the data uuid has already been processed
    function uuidIsProcessed(bytes16 uuid) external view returns (bool);

    /// @notice Parses a uint value from bytes
    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) external pure returns (uint256);

    /// @notice Parses an evm address from bytes
    function deserializeAddress(bytes memory b, uint256 startPos)
        external
        pure
        returns (address);

    /// @notice Parses bytes32 from bytes
    function bytesToBytes32(bytes memory b, uint256 offset)
        external
        pure
        returns (bytes32);

    /// @notice Parses bytes16 from bytes
    function bytesToBytes16(bytes memory b, uint256 offset)
        external
        pure
        returns (bytes16);

    /// @notice Compares two strings for equality
    /// @return true if strings are equal, false otherwise
    function equal(string memory a, string memory b)
        external
        pure
        returns (bool);

    /// @notice Parses data from oracles, forwards data to the oracle router
    function attachValue(bytes calldata impactData) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the nebula changes via `#setNebula`.
    /// @param nebulaOld The account that was the previous nebula
    /// @param nebulaNew The account that became the nebula
    event SetNebula(address indexed nebulaOld, address indexed nebulaNew);

    /// @notice Event emitted when the router changes via `#setRouter`.
    /// @param routerOld The previous router
    /// @param routerNew The new router
    event SetRouter(
        IOracleRouterV2 indexed routerOld,
        IOracleRouterV2 indexed routerNew
    );

    /// @notice TODO
    /// @param chain TODO
    /// @param newBool TODO
    event SetIsEVM(string chain, bool newBool);

    /// @notice Event emitted when the data is parsed and forwarded to the oracle router via `#attachValue`
    /// @param nebula The account that sent the parsed data
    /// @param uuid Unique identifier of the parsed data
    /// @dev UUID is extracted by the oracles to confirm the delivery of data
    /// @param chain Type of blockchain associated with the parsed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the parsed event originated
    /// @param topic0 The topic0 of the parsed event
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event AttachValue(
        address nebula,
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes32 topic0,
        bytes token,
        bytes sender,
        bytes receiver,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IOracleParserV2.sol";

/// @title OracleParserV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract OracleParserV2 is IOracleParserV2 {
    /// @inheritdoc IOracleParserV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IOracleParserV2
    address public override nebula;

    modifier isNebula() {
        require(msg.sender == nebula, "ACN");
        _;
    }

    /// @inheritdoc IOracleParserV2
    IOracleRouterV2 public override router;

    /// @inheritdoc IOracleParserV2
    mapping(bytes16 => bool) public override uuidIsProcessed;

    /// @inheritdoc IOracleParserV2
    mapping(string => bool) public override isEVM;

    constructor(
        IOracleRouterV2 _router,
        address _nebula,
        string[] memory evmChains
    ) {
        owner = msg.sender;
        router = _router;
        nebula = _nebula;
        for (uint256 i = 0; i < evmChains.length; i++) {
            isEVM[evmChains[i]] = true;
        }
    }

    /// @inheritdoc IOracleParserV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IOracleParserV2
    function setNebula(address _nebula) external override isOwner {
        address nebulaOld = nebula;
        nebula = _nebula;
        emit SetNebula(nebulaOld, _nebula);
    }

    /// @inheritdoc IOracleParserV2
    function setRouter(IOracleRouterV2 _router)
        external
        override
        isOwner
    {
        IOracleRouterV2 routerOld = router;
        router = _router;
        emit SetRouter(routerOld, _router);
    }

    /// @inheritdoc IOracleParserV2
    function setIsEVM(string calldata chain, bool newBool)
        external
        override
        isOwner
    {
        isEVM[chain] = newBool;
        emit SetIsEVM(chain, newBool);
    }

    /// @inheritdoc IOracleParserV2
    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) public pure override returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    /// @inheritdoc IOracleParserV2
    function deserializeAddress(bytes memory b, uint256 startPos)
        public
        pure
        override
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    /// @inheritdoc IOracleParserV2
    function bytesToBytes32(bytes memory b, uint256 offset)
        public
        pure
        override
        returns (bytes32)
    {
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    /// @inheritdoc IOracleParserV2
    function bytesToBytes16(bytes memory b, uint256 offset)
        public
        pure
        override
        returns (bytes16)
    {
        bytes16 out;
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    /// @inheritdoc IOracleParserV2
    function equal(string memory a, string memory b)
        public
        pure
        override
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @inheritdoc IOracleParserV2
    function attachValue(bytes calldata impactData) external override isNebula {
        // @dev ignore data with unexpected length
        if (impactData.length != 200) {
            return;
        }
        bytes16 uuid = bytesToBytes16(impactData, 0); // [  0: 16]
        // @dev parse data only once
        if (uuidIsProcessed[uuid]) {
            return;
        }
        uuidIsProcessed[uuid] = true;
        string memory chain = string(abi.encodePacked(impactData[16:19])); // [ 16: 19]
        if (isEVM[chain]) {
            bytes memory emiter = impactData[19:39]; // [ 19: 39]
            bytes1 topics = bytes1(impactData[39]); // [ 39: 40]
            // @dev ignore data with unexpected number of topics
            if (
                keccak256(abi.encodePacked(topics)) !=
                keccak256(
                    abi.encodePacked(bytes1(abi.encodePacked(uint256(4))[31]))
                )
            ) {
                return;
            }
            bytes32 topic0 = bytesToBytes32(impactData, 40); // [ 40: 72]
            bytes memory token = impactData[84:104]; // [ 72:104][12:32]
            bytes memory sender = impactData[116:136]; // [104:136][12:32]
            bytes memory receiver = impactData[148:168]; // [136:168][12:32]
            uint256 amount = deserializeUint(impactData, 168, 32); // [168:200]

            router.routeValue(
                uuid,
                chain,
                emiter,
                topic0,
                token,
                sender,
                receiver,
                amount
            );

            emit AttachValue(
                msg.sender,
                uuid,
                chain,
                emiter,
                topic0,
                token,
                sender,
                receiver,
                amount
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IOracleRouterV2.sol";

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IDeliveryRouter is IOracleRouterV2 {

    /// @notice TODO
    function governanceToken() external view returns (IERC20);

    /// @notice TODO
    function wallet() external view returns (address);

    /// @notice TODO
    function setWallet(address _wallet) external;

    /// @notice Look up topic0 of the event associated with adding governance tokens
    function confirmClaimTopic() external view returns (bytes32);

    /// @notice Sets topic0 of the event associated with claiming governance topics
    function setConfirmClaimTopic(bytes32 _lpSubTopic) external;

    /// @notice Event emitted when the ConfirmClaimTopic is set via '#setConfirmClaimTopic'
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetConfirmClaimTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice Event emitted when the wallet changes via `#setWallet`.
    /// @param walletOld The previous wallet
    /// @param walletNew The new wallet
    event SetWallet(address indexed walletOld, address indexed walletNew);

    /// @notice TODO
    event DeliverClaim(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IDeliveryRouter.sol";

/// @title DeliveryRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract DeliveryRouter is IDeliveryRouter {
    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IDeliveryRouter
    bytes32 public override confirmClaimTopic;
    /// @inheritdoc IDeliveryRouter
    address public override wallet;
    /// @inheritdoc IDeliveryRouter
    IERC20 public override governanceToken;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    constructor(
        address _wallet,
        IERC20 _governanceToken,
        bytes32 _confirmClaimTopic
    ) {
        owner = msg.sender;
        wallet = _wallet;
        governanceToken = _governanceToken;
        confirmClaimTopic = _confirmClaimTopic;
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IDeliveryRouter
    function setWallet(address _wallet) public override isOwner {
        address walletOld = wallet;
        wallet = _wallet;
        emit SetWallet(walletOld, _wallet);
    }

    /// @inheritdoc IOracleRouterV2
    function setCanRoute(address parser, bool _canRoute)
        external
        override
        isOwner
    {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    /// @inheritdoc IDeliveryRouter
    function setConfirmClaimTopic(bytes32 _confirmClaimTopic) external override isOwner {
        bytes32 topicOld = confirmClaimTopic;
        confirmClaimTopic = _confirmClaimTopic;
        emit SetConfirmClaimTopic(topicOld, _confirmClaimTopic);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) internal pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        internal
        pure
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    /// @inheritdoc IOracleRouterV2
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "ACR");

        if (equal(topic0, confirmClaimTopic)) {
            address user = deserializeAddress(receiver, 0);
            governanceToken.transferFrom(wallet, user, amount);
            emit DeliverClaim(address(governanceToken), user, user, amount);
        }

        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBalanceKeeperV2.sol";
import "./ILPKeeperV2.sol";
import "./IOracleRouterV2.sol";

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IClaimRouter is IOracleRouterV2 {

    /// @notice Address of the contract that tracks governance balances
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice TODO
    function requestClaimTopic() external view returns (bytes32);

    /// @notice TODO
    function setRequestClaimTopic(bytes32 _requestClaimTopic) external;

    /// @notice TODO
    /// @param topicOld The previous topic
    /// @param topicNew The new topic
    event SetRequestClaimTopic(bytes32 indexed topicOld, bytes32 indexed topicNew);

    /// @notice TODO
    event ClaimBSC(
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );

    /// @notice TODO
    event ClaimPLG(
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );

    /// @notice TODO
    event ClaimETH(
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IClaimRouter.sol";

/// @title ClaimRouter
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract ClaimRouter is IClaimRouter {
    /// @inheritdoc IOracleRouterV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IClaimRouter
    IBalanceKeeperV2 public override balanceKeeper;
    /// @inheritdoc IClaimRouter
    bytes32 public override requestClaimTopic;

    /// @inheritdoc IOracleRouterV2
    mapping(address => bool) public override canRoute;

    constructor(
        IBalanceKeeperV2 _balanceKeeper,
        bytes32 _requestClaimTopic
    ) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
        requestClaimTopic = _requestClaimTopic;
    }

    /// @inheritdoc IOracleRouterV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IOracleRouterV2
    function setCanRoute(address parser, bool _canRoute)
        external
        override
        isOwner
    {
        canRoute[parser] = _canRoute;
        emit SetCanRoute(msg.sender, parser, canRoute[parser]);
    }

    /// @inheritdoc IClaimRouter
    function setRequestClaimTopic(bytes32 _requestClaimTopic) external override isOwner {
        bytes32 topicOld = requestClaimTopic;
        requestClaimTopic = _requestClaimTopic;
        emit SetRequestClaimTopic(topicOld, _requestClaimTopic);
    }

    function equal(bytes32 a, bytes32 b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @inheritdoc IOracleRouterV2
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external override {
        require(canRoute[msg.sender], "ACR");

        if (equal(topic0, requestClaimTopic)) {
            if (balanceKeeper.balance(chain, sender) >= amount) {
                balanceKeeper.subtract("EVM", sender, amount);
                if (equal(chain, "ETH")) {
                    emit ClaimETH(token, sender, receiver, amount);
                }
                if (equal(chain, "BSC")) {
                    emit ClaimBSC(token, sender, receiver, amount);
                }
                if (equal(chain, "PLG")) {
                    emit ClaimPLG(token, sender, receiver, amount);
                }
            }
        }

        emit RouteValue(uuid, chain, emiter, token, sender, receiver, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IShares.sol";
import "./IFarm.sol";
import "./IBalanceKeeperV2.sol";

/// @title The interface for Graviton balance adder
/// @notice BalanceAdder adds governance balance to users according to farming campaigns
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IBalanceAdderV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Contract that stores governance balance of users
    function balanceKeeper() external view returns (IBalanceKeeperV2);

    /// @notice Look up the contract that stores user shares in the `farmIndex` farming campaign
    function shares(uint256 farmIndex) external view returns (IShares);

    /// @notice Look up the contract that calculates funds available for the `farmIndex` farming campaign
    function farms(uint256 farmIndex) external view returns (IFarm);

    /// @notice Look up the amount of funds already distributed for the `farmIndex` farming campaign
    function lastPortions(uint256 farmIndex) external view returns (uint256);

    /// @notice Id of the user to receive funds in the current farming campaign
    /// @dev When current user is 0, campaign has not started processing
    /// @dev When processing is finished, current user is set to 0
    function currentUser() external view returns (uint256);

    /// @notice Id of the farming campaign to process
    function currentFarm() external view returns (uint256);

    /// @notice Portion of funds to distribute in processing on this round
    function currentPortion() external view returns (uint256);

    /// @notice Total funds available for the farming campaign
    function totalUnlocked() external view returns (uint256);

    /// @notice The sum of shares of all users
    function totalShares() external view returns (uint256);

    /// @notice Look up if the `farmIndex` farming campaign is being processed
    /// @return true if the farming campaign is locked for processing,
    /// false if the current farm has not started processing
    function isProcessing(uint256 farmIndex) external view returns (bool);

    /// @notice The number of active farming campaigns
    function totalFarms() external view returns (uint256);

    /// @notice The number of users known to BalanceKeeper
    function totalUsers() external view returns (uint256);

    /// @notice Adds shares, farm and initialize lastPortions
    /// for the new farming campaign
    /// @param _share The contract that stores user shares in the farming campaign
    /// @param _farm The contract that calculates funds available for the farming campaign
    function addFarm(IShares _share, IFarm _farm) external;

    /// @notice Removes shares, farm and lastPortions for the new farming campaign
    /// @dev changes ids of farms that follow `farmIndex` in the array
    function removeFarm(uint256 farmIndex) external;

    /// @notice Adds balances to `step` of users according to current farming campaign
    /// @dev iterates over all users and then increments current farm index
    function processBalances(uint256 step) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when a farm is added via `#addFarm`
    /// @param _shares The contract that stores user shares in the farming campaign
    /// @param _farm The contract that calculates funds available for the farming campaign
    event AddFarm(
        uint256 farmIndex,
        IShares indexed _shares,
        IFarm indexed _farm
    );

    /// @notice Event emitted when a farm is removed via `#removeFarm`
    /// @param oldShares The contract that stores user shares in the farming campaign
    /// @param oldFarm The contract that calculates funds available for the farming campaign
    /// @param oldLastPortions The portions processed in the farm before it was removed
    event RemoveFarm(
        uint256 farmIndex,
        IShares indexed oldShares,
        IFarm indexed oldFarm,
        uint256 oldLastPortions
    );

    /// @notice Event emitted when balances are processed for a farm via `#processBalances`
    /// @param oldShares The contract that stores user shares in the farming campaign
    /// @param oldFarm The contract that calculates funds available for the farming campaign
    /// @param step Number of users to process
    event ProcessBalances(
        uint256 farmIndex,
        IShares indexed oldShares,
        IFarm indexed oldFarm,
        uint256 step
    );

    /// @notice Event emitted when balances are processed for a farm via `#processBalances`
    /// @param oldShares The contract that stores user shares in the farming campaign
    /// @param oldFarm The contract that calculates funds available for the farming campaign
    /// @param userId unique id of the user
    /// @param amount The amount of governance tokens added to user's governance balance
    event ProcessBalance(
        uint256 farmIndex,
        IShares indexed oldShares,
        IFarm indexed oldFarm,
        uint256 indexed userId,
        uint256 amount
    );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IBalanceAdderV2.sol";

/// @title BalanceAdderV2Old
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceAdderV2Old is IBalanceAdderV2 {
    /// @inheritdoc IBalanceAdderV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /// @inheritdoc IBalanceAdderV2
    IShares[] public override shares;
    /// @inheritdoc IBalanceAdderV2
    IFarm[] public override farms;
    /// @inheritdoc IBalanceAdderV2
    uint256[] public override lastPortions;

    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentUser;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentFarm;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentPortion;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalUnlocked;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalShares;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalUsers;

    /// @inheritdoc IBalanceAdderV2
    IBalanceKeeperV2 public override balanceKeeper;

    /// @inheritdoc IBalanceAdderV2
    mapping(uint256 => bool) public override isProcessing;

    constructor(IBalanceKeeperV2 _balanceKeeper) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
    }

    /// @inheritdoc IBalanceAdderV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IBalanceAdderV2
    function totalFarms() external view override returns (uint256) {
        return farms.length;
    }

    /// @inheritdoc IBalanceAdderV2
    function addFarm(IShares _share, IFarm _farm) external override isOwner {
        shares.push(_share);
        farms.push(_farm);
        lastPortions.push(0);
        emit AddFarm(farms.length, _share, _farm);
    }

    /// @inheritdoc IBalanceAdderV2
    /// @dev remove index from arrays
    function removeFarm(uint256 farmId) external override isOwner {
        require(!isProcessing[currentFarm], "farm is processing balances");

        IShares oldShares = shares[farmId];
        IShares[] memory newShares = new IShares[](shares.length - 1);
        uint256 j = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (i == farmId) {
                continue;
            }
            newShares[j] = shares[i];
            j++;
        }
        shares = newShares;

        IFarm oldFarm = farms[farmId];
        IFarm[] memory newFarms = new IFarm[](farms.length - 1);
        j = 0;
        for (uint256 i = 0; i < farms.length; i++) {
            if (i == farmId) {
                continue;
            }
            newFarms[j] = farms[i];
            j++;
        }
        farms = newFarms;

        uint256 oldLastPortions = lastPortions[farmId];
        uint256[] memory newLastPortions = new uint256[](
            lastPortions.length - 1
        );
        j = 0;
        for (uint256 i = 0; i < lastPortions.length; i++) {
            if (i == farmId) {
                continue;
            }
            newLastPortions[j] = lastPortions[i];
            j++;
        }
        lastPortions = newLastPortions;

        emit RemoveFarm(farmId, oldShares, oldFarm, oldLastPortions);
    }

    /// @inheritdoc IBalanceAdderV2
    function processBalances(uint256 step) external override {
        /// @dev Return if there are no farming campaigns
        if (farms.length == 0) {
            return;
        }

        uint256 fromUser = currentUser;
        uint256 toUser = currentUser + step;

        if (!isProcessing[currentFarm] && toUser > 0) {
            isProcessing[currentFarm] = true;
            totalUsers = balanceKeeper.totalUsers();
            totalShares = shares[currentFarm].totalShares();
            totalUnlocked = farms[currentFarm].totalUnlocked();
            currentPortion = totalUnlocked - lastPortions[currentFarm];
        }

        if (toUser > totalUsers) {
            toUser = totalUsers;
        }

        emit ProcessBalances(
            currentFarm,
            shares[currentFarm],
            farms[currentFarm],
            step
        );

        for (uint256 i = fromUser; i < toUser; i++) {
            require(
                shares[currentFarm].totalShares() > 0,
                "there are no shares"
            );
            uint256 add = (shares[currentFarm].shareById(i) * currentPortion) /
                totalShares;
            balanceKeeper.add(i, add);
            emit ProcessBalance(
                currentFarm,
                shares[currentFarm],
                farms[currentFarm],
                i,
                add
            );
        }

        if (toUser == totalUsers) {
            lastPortions[currentFarm] = totalUnlocked;
            isProcessing[currentFarm] = false;
            if (currentFarm == farms.length - 1) {
                currentFarm = 0;
            } else {
                currentFarm++;
            }
            currentUser = 0;
        } else {
            currentUser = toUser;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IFarm.sol";

/// @title FarmLinear
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract FarmLinear is IFarm {
    /// @inheritdoc IFarm
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IFarm
    bool public override farmingStarted;
    /// @inheritdoc IFarm
    bool public override farmingStopped;

    /// @inheritdoc IFarm
    uint256 public override startTimestamp;
    /// @inheritdoc IFarm
    uint256 public override lastTimestamp;
    /// @inheritdoc IFarm
    uint256 public override totalUnlocked;

    uint256 public amount;
    uint256 public period;

    constructor(
        uint256 _amount,
        uint256 _period,
        uint256 _startTimestamp
    ) {
        owner = msg.sender;
        amount = _amount;
        period = _period;
        if (_startTimestamp != 0) {
            farmingStarted = true;
            startTimestamp = _startTimestamp;
            lastTimestamp = startTimestamp;
        }
    }

    /// @inheritdoc IFarm
    function setOwner(address _owner) public override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @dev Returns the block timestamp. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IFarm
    function startFarming() public override isOwner {
        if (!farmingStarted) {
            farmingStarted = true;
            startTimestamp = _blockTimestamp();
            lastTimestamp = startTimestamp;
        }
    }

    /// @inheritdoc IFarm
    function stopFarming() public override isOwner {
        farmingStopped = true;
    }

    /// @inheritdoc IFarm
    function unlockAsset() public override {
        require(farmingStarted, "F1");
        require(!farmingStopped, "F2");

        uint256 currentTimestamp = _blockTimestamp();

        uint256 lastY = (amount * (lastTimestamp - startTimestamp) * (1e18)) /
            period;
        uint256 currentY = (amount *
            (currentTimestamp - startTimestamp) *
            (1e18)) / period;

        uint256 addAmount = currentY - lastY;

        lastTimestamp = currentTimestamp;

        totalUnlocked += addAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../FarmLinear.sol";

// used for testing time dependent behavior
contract MockTimeFarmLinear is FarmLinear {
    constructor(
        uint256 _amount,
        uint256 _period,
        uint256 _startTimestamp
    ) FarmLinear(_amount, _period, _startTimestamp) {}

    // Monday, October 5, 2020 9:00:00 AM GMT-05:00
    uint256 public time = 1601906400;

    function advanceTime(uint256 by) external {
        time += by;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IFarm.sol";

/// @title FarmCurved
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract FarmCurved is IFarm {
    /// @inheritdoc IFarm
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IFarm
    bool public override farmingStarted;
    /// @inheritdoc IFarm
    bool public override farmingStopped;

    /// @inheritdoc IFarm
    uint256 public override startTimestamp;
    /// @inheritdoc IFarm
    uint256 public override lastTimestamp;
    /// @inheritdoc IFarm
    uint256 public override totalUnlocked;

    uint256 public c;
    uint256 public a;

    constructor(
        uint256 _a,
        uint256 _c,
        uint256 _startTimestamp
    ) {
        owner = msg.sender;
        a = _a;
        c = _c;
        if (_startTimestamp != 0) {
            farmingStarted = true;
            startTimestamp = _startTimestamp;
            lastTimestamp = startTimestamp;
        }
    }

    /// @inheritdoc IFarm
    function setOwner(address _owner) public override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @dev Returns the block timestamp. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IFarm
    function startFarming() public override isOwner {
        if (!farmingStarted) {
            farmingStarted = true;
            startTimestamp = _blockTimestamp();
            lastTimestamp = startTimestamp;
        }
    }

    /// @inheritdoc IFarm
    function stopFarming() public override isOwner {
        farmingStopped = true;
    }

    /// @inheritdoc IFarm
    function unlockAsset() public override {
        require(farmingStarted, "F1");
        require(!farmingStopped, "F2");

        uint256 currentTimestamp = _blockTimestamp();

        uint256 lastY = (a * (1e18)) / (lastTimestamp + a / c - startTimestamp);
        uint256 currentY = (a * (1e18)) /
            (currentTimestamp + a / c - startTimestamp);

        uint256 addAmount = lastY - currentY;

        lastTimestamp = currentTimestamp;

        totalUnlocked += addAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../FarmCurved.sol";

// used for testing time dependent behavior
contract MockTimeFarmCurved is FarmCurved {
    constructor(
        uint256 _amount,
        uint256 _period,
        uint256 _startTimestamp
    ) FarmCurved(_amount, _period, _startTimestamp) {}

    // Monday, October 5, 2020 9:00:00 AM GMT-05:00
    uint256 public time = 1601906400;

    function advanceTime(uint256 by) external {
        time += by;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IBalanceAdderV2.sol";

/// @title BalanceAdderV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceAdderV2 is IBalanceAdderV2 {
    /// @inheritdoc IBalanceAdderV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IBalanceAdderV2
    IShares[] public override shares;
    /// @inheritdoc IBalanceAdderV2
    IFarm[] public override farms;
    /// @inheritdoc IBalanceAdderV2
    uint256[] public override lastPortions;

    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentUser;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentFarm;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override currentPortion;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalUnlocked;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalShares;
    /// @inheritdoc IBalanceAdderV2
    uint256 public override totalUsers;

    /// @inheritdoc IBalanceAdderV2
    IBalanceKeeperV2 public override balanceKeeper;

    /// @inheritdoc IBalanceAdderV2
    mapping(uint256 => bool) public override isProcessing;

    constructor(IBalanceKeeperV2 _balanceKeeper) {
        owner = msg.sender;
        balanceKeeper = _balanceKeeper;
    }

    /// @inheritdoc IBalanceAdderV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IBalanceAdderV2
    function totalFarms() external view override returns (uint256) {
        return farms.length;
    }

    /// @inheritdoc IBalanceAdderV2
    function addFarm(IShares _share, IFarm _farm) external override isOwner {
        shares.push(_share);
        farms.push(_farm);
        lastPortions.push(0);
        emit AddFarm(farms.length, _share, _farm);
    }

    /// @inheritdoc IBalanceAdderV2
    /// @dev remove index from arrays
    function removeFarm(uint256 farmId) external override isOwner {
        require(!isProcessing[currentFarm], "BA1");

        IShares oldShares = shares[farmId];
        IShares[] memory newShares = new IShares[](shares.length - 1);
        uint256 j = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (i == farmId) {
                continue;
            }
            newShares[j] = shares[i];
            j++;
        }
        shares = newShares;

        IFarm oldFarm = farms[farmId];
        IFarm[] memory newFarms = new IFarm[](farms.length - 1);
        j = 0;
        for (uint256 i = 0; i < farms.length; i++) {
            if (i == farmId) {
                continue;
            }
            newFarms[j] = farms[i];
            j++;
        }
        farms = newFarms;

        uint256 oldLastPortions = lastPortions[farmId];
        uint256[] memory newLastPortions = new uint256[](
            lastPortions.length - 1
        );
        j = 0;
        for (uint256 i = 0; i < lastPortions.length; i++) {
            if (i == farmId) {
                continue;
            }
            newLastPortions[j] = lastPortions[i];
            j++;
        }
        lastPortions = newLastPortions;

        emit RemoveFarm(farmId, oldShares, oldFarm, oldLastPortions);
    }

    /// @inheritdoc IBalanceAdderV2
    function processBalances(uint256 step) external override {
        /// @dev Return if there are no farming campaigns
        if (farms.length == 0) {
            return;
        }

        uint256 fromUser = currentUser;
        uint256 toUser = currentUser + step;

        if (!isProcessing[currentFarm] && toUser > 0) {
            isProcessing[currentFarm] = true;
            totalUsers = shares[currentFarm].totalUsers();
            totalShares = shares[currentFarm].totalShares();
            totalUnlocked = farms[currentFarm].totalUnlocked();
            currentPortion = totalUnlocked - lastPortions[currentFarm];
        }

        if (toUser > totalUsers) {
            toUser = totalUsers;
        }

        emit ProcessBalances(
            currentFarm,
            shares[currentFarm],
            farms[currentFarm],
            step
        );

        if (totalShares > 0) {
            for (uint256 i = fromUser; i < toUser; i++) {
                uint256 userId = shares[currentFarm].userIdByIndex(i);
                uint256 add = (shares[currentFarm].shareById(userId) *
                    currentPortion) / totalShares;
                balanceKeeper.add(userId, add);
                emit ProcessBalance(
                    currentFarm,
                    shares[currentFarm],
                    farms[currentFarm],
                    userId,
                    add
                );
            }
        }

        if (toUser == totalUsers) {
            lastPortions[currentFarm] = totalUnlocked;
            isProcessing[currentFarm] = false;
            if (currentFarm == farms.length - 1) {
                currentFarm = 0;
            } else {
                currentFarm++;
            }
            currentUser = 0;
        } else {
            currentUser = toUser;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../v1/ClaimGTON.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalanceKeeper.sol";
import "../interfaces/IVoter.sol";

// used for testing time dependent behavior
contract MockTimeClaimGTON is ClaimGTON {
    constructor(
        IERC20 _governanceToken,
        address _wallet,
        IBalanceKeeper _balanceKeeper,
        IVoter _voter
    ) ClaimGTON(_governanceToken, _wallet, _balanceKeeper, _voter) {}

    // Monday, October 5, 2020 9:00:00 AM GMT-05:00
    uint256 public time = 1601906400;

    function advanceTime(uint256 by) external {
        time += by;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";

interface IRelayLock {
    function lock(string calldata destination, bytes calldata receiver) external payable;

    event Lock(string indexed destination, bytes indexed receiver, uint256 amount);
}
interface WNative {
     function deposit() external payable;

     function withdraw(uint wad) external;
     
     function approve(address spender, uint256 amount) external returns (bool);
}
interface V2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

/// @title RelayLock
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayLock is IRelayLock {

    address public owner;
    WNative public wnative;
    V2Router public router;
    IERC20 public gton;

    constructor (WNative _wnative, V2Router _router, IERC20 _gton) {
        owner = msg.sender;
        wnative = _wnative;
        router = _router;
        gton = _gton;
    }

    function lock(string memory destination, bytes memory receiver) external payable override {
        // TODO: transfer native
        // TODO: wrap native to erc20
        wnative.deposit{value: msg.value}();
        wnative.approve(address(router), msg.value);
        // TODO: swap for gton on dex
        address[] memory path = new address[](2);
        path[0] = address(wnative);
        path[1] = address(gton);
        uint[] memory amounts = router.swapExactTokensForTokens(msg.value, 0, path, address(this), block.timestamp+3600);
        // TODO: throw event
        emit Lock(destination, receiver, amounts[0]);
    }
    
    function reclaimERC20(IERC20 token) public {
        require(msg.sender == owner, "");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function reclaimNative(uint256 amount) public {
        require(msg.sender == owner, "");
        payable(msg.sender).transfer(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @title The interface for Graviton governance token lock
/// @notice Locks governance tokens
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILockGTON {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if locking is allowed
    function canLock() external view returns (bool);

    /// @notice Sets the permission to lock to `_canLock`
    function setCanLock(bool _canLock) external;

    /// @notice Address of the governance token
    function governanceToken() external view returns (IERC20);

    /// @notice Transfers locked governance tokens to the next version of LockGTON
    function migrate(address newLock) external;

    /// @notice Locks `amount` of governance tokens
    function lock(uint256 amount) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `sender` locks `amount` of governance tokens
    /// @dev LockGTON event is not called Lock so the topic0 is different
    /// from the lp-token locking event when parsed by the oracle parser
    /// @param governanceToken The address of governance token
    /// @dev governanceToken is specified so the event has the same number of topics
    /// as the lp-token locking event when parsed by the oracle parser
    /// @param sender The account that locked governance tokens
    /// @param receiver The account to whose governance balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of governance tokens locked
    event LockGTON(
        address indexed governanceToken,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the permission to lock is updated via `#setCanLock`
    /// @param owner The owner account at the time of change
    /// @param newBool Updated permission
    event SetCanLock(address indexed owner, bool indexed newBool);

    /// @notice Event emitted when the locked governance tokens are transfered the another version of LockGTON
    /// @param newLock The new Lock contract
    /// @param amount Amount of tokens migrated
    event Migrate(address indexed newLock, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockGTON.sol";
import "./interfaces/IBalanceKeeperV2.sol";

/// @title LockGTONOnchain
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockGTONOnchain is ILockGTON {
    /// @inheritdoc ILockGTON
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockGTON
    IERC20 public override governanceToken;

    IBalanceKeeperV2 public balanceKeeper;

    /// @inheritdoc ILockGTON
    bool public override canLock;

    constructor(IERC20 _governanceToken, IBalanceKeeperV2 _balanceKeeper) {
        owner = msg.sender;
        governanceToken = _governanceToken;
        balanceKeeper = _balanceKeeper;
    }

    /// @inheritdoc ILockGTON
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockGTON
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockGTON
    function migrate(address newLock) external override isOwner {
        uint256 amount = governanceToken.balanceOf(address(this));
        governanceToken.transfer(newLock, amount);
        emit Migrate(newLock, amount);
    }

    /// @inheritdoc ILockGTON
    function lock(uint256 amount) external override {
        require(canLock, "LG1");
        bytes memory receiverBytes = abi.encodePacked(msg.sender);
        if (!balanceKeeper.isKnownUser("EVM", receiverBytes)) {
            balanceKeeper.open("EVM", receiverBytes);
        }
        balanceKeeper.add("EVM", abi.encodePacked(receiverBytes), amount);
        governanceToken.transferFrom(msg.sender, address(this), amount);
        emit LockGTON(address(governanceToken), msg.sender, msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockGTON.sol";

/// @title LockGTON
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockGTON is ILockGTON {
    /// @inheritdoc ILockGTON
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockGTON
    IERC20 public override governanceToken;

    /// @inheritdoc ILockGTON
    bool public override canLock;

    constructor(IERC20 _governanceToken) {
        owner = msg.sender;
        governanceToken = _governanceToken;
    }

    /// @inheritdoc ILockGTON
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockGTON
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockGTON
    function migrate(address newLock) external override isOwner {
        uint256 amount = governanceToken.balanceOf(address(this));
        governanceToken.transfer(newLock, amount);
        emit Migrate(newLock, amount);
    }

    /// @inheritdoc ILockGTON
    function lock(uint256 amount) external override {
        require(canLock, "LG1");
        governanceToken.transferFrom(msg.sender, address(this), amount);
        emit LockGTON(address(governanceToken), msg.sender, msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IBalanceKeeperV2.sol";

/// @title BalanceKeeperV2
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract BalanceKeeperV2 is IBalanceKeeperV2 {
    /// @inheritdoc IBalanceKeeperV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IBalanceKeeperV2
    mapping(address => bool) public override canAdd;
    /// @inheritdoc IBalanceKeeperV2
    mapping(address => bool) public override canSubtract;
    /// @inheritdoc IBalanceKeeperV2
    mapping(address => bool) public override canOpen;

    mapping(uint256 => string) internal _userChainById;
    mapping(uint256 => bytes) internal _userAddressById;
    mapping(string => mapping(bytes => uint256)) internal _userIdByChainAddress;
    mapping(string => mapping(bytes => bool)) internal _isKnownUser;

    /// @inheritdoc IBalanceKeeperV2
    uint256 public override totalUsers;
    /// @inheritdoc IBalanceKeeperV2
    uint256 public override totalBalance;
    mapping(uint256 => uint256) internal _balance;

    constructor() {
        owner = msg.sender;
    }

    /// @inheritdoc IBalanceKeeperV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IBalanceKeeperV2
    function setCanOpen(address opener, bool _canOpen)
        external
        override
        isOwner
    {
        canOpen[opener] = _canOpen;
        emit SetCanOpen(msg.sender, opener, canOpen[opener]);
    }

    /// @inheritdoc IBalanceKeeperV2
    function setCanAdd(address adder, bool _canAdd) external override isOwner {
        canAdd[adder] = _canAdd;
        emit SetCanAdd(msg.sender, adder, canAdd[adder]);
    }

    /// @inheritdoc IBalanceKeeperV2
    function setCanSubtract(address subtractor, bool _canSubtract)
        external
        override
        isOwner
    {
        canSubtract[subtractor] = _canSubtract;
        emit SetCanSubtract(msg.sender, subtractor, canSubtract[subtractor]);
    }

    /// @inheritdoc IBalanceKeeperV2
    function isKnownUser(uint256 userId) public view override returns (bool) {
        return userId < totalUsers;
    }

    /// @inheritdoc IBalanceKeeperV2
    function isKnownUser(string calldata userChain, bytes calldata userAddress)
        public
        view
        override
        returns (bool)
    {
        return _isKnownUser[userChain][userAddress];
    }

    /// @inheritdoc IBalanceKeeperV2
    function userChainById(uint256 userId)
        external
        view
        override
        returns (string memory)
    {
        require(isKnownUser(userId), "BK1");
        return _userChainById[userId];
    }

    /// @inheritdoc IBalanceKeeperV2
    function userAddressById(uint256 userId)
        external
        view
        override
        returns (bytes memory)
    {
        require(isKnownUser(userId), "BK1");
        return _userAddressById[userId];
    }

    /// @inheritdoc IBalanceKeeperV2
    function userChainAddressById(uint256 userId)
        external
        view
        override
        returns (string memory, bytes memory)
    {
        require(isKnownUser(userId), "BK1");
        return (_userChainById[userId], _userAddressById[userId]);
    }

    /// @inheritdoc IBalanceKeeperV2
    function userIdByChainAddress(
        string calldata userChain,
        bytes calldata userAddress
    ) external view override returns (uint256) {
        require(isKnownUser(userChain, userAddress), "BK1");
        return _userIdByChainAddress[userChain][userAddress];
    }

    /// @inheritdoc IBalanceKeeperV2
    function balance(uint256 userId) external view override returns (uint256) {
        return _balance[userId];
    }

    /// @inheritdoc IBalanceKeeperV2
    function balance(string calldata userChain, bytes calldata userAddress)
        external
        view
        override
        returns (uint256)
    {
        if (!isKnownUser(userChain, userAddress)) {
            return 0;
        }
        return _balance[_userIdByChainAddress[userChain][userAddress]];
    }

    /// @inheritdoc IBalanceKeeperV2
    function open(string calldata userChain, bytes calldata userAddress)
        external
        override
    {
        require(canOpen[msg.sender], "ACO");
        if (!isKnownUser(userChain, userAddress)) {
            uint256 userId = totalUsers;
            _userChainById[userId] = userChain;
            _userAddressById[userId] = userAddress;
            _userIdByChainAddress[userChain][userAddress] = userId;
            _isKnownUser[userChain][userAddress] = true;
            totalUsers++;
            emit Open(msg.sender, userId);
        }
    }

    /// @inheritdoc IBalanceKeeperV2
    function add(uint256 userId, uint256 amount) external override {
        require(canAdd[msg.sender], "ACA");
        require(isKnownUser(userId), "BK1");
        _add(userId, amount);
    }

    /// @inheritdoc IBalanceKeeperV2
    function add(
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canAdd[msg.sender], "ACA");
        require(isKnownUser(userChain, userAddress), "BK1");
        _add(_userIdByChainAddress[userChain][userAddress], amount);
    }

    function _add(uint256 userId, uint256 amount) internal {
        _balance[userId] += amount;
        totalBalance += amount;
        emit Add(msg.sender, userId, amount);
    }

    /// @inheritdoc IBalanceKeeperV2
    function subtract(uint256 userId, uint256 amount) external override {
        require(canSubtract[msg.sender], "ACS");
        require(isKnownUser(userId), "BK1");
        _subtract(userId, amount);
    }

    /// @inheritdoc IBalanceKeeperV2
    function subtract(
        string calldata userChain,
        bytes calldata userAddress,
        uint256 amount
    ) external override {
        require(canSubtract[msg.sender], "ACS");
        require(isKnownUser(userChain, userAddress), "BK1");
        _subtract(_userIdByChainAddress[userChain][userAddress], amount);
    }

    function _subtract(uint256 userId, uint256 amount) internal {
        _balance[userId] -= amount;
        totalBalance -= amount;
        emit Subtract(msg.sender, userId, amount);
    }

    /// @inheritdoc IShares
    function shareById(uint256 userId)
        external
        view
        override
        returns (uint256)
    {
        return _balance[userId];
    }

    /// @inheritdoc IShares
    function totalShares() external view override returns (uint256) {
        return totalBalance;
    }

    /// @inheritdoc IShares
    function userIdByIndex(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(index < totalUsers, "BK2");
        return index;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBalanceKeeperV1 {
    function owner() external view returns (address);

    function allowedAdders(address user) external view returns (bool);

    function allowedSubtractors(address user) external view returns (bool);

    function totalUsers() external view returns (uint256);

    function knownUsers(address user) external view returns (bool);

    function userAddresses(uint256 index) external view returns (address);

    function userBalance(address user) external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function toggleAdder(address adder) external;

    function toggleSubtractor(address subtractor) external;

    function addValue(address user, uint256 value) external;

    function subtractValue(address user, uint256 value) external;

    event AddValueEvent(
        address indexed adder,
        address indexed user,
        uint256 indexed amount
    );
    event SubtractValueEvent(
        address indexed subtractor,
        address indexed user,
        uint256 indexed amount
    );
    event TransferOwnershipEvent(address oldOwner, address newOwner);
    event ToggleAdderEvent(
        address indexed owner,
        address indexed adder,
        bool indexed newBool
    );
    event ToggleSubtractorEvent(
        address indexed owner,
        address indexed subtractor,
        bool indexed newBool
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../interfaces/IERC20Minimal.sol";

contract TestERC20 is IERC20Minimal {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(uint256 amountToMint) {
        mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 amount) public {
        uint256 balanceNext = balanceOf[to] + amount;
        require(balanceNext >= amount, "overflow balance");
        balanceOf[to] = balanceNext;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        uint256 balanceBefore = balanceOf[msg.sender];
        require(balanceBefore >= amount, "insufficient balance");
        balanceOf[msg.sender] = balanceBefore - amount;

        uint256 balanceRecipient = balanceOf[recipient];
        require(
            balanceRecipient + amount >= balanceRecipient,
            "recipient balance overflow"
        );
        balanceOf[recipient] = balanceRecipient + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 allowanceBefore = allowance[sender][msg.sender];
        require(allowanceBefore >= amount, "allowance insufficient");

        allowance[sender][msg.sender] = allowanceBefore - amount;

        uint256 balanceRecipient = balanceOf[recipient];
        require(
            balanceRecipient + amount >= balanceRecipient,
            "overflow balance recipient"
        );
        balanceOf[recipient] = balanceRecipient + amount;
        uint256 balanceSender = balanceOf[sender];
        require(balanceSender >= amount, "underflow balance sender");
        balanceOf[sender] = balanceSender - amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint balance);
}

/// @title Faucet
contract Faucet {

    address public owner;
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    mapping (address => mapping (address => bool)) internal userTokenDropped;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwnerAddress) public isOwner {
        owner = newOwnerAddress;
    }

    function drop(IERC20 token) public {
        require(!userTokenDropped[msg.sender][address(token)], "Already requested");
        uint amount = 100 * 1e18;
        require(token.balanceOf(address(this)) >= amount);
        userTokenDropped[msg.sender][address(token)] = true;
        require(token.transfer(msg.sender, amount));
    }

    function reclaim(IERC20 token) public isOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is
    IAccessControlEnumerable,
    AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
    constructor() {
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

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is
    Context,
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}