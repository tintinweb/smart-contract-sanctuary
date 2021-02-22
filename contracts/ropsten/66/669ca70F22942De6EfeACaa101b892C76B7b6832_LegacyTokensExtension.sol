/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/common/Validating.sol

pragma solidity 0.7.1;


interface Validating {
  modifier notZero(uint number) { require(number > 0, "invalid 0 value"); _; }
  modifier notEmpty(string memory text) { require(bytes(text).length > 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address"); _; }
}

// File: contracts/common/HasOwners.sol

pragma solidity 0.7.1;



/// @notice providing an ownership access control mechanism
contract HasOwners is Validating {

  address[] public owners;
  mapping(address => bool) public isOwner;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  /// @notice initializing the owners list (with at least one owner)
  constructor(address[] memory owners_) {
    require(owners_.length > 0, "there must be at least one owner");
    for (uint i = 0; i < owners_.length; i++) addOwner_(owners_[i]);
  }

  /// @notice requires the sender to be one of the contract owners
  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  /// @notice list all accounts with an owner access
  function getOwners() public view returns (address[] memory) { return owners; }

  /// @notice authorize an `account` with owner access
  function addOwner(address owner) external onlyOwner { addOwner_(owner); }

  function addOwner_(address owner) private validAddress(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }

  /// @notice revoke an `account` owner access (while ensuring at least one owner remains)
  function removeOwner(address owner) external onlyOwner {
    require(isOwner[owner], 'only owners can be removed');
    require(owners.length > 1, 'can not remove last owner');
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        owners.pop();
        emit OwnerRemoved(owner);
        break;
      }
    }
  }

}

// File: contracts/common/Versioned.sol

pragma solidity 0.7.1;


contract Versioned {

  string public version;

  constructor(string memory version_) { version = version_; }

}

// File: contracts/gluon/AppLogic.sol

pragma solidity 0.7.1;


/**
  * @notice representing an app's in-and-out transfers of assets
  * @dev an account/asset based app should implement its own bookkeeping
  */
interface AppLogic {

  /// @notice when an app proposal has been activated, Gluon will call this method on the previously active app version
  /// @dev each app must implement, providing a future upgrade path, and call retire_() at the very end.
  /// this is the chance for the previously active app version to migrate to the new version
  /// i.e.: migrating data, deprecate prior behavior, releasing resources, etc.
  function upgrade() external;

  /// @dev once an asset has been deposited into the app's safe within Gluon, the app is given the chance to do
  /// it's own per account/asset bookkeeping
  ///
  /// @param account any Ethereum address
  /// @param asset any ERC20 token or ETH (represented by address 0x0)
  /// @param quantity quantity of asset
  function credit(address account, address asset, uint quantity) external;

