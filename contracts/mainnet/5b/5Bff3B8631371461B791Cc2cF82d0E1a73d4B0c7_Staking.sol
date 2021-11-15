// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Staking/CappedRewardCalculator.sol";
import "./ClaimsRegistry.sol";

/// @title A staking contract which allows only verified users (by checking a separate contract for a valid signature)
/// @author Miguel Palhas <[email protected]>
contract Staking is CappedRewardCalculator, Ownable {
  /// @notice the token to stake
  ERC20 public immutable erc20;

  /// @notice claim registry where signatures are to be stored and verified
  IClaimsRegistryVerifier public immutable registry;

  /// @notice The expected attester address against which claims will be verified
  ///   (i.e. they must be signed by this address)
  address public immutable claimAttester;

  /// @notice The minimum staking amount per account
  uint public immutable minAmount;

  /// @notice The maximum staking amount per account
  uint public immutable maxAmount;

  /// @notice Locked rewards pending withdrawal
  uint public lockedReward = 0;

  /// @notice Rewards already distributed
  uint public distributedReward = 0;

  /// @notice How much is currently staked
  uint public stakedAmount = 0;

  /// @notice Subscription details for each account
  mapping(address => Subscription) public subscriptions;

  /// @notice Emitted when an account stakes tokens and creates a new subscription
  event Subscribed(
    address subscriber,
    uint date,
    uint stakedAmount,
    uint maxReward
  );

  /// @notice Emitted when an account withdraws an existing stake
  event Withdrawn(
    address subscriber,
    uint date,
    uint withdrawAmount
  );

  /// @notice Details of a particular subscription
  struct Subscription {
    bool active;
    address subscriberAddress; // addres the subscriptions refers to
    uint startDate;      // Block timestamp at which the subscription was made
    uint stakedAmount;   // How much was staked
    uint maxReward;      // Maximum reward given if user stays until the end of the staking period
    uint withdrawAmount; // Total amount withdrawn (initial amount + final calculated reward)
    uint withdrawDate;   // Block timestamp at which the subscription was withdrawn (or 0 while staking is in progress)
  }

  /// @notice Staking constructor
  /// @param _token ERC20 token address to use
  /// @param _registry ClaimsRegistry address to use
  /// @param _attester expected attester of claims when verifying them
  /// @param _startDate timestamp starting at which stakes are allowed. Must be greater than instantiation timestamp
  /// @param _endDate timestamp at which staking is over (no more rewards are given, and new stakes are not allowed)
  /// @param _minAmount minimum staking amount for each account
  /// @param _maxAmount maximum staking amount for each account
  /// @param _cap max % of individual reward for curve period
  constructor(
    address _token,
    address _registry,
    address _attester,
    uint _startDate,
    uint _endDate,
    uint _minAmount,
    uint _maxAmount,
    uint _cap
  ) CappedRewardCalculator(_startDate, _endDate, _cap) {
    require(_token != address(0), "Staking: token address cannot be 0x0");
    require(_registry != address(0), "Staking: claims registry address cannot be 0x0");
    require(_attester != address(0), "Staking: claim attester cannot be 0x0");
    require(block.timestamp <= _startDate, "Staking: start date must be in the future");
    require(_minAmount > 0, "Staking: invalid individual min amount");
    require(_maxAmount > _minAmount, "Staking: max amount must be higher than min amount");

    erc20 = ERC20(_token);
    registry = IClaimsRegistryVerifier(_registry);
    claimAttester = _attester;

    minAmount = _minAmount;
    maxAmount = _maxAmount;
  }

  /// @notice Get the total size of the reward pool
  /// @return Returns the total size of the reward pool, including locked and distributed tokens
  function totalPool() public view returns (uint) {
    return erc20.balanceOf(address(this)) - stakedAmount + distributedReward;
  }

  /// @notice Get the available size of the reward pool
  /// @return Returns the available size of the reward pool, no including locked or distributed rewards
  function availablePool() public view returns (uint) {
    return erc20.balanceOf(address(this)) - stakedAmount - lockedReward;
  }

  /// @notice Requests a new stake to be created. Only one stake per account is
  ///   created, maximum rewards are calculated upfront, and a valid claim
  ///   signature needs to be provided, which will be checked against the expected
  ///   attester on the registry contract
  /// @param _amount Amount of tokens to stake
  /// @param claimSig Signature to check against the registry contract
  function stake(uint _amount, bytes calldata claimSig) external {
    uint time = block.timestamp;
    address subscriber = msg.sender;

    require(registry.verifyClaim(msg.sender, claimAttester, claimSig), "Staking: could not verify claim");
    require(_amount >= minAmount, "Staking: staked amount needs to be greater than or equal to minimum amount");
    require(_amount <= maxAmount, "Staking: staked amount needs to be lower than or equal to maximum amount");
    require(time >= startDate, "Staking: staking period not started");
    require(time < endDate, "Staking: staking period finished");
    require(subscriptions[subscriber].active == false, "Staking: this account has already staked");


    uint maxReward = calculateReward(time, endDate, _amount);
    require(maxReward <= availablePool(), "Staking: not enough tokens available in the pool");
    lockedReward += maxReward;
    stakedAmount += _amount;

    subscriptions[subscriber] = Subscription(
      true,
      subscriber,
      time,
      _amount,
      maxReward,
      0,
      0
    );

    // transfer tokens from subscriber to the contract
    require(erc20.transferFrom(subscriber, address(this), _amount),
      "Staking: Could not transfer tokens from subscriber");

    emit Subscribed(subscriber, time, _amount, maxReward);
  }

  /// @notice Withdrawn the stake belonging to `msg.sender`
  function withdraw() external {
    address subscriber = msg.sender;
    uint time = block.timestamp;

    require(subscriptions[subscriber].active == true, "Staking: no active subscription found for this address");

    Subscription memory sub = subscriptions[subscriber];

    uint actualReward = calculateReward(sub.startDate, time, sub.stakedAmount);
    uint total = sub.stakedAmount + actualReward;

    // update subscription state
    sub.withdrawAmount = total;
    sub.withdrawDate = time;
    sub.active = false;
    subscriptions[subscriber] = sub;

    // update locked amount
    lockedReward -= sub.maxReward;
    distributedReward += actualReward;
    stakedAmount -= sub.stakedAmount;

    // transfer tokens back to subscriber
    require(erc20.transfer(subscriber, total), "Staking: Transfer has failed");

    emit Withdrawn(subscriber, time, total);
  }

  /// @notice returns the initial amount staked by a given account
  /// @param _subscriber The account to check
  /// @return The amount that was staked by the given account
  function getStakedAmount(address _subscriber) external view returns (uint) {
    if (subscriptions[_subscriber].stakedAmount > 0 && subscriptions[_subscriber].withdrawDate == 0) {
      return subscriptions[_subscriber].stakedAmount;
    } else {
      return 0;
    }
  }

  /// @notice Gets the maximum reward for an existing subscription
  /// @param _subscriber address of the subscription to check
  /// @return Maximum amount of tokens the subscriber can get by staying until the end of the staking period
  function getMaxStakeReward(address _subscriber) external view returns (uint) {
    Subscription memory sub = subscriptions[_subscriber];

    if (sub.active) {
      return subscriptions[_subscriber].maxReward;
    } else {
      return 0;
    }
  }

  /// @notice Gets the amount already earned by an existing subscription
  /// @param _subscriber address of the subscription to check
  /// @return Amount the subscriber has earned to date
  function getCurrentReward(address _subscriber) external view returns (uint) {
    Subscription memory sub = subscriptions[_subscriber];

    if (sub.active) {
      return calculateReward(sub.startDate, block.timestamp, sub.stakedAmount);
    } else {
      return 0;
    }
  }

  /// @notice Withdraws all unlocked tokens from the pool to the owner. Only works if staking period has already ended
  function withdrawPool() external onlyOwner {
    require(block.timestamp > endDate, "Staking: staking not over yet");

    erc20.transfer(owner(), availablePool());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @title Calculates rewards based on an initial downward curve period, and a second constant period
/// @notice Calculation of the reward is based on a few rules:
///   * start and end date of the staking period (the earlier you enter, and
///     the longer you stay, the greater your overall reward)
///
///   * At each point, the the current reward is described by a downward curve
///     (https://www.desmos.com/calculator/dz8vk1urep)
///
///   * Computing your total reward (which is done upfront in order to lock and
///     guarantee your reward) means computing the integral of the curve period from
///     your enter date until the end
///     (https://www.wolframalpha.com/input/?i=integrate+%28100-x%29%5E2)
///
///   * This integral is the one being calculated in the `integralAtPoint` function
///
///   * Besides this rule, rewards are also capped by a maximum percentage
///     provided at contract instantiation time (a cap of 40 means your maximum
///     possible reward is 40% of your initial stake
///
/// @author Miguel Palhas <[email protected]>
contract CappedRewardCalculator {
  /// @notice start of the staking period
  uint public immutable startDate;
  /// @notice end of the staking period
  uint public immutable endDate;
  /// @notice Reward cap for curve period
  uint public immutable cap;

  uint constant private year = 365 days;
  uint constant private day = 1 days;
  uint private constant mul = 1000000;

  /// @notice constructor
  /// @param _start The start timestamp for staking
  /// @param _start The end timestamp for staking
  /// @param _cap The cap percentage of the reward (40 == maximum of 40% of your initial stake)
  constructor(
    uint _start,
    uint _end,
    uint _cap
  ) {
    require(block.timestamp <= _start, "CappedRewardCalculator: start date must be in the future");
    require(
      _start < _end,
      "CappedRewardCalculator: end date must be after start date"
    );

    require(_cap > 0, "CappedRewardCalculator: curve cap cannot be 0");

    startDate = _start;
    endDate = _end;
    cap = _cap;
  }

  /// @notice Given a timestamp range and an amount, calculates the expected nominal return
  /// @param _start The start timestamp to consider
  /// @param _end The end timestamp to consider
  /// @param _amount The amount to stake
  /// @return The nominal amount of the reward
  function calculateReward(
    uint _start,
    uint _end,
    uint _amount
  ) public view returns (uint) {
    (uint start, uint end) = truncatePeriod(_start, _end);
    (uint startPercent, uint endPercent) = toPeriodPercents(start, end);

    uint percentage = curvePercentage(startPercent, endPercent);

    uint reward = _amount * cap * percentage / (mul * 100);

    return reward;
  }

  /// @notice Estimates the current offered APY
  /// @return The estimated APY (40 == 40%)
  function currentAPY() public view returns (uint) {
    uint amount = 100 ether;
    uint today = block.timestamp;

    if (today < startDate) {
      today = startDate;
    }

    uint todayReward = calculateReward(startDate, today, amount);

    uint tomorrow = today + day;
    uint tomorrowReward = calculateReward(startDate, tomorrow, amount);

    uint delta = tomorrowReward - todayReward;
    uint apy = delta * 365 * 100 / amount;

    return apy;
  }

  function toPeriodPercents(
    uint _start,
    uint _end
  ) internal view returns (uint, uint) {
    uint totalDuration = endDate - startDate;

    if (totalDuration == 0) {
      return (0, mul);
    }

    uint startPercent = (_start - startDate) * mul / totalDuration;
    uint endPercent = (_end - startDate) * mul / totalDuration;

    return (startPercent, endPercent);
  }

  function truncatePeriod(
    uint _start,
    uint _end
  ) internal view returns (uint, uint) {
    if (_end <= startDate || _start >= endDate) {
      return (startDate, startDate);
    }

    uint start = _start < startDate ? startDate : _start;
    uint end = _end > endDate ? endDate : _end;

    return (start, end);
  }

  function curvePercentage(uint _start, uint _end) internal pure returns (uint) {
    int maxArea = integralAtPoint(mul) - integralAtPoint(0);
    int actualArea = integralAtPoint(_end) - integralAtPoint(_start);

    uint ratio = uint(actualArea * int(mul) / maxArea);

    return ratio;
  }


  function integralAtPoint(uint _x) internal pure returns (int) {
    int x = int(_x);
    int p1 = ((x - int(mul)) ** 3) / (3 * int(mul));

    return p1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ClaimsRegistry/Verifier.sol";

/// @title The claim verification interface expected by the Staking contract
/// @author Miguel Palhas <[email protected]>
interface IClaimsRegistryVerifier {
  /// @notice Verifies that the given `sig` corresponds to a claim about `subject`, signed by `attester`
  /// @param subject The subject the claim refers to
  /// @param attester The account that is expected to have signed the claim
  /// @param sig The signature
  /// @return Whether a claim about `subject` and signed by `attester` does exist and matches `sig`
  function verifyClaim(address subject, address attester, bytes calldata sig) external view returns (bool);
}

/// @title A claim registry. Does not actually store data, but only signatures of claims and their subjects
/// @author Miguel Palhas <[email protected]>
contract ClaimsRegistry is IClaimsRegistryVerifier, Verifier {
  /// @notice The mapping of keys to claims
  mapping(bytes32 => Claim) public registry;

  /// @notice Struct containing all public data about a claim (currently only the subject)
  struct Claim {
    address subject; // Subject the claim refers to
    bool revoked;    // Whether the claim is revoked or not
  }

  /// @notice Emitted when a signed claim is successfuly stored
  event ClaimStored(
    bytes sig
  );

  /// @notice Emitted when a previously stored claim is successfuly revoked by the attester
  event ClaimRevoked(
    bytes sig
  );

  /// @notice Stores a claim about `subject`, signed by `attester`. Instead of
  ///   actual data, receives only `claimHash` and `sig`, and checks whether the
  ///   signature matches the expected key, and is signed by `attester`
  /// @param subject Account the claim refers to
  /// @param attester Account that signed the claim
  /// @param claimHash the claimHash that was signed along with the subject
  /// @param sig The given signature that must match (`subject`, `claimhash`)
  function setClaimWithSignature(
    address subject,
    address attester,
    bytes32 claimHash,
    bytes calldata sig
  ) public {
    bytes32 signable = computeSignableKey(subject, claimHash);

    require(verifyWithPrefix(signable, sig, attester), "ClaimsRegistry: Claim signature does not match attester");

    bytes32 key = computeKey(attester, sig);

    registry[key] = Claim(subject, false);

    emit ClaimStored(sig);
  }

  /// @notice Checks if a claim signature is valid and stored, and returns the corresponding subject
  /// @param attester Account that signed the claim
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  /// @return The subject of the claim, or address(0) if none was found
  function getClaim(
    address attester,
    bytes calldata sig
  ) public view returns (address) {
    bytes32 key = keccak256(abi.encodePacked(attester, sig));

    if (registry[key].revoked) {
      return address(0);
    } else {
      return registry[key].subject;
    }

  }

  /// @notice Checks if a claim signature is valid, and corresponds to the given subject
  /// @param subject Account the claim refers to
  /// @param attester Account that signed the claim
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  /// @return The subject of the claim, or address(0) if none was found
  function verifyClaim(
    address subject,
    address attester,
    bytes calldata sig
  ) override external view returns (bool) {
    return getClaim(attester, sig) == subject;
  }

  /// @notice Callable by an attester, to revoke previously signed claims about a subject
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  function revokeClaim(
    bytes calldata sig
  ) public {
    bytes32 key = computeKey(msg.sender, sig);

    require(registry[key].subject != address(0), "ClaimsRegistry: Claim not found");

    registry[key].revoked = true;

    emit ClaimRevoked(sig);
  }

  /// @notice computes the hash that must be signed by the attester before storing a claim
  /// @param subject Account the claim refers to
  /// @param claimHash the claimHash that was signed along with the subject
  /// @return The hash to be signed by the attester
  function computeSignableKey(address subject, bytes32 claimHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(subject, claimHash));
  }

  function computeKey(address attester, bytes calldata sig) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(attester, sig));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @title A set of helper functions to verify signatures, to be used in the ClaimsRegistry
/// @author Miguel Palhas <[email protected]>
contract Verifier {

  /// @notice Verifies that the given signature matches the provided data, and
  ///   was signed by the provided issuer. Assumes data was signed using the
  ///   Ethereum prefix to protect against unkonwingly signing transactions
  /// @param hash The data to verify
  /// @param sig The signature of the data
  /// @param signer The expected signer of the data
  /// @return `true` if `signer` and `hash` match `sig`
  function verifyWithPrefix(bytes32 hash, bytes calldata sig, address signer) public pure returns (bool) {
    return verify(addPrefix(hash), sig, signer);
  }

  /// @notice Recovers the signer of the given signature and data. Assumes data
  ///  was signed using the Ethereum prefix to protect against unknowingly signing
  ///  transaction.s
  /// @param hash The data to verify
  /// @param sig The signature of the data
  /// @return The address recovered by checking the signature against the data
  function recoverWithPrefix(bytes32 hash, bytes calldata sig) public pure returns (address) {
    return recover(addPrefix(hash), sig);
  }

  function verify(bytes32 hash, bytes calldata sig, address signer) internal pure returns (bool) {
    return recover(hash, sig) == signer;
  }

  function recover(bytes32 hash, bytes calldata _sig) internal pure returns (address) {
    bytes memory sig = _sig;
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return address(0);
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function addPrefix(bytes32 hash) private pure returns (bytes32) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";

    return keccak256(abi.encodePacked(prefix, hash));
  }
}

