// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title A contract to manage the cap table for an alternative asset
 * @author @ScalingFunds Engineering Team
 */
contract ScalingFundsToken is ERC20Snapshot, AccessControl {
  bool public areInvestorTransfersDisabled;
  bool public isCapTableLocked;
  bool public isTokenLaunched;
  bool public isTokenDead;

  bytes32 public constant SCALINGFUNDS_AGENT = keccak256("SCALINGFUNDS_AGENT");
  bytes32 public constant TRANSFER_AGENT = keccak256("TRANSFER_AGENT");
  bytes32 public constant ALLOWLISTED_INVESTOR =
    keccak256("ALLOWLISTED_INVESTOR");

  ScalingFundsToken internal _previousContract;

  /**********/
  /* EVENTS */
  /**********/

  /**
   * @notice Emitted when transfers between investors are disabled
   * @param caller Address that called the function
   */
  event InvestorTransfersDisabled(address indexed caller);

  /**
   * @notice Emitted when transfers between investors are enabled
   * @param caller Address that called the function
   */
  event InvestorTransfersEnabled(address indexed caller);

  /**
   * @notice Emitted when the CapTable is locked preventing transfers
   * @param caller Address that called the function
   */
  event CapTableLocked(address indexed caller);

  /**
   * @notice Emitted when the CapTable is unlocked allowing transfers
   * @param caller Address that called the function
   */
  event CapTableUnlocked(address indexed caller);

  /**
   * @notice Emitted when the Token is launched
   * @param caller Address that called the function
   */
  event TokenLaunched(address indexed caller);

  /**
   * @notice Emitted when the token is killed
   * @param caller Address that called the function
   * @param reason Reason for killing the token
   */
  event TokenKilled(address indexed caller, string reason);

  /**
   * @notice Emitted when a transfer of tokens is forced from one address to another
   * @param from Address that is sending tokens
   * @param to Address that is receiving tokens
   * @param amount Amount of tokens that were transferred
   * @param reason Reason for conducting force-transfer
   */
  event ForcedTransfer(
    address indexed from,
    address indexed to,
    uint256 amount,
    string reason
  );

  /**
   * @notice Emitted when _previousContract is linked
   * @param previousContractAddress Address of the previous contract that was previously tracking the cap table of this asset
   */
  event PreviousContractLinked(address indexed previousContractAddress);

  /*************/
  /* MODIFIERS */
  /*************/

  /**
   * @notice Modified function is only callable when investor transfers are enabled
   * @dev Used to prevent transfers between investors
   */
  modifier whenInvestorTransfersAreEnabled() {
    require(!areInvestorTransfersDisabled, "Investor Transfers are disabled");
    _;
  }

  /**
   * @notice Modified function is only callable when cap table is unlocked
   * @dev Used to prevent all changes to the cap table
   */
  modifier whenCapTableIsUnlocked() {
    require(!isCapTableLocked, "CapTable is locked");
    _;
  }

  /**
   * @notice Modified function is only callable BEFORE token has launched
   * @dev Used to migrate roles and balances from a previous token
   */
  modifier onlyBeforeLaunch() {
    require(!isTokenLaunched, "Token is already launched");
    _;
  }

  /**
   * @notice Modified function is only callable AFTER token has launched
   * @dev Used to prevent calling non-migration functions before token is launched
   */
  modifier onlyAfterLaunch() {
    require(isTokenLaunched, "Token is not yet launched");
    _;
  }

  /**
   * @notice Modified function is only callable when the token is active
   * @dev Used to prevent any state changes on a dead token
   */
  modifier whenTokenIsActive() {
    require(!isTokenDead, "Token is dead");
    _;
  }

  /**
   * @notice Modified function is only callable by a SCALINGFUNDS_AGENT
   * @dev Used for launching the token, migrations and, if need be, killing the token
   */
  modifier onlyScalingFundsAgent {
    require(
      super.hasRole(SCALINGFUNDS_AGENT, msg.sender),
      "Caller does not have SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be a SCALINGFUNDS_AGENT
   * @param account The address to check
   * @dev Used to prevent ScalingFunds agents to become transfer agents or allowlisted investors
   */
  modifier isNotScalingFundsAgent(address account) {
    require(
      !super.hasRole(SCALINGFUNDS_AGENT, account),
      "account cannot have SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function is only callable by a TRANSFER_AGENT
   * @dev Used for all transfer agent responsibilities such as managing the allowlist, locking the cap table, or conducting a force-transfer
   */
  modifier onlyTransferAgent {
    require(
      super.hasRole(TRANSFER_AGENT, msg.sender),
      "Caller does not have TRANSFER_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be a TRANSFER_AGENT
   * @param account The address to check
   * @dev Used to prevent transfer agents to become ScalingFunds agents or allowlisted investors
   */
  modifier isNotTransferAgent(address account) {
    require(
      !super.hasRole(TRANSFER_AGENT, account),
      "account cannot have TRANSFER_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function is only callable by a TRANSFER_AGENT or SCALINGFUNDS_AGENT
   * @dev Used to enable transfer agents and ScalingFunds agents to easily retrieve all allowlisted investors or all transfer agents
   */
  modifier onlyTransferAgentOrScalingFundsAgent {
    require(
      super.hasRole(TRANSFER_AGENT, msg.sender) ||
        super.hasRole(SCALINGFUNDS_AGENT, msg.sender),
      "Caller does not have TRANSFER_AGENT or SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param must be an ALLOWLISTED_INVESTOR
   * @param account Investor address to check
   */
  modifier isAllowlistedInvestor(address account) {
    require(
      super.hasRole(ALLOWLISTED_INVESTOR, account),
      "account does not have ALLOWLISTED_INVESTOR role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be an ALLOWLISTED_INVESTOR
   * @param account Investor address to check
   */
  modifier isNotAllowlistedInvestor(address account) {
    require(
      !super.hasRole(ALLOWLISTED_INVESTOR, account),
      "account cannot have ALLOWLISTED_INVESTOR role"
    );
    _;
  }

  /*************/
  /* FUNCTIONS */
  /*************/

  /**
   * @notice Initializes the token and sets up the initial roles
   * @param name ERC20 name of the deployed token
   * @param symbol ERC20 symbol ot the deployed token
   * @param transferAgent Address of the first transfer agent
   * @param scalingFundsAgent Address of the first ScalingFunds agent
   * @dev - All tokens are initialized in pre-launch mode to allow for potential migrations to happen
   * - All tokens have investor-transfers disabled by default and must be explicitly enabled by the transfer agent, if desired.
   */
  constructor(
    string memory name,
    string memory symbol,
    address transferAgent,
    address scalingFundsAgent
  ) ERC20(name, symbol) {
    areInvestorTransfersDisabled = true;
    isCapTableLocked = false;
    isTokenDead = false;
    isTokenLaunched = false;

    super._setupRole(TRANSFER_AGENT, transferAgent);
    super._setupRole(SCALINGFUNDS_AGENT, scalingFundsAgent);

    super._setRoleAdmin(SCALINGFUNDS_AGENT, SCALINGFUNDS_AGENT);
    super._setRoleAdmin(TRANSFER_AGENT, TRANSFER_AGENT);
    super._setRoleAdmin(ALLOWLISTED_INVESTOR, TRANSFER_AGENT);
  }

  /*****************/
  /* STATE CONTROL */
  /*****************/

  /**
   * @notice Disables transfers between investors
   * @dev - Used to temporarily disable all transfers between investors
   * - Transfer agents are not affected by this and can continue to manage the cap table.
   * - Emits {InvestorTransfersDisabled} event
   *
   * Can only be called:
   * - by transfer agents
   * - when investor-transfers are enabled
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function disableInvestorTransfers()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
    whenInvestorTransfersAreEnabled
  {
    areInvestorTransfersDisabled = true;
    emit InvestorTransfersDisabled(msg.sender);
  }

  /**
   * @notice Enables transfer between investors
   * @dev - Used to enable allowlisted investors to transfer tokens with each other
   * - Emits {InvestorTransfersEnabled} event
   *
   * Can only be called:
   *
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function enableInvestorTransfers()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
  {
    require(areInvestorTransfersDisabled, "Investor Transfers are enabled");
    areInvestorTransfersDisabled = false;
    emit InvestorTransfersEnabled(msg.sender);
  }

  /**
   * @notice Locks the cap table
   * @dev - Used to effectively "freeze" the cap table and prevent all balance changes, for example when conducting dividend payouts
   * - Emits {CapTableLocked} event
   *
   * Can only be called:
   * - by transfer agents
   * - when cap table is unlocked
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function lockCapTable()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
    whenCapTableIsUnlocked
  {
    isCapTableLocked = true;
    emit CapTableLocked(msg.sender);
  }

  /**
   * @notice Unlocks the cap table
   * @dev - Used to "unfreeze" the cap table and re-enable balance changes, for example after conducting dividend payouts
   * - Emits {CapTableUnlocked} event
   *
   * Can only be called:
   * - by transfer agents
   * - when token is active (NOT dead)
   * - AFTER token has launched
   */
  function unlockCapTable()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
  {
    require(isCapTableLocked, "CapTable is already unlocked");
    isCapTableLocked = false;
    emit CapTableUnlocked(msg.sender);
  }

  /**
   * @notice Launches the token after intialisation (and optional migration) is complete
   * @dev - This action is irreversible, a token can not be "unlaunched" to return to the pre-launch phase
   * - Emits {TokenLaunched} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   * - when token is active (NOT dead)
   */
  function launchToken()
    external
    onlyScalingFundsAgent
    whenTokenIsActive
    onlyBeforeLaunch
  {
    isTokenLaunched = true;
    emit TokenLaunched(msg.sender);
  }

  /**
   * @notice Kills and permanently deactivates the token
   * @param reason A short comment on why the token is being killed
   * @dev - Used after the managed asset has reached its end of life, or when migrating the cap table to a new contract
   * - Emits {TokenKilled} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - before OR after token has launched
   * - when token is active (NOT dead)
   */
  function killToken(string calldata reason)
    external
    onlyScalingFundsAgent
    whenTokenIsActive
  {
    bytes memory reasonAsBytes = bytes(reason);
    require(reasonAsBytes.length > 0, "reason string is empty");
    isTokenDead = true;
    emit TokenKilled(msg.sender, reason);
  }

  /**
   * @notice Takes a snapshot of the current balances
   * @dev - Used to simplify contract migrations, or to take cap table snapshots ahead of dividend payouts and similar corporate actions
   * - Emits {Snapshot} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - before OR after token has launched
   */
  function takeSnapshot() external onlyScalingFundsAgent returns (uint256) {
    return super._snapshot();
  }

  /*********/
  /* ERC20 */
  /*********/

  /**
   * @notice Issues tokens to allowlisted investors
   * @param to Investor address to issue tokens to
   * @param amount Amount of tokens to issue
   * @dev - Emits {Transfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function mint(address to, uint256 amount)
    public
    onlyAfterLaunch
    onlyTransferAgent
    isAllowlistedInvestor(to)
    returns (bool)
  {
    super._mint(to, amount);
    return true;
  }

  /**
   * @notice Redeems tokens for investors by burning them
   * @param account Investor address to redeem tokens from
   * @param amount Amount of tokens to redeem
   * @dev - Emits {Transfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function burn(address account, uint256 amount)
    public
    onlyAfterLaunch
    onlyTransferAgent
    returns (bool)
  {
    super._burn(account, amount);
    return true;
  }

  /**
   * @notice Issues tokens to allowlisted investors in batch
   * @param accounts Investor addresses to issue tokens to
   * @param amounts Amounts of tokens to issue to each address at same index
   * @dev - Emits {Transfer} events
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function batchMint(address[] calldata accounts, uint256[] calldata amounts)
    external
    onlyAfterLaunch
    onlyTransferAgent
    returns (bool)
  {
    require(
      (accounts.length == amounts.length),
      "accounts and amounts do not have the same length"
    );
    for (uint256 i = 0; i < accounts.length; i++) {
      mint(accounts[i], amounts[i]);
    }
    return true;
  }

  /**
   * @notice ERC20 Transfer function override that prevents transfers from or to non-allowlisted addresses
   * @param to Recipient's address
   * @param amount Amount of tokens to transfer
   * @dev - Transfers will be rejected when TransferAgent has disabled transfers between investors
   * - Emits {Transfer} event
   *
   * Can only be called:
   * - by allowlisted investors
   * - when investor-transfers are enabled
   * - if `to` address is also allowlisted
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function transfer(address to, uint256 amount)
    public
    override
    whenInvestorTransfersAreEnabled
    isAllowlistedInvestor(msg.sender)
    isAllowlistedInvestor(to)
    returns (bool)
  {
    return super.transfer(to, amount);
  }

  /**
   * @notice Force-transfer tokens
   * @param from Previous token holder
   * @param to New token holder
   * @param amount Amount of tokens to transfer
   * @param reason Reason for conducting a force-transfer
   * @dev - Used to enable transfer agents to comply with court orders or other legal transfer requests
   * - Emits {ForcedTransfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `from` and `to` address are both allowlisted
   * - if a `reason` for the force-transfer has been given
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function forceTransfer(
    address from,
    address to,
    uint256 amount,
    string memory reason
  )
    external
    onlyAfterLaunch
    onlyTransferAgent
    isAllowlistedInvestor(from)
    isAllowlistedInvestor(to)
    returns (bool)
  {
    bytes memory reasonAsBytes = bytes(reason);
    require(reasonAsBytes.length > 0, "reason string is empty");
    super._transfer(from, to, amount);
    emit ForcedTransfer(from, to, amount, reason);
    return true;
  }

  /**
   * @notice ERC20 BeforeTokenTransfer override that prevents all transfers when cap tab is locked or token is dead
   * @param from Sender address
   * @param to Recipient address
   * @param amount Amount of tokens to transfer
   * @dev - This hook is always called before any transfer (including minting and burning which in Ethereum are effectively transfer FROM or TO the zero-address)
   *
   * Can only be called:
   * - when token is active
   * - cap table is unlocked
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenTokenIsActive whenCapTableIsUnlocked {
    super._beforeTokenTransfer(from, to, amount);
  }

  /************************************/
  /* ACCESS CONTROL & ROLE MANAGEMENT */
  /************************************/

  /**
   * @notice Adds an individual investor to the allowlist
   * @param account Investor address to add to the allowlist
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `account` is not a transfer agent or a ScalingFunds agent
   */
  function addInvestorToAllowlist(address account)
    public
    onlyTransferAgent
    isNotTransferAgent(account)
    isNotScalingFundsAgent(account)
    returns (bool)
  {
    require(account != address(0), "Zero address cannot be allowlisted");
    super.grantRole(ALLOWLISTED_INVESTOR, account);
    return true;
  }

  /**
   * @notice Removes an individual investor from the allowlist
   * @param account Investor address to remove from the allowlist
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by transfer agents
   */
  function removeInvestorFromAllowlist(address account)
    public
    onlyTransferAgent
    returns (bool)
  {
    super.revokeRole(ALLOWLISTED_INVESTOR, account);
    return true;
  }

  /**
   * @notice Adds investors to the allowlist in batch
   * @param accounts List of investor addresses to add to the allowlist
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by transfer agents
   */
  function batchAddInvestorsToAllowlist(address[] calldata accounts)
    public
    onlyTransferAgent
    returns (bool)
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      addInvestorToAllowlist(accounts[i]);
    }
    return true;
  }

  /**
   * @notice Removes investors from the allowlist in batch
   * @param accounts List of investor addresses to remove from the allowlist
   * @dev - Emits {RoleRevoked} events
   *
   * Can only be called:
   * - by transfer agents
   */
  function batchRemoveInvestorsFromAllowlist(address[] calldata accounts)
    public
    onlyTransferAgent
    returns (bool)
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      removeInvestorFromAllowlist(accounts[i]);
    }
    return true;
  }

  /**
   * @notice Gets all allowlisted investors
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by transfer agents
   * - by ScalingFunds agents
   */
  function getAllAllowlistedInvestors()
    external
    view
    onlyTransferAgentOrScalingFundsAgent
    returns (address[] memory)
  {
    uint256 investorCount = super.getRoleMemberCount(ALLOWLISTED_INVESTOR);
    address[] memory allowlistedInvestors = new address[](investorCount);
    for (uint256 i = 0; i < investorCount; i++) {
      address _investor = super.getRoleMember(ALLOWLISTED_INVESTOR, i);
      allowlistedInvestors[i] = _investor;
    }
    return allowlistedInvestors;
  }

  /**
   * @notice Adds a new transfer agent
   * @param account Address to grant TRANSFER_AGENT role to
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `account` is not an allowlisted investor
   * - if `account` is not a ScalingFunds agent
   * - if `account` is not the zero address
   */
  function addTransferAgent(address account)
    external
    onlyTransferAgent
    isNotAllowlistedInvestor(account)
    isNotScalingFundsAgent(account)
  {
    require(account != address(0), "Transfer agent cannot be zero address");
    super.grantRole(TRANSFER_AGENT, account);
  }

  /**
   * @notice Removes a transfer agent
   * @param account Address to revoke TRANSFER_AGENT role from
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by transfer agents
   */
  function removeTransferAgent(address account) external onlyTransferAgent {
    super.revokeRole(TRANSFER_AGENT, account);
  }

  /**
   * @notice Gets all transfer agents
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by transfer agents
   * - by ScalingFunds agents
   */
  function getAllTransferAgents()
    external
    view
    onlyTransferAgentOrScalingFundsAgent
    returns (address[] memory)
  {
    uint256 transferAgentCount = super.getRoleMemberCount(TRANSFER_AGENT);
    address[] memory transferAgents = new address[](transferAgentCount);
    for (uint256 i = 0; i < transferAgentCount; i++) {
      address _transferAgent = super.getRoleMember(TRANSFER_AGENT, i);
      transferAgents[i] = _transferAgent;
    }
    return transferAgents;
  }

  /**
   * @notice Adds a ScalingFunds agent
   * @param account Address to grant SCALINGFUNDS_AGENT role to
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - if `account` is not an allowlisted investor
   * - if `account` is not a transfer agent
   * - if `account` is not the zero address
   */
  function addScalingFundsAgent(address account)
    external
    onlyScalingFundsAgent
    isNotAllowlistedInvestor(account)
    isNotTransferAgent(account)
  {
    require(
      (account != address(0)),
      "ScalingFunds agent cannot be zero address"
    );
    super.grantRole(SCALINGFUNDS_AGENT, account);
  }

  /**
   * @notice Removes a ScalingFunds agent
   * @param account Address to revoke SCALINGFUNDS_AGENT role from
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   */
  function removeScalingFundsAgent(address account)
    external
    onlyScalingFundsAgent
  {
    super.revokeRole(SCALINGFUNDS_AGENT, account);
  }

  /**
   * @notice Gets all Scalingfunds agents
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by ScalingFunds agents
   */
  function getAllScalingFundsAgents()
    external
    view
    onlyScalingFundsAgent
    returns (address[] memory)
  {
    uint256 scalingfundAgentCount =
      super.getRoleMemberCount(SCALINGFUNDS_AGENT);
    address[] memory scalingfundAgents = new address[](scalingfundAgentCount);
    for (uint256 i = 0; i < scalingfundAgentCount; i++) {
      address _scalingFundsAgent = super.getRoleMember(SCALINGFUNDS_AGENT, i);
      scalingfundAgents[i] = _scalingFundsAgent;
    }
    return scalingfundAgents;
  }

  /**********************/
  /* CONTRACT MIGRATION */
  /**********************/

  /**
   * @notice Links this token to a predecessor token that was previously tracking this asset's CapTable
   * @param _previousContractAddress Previous contract to link to
   * @dev - Used to keep audit trail intact in case of a contract migration
   * - Emits {PreviousContractLinked} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - if `_previousContract` is not already linked
   * - if `_previousContractAddress` is a smart contract (NOT an individual wallet)
   * - BEFORE token has launched
   */
  function linkPreviousContract(address _previousContractAddress)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    require(
      address(_previousContract) == address(0),
      "_previousContract can only be linked once"
    );

    require(
      Address.isContract(_previousContractAddress),
      "_previousContractAddress must be a contract"
    );

    _previousContract = ScalingFundsToken(_previousContractAddress);

    emit PreviousContractLinked(_previousContractAddress);
  }

  function previousContractAddress() external view returns (address) {
    return address(_previousContract);
  }

  /**
   * @notice Migrates initial list of transfer agents
   * @param transferAgents List of addresses to grant TRANSFER_AGENT role to
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateTransferAgents(address[] calldata transferAgents)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < transferAgents.length; i++) {
      super._setupRole(TRANSFER_AGENT, transferAgents[i]);
    }
  }

  /**
   * @notice Migrates initial list of allowlisted investors
   * @param investors List of addresses to grant ALLOWLISTED_INVESTOR role to
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateAllowlistedInvestors(address[] calldata investors)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < investors.length; i++) {
      super._setupRole(ALLOWLISTED_INVESTOR, investors[i]);
    }
  }

  /**
   * @notice Migrates initial list of ScalingFunds agents
   * @param scalingFundsAgents List of addresses to grant SCALINGFUNDS_AGENT role to
   * @dev - Emits {RoleGranted} event for every ScalingFunds agent address
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateScalingFundsAgents(address[] calldata scalingFundsAgents)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < scalingFundsAgents.length; i++) {
      super._setupRole(SCALINGFUNDS_AGENT, scalingFundsAgents[i]);
    }
  }

  /**
   * @notice Migrates balances from a snapshot of the previousContract
   * @param investors List of investors to migrate balances for
   * @param snapshotId Snapshot ID on the previousContract
   * @dev - Emits {Transfer} event for every migrated balance
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateBalancesFromSnapshot(
    address[] calldata investors,
    uint256 snapshotId
  ) external onlyScalingFundsAgent onlyBeforeLaunch {
    for (uint256 i = 0; i < investors.length; i++) {
      address investor = investors[i];
      uint256 balance = super.balanceOf(investor);
      uint256 snapshotBalance =
        _previousContract.balanceOfAt(investor, snapshotId);
      // reset investor balance to zero for safety (e.g. avoids the case where `migrateBalances()` was called before already)
      if (balance > 0) {
        super._burn(investor, balance);
      }
      super._mint(investor, snapshotBalance);
    }
  }

  /**
   * @notice Migrates balances of investors from an off-chain source
   * @param investors List of investors to migrate balances for
   * @param balances Matching list of balances for each investor
   * @dev - Emits {Transfer} event for every migrated balance
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   * - if the `investors` list and the `balances` list have the same length
   */
  function migrateBalances(
    address[] calldata investors,
    uint256[] calldata balances
  ) external onlyScalingFundsAgent onlyBeforeLaunch returns (bool) {
    require(
      (investors.length == balances.length),
      "investors and balances do not have the same length"
    );
    for (uint256 i = 0; i < balances.length; i++) {
      address investor = investors[i];
      uint256 newBalance = balances[i];
      uint256 currentBalance = super.balanceOf(investor);
      // reset investor balance to zero for safety (e.g. avoids the case where `migrateBalancesFromSnapshot()` was called before already)
      if (currentBalance > 0) {
        super._burn(investor, currentBalance);
      }
      super._mint(investor, newBalance);
    }
    return true;
  }

  /********************************/
  /* ERC20 UNSUPPORTED OPERATIONS */
  /********************************/

  /**
   * @notice `transferFrom` is not supported in this contract
   */
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override returns (bool) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `approve` is not supported in this contract
   */
  function approve(address, uint256) public pure override returns (bool) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `allowance` is not supported in this contract
   */
  function allowance(address, address) public pure override returns (uint256) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `increaseAllowance` is not supported in this contract
   */
  function increaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
  {
    revert("Operation Not Supported");
  }

  /**
   * @notice `dereaseAllowance` is not supported in this contract
   */
  function decreaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
  {
    revert("Operation Not Supported");
  }

  /***************************************/
  /* AccessControl UNSUPPORTED OPERATIONS */
  /***************************************/
  /**
   * @notice `renounceRole` is not supported in this contract
   */
  function renounceRole(bytes32, address) public pure override {
    revert("Operation Not Supported");
  }

  /**
   * @notice `grantRole` is not supported in this contract
   */
  function grantRole(bytes32, address) public pure override {
    revert("Operation Not Supported");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}