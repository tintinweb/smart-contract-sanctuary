// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IDeFiPlazaGov.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeFi Plaza governance token (DFPgov)
 * @author Jazzer 9F
 * @notice Implements lean on gas liquidity reward program for DeFi Plaza
 */
contract DFPgov is IDeFiPlazaGov, Ownable, ERC20 {

  // global staking contract state parameters squeezed in 256 bits
  struct StakingState {
    uint96 totalStake;                      // Total LP tokens currently staked
    uint96 rewardsAccumulatedPerLP;         // Rewards accumulated per staked LP token (16.80 bits)
    uint32 lastUpdate;                      // Timestamp of last update
    uint32 startTime;                       // Timestamp rewards started
  }

  // data per staker, some bits remaining available
  struct StakeData {
    uint96 stake;                           // Amount of LPs staked for this staker
    uint96 rewardsPerLPAtTimeStaked;        // Baseline rewards at the time these LPs were staked
  }

  address public founder;
  address public multisig;
  address public indexToken;
  StakingState public stakingState;
  mapping(address => StakeData) public stakerData;
  uint256 public multisigAllocationClaimed;
  uint256 public founderAllocationClaimed;

  /**
  * Basic setup
  */
  constructor(address founderAddress, uint256 mintAmount, uint32 startTime) ERC20("Defi Plaza governance", "DFP2") {
    // contains the global state of the staking progress
    StakingState memory state;
    state.startTime = startTime;
    stakingState = state;

    // generate the initial 4M founder allocation
    founder = founderAddress;
    _mint(founderAddress, mintAmount);
  }

  /**
  * For staking LPs to accumulate governance token rewards.
  * Maintains a single stake per user, but allows to add on top of existing stake.
  */
  function stake(uint96 LPamount)
    external
    override
    returns(bool success)
  {
    // Collect LPs
    require(
      IERC20(indexToken).transferFrom(msg.sender, address(this), LPamount),
      "DFP: Transfer failed"
    );

    // Update global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }
    state.totalStake += LPamount;
    stakingState = state;

    // Update staker data for this user
    StakeData memory staker = stakerData[msg.sender];
    if (staker.stake == 0) {
      staker.stake = LPamount;
      staker.rewardsPerLPAtTimeStaked = state.rewardsAccumulatedPerLP;
    } else {
      uint256 LP1 = staker.stake + LPamount;
      uint256 RLP0_ = (uint256(LPamount) * state.rewardsAccumulatedPerLP + uint256(staker.stake) * staker.rewardsPerLPAtTimeStaked) / LP1;
      staker.stake = uint96(LP1);
      staker.rewardsPerLPAtTimeStaked = uint96(RLP0_);
    }
    stakerData[msg.sender] = staker;

    // Emit staking event
    emit Staked(msg.sender, LPamount);
    return true;
  }

  /**
  * For unstaking LPs and collecting rewards accumulated up to this point.
  * Any unstake action distributes and resets rewards. Simply claiming rewards
  * without unstaking can be done by unstaking zero LPs.
  */
  function unstake(uint96 LPamount)
    external
    override
    returns(uint256 rewards)
  {
    // Collect data for this user
    StakeData memory staker = stakerData[msg.sender];
    require(
      staker.stake >= LPamount,
      "DFP: Insufficient stake"
    );

    // Update the global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }
    state.totalStake -= LPamount;
    stakingState = state;

    // Calculate rewards
    rewards = ((uint256(state.rewardsAccumulatedPerLP) - staker.rewardsPerLPAtTimeStaked) * staker.stake) >> 80;

    // Update user data
    if (LPamount == staker.stake) delete stakerData[msg.sender];
    else {
      staker.stake -= LPamount;
      staker.rewardsPerLPAtTimeStaked = state.rewardsAccumulatedPerLP;
      stakerData[msg.sender] = staker;
    }

    // Distribute reward and emit event
    _mint(msg.sender, rewards);
    require(
      IERC20(indexToken).transfer(msg.sender, LPamount),
      "DFP: Kernel panic"
    );
    emit Unstaked(msg.sender, LPamount, rewards);
  }

  /**
  * Helper function to check unclaimed rewards for any address
  */
  function rewardsQuote(address stakerAddress)
    external
    view
    override
    returns(uint256 rewards)
  {
    // Collect user data
    StakeData memory staker = stakerData[stakerAddress];

    // Calculate distribution since last on chain update
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
    }

    // Calculate unclaimed rewards
    rewards = ((uint256(state.rewardsAccumulatedPerLP) - staker.rewardsPerLPAtTimeStaked) * staker.stake) >> 80;
  }

  /**
  * Configure which token is accepted as stake. Can only be done once.
  */
  function setIndexToken(address indexTokenAddress)
    external
    onlyOwner
    returns(bool success)
  {
    require(indexToken==address(0), "Already configured");
    indexToken = indexTokenAddress;
    _mint(indexTokenAddress, 36e23);
    return true;
  }

  /**
  * Set community multisig address
  */
  function setMultisigAddress(address multisigAddress)
    external
    onlyOwner
    returns(bool success)
  {
    multisig = multisigAddress;
    return true;
  }

  /**
  * Community is allocated 5M governance tokens which are released on the same
  * curve as the tokens that users can stake for. No staking required for this.
  * Rewards accumulated can be claimed into the multisig address anytime.
  */
  function claimMultisigAllocation()
    external
    returns(uint256 amountReleased)
  {
    // Collect global staking state
    StakingState memory state = stakingState;
    require(block.timestamp > state.startTime, "Too early guys");

    // Calculate total community allocation until now
    uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
    t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
    uint256 R1 = 5e24 * t1 / 365 days - 25e23 * t1 * t1 / (365 days)**2;

    // Calculate how much is to be released now & update released counter
    amountReleased = R1 - multisigAllocationClaimed;
    multisigAllocationClaimed = R1;

    // Grant rewards and emit event for logging
    _mint(multisig, amountReleased);
    emit MultisigClaim(multisig, amountReleased);
  }

  /**
  * Founder is granted 5M governance tokens after 1 year.
  */
  function claimFounderAllocation(uint256 amount, address destination)
    external
    returns(uint256 actualAmount)
  {
    // Basic validity checks
    require(msg.sender == founder, "Not yours man");
    StakingState memory state = stakingState;
    require(block.timestamp - state.startTime >= 365 days, "Too early man");

    // Calculate how many rewards are still available & update claimed counter
    uint256 availableAmount = 25e23 - founderAllocationClaimed;
    actualAmount = (amount > availableAmount) ? availableAmount : amount;
    founderAllocationClaimed += actualAmount;

    // Grant rewards and emit event for logging
    _mint(destination, actualAmount);
    emit FounderClaim(destination, actualAmount);
  }

  /**
  * Freeze program (makes it easier to migrate if required)
  * This is a one-way thing, only to be used in case of migration.
  */
  function stopProgram()
    external
    onlyOwner()
  {
    // Update the global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }

    // Freeze by setting the startTime when we're all going to be dead
    state.startTime = type(uint32).max;
    stakingState = state;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

interface IDeFiPlazaGov {
  function stake(
    uint96 LPamount
  ) external returns(bool success);

  function unstake(
    uint96 LPamount
  ) external returns(uint256 rewards);

  function rewardsQuote(
    address stakerAddress
  ) external view returns(uint256 rewards);

  event Staked(
    address staker,
    uint256 LPamount
  );

  event Unstaked(
    address staker,
    uint256 LPamount,
    uint256 rewards
  );

  event MultisigClaim(
    address multisig,
    uint256 amount
  );

  event FounderClaim(
    address claimant,
    uint256 amount
  );
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
    constructor() {
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

import "../IERC20.sol";

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
        return msg.data;
    }
}

