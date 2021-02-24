// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import "./interfaces/IVotingPowerFormula.sol";
import "./lib/SafeMath.sol";
import "./lib/ReentrancyGuardUpgradeSafe.sol";
import "./lib/PrismProxyImplementation.sol";
import "./lib/VotingPowerStorage.sol";
import "./lib/SafeERC20.sol";

/**
 * @title VotingPower
 * @dev Implementation contract for voting power prism proxy
 * Calls should not be made directly to this contract, instead make calls to the VotingPowerPrism proxy contract
 * The exception to this is the `become` function specified in PrismProxyImplementation 
 * This function is called once and is used by this contract to accept its role as the implementation for the prism proxy
 */
contract VotingPower is PrismProxyImplementation, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice An event that's emitted when a user's staked balance increases
    event Staked(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);

    /// @notice An event that's emitted when a user's staked balance decreases
    event Withdrawn(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);

    /// @notice An event that's emitted when an account's vote balance changes
    event VotingPowerChanged(address indexed voter, uint256 indexed previousBalance, uint256 indexed newBalance);

    /// @notice Event emitted when the owner of the voting power contract is updated
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

    /// @notice restrict functions to just owner address
    modifier onlyOwner {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(app.owner == address(0) || msg.sender == app.owner, "only owner");
        _;
    }

    /**
     * @notice Initialize VotingPower contract
     * @dev Should be called via VotingPowerPrism before calling anything else
     * @param _archToken address of ARCH token
     * @param _vestingContract address of Vesting contract
     */
    function initialize(
        address _archToken,
        address _vestingContract
    ) public initializer {
        __ReentrancyGuard_init_unchained();
        AppStorage storage app = VotingPowerStorage.appStorage();
        app.archToken = IArchToken(_archToken);
        app.vesting = IVesting(_vestingContract);
    }

    /**
     * @notice Address of ARCH token
     * @return Address of ARCH token
     */
    function archToken() public view returns (address) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return address(app.archToken);
    }

    /**
     * @notice Decimals used for voting power
     * @return decimals
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Address of vesting contract
     * @return Address of vesting contract
     */
    function vestingContract() public view returns (address) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return address(app.vesting);
    }

    /**
     * @notice Address of token registry
     * @return Address of token registry
     */
    function tokenRegistry() public view returns (address) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return address(app.tokenRegistry);
    }

    /**
     * @notice Address of lockManager
     * @return Address of lockManager
     */
    function lockManager() public view returns (address) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return app.lockManager;
    }

    /**
     * @notice Address of owner
     * @return Address of owner
     */
    function owner() public view returns (address) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return app.owner;
    }

    /**
     * @notice Sets token registry address
     * @param registry Address of token registry
     */
    function setTokenRegistry(address registry) public onlyOwner {
        AppStorage storage app = VotingPowerStorage.appStorage();
        app.tokenRegistry = ITokenRegistry(registry);
    }

    /**
     * @notice Sets lockManager address
     * @param newLockManager Address of lockManager
     */
    function setLockManager(address newLockManager) public onlyOwner {
        AppStorage storage app = VotingPowerStorage.appStorage();
        app.lockManager = newLockManager;
    }

    /**
     * @notice Change owner of vesting contract
     * @param newOwner New owner address
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0) && newOwner != address(this), "VP::changeOwner: not valid address");
        AppStorage storage app = VotingPowerStorage.appStorage();
        emit ChangedOwner(app.owner, newOwner);
        app.owner = newOwner;   
    }

    /**
     * @notice Stake ARCH tokens using offchain approvals to unlock voting power
     * @param amount The amount to stake
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function stakeWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "VP::stakeWithPermit: cannot stake 0");
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(app.archToken.balanceOf(msg.sender) >= amount, "VP::stakeWithPermit: not enough tokens");

        app.archToken.permit(msg.sender, address(this), amount, deadline, v, r, s);

        _stake(msg.sender, address(app.archToken), amount, amount);
    }

    /**
     * @notice Stake ARCH tokens to unlock voting power for `msg.sender`
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external nonReentrant {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(amount > 0, "VP::stake: cannot stake 0");
        require(app.archToken.balanceOf(msg.sender) >= amount, "VP::stake: not enough tokens");
        require(app.archToken.allowance(msg.sender, address(this)) >= amount, "VP::stake: must approve tokens before staking");

        _stake(msg.sender, address(app.archToken), amount, amount);
    }

    /**
     * @notice Stake LP tokens to unlock voting power for `msg.sender`
     * @param token The token to stake
     * @param amount The amount to stake
     */
    function stake(address token, uint256 amount) external nonReentrant {
        IERC20 lptoken = IERC20(token);
        require(amount > 0, "VP::stake: cannot stake 0");
        require(lptoken.balanceOf(msg.sender) >= amount, "VP::stake: not enough tokens");
        require(lptoken.allowance(msg.sender, address(this)) >= amount, "VP::stake: must approve tokens before staking");

        AppStorage storage app = VotingPowerStorage.appStorage();
        address tokenFormulaAddress = app.tokenRegistry.tokenFormulas(token);
        require(tokenFormulaAddress != address(0), "VP::stake: token not supported");
        
        IVotingPowerFormula tokenFormula = IVotingPowerFormula(tokenFormulaAddress);
        uint256 votingPower = tokenFormula.convertTokensToVotingPower(amount);
        _stake(msg.sender, token, amount, votingPower);
    }

    /**
     * @notice Count vesting ARCH tokens toward voting power for `account`
     * @param account The recipient of voting power
     * @param amount The amount of voting power to add
     */
    function addVotingPowerForVestingTokens(address account, uint256 amount) external nonReentrant {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(amount > 0, "VP::addVPforVT: cannot add 0 voting power");
        require(msg.sender == address(app.vesting), "VP::addVPforVT: only vesting contract");

        _increaseVotingPower(account, amount);
    }

    /**
     * @notice Remove claimed vesting ARCH tokens from voting power for `account`
     * @param account The account with voting power
     * @param amount The amount of voting power to remove
     */
    function removeVotingPowerForClaimedTokens(address account, uint256 amount) external nonReentrant {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(amount > 0, "VP::removeVPforCT: cannot remove 0 voting power");
        require(msg.sender == address(app.vesting), "VP::removeVPforCT: only vesting contract");

        _decreaseVotingPower(account, amount);
    }

    /**
     * @notice Count locked tokens toward voting power for `account`
     * @param account The recipient of voting power
     * @param amount The amount of voting power to add
     */
    function addVotingPowerForLockedTokens(address account, uint256 amount) external nonReentrant {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(amount > 0, "VP::addVPforLT: cannot add 0 voting power");
        require(msg.sender == app.lockManager, "VP::addVPforLT: only lockManager contract");

        _increaseVotingPower(account, amount);
    }

    /**
     * @notice Remove unlocked tokens from voting power for `account`
     * @param account The account with voting power
     * @param amount The amount of voting power to remove
     */
    function removeVotingPowerForUnlockedTokens(address account, uint256 amount) external nonReentrant {
        AppStorage storage app = VotingPowerStorage.appStorage();
        require(amount > 0, "VP::removeVPforUT: cannot remove 0 voting power");
        require(msg.sender == app.lockManager, "VP::removeVPforUT: only lockManager contract");

        _decreaseVotingPower(account, amount);
    }

    /**
     * @notice Withdraw staked ARCH tokens, removing voting power for `msg.sender`
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "VP::withdraw: cannot withdraw 0");
        AppStorage storage app = VotingPowerStorage.appStorage();
        _withdraw(msg.sender, address(app.archToken), amount, amount);
    }

    /**
     * @notice Withdraw staked LP tokens, removing voting power for `msg.sender`
     * @param token The token to withdraw
     * @param amount The amount to withdraw
     */
    function withdraw(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "VP::withdraw: cannot withdraw 0");
        Stake memory s = getStake(msg.sender, token);
        uint256 vpToWithdraw = amount.mul(s.votingPower).div(s.amount);
        _withdraw(msg.sender, token, amount, vpToWithdraw);
    }

    /**
     * @notice Get total amount of ARCH tokens staked in contract by `staker`
     * @param staker The user with staked ARCH
     * @return total ARCH amount staked
     */
    function getARCHAmountStaked(address staker) public view returns (uint256) {
        return getARCHStake(staker).amount;
    }

    /**
     * @notice Get total amount of tokens staked in contract by `staker`
     * @param staker The user with staked tokens
     * @param stakedToken The staked token
     * @return total amount staked
     */
    function getAmountStaked(address staker, address stakedToken) public view returns (uint256) {
        return getStake(staker, stakedToken).amount;
    }

    /**
     * @notice Get staked amount and voting power from ARCH tokens staked in contract by `staker`
     * @param staker The user with staked ARCH
     * @return total ARCH staked
     */
    function getARCHStake(address staker) public view returns (Stake memory) {
        AppStorage storage app = VotingPowerStorage.appStorage();
        return getStake(staker, address(app.archToken));
    }

    /**
     * @notice Get total staked amount and voting power from `stakedToken` staked in contract by `staker`
     * @param staker The user with staked tokens
     * @param stakedToken The staked token
     * @return total staked
     */
    function getStake(address staker, address stakedToken) public view returns (Stake memory) {
        StakeStorage storage ss = VotingPowerStorage.stakeStorage();
        return ss.stakes[staker][stakedToken];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function balanceOf(address account) public view returns (uint256) {
        CheckpointStorage storage cs = VotingPowerStorage.checkpointStorage();
        uint32 nCheckpoints = cs.numCheckpoints[account];
        return nCheckpoints > 0 ? cs.checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function balanceOfAt(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "VP::balanceOfAt: not yet determined");
        
        CheckpointStorage storage cs = VotingPowerStorage.checkpointStorage();
        uint32 nCheckpoints = cs.numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (cs.checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return cs.checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (cs.checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = cs.checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return cs.checkpoints[account][lower].votes;
    }

    /**
     * @notice Internal implementation of stake
     * @param voter The user that is staking tokens
     * @param token The token to stake
     * @param tokenAmount The amount of token to stake
     * @param votingPower The amount of voting power stake translates into
     */
    function _stake(address voter, address token, uint256 tokenAmount, uint256 votingPower) internal {
        IERC20(token).safeTransferFrom(voter, address(this), tokenAmount);

        StakeStorage storage ss = VotingPowerStorage.stakeStorage();
        ss.stakes[voter][token].amount = ss.stakes[voter][token].amount.add(tokenAmount);
        ss.stakes[voter][token].votingPower = ss.stakes[voter][token].votingPower.add(votingPower);

        emit Staked(voter, token, tokenAmount, votingPower);

        _increaseVotingPower(voter, votingPower);
    }

    /**
     * @notice Internal implementation of withdraw
     * @param voter The user with tokens staked
     * @param token The token that is staked
     * @param tokenAmount The amount of token to withdraw
     * @param votingPower The amount of voting power stake translates into
     */
    function _withdraw(address voter, address token, uint256 tokenAmount, uint256 votingPower) internal {
        StakeStorage storage ss = VotingPowerStorage.stakeStorage();
        require(ss.stakes[voter][token].amount >= tokenAmount, "VP::_withdraw: not enough tokens staked");
        require(ss.stakes[voter][token].votingPower >= votingPower, "VP::_withdraw: not enough voting power");
        ss.stakes[voter][token].amount = ss.stakes[voter][token].amount.sub(tokenAmount);
        ss.stakes[voter][token].votingPower = ss.stakes[voter][token].votingPower.sub(votingPower);
        
        IERC20(token).safeTransfer(voter, tokenAmount);

        emit Withdrawn(voter, token, tokenAmount, votingPower);
        
        _decreaseVotingPower(voter, votingPower);
    }

    /**
     * @notice Increase voting power of voter
     * @param voter The voter whose voting power is increasing 
     * @param amount The amount of voting power to increase by
     */
    function _increaseVotingPower(address voter, uint256 amount) internal {
        CheckpointStorage storage cs = VotingPowerStorage.checkpointStorage();
        uint32 checkpointNum = cs.numCheckpoints[voter];
        uint256 votingPowerOld = checkpointNum > 0 ? cs.checkpoints[voter][checkpointNum - 1].votes : 0;
        uint256 votingPowerNew = votingPowerOld.add(amount);
        _writeCheckpoint(voter, checkpointNum, votingPowerOld, votingPowerNew);
    }

    /**
     * @notice Decrease voting power of voter
     * @param voter The voter whose voting power is decreasing 
     * @param amount The amount of voting power to decrease by
     */
    function _decreaseVotingPower(address voter, uint256 amount) internal {
        CheckpointStorage storage cs = VotingPowerStorage.checkpointStorage();
        uint32 checkpointNum = cs.numCheckpoints[voter];
        uint256 votingPowerOld = checkpointNum > 0 ? cs.checkpoints[voter][checkpointNum - 1].votes : 0;
        uint256 votingPowerNew = votingPowerOld.sub(amount);
        _writeCheckpoint(voter, checkpointNum, votingPowerOld, votingPowerNew);
    }

    /**
     * @notice Create checkpoint of voting power for voter at current block number
     * @param voter The voter whose voting power is changing
     * @param nCheckpoints The current checkpoint number for voter
     * @param oldVotes The previous voting power of this voter
     * @param newVotes The new voting power of this voter
     */
    function _writeCheckpoint(address voter, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = _safe32(block.number, "VP::_writeCheckpoint: block number exceeds 32 bits");

      CheckpointStorage storage cs = VotingPowerStorage.checkpointStorage();
      if (nCheckpoints > 0 && cs.checkpoints[voter][nCheckpoints - 1].fromBlock == blockNumber) {
          cs.checkpoints[voter][nCheckpoints - 1].votes = newVotes;
      } else {
          cs.checkpoints[voter][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          cs.numCheckpoints[voter] = nCheckpoints + 1;
      }

      emit VotingPowerChanged(voter, oldVotes, newVotes);
    }

    /**
     * @notice Converts uint256 to uint32 safely
     * @param n Number
     * @param errorMessage Error message to use if number cannot be converted
     * @return uint32 number
     */
    function _safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IArchToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function mint(address dst, uint256 amount) external returns (bool);
    function burn(address src, uint256 amount) external returns (bool);
    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);
    function supplyManager() external view returns (address);
    function metadataManager() external view returns (address);
    function supplyChangeAllowedAfter() external view returns (uint256);
    function supplyChangeWaitingPeriod() external view returns (uint32);
    function supplyChangeWaitingPeriodMinimum() external view returns (uint32);
    function mintCap() external view returns (uint16);
    function setSupplyManager(address newSupplyManager) external returns (bool);
    function setMetadataManager(address newMetadataManager) external returns (bool);
    function setSupplyChangeWaitingPeriod(uint32 period) external returns (bool);
    function setMintCap(uint16 newCap) external returns (bool);
    event MintCapChanged(uint16 indexed oldMintCap, uint16 indexed newMintCap);
    event SupplyManagerChanged(address indexed oldManager, address indexed newManager);
    event SupplyChangeWaitingPeriodChanged(uint32 indexed oldWaitingPeriod, uint32 indexed newWaitingPeriod);
    event MetadataManagerChanged(address indexed oldManager, address indexed newManager);
    event TokenMetaUpdated(string indexed name, string indexed symbol);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ITokenRegistry {
    function owner() external view returns (address);
    function tokenFormulas(address) external view returns (address);
    function setTokenFormula(address token, address formula) external;
    function removeToken(address token) external;
    function changeOwner(address newOwner) external;
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event TokenAdded(address indexed token, address indexed formula);
    event TokenRemoved(address indexed token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IVault {
    
    struct Lock {
        address token;
        address receiver;
        uint48 startTime;
        uint16 vestingDurationInDays;
        uint16 cliffDurationInDays;
        uint256 amount;
        uint256 amountClaimed;
        uint256 votingPower;
    }

    struct LockBalance {
        uint256 id;
        uint256 claimableAmount;
        Lock lock;
    }

    struct TokenBalance {
        uint256 totalAmount;
        uint256 claimableAmount;
        uint256 claimedAmount;
        uint256 votingPower;
    }

    function lockTokens(address token, address locker, address receiver, uint48 startTime, uint256 amount, uint16 lockDurationInDays, uint16 cliffDurationInDays, bool grantVotingPower) external;
    function lockTokensWithPermit(address token, address locker, address receiver, uint48 startTime, uint256 amount, uint16 lockDurationInDays, uint16 cliffDurationInDays, bool grantVotingPower, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function claimUnlockedTokenAmounts(uint256[] memory lockIds, uint256[] memory amounts) external;
    function claimAllUnlockedTokens(uint256[] memory lockIds) external;
    function tokenLocks(uint256 lockId) external view returns(Lock memory);
    function allActiveLockIds() external view returns(uint256[] memory);
    function allActiveLocks() external view returns(Lock[] memory);
    function allActiveLockBalances() external view returns(LockBalance[] memory);
    function activeLockIds(address receiver) external view returns(uint256[] memory);
    function allLocks(address receiver) external view returns(Lock[] memory);
    function activeLocks(address receiver) external view returns(Lock[] memory);
    function activeLockBalances(address receiver) external view returns(LockBalance[] memory);
    function totalTokenBalance(address token) external view returns(TokenBalance memory balance);
    function tokenBalance(address token, address receiver) external view returns(TokenBalance memory balance);
    function lockBalance(uint256 lockId) external view returns (LockBalance memory);
    function claimableBalance(uint256 lockId) external view returns (uint256);
    function extendLock(uint256 lockId, uint16 vestingDaysToAdd, uint16 cliffDaysToAdd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IArchToken.sol";
import "./IVotingPower.sol";

interface IVesting {
    
    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint16 vestingDuration;
        uint16 vestingCliff;
        uint256 totalClaimed;
    }

    function owner() external view returns (address);
    function token() external view returns (IArchToken);
    function votingPower() external view returns (IVotingPower);
    function addTokenGrant(address recipient, uint256 startTime, uint256 amount, uint16 vestingDurationInDays, uint16 vestingCliffInDays) external;
    function getTokenGrant(address recipient) external view returns(Grant memory);
    function calculateGrantClaim(address recipient) external view returns (uint256);
    function vestedBalance(address account) external view returns (uint256);
    function claimedBalance(address recipient) external view returns (uint256);
    function claimVestedTokens(address recipient) external;
    function tokensVestedPerDay(address recipient) external view returns(uint256);
    function setVotingPowerContract(address newContract) external;
    function changeOwner(address newOwner) external;
    event GrantAdded(address indexed recipient, uint256 indexed amount, uint256 startTime, uint16 vestingDurationInDays, uint16 vestingCliffInDays);
    event GrantTokensClaimed(address indexed recipient, uint256 indexed amountClaimed);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangedVotingPower(address indexed oldContract, address indexed newContract);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/PrismProxy.sol";

interface IVotingPower {

    struct Stake {
        uint256 amount;
        uint256 votingPower;
    }

    function setPendingProxyImplementation(address newPendingImplementation) external returns (bool);
    function acceptProxyImplementation() external returns (bool);
    function setPendingProxyAdmin(address newPendingAdmin) external returns (bool);
    function acceptProxyAdmin() external returns (bool);
    function proxyAdmin() external view returns (address);
    function pendingProxyAdmin() external view returns (address);
    function proxyImplementation() external view returns (address);
    function pendingProxyImplementation() external view returns (address);
    function proxyImplementationVersion() external view returns (uint8);
    function become(PrismProxy prism) external;
    function initialize(address _archToken, address _vestingContract) external;
    function owner() external view returns (address);
    function archToken() external view returns (address);
    function vestingContract() external view returns (address);
    function tokenRegistry() external view returns (address);
    function lockManager() external view returns (address);
    function changeOwner(address newOwner) external;
    function setTokenRegistry(address registry) external;
    function setLockManager(address newLockManager) external;
    function stake(uint256 amount) external;
    function stakeWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 amount) external;
    function addVotingPowerForVestingTokens(address account, uint256 amount) external;
    function removeVotingPowerForClaimedTokens(address account, uint256 amount) external;
    function addVotingPowerForLockedTokens(address account, uint256 amount) external;
    function removeVotingPowerForUnlockedTokens(address account, uint256 amount) external;
    function getARCHAmountStaked(address staker) external view returns (uint256);
    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getARCHStake(address staker) external view returns (Stake memory);
    function getStake(address staker, address stakedToken) external view returns (Stake memory);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
    event NewPendingImplementation(address indexed oldPendingImplementation, address indexed newPendingImplementation);
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);
    event Staked(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);
    event Withdrawn(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);
    event VotingPowerChanged(address indexed voter, uint256 indexed previousBalance, uint256 indexed newBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IVotingPowerFormula {
    function convertTokensToVotingPower(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract PrismProxy {

    /// @notice Proxy admin and implementation storage variables
    struct ProxyStorage {
        // Administrator for this contract
        address admin;

        // Pending administrator for this contract
        address pendingAdmin;

        // Active implementation of this contract
        address implementation;

        // Pending implementation of this contract
        address pendingImplementation;

        // Implementation version of this contract
        uint8 version;
    }

    /// @dev Position in contract storage where prism ProxyStorage struct will be stored
    bytes32 constant PRISM_PROXY_STORAGE_POSITION = keccak256("prism.proxy.storage");

    /// @notice Emitted when pendingImplementation is changed
    event NewPendingImplementation(address indexed oldPendingImplementation, address indexed newPendingImplementation);

    /// @notice Emitted when pendingImplementation is accepted, which means implementation is updated
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @notice Load proxy storage struct from specified PRISM_PROXY_STORAGE_POSITION
     * @return ps ProxyStorage struct
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {        
        bytes32 position = PRISM_PROXY_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    /*** Admin Functions ***/
    
    /**
     * @notice Create new pending implementation for prism. msg.sender must be admin
     * @dev Admin function for proposing new implementation contract
     * @return boolean indicating success of operation
     */
    function setPendingProxyImplementation(address newPendingImplementation) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        require(msg.sender == s.admin, "Prism::setPendingProxyImp: caller must be admin");

        address oldPendingImplementation = s.pendingImplementation;

        s.pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Accepts new implementation for prism. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return boolean indicating success of operation
     */
    function acceptProxyImplementation() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == s.pendingImplementation && s.pendingImplementation != address(0), "Prism::acceptProxyImp: caller must be pending implementation");
 
        // Save current values for inclusion in log
        address oldImplementation = s.implementation;
        address oldPendingImplementation = s.pendingImplementation;

        s.implementation = s.pendingImplementation;

        s.pendingImplementation = address(0);
        s.version++;

        emit NewImplementation(oldImplementation, s.implementation);
        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return boolean indicating success of operation
     */
    function setPendingProxyAdmin(address newPendingAdmin) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller = admin
        require(msg.sender == s.admin, "Prism::setPendingProxyAdmin: caller must be admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = s.pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        s.pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return true;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return boolean indicating success of operation
     */
    function acceptProxyAdmin() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == s.pendingAdmin && msg.sender != address(0), "Prism::acceptProxyAdmin: caller must be pending admin");

        // Save current values for inclusion in log
        address oldAdmin = s.admin;
        address oldPendingAdmin = s.pendingAdmin;

        // Store admin with value pendingAdmin
        s.admin = s.pendingAdmin;

        // Clear the pending value
        s.pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, s.admin);
        emit NewPendingAdmin(oldPendingAdmin, s.pendingAdmin);

        return true;
    }

    /**
     * @notice Get current admin for prism proxy
     * @return admin address
     */
    function proxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.admin;
    }

    /**
     * @notice Get pending admin for prism proxy
     * @return admin address
     */
    function pendingProxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingAdmin;
    }

    /**
     * @notice Address of implementation contract
     * @return implementation address
     */
    function proxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.implementation;
    }

    /**
     * @notice Address of pending implementation contract
     * @return pending implementation address
     */
    function pendingProxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingImplementation;
    }

    /**
     * @notice Current implementation version for proxy
     * @return version number
     */
    function proxyImplementationVersion() public view returns (uint8) {
        ProxyStorage storage s = proxyStorage();
        return s.version;
    }

    /**
     * @notice Delegates execution to an implementation contract.
     * @dev Returns to the external caller whatever the implementation returns or forwards reverts
     */
    function _forwardToImplementation() internal {
        ProxyStorage storage s = proxyStorage();
        // delegate all other functions to current implementation
        (bool success, ) = s.implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./PrismProxy.sol";

contract PrismProxyImplementation is Initializable {
    /**
     * @notice Accept invitation to be implementation contract for proxy
     * @param prism Prism Proxy contract
     */
    function become(PrismProxy prism) public {
        require(msg.sender == prism.proxyAdmin(), "Prism::become: only proxy admin can change implementation");
        require(prism.acceptProxyImplementation() == true, "Prism::become: change not authorized");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IArchToken.sol";
import "../interfaces/IVesting.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ITokenRegistry.sol";

/// @notice App metadata storage
struct AppStorage {
    // A record of states for signing / validating signatures
    mapping (address => uint) nonces;

    // ARCH token
    IArchToken archToken;

    // Vesting contract
    IVesting vesting;

    // Voting Power owner
    address owner;
    
    // lockManager contract
    address lockManager;

    // Token registry contract
    ITokenRegistry tokenRegistry;
}

/// @notice A checkpoint for marking number of votes from a given block
struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
}

/// @notice All storage variables related to checkpoints
struct CheckpointStorage {
     // A record of vote checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) numCheckpoints;
}

/// @notice The amount of a given token that has been staked, and the resulting voting power
struct Stake {
    uint256 amount;
    uint256 votingPower;
}

/// @notice All storage variables related to staking
struct StakeStorage {
    // Official record of staked balances for each account > token > stake
    mapping (address => mapping (address => Stake)) stakes;
}

library VotingPowerStorage {
    bytes32 constant VOTING_POWER_APP_STORAGE_POSITION = keccak256("voting.power.app.storage");
    bytes32 constant VOTING_POWER_CHECKPOINT_STORAGE_POSITION = keccak256("voting.power.checkpoint.storage");
    bytes32 constant VOTING_POWER_STAKE_STORAGE_POSITION = keccak256("voting.power.stake.storage");
    
    /**
     * @notice Load app storage struct from specified VOTING_POWER_APP_STORAGE_POSITION
     * @return app AppStorage struct
     */
    function appStorage() internal pure returns (AppStorage storage app) {        
        bytes32 position = VOTING_POWER_APP_STORAGE_POSITION;
        assembly {
            app.slot := position
        }
    }

    /**
     * @notice Load checkpoint storage struct from specified VOTING_POWER_CHECKPOINT_STORAGE_POSITION
     * @return cs CheckpointStorage struct
     */
    function checkpointStorage() internal pure returns (CheckpointStorage storage cs) {        
        bytes32 position = VOTING_POWER_CHECKPOINT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    /**
     * @notice Load stake storage struct from specified VOTING_POWER_STAKE_STORAGE_POSITION
     * @return ss StakeStorage struct
     */
    function stakeStorage() internal pure returns (StakeStorage storage ss) {        
        bytes32 position = VOTING_POWER_STAKE_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }
}