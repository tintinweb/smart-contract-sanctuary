/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn&#39;t required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`&#39;s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller&#39;s allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract&#39;s constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity&#39;s return data size checking mechanism, since
        // we&#39;re implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/CERC20.sol

pragma solidity ^0.5.2;

interface CERC20 {
  function mint(uint256 mintAmount) external returns (uint256);
  function redeem(uint256 redeemTokens) external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function supplyRatePerBlock() external view returns (uint256);
}

// File: contracts/interfaces/iERC20.sol

pragma solidity ^0.5.2;

interface iERC20 {
  function mint(
    address receiver,
    uint256 depositAmount)
    external
    returns (uint256 mintAmount);

  function burn(
    address receiver,
    uint256 burnAmount)
    external
    returns (uint256 loanAmountPaid);

  function tokenPrice()
    external
    view
    returns (uint256 price);

  function supplyInterestRate()
    external
    view
    returns (uint256);

  function claimLoanToken()
    external
    returns (uint256 claimedAmount);

  /* function burnToEther(
    address receiver,
    uint256 burnAmount)
    external
    returns (uint256 loanAmountPaid);


  function supplyInterestRate()
    external
    view
    returns (uint256);

  function assetBalanceOf(
    address _owner)
    external
    view
    returns (uint256);

  function claimLoanToken()
    external
    returns (uint256 claimedAmount); */
}

// File: contracts/IdleHelp.sol

pragma solidity ^0.5.2;





