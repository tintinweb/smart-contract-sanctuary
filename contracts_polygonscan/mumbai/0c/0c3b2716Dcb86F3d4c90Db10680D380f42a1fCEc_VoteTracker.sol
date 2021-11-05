// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IVoteTracker.sol";
import "../interfaces/IBalanceTracker.sol";

import "../interfaces/events/EventWrapper.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/Math.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interfaces/events/EventReceiver.sol";
import "../interfaces/structs/UserVotePayload.sol";

contract VoteTracker is Initializable, EventReceiver, IVoteTracker, Ownable, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant ONE_WITH_EIGHTEEN_PRECISION = 1_000_000_000_000_000_000;

    /// @dev EIP191 header for EIP712 prefix
    string public constant EIP191_HEADER = "\x19\x01";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant USER_VOTE_PAYLOAD_TYPEHASH =
        keccak256(
            "UserVotePayload(address account,bytes32 voteSessionKey,uint256 nonce,uint256 chainId,uint256 totalVotes,UserVoteAllocationItem[] allocations)UserVoteAllocationItem(bytes32 reactorKey,uint256 amount)"
        );

    bytes32 public constant USER_VOTE_ALLOCATION_ITEM_TYPEHASH =
        keccak256("UserVoteAllocationItem(bytes32 reactorKey,uint256 amount)");

    bytes32 public constant DOMAIN_NAME = keccak256("Tokemak Voting");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");

    bytes32 public constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
    bytes32 public constant EVENT_TYPE_TRANSFER = bytes32("Transfer");
    bytes32 public constant EVENT_TYPE_SLASH = bytes32("Slash");
    bytes32 public constant EVENT_TYPE_WITHDRAW = bytes32("Withdraw");
    bytes32 public constant EVENT_TYPE_CYCLECOMPLETE = bytes32("Cycle Complete");
    bytes32 public constant EVENT_TYPE_VOTE = bytes32("Vote");

    //Normally these would only be generated during construction against the current chain id
    //However, our users will be signing while connected to mainnet so we'll need a diff
    //chainId than we're running on. We'll validate the intended chain in the message itself
    //against the actual chain the contract is running on.
    bytes32 public currentDomainSeparator;
    uint256 public currentSigningChainId;

    //For when the users decide to connect to the network and submit directly
    //We'll want domain to be the actual chain
    NetworkSettings public networkSettings;

    /// @dev All publically accessible but you can use getUserVotes() to pull it all together
    mapping(address => UserVoteDetails) public userVoteDetails;
    mapping(address => bytes32[]) public userVoteKeys;
    mapping(address => mapping(bytes32 => uint256)) public userVoteItems;

    /// @dev Stores the users next valid vote nonce
    mapping(address => uint256) public override userNonces;

    /// @dev Stores the last block during which a user voted through our proxy
    mapping(address => uint256) public override lastUserProxyVoteBlock;

    VoteTrackSettings public settings;

    address[] public votingTokens;
    mapping(address => uint256) public voteMultipliers;

    /// @dev Total of all user aggregations
    /// @dev getSystemAggregation() to reconstruct
    EnumerableSet.Bytes32Set private allowedreactorKeys;
    mapping(bytes32 => uint256) public systemAggregations;
    mapping(bytes32 => address) public placementTokens;

    mapping(address => bool) public override proxySubmitters;

    // solhint-disable-next-line func-visibility
    function initialize(
        address eventProxy,
        bytes32 initialVoteSession,
        address balanceTracker,
        uint256 signingOnChain,
        VoteTokenMultipler[] memory voteTokens
    ) public initializer {
        require(initialVoteSession.length > 0, "INVALID_SESSION_KEY");
        require(voteTokens.length > 0, "NO_VOTE_TOKENS");

        __Ownable_init_unchained();
        __Pausable_init_unchained();

        EventReceiver.init(eventProxy);

        settings.voteSessionKey = initialVoteSession;
        settings.balanceTrackerAddress = balanceTracker;

        setVoteMultiplers(voteTokens);

        setSigningChainId(signingOnChain);

        networkSettings.chainId = _getChainID();
        networkSettings.domainSeparator = _buildDomainSeparator(_getChainID());
    }

    /// @notice Vote for the assets and reactors you wish to see liquidity deployed for
    /// @param userVotePayload Users vote percent breakdown
    /// @param signature Account signature
    function vote(
        UserVotePayload memory userVotePayload,
        Signature memory signature
    ) external override whenNotPaused {
        uint256 domainChain = _getChainID();

        require(domainChain == userVotePayload.chainId, "INVALID_PAYLOAD_CHAIN");

        // Rate limiting when using our proxy apis
        // Users can only submit every X blocks
        if (proxySubmitters[msg.sender]) {
            require(
                lastUserProxyVoteBlock[userVotePayload.account].add(settings.voteEveryBlockLimit) <
                    block.number,
                "TOO_FREQUENT_VOTING"
            );
            lastUserProxyVoteBlock[userVotePayload.account] = block.number;
            domainChain = currentSigningChainId;
        }

        // Validate the signer is the account the votes are on behalf of
        address signatureSigner = _hash(domainChain, userVotePayload, signature.signatureType).recover(signature.v, signature.r, signature.s);
        require(signatureSigner == userVotePayload.account, "MISMATCH_SIGNER");

        _vote(userVotePayload);
    }

    function voteDirect(UserVotePayload memory userVotePayload) external override whenNotPaused {
        require(msg.sender == userVotePayload.account, "MUST_BE_SENDER");
        require(userVotePayload.chainId == networkSettings.chainId, "INVALID_PAYLOAD_CHAIN");
        
        _vote(userVotePayload);
    }

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts list that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) public override {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(account != address(0), "INVALID_ADDRESS");

            bytes32[] memory keys = userVoteKeys[account];
            uint256 maxAvailableVotes = getMaxVoteBalance(account);
            uint256 maxVotesToUse = Math.min(
                maxAvailableVotes,
                userVoteDetails[account].totalUsedVotes
            );

            //Grab their current aggregation and back it out of the system aggregation
            bytes32[] storage currentAccountVoteKeys = userVoteKeys[account];
            uint256 userAggLength = currentAccountVoteKeys.length;

            if (userAggLength > 0) {
                for (uint256 i = userAggLength; i > 0; i--) {
                    uint256 amt = userVoteItems[account][currentAccountVoteKeys[i - 1]];
                    systemAggregations[currentAccountVoteKeys[i - 1]] = systemAggregations[
                        currentAccountVoteKeys[i - 1]
                    ].sub(amt);
                    currentAccountVoteKeys.pop();
                }
            }

            //Compute new aggregations
            if (maxVotesToUse > 0) {
                for (uint256 j = 0; j < keys.length; j++) {
                    UserVoteAllocationItem memory placement = UserVoteAllocationItem({
                        reactorKey: keys[j],
                        amount: userVoteItems[account][keys[j]]
                    });

                    placement.amount = maxVotesToUse.mul(placement.amount).div(userVoteDetails[account].totalUsedVotes);

                    //Update user aggregation
                    userVoteItems[account][placement.reactorKey] = placement.amount;
                    userVoteKeys[account].push(placement.reactorKey);

                    //Update system aggregation
                    systemAggregations[placement.reactorKey] = systemAggregations[
                        placement.reactorKey
                    ].add(placement.amount);
                }
            }

            //Call here emits
            //Update users aggregation details
            userVoteDetails[account] = UserVoteDetails({
                totalUsedVotes: maxVotesToUse,
                totalAvailableVotes: maxAvailableVotes
            });

            emit UserAggregationUpdated(account);
        }
    }

    function getUserVotes(address account) external view override returns (UserVotes memory) {
        bytes32[] memory keys = userVoteKeys[account];
        UserVoteAllocationItem[] memory placements = new UserVoteAllocationItem[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            placements[i] = UserVoteAllocationItem({
                reactorKey: keys[i],
                amount: userVoteItems[account][keys[i]]
            });
        }
        return UserVotes({votes: placements, details: userVoteDetails[account]});
    }

    function getSystemVotes() public view override returns (SystemVotes memory systemVotes) {
        uint256 placements = allowedreactorKeys.length();
        SystemAllocation[] memory votes = new SystemAllocation[](placements);
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < placements; i++) {
            votes[i] = SystemAllocation({
                reactorKey: allowedreactorKeys.at(i),
                totalVotes: systemAggregations[allowedreactorKeys.at(i)],
                token: placementTokens[allowedreactorKeys.at(i)]
            });
            totalVotes = totalVotes.add(votes[i].totalVotes);
        }

        systemVotes = SystemVotes({
            details: SystemVoteDetails({
                voteSessionKey: settings.voteSessionKey,
                totalVotes: totalVotes
            }),
            votes: votes
        });
    }

    function getMaxVoteBalance(address account) public view override returns (uint256) {
        TokenBalance[] memory balances = IBalanceTracker(settings.balanceTrackerAddress).getBalance(
            account,
            votingTokens
        );
        return _getVotingPower(balances);
    }

    function getVotingPower(TokenBalance[] memory balances)
        external
        view
        override
        returns (uint256 votes)
    {
        votes = _getVotingPower(balances);
    }

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setBalanceTrackerAddress(address contractAddress) external override onlyOwner {
        settings.balanceTrackerAddress = contractAddress;

        emit BalanceTrackerAddressSet(contractAddress);
    }

    function setProxySubmitters(address[] calldata submitters, bool allowed)
        public
        override
        onlyOwner
    {
        uint256 length = submitters.length;
        for (uint256 i = 0; i < length; i++) {
            proxySubmitters[submitters[i]] = allowed;
        }

        emit ProxySubmitterSet(submitters, allowed);
    }

    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed)
        public
        override
        onlyOwner
    {
        uint256 length = reactorKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (allowed) {
                allowedreactorKeys.add(reactorKeys[i].key);
                placementTokens[reactorKeys[i].key] = reactorKeys[i].token;
            } else {
                allowedreactorKeys.remove(reactorKeys[i].key);
                delete placementTokens[reactorKeys[i].key];
            }
        }

        bytes32[] memory validKeys = getReactorKeys();

        emit ReactorKeysSet(validKeys);
    }

    function setSigningChainId(uint256 chainId) public override onlyOwner {
        currentSigningChainId = chainId;
        currentDomainSeparator = _buildDomainSeparator(chainId);

        emit SigningChainIdSet(chainId);
    }

    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) public override onlyOwner {
        uint256 votingTokenLength = votingTokens.length;
        if (votingTokenLength > 0) {
            for (uint256 i = votingTokenLength; i > 0; i--) {
                votingTokens.pop();
            }
        }

        for (uint256 i = 0; i < multipliers.length; i++) {
            voteMultipliers[multipliers[i].token] = multipliers[i].multiplier;
            votingTokens.push(multipliers[i].token);
        }

        emit VoteMultipliersSet(multipliers);
    }

    function getVotingTokens() external view override returns (address[] memory tokens) {
        uint256 length = votingTokens.length;
        tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = votingTokens[i];
        }
    }

    function setProxyRateLimit(uint256 voteEveryBlockLimit) external override onlyOwner {
        settings.voteEveryBlockLimit = voteEveryBlockLimit;

        emit ProxyRateLimitSet(voteEveryBlockLimit);
    }

    function getReactorKeys() public view override returns (bytes32[] memory reactorKeys) {
        uint256 length = allowedreactorKeys.length();
        reactorKeys = new bytes32[](length);

        for (uint256 i = 0; i < length; i++) {
            reactorKeys[i] = allowedreactorKeys.at(i);
        }
    }

    function getSettings() external view override returns (VoteTrackSettings memory) {
        return settings;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _onEventReceive(
        address,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual override {
        if (eventType == EVENT_TYPE_CYCLECOMPLETE) {
            _onCycleRollover(data);
        } else if (
            eventType == EVENT_TYPE_DEPOSIT ||
            eventType == EVENT_TYPE_TRANSFER ||
            eventType == EVENT_TYPE_WITHDRAW ||
            eventType == EVENT_TYPE_SLASH
        ) {
            _onBalanceChange(data);
        } else if (eventType == EVENT_TYPE_VOTE) {
            _onEventVote(data);
        } else {
            revert("INVALID_EVENT_TYPE");
        }
    }

    function _removeUserVoteKey(address account, bytes32 reactorKey) internal whenNotPaused {
        uint256 i = 0;
        bool deleted = false;
        while (i < userVoteKeys[account].length && !deleted) {
            if (userVoteKeys[account][i] == reactorKey) {
                userVoteKeys[account][i] = userVoteKeys[account][userVoteKeys[account].length - 1];
                userVoteKeys[account].pop();
                deleted = true;
            }
            i++;
        }
    }

    function _vote(UserVotePayload memory userVotePayload) internal whenNotPaused {
        address account = userVotePayload.account;
        uint256 totalUsedVotes = userVoteDetails[account].totalUsedVotes;

        require(
            settings.voteSessionKey == userVotePayload.voteSessionKey,
            "NOT_CURRENT_VOTE_SESSION"
        );
        require(userNonces[account] == userVotePayload.nonce, "INVALID_NONCE");

        // Ensure the message cannot be replayed
        userNonces[userVotePayload.account] = userNonces[userVotePayload.account].add(1);

        for (uint256 i = 0; i < userVotePayload.allocations.length; i++) {
            bytes32 reactorKey = userVotePayload.allocations[i].reactorKey;
            uint256 amount = userVotePayload.allocations[i].amount;

            //Ensure where they are voting is allowed
            require(allowedreactorKeys.contains(reactorKey), "PLACEMENT_NOT_ALLOWED");

            // check if user has already voted for this reactor
            if (userVoteItems[account][reactorKey] > 0) {
                if (amount == 0) {
                    _removeUserVoteKey(account, reactorKey);
                }

                uint256 currentAmount = userVoteItems[account][reactorKey];

                // increase or decrease systemAggregations[reactorKey] by the difference between currentAmount and amount
                if (currentAmount > amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey].sub(
                        currentAmount - amount
                    );
                    totalUsedVotes = totalUsedVotes.sub(currentAmount - amount);
                } else if (currentAmount < amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey].add(
                        amount - currentAmount
                    );
                    totalUsedVotes = totalUsedVotes.add(amount - currentAmount);
                }
                userVoteItems[account][reactorKey] = amount;
            } else {
                userVoteKeys[account].push(reactorKey);
                userVoteItems[account][reactorKey] = amount;
                systemAggregations[reactorKey] = systemAggregations[reactorKey].add(amount);
                totalUsedVotes = totalUsedVotes.add(amount);
            }
        }

        require(totalUsedVotes == userVotePayload.totalVotes, "VOTE_TOTAL_MISMATCH");

        uint256 totalAvailableVotes = getMaxVoteBalance(account);
        require(totalUsedVotes <= totalAvailableVotes, "NOT_ENOUGH_VOTES");

        //Update users aggregation details
        userVoteDetails[account] = UserVoteDetails({
            totalUsedVotes: totalUsedVotes,
            totalAvailableVotes: totalAvailableVotes
        });

        emit UserVoted(userVotePayload.account, userVotePayload);
    }

    function _onEventVote(bytes calldata data) private {
        (, bytes memory e) = abi.decode(data, (bytes32, bytes));

        UserVotePayload memory userVotePayload = abi.decode(e, (UserVotePayload));

        uint256 domainChain = _getChainID();

        require(domainChain == userVotePayload.chainId, "INVALID_PAYLOAD_CHAIN");
        _vote(userVotePayload);
    }

    function _getVotingPower(TokenBalance[] memory balances) private view returns (uint256 votes) {
        for (uint256 i = 0; i < balances.length; i++) {
            votes = votes.add(
                balances[i].amount.mul(voteMultipliers[balances[i].token]).div(
                    ONE_WITH_EIGHTEEN_PRECISION
                )
            );
        }
    }

    function _onCycleRollover(bytes calldata data) private {
        SystemVotes memory lastAgg = getSystemVotes();
        CycleRolloverEvent memory e = abi.decode(data, (CycleRolloverEvent));
        bytes32 newKey = bytes32(e.cycleIndex);
        settings.voteSessionKey = newKey;
        emit VoteSessionRollover(newKey, lastAgg);
    }

    function _onBalanceChange(bytes calldata data) private {
        BalanceUpdateEvent memory e = abi.decode(data, (BalanceUpdateEvent));
        address[] memory accounts = new address[](1);
        accounts[0] = e.account;
        updateUserVoteTotals(accounts);
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function _domainSeparatorV4(uint256 domainChain) internal view virtual returns (bytes32) {
        if (domainChain == currentSigningChainId) {
            return currentDomainSeparator;
        } else if (domainChain == networkSettings.chainId) {
            return networkSettings.domainSeparator;
        } else {
            return _buildDomainSeparator(domainChain);
        }
    }

    function _buildDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    chainId,
                    address(this)
                )
            );
    }

    function _hash(uint256 domainChain, UserVotePayload memory userVotePayload, SignatureType signatureType)
        private
        view
        returns (bytes32)
    {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(domainChain),
                _hashUserVotePayload(userVotePayload)
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _hashUserVotePayload(UserVotePayload memory userVote) private pure returns (bytes32) {
        bytes32[] memory encodedVotes = new bytes32[](userVote.allocations.length);
        for (uint256 ix = 0; ix < userVote.allocations.length; ix++) {
            encodedVotes[ix] = _hashUserVoteAllocationItem(userVote.allocations[ix]);
        }

        return
            keccak256(
                abi.encode(
                    USER_VOTE_PAYLOAD_TYPEHASH,
                    userVote.account,
                    userVote.voteSessionKey,
                    userVote.nonce,
                    userVote.chainId,
                    userVote.totalVotes,
                    keccak256(abi.encodePacked(encodedVotes))
                )
            );
    }

    function _hashUserVoteAllocationItem(UserVoteAllocationItem memory voteAllocation)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    USER_VOTE_ALLOCATION_ITEM_TYPEHASH,
                    voteAllocation.reactorKey,
                    voteAllocation.amount
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./events/IEventReceiver.sol";
import "./structs/TokenBalance.sol";
import "./structs/UserVotePayload.sol";

interface IVoteTracker is IEventReceiver {

    //Collpased simple settings
    struct VoteTrackSettings {
        address balanceTrackerAddress;
        uint256 voteEveryBlockLimit;
        uint256 lastProcessedEventId;
        bytes32 voteSessionKey;
    }

    //Colapsed NETWORK settings
    struct NetworkSettings {
        bytes32 domainSeparator;
        uint256 chainId;
    }

    struct UserVotes {
        UserVoteDetails details;
        UserVoteAllocationItem[] votes;
    }

    struct UserVoteDetails {
        uint256 totalUsedVotes;
        uint256 totalAvailableVotes;
    }

    struct SystemVotes {
        SystemVoteDetails details;
        SystemAllocation[] votes;
    }

    struct SystemVoteDetails {
        bytes32 voteSessionKey;
        uint256 totalVotes;
    }

    struct SystemAllocation {
        address token;
        bytes32 reactorKey;
        uint256 totalVotes;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct VoteTokenMultipler {
        address token;
        uint256 multiplier;
    }    

    struct VotingLocation {
        address token;
        bytes32 key;         
    }

    enum SignatureType {
        INVALID,
        EIP712,
        ETHSIGN
    }

    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event UserAggregationUpdated(address account);
    event UserVoted(address account, UserVotePayload votes); 
    event VoteSessionRollover(bytes32 newKey, SystemVotes votesAtRollover);
    event BalanceTrackerAddressSet(address contractAddress);
    event ProxySubmitterSet(address[] accounts, bool allowed);
    event ReactorKeysSet(bytes32[] allValidKeys);
    event VoteMultipliersSet(VoteTokenMultipler[] multipliers);
    event ProxyRateLimitSet(uint256 voteEveryBlockLimit);
    event SigningChainIdSet(uint256 chainId);
    
    /// @notice Get the current nonce an account should use to vote with
    /// @param account Account to query
    /// @return nonce Nonce that shoul dbe used to vote with
    function userNonces(address account) external returns (uint256 nonce);

    /// @notice Get the last block a user submitted a vote through a relayer
    /// @param account Account to check
    /// @return blockNumber
    function lastUserProxyVoteBlock(address account) external returns (uint256 blockNumber);

    /// @notice Check if an account is currently configured as a relayer
    /// @param account Account to check
    /// @return allowed
    function proxySubmitters(address account) external returns (bool allowed);

    /// @notice Get the tokens that are currently used to calculate voting power
    /// @return tokens 
    function getVotingTokens() external view returns (address[] memory tokens);

    /// @notice Allows backfilling of current balance
    /// @param userVotePayload Users vote percent breakdown
    /// @param signature Account signature
    function vote(UserVotePayload calldata userVotePayload, Signature memory signature) external;

    function voteDirect(UserVotePayload memory userVotePayload) external;

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) external;

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setBalanceTrackerAddress(address contractAddress) external;

    /// @notice Toggle the accounts that are currently used to relay votes and thus subject to rate limits
    /// @param submitters Relayer account array
    /// @param allowed Add or remove the account
    function setProxySubmitters(address[] calldata submitters, bool allowed) external;

    /// @notice Get the reactors we are currently accepting votes for
    /// @return reactorKeys Reactor keys we are currently accepting
    function getReactorKeys() external view returns (bytes32[] memory reactorKeys);

    /// @notice Set the reactors that we are currently accepting votes for
    /// @param reactorKeys Array for token+key where token is the underlying ERC20 for the reactor and key is asset-default|exchange
    /// @param allowed Add or remove the keys from use  
    /// @dev Only current reactor keys will be returned from getSystemVotes()  
    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed) external;

    /// @notice Changes the chain id users will sign their vote messages on
    /// @param chainId Chain id the users will be connected to when they vote
    function setSigningChainId(uint256 chainId) external;

    /// @notice Current votes for the account
    /// @param account Account to get votes for
    /// @return Votes for the current account
    function getUserVotes(address account) external view returns(UserVotes memory);

    /// @notice Current total votes for the system
    /// @return systemVotes
    function getSystemVotes() external view returns(SystemVotes memory systemVotes);    

    /// @notice Get the current voting power for an account
    /// @param account Account to check
    /// @return Current voting power
    function getMaxVoteBalance(address account) external view returns (uint256);

    /// @notice Given a set of token balances, determine the voting power given current multipliers
    /// @param balances Token+Amount to use for calculating votes
    /// @return votes Voting power
    function getVotingPower(TokenBalance[] memory balances) external view returns (uint256 votes);

    /// @notice Set the voting power tokens get
    /// @param multipliers Token and multipliers to set. Multipliers should have 18 precision
    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) external;

    /// @notice Set the rate limit for using the proxy submission route
    /// @param voteEveryBlockLimit Minimum block gap between proxy submissions
    function setProxyRateLimit(uint256 voteEveryBlockLimit) external;

    /// @notice Returns general settings and current system vote details
    function getSettings() external view returns (VoteTrackSettings memory settings);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./events/IEventReceiver.sol";
