// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ProxyClones/OwnableForClones.sol";

// Flexible Vesting Schedule with easy Snapshot compatibility designed by Phil Thomsen @theDAC
//for more information please visit: github.cikm


contract DACVesting is OwnableForClones {

  IERC20 public token;
  // Blocktime when the release schedule starts
  uint256 public startTime;

  //everything is released once blocktime >= startTime + duration
  uint256 public duration;

  // 1= linear; 2 = quadratic etc.
  uint256 public exp;

  // cliff: 100 = 1%;
  uint256 public cliff;
  // indicates how much earlier than startTime the cliff amount gets released
  uint256 public cliffDelay;

  // maps what each user has deposited total / gotten back out total; Deposit>=Drained at all times
  mapping(address => uint256) private totalDeposit;
  mapping(address => uint256) private drainedAmount;

  event TokensDeposited(address indexed beneficiary, uint256 indexed amount);
  event TokensRetrieved(address indexed beneficiary, uint256 indexed amount);
  event VestingDecreased(address indexed beneficiary, uint256 indexed amount);

  /**
   * @notice initializes the contract, with all parameters set at once
   * @param _token the only token contract that is accepted in this vesting instance
   * @param _owner the owner that can call decreaseVesting, set address(0) to have no owner
   * @param _cliffInTenThousands amount of tokens to be released ahead of startTime: 10000 => 100%
   * @param _cliffDelayInDays the cliff can be retrieved this many days before StartTime of the schedule
   * @param _exp this sets the pace of the schedule. 0 is instant, 1 is linear over time, 2 is quadratic over time etc.
   */
  function initialize
   (
    address _token,
    address _owner,
    uint256 _startInDays,
    uint256 _durationInDays,
    uint256 _cliffInTenThousands,
    uint256 _cliffDelayInDays,
    uint256 _exp
   )
    external initializer
   {
    __Ownable_init();
    token = IERC20(_token);
    startTime = block.timestamp + _startInDays * 86400;
    duration = _durationInDays * 86400;
    cliff = _cliffInTenThousands;
    cliffDelay = _cliffDelayInDays * 86400;
    exp = _exp;
    if (_owner == address(0)) {
      renounceOwnership();
    }else {
      transferOwnership(_owner);
    }
  }

  /**
  * @notice same as depositFor but with memory array as input for gas savings
  */
  function depositForCrowd(address[] memory _recipient, uint256[] memory _amount) external {
    require(_recipient.length == _amount.length, "lengths must match");
    for (uint256 i = 0; i < _recipient.length; i++) {
      _rawDeposit(msg.sender, _recipient[i], _amount[i]);    
    }
  }

  /**
  * @notice sender can deposit tokens for someone else
  * @param _recipient the use to deposit for 
  * @param _amount the amount of tokens to deposit with all decimals
  */
  function depositFor(address _recipient, uint256 _amount) external {
    _rawDeposit(msg.sender, _recipient, _amount);
  }

  /**
  * @notice deposits the amount owned by _recipient from sender for _recipient into this contract
  * @param _recipient the address the funds are vested for
  * @dev only useful in specific contexts like having to burn a wallet and deposit it back in the vesting contract e.g.
  */
  function depositAllFor(address _recipient) external {
    _rawDeposit(msg.sender, _recipient, token.balanceOf(_recipient));
  }

  /**
  * @notice user method to retrieve all that is retrievable
  * @notice reverts when there is nothing to retrieve to save gas
  */
  function retrieve() external {
    uint256 amount = getRetrievableAmount(msg.sender);
    require(amount != 0, "nothing to retrieve");
    _rawRetrieve(msg.sender, amount);
  }

  /**
  * @notice retrieve for an array of addresses at once, useful if users are unable to use the retrieve method or to save gas with mass retrieves
  * @dev does NOT revert when one of the accounts has nothing to retrieve
  */
  function retrieveFor(address[] memory accounts) external {
    for (uint256 i = 0; i < accounts.length; i++) {
      uint256 amount = getRetrievableAmount(accounts[i]);
      _rawRetrieve(accounts[i], amount);
    }
  }

  /**
  * @notice if the ownership got renounced (owner == 0), then this function is uncallable and the vesting is trustless for benificiary
  * @dev only callable by the owner of this instance
  * @dev amount will be stuck in the contract and effectively burned
  */
  function decreaseVesting(address _account, uint256 amount) external onlyOwner {
    require(drainedAmount[_account] <= totalDeposit[_account] - amount, "deposit has to be >= drainedAmount");
    totalDeposit[_account] -= amount;
    emit VestingDecreased(_account, amount);
  }

  /**
  * @return the total amount that got deposited for _account over the whole lifecycle with all decimal places
  */
  function getTotalDeposit(address _account) external view returns(uint256) {
    return totalDeposit[_account];
  }

  /** 
  * @return the amount of tokens still in vesting for _account
  */
  function getTotalVestingBalance(address _account) external view returns(uint256) {
    return totalDeposit[_account] - drainedAmount[_account];
  }

  /**
  * @return the percentage that is retrievable, 100 = 100%
  */
  function getRetrievablePercentage() external view returns(uint256) {
    return _getPercentage() / 100;
  }

  /**
  * @notice useful for easy snapshot implementation
  * @return the balance of token for this account plus the amount that is still vested for account
  */
  function balanceOf(address account) external view returns(uint256) {
    return token.balanceOf(account) + totalDeposit[account] - drainedAmount[account];
  }

  /**
  * @return the amount that _account can retrieve at that block with all decimals
  */
  function getRetrievableAmount(address _account) public view returns(uint256) {
    if(_getPercentage() * totalDeposit[_account] / 1e4 > drainedAmount[_account]) {
      return (_getPercentage() * totalDeposit[_account] / 1e4) - drainedAmount[_account];
    }else {
      return 0;
    }
  }

  function _rawDeposit(address _from, address _for, uint256 _amount) private {
    require(token.transferFrom(_from, address(this), _amount));
    totalDeposit[_for] += _amount;
    emit TokensDeposited(_for, _amount);
  }

  function _rawRetrieve(address account, uint256 amount) private {
    drainedAmount[account] += amount;
    token.transfer(account, amount);
    assert(drainedAmount[account] <= totalDeposit[account]);
    emit TokensRetrieved(account, amount);
  }

  /**
  * @dev the core calculation method
  * @dev returns 1e4 for 100%; 1e3 for 10%; 1e2 for 1%; 1e1 for 0.1% and 1e0 for 0.01%
  */
  function _getPercentage() private view returns(uint256) {
    if (cliff == 0) {
      return _getPercentageNoCliff();
    }else {
      return _getPercentageWithCliff();
    }
  }

  function _getPercentageNoCliff() private view returns(uint256) {
    if (startTime > block.timestamp) {
      return 0;
    }else if (startTime + duration > block.timestamp) {
      return (1e4 * (block.timestamp - startTime)**exp) / duration**exp;
    }else {
      return 1e4;
    }
  }

  function _getPercentageWithCliff() private view returns(uint256) {
    if (block.timestamp + cliffDelay < startTime) {
      return 0;
    }else if (block.timestamp < startTime) {
      return cliff;
    }else if (1e4 * (block.timestamp - startTime)**exp / duration**exp + cliff < 1e4) {
      return (1e4 * (block.timestamp - startTime)**exp / duration**exp) + cliff;
    }else {
      return 1e4;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextForClones.sol";

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
abstract contract OwnableForClones is ContextForClones {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

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
abstract contract ContextForClones is Initializable {
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