  /// @dev before an asset can be withdrawn from the app's safe within Gluon, the quantity and asset to withdraw must be
  /// derived from `parameters`. if the app is account/asset based, it should take this opportunity to:
  /// - also derive the owning account from `parameters`
  /// - prove that the owning account indeed has the derived quantity of the derived asset
  /// - do it's own per account/asset bookkeeping
  /// notice that the derived account is not necessarily the same as the provided account; a classic usage example is
  /// an account transfers assets across app (in which case the provided account would be the target app)
  ///
  /// @param account any Ethereum address to which `quantity` of `asset` would be transferred to
  /// @param parameters a bytes-marshalled record containing all data needed for the app-specific logic
  /// @return asset any ERC20 token or ETH (represented by address 0x0)
  /// @return quantity quantity of asset
  function debit(address account, bytes calldata parameters) external returns (address asset, uint quantity);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/gluon/AppGovernance.sol

pragma solidity 0.7.1;


interface AppGovernance {
  function approve(uint32 id) external;
  function disapprove(uint32 id) external;
  function activate(uint32 id) external;
}

// File: contracts/gluon/GluonWallet.sol

pragma solidity 0.7.1;


interface GluonWallet {
  function depositEther(uint32 id) external payable;
  function depositToken(uint32 id, address token, uint quantity) external;
  function withdraw(uint32 id, bytes calldata parameters) external;
  function transfer(uint32 from, uint32 to, bytes calldata parameters) external;
}

// File: contracts/apps/stake/Governing.sol

pragma solidity 0.7.1;


interface Governing {
  function deleteVoteTally(address proposal) external;
  function activationInterval() external view returns (uint);
  function governanceToken() external returns (address);
}

// File: contracts/gluon/HasAppOwners.sol

pragma solidity 0.7.1;



/// @notice providing a per-app ownership access control
contract HasAppOwners is HasOwners {

  mapping(uint32 => address[]) public appOwners;

  event AppOwnerAdded (uint32 appId, address appOwner);
  event AppOwnerRemoved (uint32 appId, address appOwner);

  constructor(address[] memory owners_) HasOwners(owners_) { }

  /// @notice requires the sender to be one of the app owners (of `appId`)
  ///
  /// @param appId index of the target app
  modifier onlyAppOwner(uint32 appId) { require(isAppOwner(appId, msg.sender), "invalid sender; must be app owner"); _; }

  function isAppOwner(uint32 appId, address appOwner) public view returns (bool) {
    address[] memory currentOwners = appOwners[appId];
    for (uint i = 0; i < currentOwners.length; i++) {
      if (currentOwners[i] == appOwner) return true;
    }
    return false;
  }

  /// @notice list all accounts with an app-owner access for `appId`
  ///
  /// @param appId index of the target app
  function getAppOwners(uint32 appId) public view returns (address[] memory) { return appOwners[appId]; }

  function addAppOwners(uint32 appId, address[] calldata toBeAdded) external onlyAppOwner(appId) {
    addAppOwners_(appId, toBeAdded);
  }

  /// @notice authorize each of `toBeAdded` with app-owner access
  ///
  /// @param appId index of the target app
  /// @param toBeAdded accounts to be authorized
  /// (the initial app-owners are established during app registration)
  function addAppOwners_(uint32 appId, address[] memory toBeAdded) internal {
    for (uint i = 0; i < toBeAdded.length; i++) {
      if (!isAppOwner(appId, toBeAdded[i])) {
        appOwners[appId].push(toBeAdded[i]);
        emit AppOwnerAdded(appId, toBeAdded[i]);
      }
    }
  }


  /// @notice revokes app-owner access for each of `toBeRemoved` (while ensuring at least one app-owner remains)
  ///
  /// @param appId index of the target app
  /// @param toBeRemoved accounts to have their membership revoked
  function removeAppOwners(uint32 appId, address[] calldata toBeRemoved) external onlyAppOwner(appId) {
    address[] storage currentOwners = appOwners[appId];
    require(currentOwners.length > toBeRemoved.length, "can not remove last owner");
    for (uint i = 0; i < toBeRemoved.length; i++) {
      for (uint j = 0; j < currentOwners.length; j++) {
        if (currentOwners[j] == toBeRemoved[i]) {
          currentOwners[j] = currentOwners[currentOwners.length - 1];
          currentOwners.pop();
          emit AppOwnerRemoved(appId, toBeRemoved[i]);
          break;
        }
      }
    }
  }

}

// File: contracts/gluon/Gluon.sol

pragma solidity 0.7.1;











/**
  * @title the Gluon-Plasma contract for upgradable side-chain apps (see: https://leverj.io/GluonPlasma.pdf)
  * @notice once an app has been provisioned with me, I enable:
  * - depositing an asset into an app
  * - withdrawing an asset from an app
  * - transferring an asset across apps
  * - submitting (and discarding) an upgrade proposal for an app
  * - voting for/against app proposals
  * - upgrading an approved app proposal
  */
contract Gluon is Validating, Versioned, AppGovernance, GluonWallet, HasAppOwners {
  using SafeMath for uint;

  struct App {
    address[] history;
    address proposal;
    uint activationBlock;
    mapping(address => uint) balances;
  }

  address private constant ETH = address(0x0);
  uint32 private constant REGISTRY_INDEX = 0;
  uint32 private constant STAKE_INDEX = 1;

  mapping(uint32 => App) public apps;
  mapping(address => bool) public proposals;
  uint32 public totalAppsCount = 0;

  event AppRegistered (uint32 appId);
  event AppProvisioned(uint32 indexed appId, uint8 version, address logic);
  event ProposalAdded(uint32 indexed appId, uint8 version, address logic, uint activationBlock);
  event ProposalRemoved(uint32 indexed appId, uint8 version, address logic);
  event Activated(uint32 indexed appId, uint8 version, address logic);

  constructor(address[] memory owners_, string memory version_) Versioned(version_) HasAppOwners(owners_) {
    registerApp_(REGISTRY_INDEX, owners);
    registerApp_(STAKE_INDEX, owners);
  }

  /// @notice requires the sender to be the currently active (latest) version of the app contract (identified by appId)
  ///
  /// @param appId index of the provisioned app in question
  modifier onlyCurrentLogic(uint32 appId) { require(msg.sender == current(appId), "invalid sender; must be latest logic contract"); _; }

  modifier provisioned(uint32 appId) { require(apps[appId].history.length > 0, "App is not yet provisioned"); _; }

  function registerApp(uint32 appId, address[] calldata accounts) external onlyOwner { registerApp_(appId, accounts); }

  function registerApp_(uint32 appId, address[] memory accounts) private {
    require(appOwners[appId].length == 0, "App already has app owner");
    require(totalAppsCount == appId, "app ids are incremented by 1");
    totalAppsCount++;
    emit AppRegistered(appId);
    addAppOwners_(appId, accounts);
  }

  /// @notice on-boarding an app
  ///
  /// @param logic address of the app's contract (the first version)
  /// @param appId index of the provisioned app in question
  function provisionApp(uint32 appId, address logic) external onlyAppOwner(appId) validAddress(logic) {
    App storage app = apps[appId];
    require(app.history.length == 0, "App is already provisioned");
    app.history.push(logic);
    emit AppProvisioned(appId, uint8(app.history.length - 1), logic);
  }

  /************************************************* Governance ************************************************/

  function addProposal(uint32 appId, address logic) external onlyAppOwner(appId) provisioned(appId) validAddress(logic) {
    App storage app = apps[appId];
    require(app.proposal == address(0x0), "Proposal already exists. remove proposal before adding new one");
    app.proposal = logic;
    app.activationBlock = block.number + Governing(current(STAKE_INDEX)).activationInterval();
    proposals[logic] = true;
    emit ProposalAdded(appId, uint8(app.history.length - 1), app.proposal, app.activationBlock);
  }

  function removeProposal(uint32 appId) external onlyAppOwner(appId) provisioned(appId) {
    App storage app = apps[appId];
    emit ProposalRemoved(appId, uint8(app.history.length - 1), app.proposal);
    deleteProposal(app);
  }

  function deleteProposal(App storage app) private {
    Governing(current(STAKE_INDEX)).deleteVoteTally(app.proposal);
    delete proposals[app.proposal];
    delete app.proposal;
    app.activationBlock = 0;
  }

  /************************************************* AppGovernance ************************************************/

  function approve(uint32 appId) external override onlyCurrentLogic(STAKE_INDEX) {
    apps[appId].activationBlock = block.number;
  }

  function disapprove(uint32 appId) external override onlyCurrentLogic(STAKE_INDEX) {
    App storage app = apps[appId];
    emit ProposalRemoved(appId, uint8(app.history.length - 1), app.proposal);
    deleteProposal(app);
  }

  function activate(uint32 appId) external override onlyCurrentLogic(appId) provisioned(appId) {
    App storage app = apps[appId];
    require(app.activationBlock > 0, "nothing to activate");
    require(app.activationBlock < block.number, "new app can not be activated before activation block");
    app.history.push(app.proposal); // now make it the current
    deleteProposal(app);
    emit Activated(appId, uint8(app.history.length - 1), current(appId));
  }

  /**************************************************** GluonWallet ****************************************************/

  /// @notice deposit ETH asset on behalf of the sender into an app's safe
  ///
  /// @param appId index of the target app
  function depositEther(uint32 appId) external override payable provisioned(appId) {
    App storage app = apps[appId];
    app.balances[ETH] = app.balances[ETH].add(msg.value);
    AppLogic(current(appId)).credit(msg.sender, ETH, msg.value);
  }

  /// @notice deposit ERC20 token asset (represented by address 0x0) on behalf of the sender into an app's safe
  /// @dev an account must call token.approve(logic, quantity) beforehand
  ///
  /// @param appId index of the target app
  /// @param token address of ERC20 token contract
  /// @param quantity how much of token
  function depositToken(uint32 appId, address token, uint quantity) external override provisioned(appId) {
    transferTokensToGluonSecurely(appId, IERC20(token), quantity);
    AppLogic(current(appId)).credit(msg.sender, token, quantity);
  }

  function transferTokensToGluonSecurely(uint32 appId, IERC20 token, uint quantity) private {
    uint balanceBefore = token.balanceOf(address(this));
    require(token.transferFrom(msg.sender, address(this), quantity), "failure to transfer quantity from token");
    uint balanceAfter = token.balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) == quantity, "bad Token; transferFrom erroneously reported of successful transfer");
    App storage app = apps[appId];
    app.balances[address(token)] = app.balances[address(token)].add(quantity);
  }

  /// @notice withdraw a quantity of asset from an app's safe
  /// @dev quantity & asset should be derived by the app
  ///
  /// @param appId index of the target app
  /// @param parameters a bytes-marshalled record containing at the very least quantity & asset
  function withdraw(uint32 appId, bytes calldata parameters) external override provisioned(appId) {
    (address asset, uint quantity) = AppLogic(current(appId)).debit(msg.sender, parameters);
    if (quantity > 0) {
      App storage app = apps[appId];
      require(app.balances[asset] >= quantity, "not enough funds to transfer");
      app.balances[asset] = apps[appId].balances[asset].sub(quantity);
      asset == ETH ?
        require(address(uint160(msg.sender)).send(quantity), "failed to transfer ether") : // explicit casting to `address payable`
        transferTokensToAccountSecurely(IERC20(asset), quantity, msg.sender);
    }
  }

  function transferTokensToAccountSecurely(IERC20 token, uint quantity, address to) private {
    uint balanceBefore = token.balanceOf(to);
    require(token.transfer(to, quantity), "failure to transfer quantity from token");
    uint balanceAfter = token.balanceOf(to);
    require(balanceAfter.sub(balanceBefore) == quantity, "bad Token; transferFrom erroneously reported of successful transfer");
  }

  /// @notice withdraw a quantity of asset from a source app's safe and transfer it (within Gluon) to a target app's safe
  /// @dev quantity & asset should be derived by the source app
  ///
  /// @param from index of the source app
  /// @param to index of the target app
  /// @param parameters a bytes-marshalled record containing at the very least quantity & asset
  function transfer(uint32 from, uint32 to, bytes calldata parameters) external override provisioned(from) provisioned(to) {
    (address asset, uint quantity) = AppLogic(current(from)).debit(msg.sender, parameters);
    if (quantity > 0) {
      if (from != to) {
        require(apps[from].balances[asset] >= quantity, "not enough balance in logic to transfer");
        apps[from].balances[asset] = apps[from].balances[asset].sub(quantity);
        apps[to].balances[asset] = apps[to].balances[asset].add(quantity);
      }
      AppLogic(current(to)).credit(msg.sender, asset, quantity);
    }
  }

  /**************************************************** GluonView  ****************************************************/

  /// @notice view of current app data
  ///
  /// @param appId index of the provisioned app in question
  /// @return current address of the app's current contract
  /// @return proposal address of the app's pending proposal contract (if any)
  /// @return activationBlock the block in which the proposal can be activated
  function app(uint32 appId) external view returns (address current, address proposal, uint activationBlock) {
    App storage app_ = apps[appId];
    current = app_.history[app_.history.length - 1];
    proposal = app_.proposal;
    activationBlock = app_.activationBlock;
  }

  function current(uint32 appId) public view returns (address) { return apps[appId].history[apps[appId].history.length - 1]; }

  /// @notice view of the full chain of (contract addresses) of the app versions, up to and including the current one
  function history(uint32 appId) external view returns (address[] memory) { return apps[appId].history; }

  /// @notice is the `logic` contract one of the `appId` app?
  function isAnyLogic(uint32 appId, address logic) public view returns (bool) {
    address[] memory history_ = apps[appId].history;
    for (uint i = history_.length; i > 0; i--) {
      if (history_[i - 1] == logic) return true;
    }
    return false;
  }

  /// @notice what is the current balance of `asset` in the `appId` app's safe?
  function getBalance(uint32 appId, address asset) external view returns (uint) { return apps[appId].balances[asset]; }

}