import "./structs/TokenBalance.sol";

interface IBalanceTracker is IEventReceiver {


    struct SetTokenBalance {
        address account;
        address token;
        uint256 amount;
    }

    /// @param account User address
    /// @param token Token address
    /// @param amount User balance set for the user-token key
    /// @param stateSynced True if the event is from the L1 to L2 state sync. False if backfill
    /// @param applied False if the update was not actually recorded. Only applies to backfill updates that are skipped
    event BalanceUpdate(address account, address token, uint256 amount, bool stateSynced, bool applied);

    /// @notice Retrieve the current balances for the supplied account and tokens
    function getBalance(address account, address[] calldata tokens) external view returns (TokenBalance[] memory userBalances);

    /// @notice Allows backfilling of current balance
    /// @dev onlyOwner. Only allows unset balances to be updated
    function setBalance(SetTokenBalance[] calldata balances) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct EventWrapper {
    bytes32 eventType;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IEventReceiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

abstract contract EventReceiver is Initializable, IEventReceiver {
    
    address public eventProxy;

    event ProxyAddressSet(address proxyAddress);

    function init(address eventProxyAddress) public initializer {
        require(eventProxyAddress != address(0), "INVALID_ROOT_PROXY");   

        _setEventProxyAddress(eventProxyAddress);
    }

    function onEventReceive(address sender, bytes32 eventType, bytes calldata data) external override {
        require(msg.sender == eventProxy, "EVENT_PROXY_ONLY");

        _onEventReceive(sender, eventType, data);
    }

    //solhint-disable-next-line no-unused-vars
    function _onEventReceive(address sender, bytes32 eventType, bytes calldata data) internal virtual;
    
    function _setEventProxyAddress(address eventProxyAddress) private {
        eventProxy = eventProxyAddress;

        emit ProxyAddressSet(eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

struct UserVotePayload {
    address account;
    bytes32 voteSessionKey;
    uint256 nonce;
    uint256 chainId;
    uint256 totalVotes;
    UserVoteAllocationItem[] allocations;
}

struct UserVoteAllocationItem {
    bytes32 reactorKey; //asset-default, in actual deployment could be asset-exchange
    uint256 amount; //18 Decimals
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IEventReceiver {

    function onEventReceive(address sender, bytes32 eventType, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

struct TokenBalance {
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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