library IdleHelp {
  using SafeMath for uint256;

  function getPriceInToken(address cToken, address iToken, address bestToken, uint256 totalSupply, uint256 poolSupply)
    public view
    returns (uint256 tokenPrice) {
      // 1Token = net_asset_value / total_Token_liquidity
      // net_asset_value = (rate of 1(cToken || iToken) in underlying_Token) * balanceOf((cToken || iToken))
      uint256 navPool;
      uint256 price;

      // rate
      if (bestToken == cToken) {
        // exchangeRateStored is the rate (in wei, 8 decimals) of 1cDAI in DAI * 10**18
        price = CERC20(cToken).exchangeRateStored(); // 202487304197710837666727644 ->
      } else {
        price = iERC20(iToken).tokenPrice(); // eg 1001495070730287403 -> 1iToken in wei = 1001495070730287403 Token
      }
      navPool = price.mul(poolSupply); // eg 43388429749999990000 in DAI
      tokenPrice = navPool.div(totalSupply); // idleToken price in token wei
  }
  function getAPRs(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (uint256 cApr, uint256 iApr) {
      uint256 cRate = CERC20(cToken).supplyRatePerBlock(); // interest % per block
      cApr = cRate.mul(blocksInAYear).mul(100);
      iApr = iERC20(iToken).supplyInterestRate(); // APR in wei 18 decimals
  }
  function getBestRateToken(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (address bestRateToken, uint256 bestRate, uint256 worstRate) {
      (uint256 cApr, uint256 iApr) = getAPRs(cToken, iToken, blocksInAYear);
      bestRateToken = cToken;
      bestRate = cApr;
      worstRate = iApr;
      if (iApr > cApr) {
        worstRate = cApr;
        bestRate = iApr;
        bestRateToken = iToken;
      }
  }
  function rebalanceCheck(address cToken, address iToken, address bestToken, uint256 blocksInAYear, uint256 minRateDifference)
    public view
    returns (bool shouldRebalance, address bestTokenAddr) {
      shouldRebalance = false;

      uint256 _bestRate;
      uint256 _worstRate;
      (bestTokenAddr, _bestRate, _worstRate) = getBestRateToken(cToken, iToken, blocksInAYear);
      if (
          bestToken == address(0) ||
          (bestTokenAddr != bestToken && (_worstRate.add(minRateDifference) < _bestRate))) {
        shouldRebalance = true;
        return (shouldRebalance, bestTokenAddr);
      }

      return (shouldRebalance, bestTokenAddr);
  }
}

// File: contracts/IdleDAI.sol

pragma solidity ^0.5.2;











contract IdleDAI is ERC20, ERC20Detailed, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public cToken; // cTokens have 8 decimals
  address public iToken; // iTokens have 18 decimals
  address public token;
  address public bestToken;

  uint256 public blocksInAYear;
  uint256 public minRateDifference;

  /**
   * @dev constructor
   */
  constructor(address _cToken, address _iToken, address _token)
    public
    ERC20Detailed("IdleDAI", "IDLEDAI", 18) {
      cToken = _cToken;
      iToken = _iToken;
      token = _token;
      blocksInAYear = 2102400; // ~15 sec per block
      minRateDifference = 300000000000000000; // 0.3% min
  }

  // onlyOwner
  function setMinRateDifference(uint256 _rate)
    external onlyOwner {
      minRateDifference = _rate;
  }
  function setBlocksInAYear(uint256 _blocks)
    external onlyOwner {
      blocksInAYear = _blocks;
  }
  function setToken(address _token)
    external onlyOwner {
      token = _token;
  }
  function setIToken(address _iToken)
    external onlyOwner {
      iToken = _iToken;
  }
  function setCToken(address _cToken)
    external onlyOwner {
      cToken = _cToken;
  }
  // This should never be called, only in case of contract failure
  // after an audit this should be removed
  function emergencyWithdraw(address _token, uint256 _value)
    external onlyOwner {
      IERC20 underlying = IERC20(_token);
      if (_value != 0) {
        underlying.safeTransfer(msg.sender, _value);
      } else {
        underlying.safeTransfer(msg.sender, underlying.balanceOf(address(this)));
      }
  }

  // view
  function tokenPrice()
    public view
    returns (uint256 price) {
      uint256 poolSupply = IERC20(cToken).balanceOf(address(this));
      if (bestToken == iToken) {
        poolSupply = IERC20(iToken).balanceOf(address(this));
      }

      price = IdleHelp.getPriceInToken(
        cToken,
        iToken,
        bestToken,
        this.totalSupply(),
        poolSupply
      );
  }
  function rebalanceCheck()
    public view
    returns (bool, address) {
      return IdleHelp.rebalanceCheck(cToken, iToken, bestToken, blocksInAYear, minRateDifference);
  }
  function getAPRs()
    external view
    returns (uint256, uint256) {
      return IdleHelp.getAPRs(cToken, iToken, blocksInAYear);
  }

  // public
  /**
   * @dev User should &#39;approve&#39; _amount tokens before calling mintIdleToken
   */
  function mintIdleToken(uint256 _amount)
    external nonReentrant
    returns (uint256 mintedTokens) {
      require(_amount > 0, "Amount is not > 0");
      // get a handle for the underlying asset contract
      IERC20 underlying = IERC20(token);
      // transfer to this contract
      underlying.safeTransferFrom(msg.sender, address(this), _amount);

      rebalance();

      uint256 idlePrice = 10**18;
      uint256 totalSupply = this.totalSupply();
      if (totalSupply != 0) {
        idlePrice = tokenPrice();
      }

      if (bestToken == cToken) {
        _mintCTokens(_amount);
      } else {
        _mintITokens(_amount);
      }
      if (totalSupply == 0) {
        mintedTokens = _amount; // 1:1
      } else {
        mintedTokens = _amount.mul(10**18).div(idlePrice);
      }
      _mint(msg.sender, mintedTokens);
  }

  /**
   * @dev here we calc the pool share of the cTokens | iTokens one can withdraw
   */
  function redeemIdleToken(uint256 _amount)
    external nonReentrant
    returns (uint256 tokensRedeemed) {
    uint256 idleSupply = this.totalSupply();
    require(idleSupply > 0, &#39;No IDLEDAI have been issued&#39;);

    if (bestToken == cToken) {
      uint256 cPoolBalance = IERC20(cToken).balanceOf(address(this));
      uint256 cDAItoRedeem = _amount.mul(cPoolBalance).div(idleSupply);
      tokensRedeemed = _redeemCTokens(cDAItoRedeem, msg.sender);
    } else {
      uint256 iPoolBalance = IERC20(iToken).balanceOf(address(this));
      uint256 iDAItoRedeem = _amount.mul(iPoolBalance).div(idleSupply);
      // TODO we should inform the user of the eventual excess of token that can be redeemed directly in Fulcrum
      tokensRedeemed = _redeemITokens(iDAItoRedeem, msg.sender);
    }
    _burn(msg.sender, _amount);
    rebalance();
  }

  /**
   * @dev Convert cToken pool in iToken pool (or the contrary) if needed
   * Everyone should be incentivized in calling this method
   */
  function rebalance()
    public {
      (bool shouldRebalance, address newBestTokenAddr) = rebalanceCheck();
      if (!shouldRebalance) {
        return;
      }

      if (bestToken != address(0)) {
        // bestToken here is the &#39;old&#39; best token
        if (bestToken == cToken) {
          _redeemCTokens(IERC20(cToken).balanceOf(address(this)), address(this)); // token are now in this contract
          _mintITokens(IERC20(token).balanceOf(address(this)));
        } else {
          _redeemITokens(IERC20(iToken).balanceOf(address(this)), address(this));
          _mintCTokens(IERC20(token).balanceOf(address(this)));
        }
      }

      // Update best token address
      bestToken = newBestTokenAddr;
  }
  /**
   * @dev here we are redeeming unclaimed token (from iToken contract) to this contracts
   * then converting the claimedTokens in the bestToken after rebalancing
   * Everyone should be incentivized in calling this method
   */
  function claimITokens()
    external
    returns (uint256 claimedTokens) {
      claimedTokens = iERC20(iToken).claimLoanToken();
      if (claimedTokens == 0) {
        return claimedTokens;
      }

      rebalance();
      if (bestToken == cToken) {
        _mintCTokens(claimedTokens);
      } else {
        _mintITokens(claimedTokens);
      }

      return claimedTokens;
  }

  // internal
  function _mintCTokens(uint256 _amount)
    internal
    returns (uint256 cTokens) {
      if (IERC20(token).balanceOf(address(this)) == 0) {
        return cTokens;
      }
      // approve the transfer to cToken contract
      IERC20(token).safeIncreaseAllowance(cToken, _amount);

      // get a handle for the corresponding cToken contract
      CERC20 _cToken = CERC20(cToken);
      // mint the cTokens and assert there is no error
      require(_cToken.mint(_amount) == 0, "Error minting");
      // cTokens are now in this contract

      // generic solidity formula is exchangeRateMantissa = (underlying / cTokens) * 1e18
      uint256 exchangeRateMantissa = _cToken.exchangeRateStored(); // (exchange_rate * 1e18)
      // so cTokens = (underlying * 1e18) / exchangeRateMantissa
      cTokens = _amount.mul(10**18).div(exchangeRateMantissa);
  }
  function _mintITokens(uint256 _amount)
    internal
    returns (uint256 iTokens) {
      if (IERC20(token).balanceOf(address(this)) == 0) {
        return iTokens;
      }
      // approve the transfer to iToken contract
      IERC20(token).safeIncreaseAllowance(iToken, _amount);
      // get a handle for the corresponding iToken contract
      iERC20 _iToken = iERC20(iToken);
      // mint the iTokens
      iTokens = _iToken.mint(address(this), _amount);
  }

  function _redeemCTokens(uint256 _amount, address _account)
    internal
    returns (uint256 tokens) {
      CERC20 _cToken = CERC20(cToken);
      // redeem all user&#39;s underlying
      require(_cToken.redeem(_amount) == 0, "Something went wrong when redeeming in cTokens");

      // generic solidity formula is exchangeRateMantissa = (underlying / cTokens) * 1e18
      uint256 exchangeRateMantissa = _cToken.exchangeRateStored(); // exchange_rate * 1e18
      // so underlying = (exchangeRateMantissa * cTokens) / 1e18
      tokens = _amount.mul(exchangeRateMantissa).div(10**18);

      if (_account != address(this)) {
        IERC20(token).safeTransfer(_account, tokens);
      }
  }
  function _redeemITokens(uint256 _amount, address _account)
    internal
    returns (uint256 tokens) {
      tokens = iERC20(iToken).burn(_account, _amount);
  }
}