// File: contracts/gluon/LegacyTokensExtension.sol

pragma solidity 0.7.1;








/**
  * @title the Gluon-Plasma Extension contract for supporting deposit and withdraw for legacy tokens
  * - depositing an token into an app
  * - withdrawing an token from an app
  * - transferring an token across apps
  */
contract LegacyTokensExtension is Versioned, GluonWallet, HasOwners {
  using SafeMath for uint;

  address[] public tokens;
  mapping(address => bool) public isTokenAllowed;

  mapping(uint32 => mapping(address => uint)) public balances;
  mapping(address => uint) public tokenBalances;

  Gluon public gluon;

  event TokenAdded(address indexed token);
  event TokenRemoved(address indexed token);

  constructor(address gluon_, address[] memory tokens_, address[] memory owners_, string memory version_)
    Versioned(version_)
    HasOwners(owners_)
  {
    gluon = Gluon(gluon_);
    for (uint i = 0; i < tokens_.length; i++) addToken_(tokens_[i]);
  }

  modifier provisioned(uint32 appId) { require(gluon.history(appId).length > 0, "App is not yet provisioned"); _; }

  /**************************************************** GluonWallet ****************************************************/

  /// @notice deposit ETH token on behalf of the sender into an app's safe
  ///
  /// @param appId index of the target app
  function depositEther(uint32 appId) external override payable provisioned(appId) {
    require(false, "prohibited operation; must use Gluon to deposit Ether");
  }

  /// @notice deposit ERC20 token token (represented by address 0x0) on behalf of the sender into an app's safe
  /// @dev an account must call token.approve(logic, quantity) beforehand
  ///
  /// @param appId index of the target app
  /// @param token address of ERC20 token contract
  /// @param quantity how much of token
  function depositToken(uint32 appId, address token, uint quantity) external override provisioned(appId) {
    require(isTokenAllowed[token], "use gluon contract");
    transferTokensToGluonSecurely(appId, LegacyToken(token), quantity);
    AppLogic(current(appId)).credit(msg.sender, token, quantity);
  }

  function transferTokensToGluonSecurely(uint32 appId, LegacyToken token, uint quantity) private {
    uint balanceBefore = token.balanceOf(address(this));
    token.transferFrom(msg.sender, address(this), quantity);
    uint balanceAfter = token.balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) == quantity, "bad LegacyToken; transferFrom erroneously reported of successful transfer");
    balances[appId][address(token)] = balances[appId][address(token)].add(quantity);
    tokenBalances[address(token)] = tokenBalances[address(token)].add(quantity);
  }

  /// @notice withdraw a quantity of token from an app's safe
  /// @dev quantity & token should be derived by the app
  ///
  /// @param appId index of the target app
  /// @param parameters a bytes-marshalled record containing at the very least quantity & token
  function withdraw(uint32 appId, bytes calldata parameters) external override provisioned(appId) {
    (address token, uint quantity) = AppLogic(current(appId)).debit(msg.sender, parameters);
    require(isTokenAllowed[token], "use gluon contract");
    if (quantity > 0) {
      require(balances[appId][token] >= quantity, "not enough funds to transfer");
      balances[appId][token] = balances[appId][token].sub(quantity);
      tokenBalances[token] = tokenBalances[token].sub(quantity);
      transferTokensToAccountSecurely(LegacyToken(token), quantity, msg.sender);
    }
  }

  function transferTokensToAccountSecurely(LegacyToken token, uint quantity, address to) private {
    uint balanceBefore = token.balanceOf(to);
    token.transfer(to, quantity);
    uint balanceAfter = token.balanceOf(to);
    require(balanceAfter.sub(balanceBefore) == quantity, "transfer failed");
  }

  /// @notice withdraw a quantity of token from a source app's safe and transfer it (within Gluon) to a target app's safe
  /// @dev quantity & token should be derived by the source app
  ///
  /// @param from index of the source app
  /// @param to index of the target app
  /// @param parameters a bytes-marshalled record containing at the very least quantity & token
  function transfer(uint32 from, uint32 to, bytes calldata parameters) external override provisioned(from) provisioned(to) {
    (address token, uint quantity) = AppLogic(current(from)).debit(msg.sender, parameters);
    require(isTokenAllowed[token], "use gluon contract");
    if (quantity > 0) {
      if (from != to) {
        require(balances[from][token] >= quantity, "not enough balance in logic to transfer");
        balances[from][token] = balances[from][token].sub(quantity);
        balances[to][token] = balances[to][token].add(quantity);
      }
      AppLogic(current(to)).credit(msg.sender, token, quantity);
    }
  }

  /**************************************************** GluonView  ****************************************************/

  function current(uint32 appId) public view returns (address) {return gluon.current(appId);}

  /// @notice what is the current balance of `token` in the `appId` app's safe?
  function getBalance(uint32 appId, address token) external view returns (uint) {return balances[appId][token];}

  /**************************************************** allowed tokens  ****************************************************/
  /// @notice add a token
  function addToken(address token) external onlyOwner {addToken_(token);}

  function addToken_(address token) private validAddress(token) {
    if (!isTokenAllowed[token]) {
      isTokenAllowed[token] = true;
      tokens.push(token);
      emit TokenAdded(token);
    }
  }

  /// @notice remove a token
  function removeToken(address token) external onlyOwner {
    require(isTokenAllowed[token], "token does not exists");
    require(tokenBalances[token] == 0, "token is in use");
    isTokenAllowed[token] = false;
    for (uint i = 0; i < tokens.length; i++) {
      if (tokens[i] == token) {
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
        emit TokenRemoved(token);
        break;
      }
    }
  }

  function getTokens() public view returns (address[] memory){return tokens;}
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface LegacyToken {
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external;
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external;
  function approve(address spender, uint value) external;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}