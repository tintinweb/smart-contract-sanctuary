/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// File: contracts/access/Ownable.sol

pragma solidity ^0.5.16;

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

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.5.16;

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
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
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
     * Counterpart to Solidity's `/` operator. Note: this function uses a
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.5.16;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
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
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
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

// File: contracts/token/ERC20.sol

pragma solidity ^0.5.16;



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
 * these events, as it isn't required by the specification.
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: contracts/libraries/Address.sol

pragma solidity ^0.5.16;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
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

// File: contracts/libraries/SafeERC20.sol

pragma solidity ^0.5.16;




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
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

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

// File: contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersVault contract
 **/

interface IDeepWatersVault {
    function liquidationUserBorrow(address _asset, address _user) external;
    function getAssetDecimals(address _asset) external view returns (uint256);
    function getAssetIsActive(address _asset) external view returns (bool);
    function getAssetDTokenAddress(address _asset) external view returns (address);
    function getAssetTotalLiquidity(address _asset) external view returns (uint256);
    function getAssetTotalBorrowBalance(address _asset) external view returns (uint256);
    function getAssetScarcityRatio(address _asset) external view returns (uint256);
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256);
    function getAssetBaseInterestRate(address _asset) external view returns (uint256);
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256);
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256);
    function getAssetVariableInterestRate(address _asset) external view returns (uint256);
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256);
    function getAssetLiquidityRate(address _asset) external view returns (uint256);
    function getAssetCumulatedLiquidityIndex(address _asset) external view returns (uint256);
    function updateCumulatedLiquidityIndex(address _asset) external returns (uint256);
    function getInterestOnDeposit(address _asset, address _user) external view returns (uint256);
    function updateUserCumulatedLiquidityIndex(address _asset, address _user) external;
    function getAssetPriceUSD(address _asset) external view returns (uint256);
    function getUserAssetBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256);
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool);
    function getAssets() external view returns (address[] memory);
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external;
    function transferToUser(address _asset, address payable _user, uint256 _amount) external;
    function transferToRouter(address _asset, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) external;
    function getUserBorrowCurrentLinearInterest(address _asset, address _user) external view returns (uint256);
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) external;
    function() external payable;
}

// File: contracts/interfaces/ILendingPool.sol

pragma solidity ^0.5.16;

/**
 * @dev Partial interface for a Aave LendingPool contract,
 * which is the main point of interaction with an Aave protocol's market
 **/
interface ILendingPool {
    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    /**
    * @dev Returns the state and configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The state of the reserve
    **/
    function getReserveData(address asset) 
        external
        view
        returns (
            //stores the reserve configuration
            //bit 0-15: LTV
            //bit 16-31: Liq. threshold
            //bit 32-47: Liq. bonus
            //bit 48-55: Decimals
            //bit 56: Reserve is active
            //bit 57: reserve is frozen
            //bit 58: borrowing is enabled
            //bit 59: stable rate borrowing enabled
            //bit 60-63: reserved
            //bit 64-79: reserve factor
            uint256 configuration,
            //the liquidity index. Expressed in ray
            uint128 liquidityIndex,
            //variable borrow index. Expressed in ray
            uint128 variableBorrowIndex,
            //the current supply rate. Expressed in ray
            uint128 currentLiquidityRate,
            //the current variable borrow rate. Expressed in ray
            uint128 currentVariableBorrowRate,
            //the current stable borrow rate. Expressed in ray
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            //tokens addresses
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            //address of the interest rate strategy
            address interestRateStrategyAddress,
            //the id of the reserve. Represents the position in the list of the active reserves
            uint8 id
        );
}

// File: contracts/interfaces/IWETHGateway.sol

pragma solidity ^0.5.16;

/**
 * @dev Partial interface for a Aave WETHGateway contract,
 **/
interface IWETHGateway {
  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param lendingPool address of the targeted underlying lending pool
   * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param lendingPool address of the targeted underlying lending pool
   * @param amount amount of aWETH to withdraw and receive native ETH
   * @param onBehalfOf address of the user who will receive native ETH
   */
  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;
  
  /**
   * @dev Get WETH address used by WETHGateway
   */
  function getWETHAddress() external view returns (address);
}

// File: contracts/interfaces/ComptrollerInterface.sol

pragma solidity ^0.5.16;

/**
 * @dev Partial interface for a Compound's CTokenInterface Contract
 **/

interface ComptrollerInterface {
    // @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external returns (bool);
    
    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (address[] memory);
}

// File: contracts/interfaces/CTokenInterface.sol

pragma solidity ^0.5.16;

/**
 * @dev Partial interface for a Compound's CTokenInterface Contract
 **/

interface CTokenInterface {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    function isCToken() external returns (bool);
    
    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external returns (address);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external returns (uint8);
    
    /*** User Interface ***/
    function mint(uint mintAmount) external returns (uint);
    
    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see CompoundCTokenError for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// File: contracts/interfaces/CEtherInterface.sol

pragma solidity ^0.5.16;

/**
 * @dev Partial interface for a Compound's CEther Contract
 **/

interface CEtherInterface {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    function isCToken() external returns (bool);
    
    /**
     * @notice EIP-20 token name for this token
     */
    function name() external returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external returns (uint8);
    
    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable;
}

// File: contracts/DeepWatersRouter.sol

pragma solidity ^0.5.16;











/**
* @title DeepWatersRouter contract
* @author DeepWaters
* @dev Implements functions to transfer assets from DeepWatersVault contract to Aave protocol and back.
*
* Holds the derivatives (aTokens).
**/
contract DeepWatersRouter is Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    IDeepWatersVault public vault;
    
    ILendingPool public aaveLendingPool;
    IWETHGateway public aaveWETHGateway;
    
    ComptrollerInterface public compoundComptroller;
    
    /**
    * @dev emitted on deposit to Aave
    * @param _asset the address of the basic asset
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositeToAave(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on redeem from Aave
    * @param _asset the address of the basic asset
    * @param _amount the amount to be redeemed
    * @param _timestamp the timestamp of the action
    **/
    event RedeemFromAave(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on deposit to Compound
    * @param _asset the address of the basic asset
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositeToCompound(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on redeem from Compound
    * @param _asset the address of the basic asset
    * @param _amount the amount to be redeemed
    * @param _timestamp the timestamp of the action
    **/
    event RedeemFromCompound(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    string[] internal compoundCTokenError = [
        'NO_ERROR',
        'UNAUTHORIZED',
        'BAD_INPUT',
        'COMPTROLLER_REJECTION',
        'COMPTROLLER_CALCULATION_ERROR',
        'INTEREST_RATE_MODEL_ERROR',
        'INVALID_ACCOUNT_PAIR',
        'INVALID_CLOSE_AMOUNT_REQUESTED',
        'INVALID_COLLATERAL_FACTOR',
        'MATH_ERROR',
        'MARKET_NOT_FRESH',
        'MARKET_NOT_LISTED',
        'TOKEN_INSUFFICIENT_ALLOWANCE',
        'TOKEN_INSUFFICIENT_BALANCE',
        'TOKEN_INSUFFICIENT_CASH',
        'TOKEN_TRANSFER_IN_FAILED',
        'TOKEN_TRANSFER_OUT_FAILED'
    ];
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Aave balances of router loans by assets
    mapping(address => uint256) public aaveRouterLoanBalances;
    
    // Compound balances of router loans by assets
    mapping(address => uint256) public compoundRouterLoanBalances;
    
    // Aave interest bearing WETH (aWETH)
    address public aWETH;
    
    constructor(
        address payable _vault,
        address _aaveLendingPool,
        address _aaveWETHGateway,
        address _compoundComptroller
    ) public {
        vault = IDeepWatersVault(_vault);
        aaveLendingPool = ILendingPool(_aaveLendingPool);
        aaveWETHGateway = IWETHGateway(_aaveWETHGateway);
        updateAWETH();
        
        compoundComptroller = ComptrollerInterface(_compoundComptroller);
    }

    /**
    * @dev deposites an asset from a DeepWatersVault to Aave protocol
    * @param _asset the address of the asset
    * @param _amount the asset amount being deposited
    **/
    function depositeToAave(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset in Aave protocol
        ( , , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(_asset);
        require(aTokenAddress != address(0), "The asset is not supported by the Aave protocol");
        
        // verification of an asset liquidity in DeepWatersVault contract
        require(_amount <= vault.getAssetTotalLiquidity(_asset), "There is not enough asset liquidity for the operation");
        
        // get _asset from DeepWatersVault contract
        vault.transferToRouter(_asset, _amount);
        
        aaveRouterLoanBalances[_asset] = aaveRouterLoanBalances[_asset].add(_amount);
        
        if (_asset == ETH_ADDRESS) {
            // deposit ETH to Aave protocol
            aaveWETHGateway.depositETH.value(_amount)(
                address(aaveLendingPool),
                address(this),
                0
            );
        } else {
            ERC20(_asset).approve(
                address(aaveLendingPool),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            
            // deposit _asset to Aave protocol
            aaveLendingPool.deposit(
                _asset,
                _amount,
                address(this),
                0
            );
        }
        
        emit DepositeToAave(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev redeems an asset from Aave protocol to DeepWatersVault
    * @param _asset the address of the asset
    * @param _amount the asset amount being redeemed
    **/
    function redeemFromAave(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset in Aave protocol
        ( , , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(_asset);
        require(aTokenAddress != address(0), "The asset is not supported by the Aave protocol");
        
        // verification loan balance of an asset in DeepWatersRouter contract
        require(_amount <= aaveRouterLoanBalances[_asset], "_amount exceeds the loan balance of an asset in DeepWatersRouter contract");

        if (_asset == ETH_ADDRESS) {
            ERC20(aWETH).approve(
                address(aaveWETHGateway),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        
            // withdraw ETH from Aave protocol
            aaveWETHGateway.withdrawETH(
                address(aaveLendingPool),
                _amount,
                address(this)
            );
            
            address(vault).transfer(_amount);
        } else {
            // withdraw _asset from Aave protocol to DeepWatersRouter contract
            aaveLendingPool.withdraw(
                _asset,
                _amount,
                address(this)
            );
            
            ERC20(_asset).safeTransfer(address(vault), _amount);
        }
        
        aaveRouterLoanBalances[_asset] = aaveRouterLoanBalances[_asset].sub(_amount);
        
        emit RedeemFromAave(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev deposites an asset from a DeepWatersVault to Compound protocol
    * @param _asset the address of the asset
    * @param _amount the asset amount being deposited
    **/
    function depositeToCompound(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset liquidity in DeepWatersVault contract
        require(_amount <= vault.getAssetTotalLiquidity(_asset), "There is not enough asset liquidity for the operation");
        
        address compoundMarketAddress = getCompoundMarketAddress(_asset);
        
        // get _asset from DeepWatersVault contract
        vault.transferToRouter(_asset, _amount);
        
        compoundRouterLoanBalances[_asset] = compoundRouterLoanBalances[_asset].add(_amount);
        
        if (_asset == ETH_ADDRESS) {
            CEtherInterface cEther = CEtherInterface(compoundMarketAddress);
            
            // deposit ETH to Compound protocol
            cEther.mint.value(_amount)();
        } else {
            ERC20(_asset).approve(
                compoundMarketAddress,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            
            CTokenInterface cToken = CTokenInterface(compoundMarketAddress);
            
            // deposit _asset to Compound protocol
            uint result = cToken.mint(_amount);
            require(result == 0, compoundCTokenError[result]);
        }
        
        emit DepositeToCompound(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev redeems an asset from Compound protocol to DeepWatersVault
    * @param _asset the address of the asset
    * @param _amount the asset amount being redeemed
    **/
    function redeemFromCompound(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification loan balance of an asset in DeepWatersRouter contract
        require(_amount <= compoundRouterLoanBalances[_asset], "_amount exceeds the loan balance of an asset in DeepWatersRouter contract");
        
        address compoundMarketAddress = getCompoundMarketAddress(_asset);
        
        CTokenInterface cToken = CTokenInterface(compoundMarketAddress);
        
        // redeem _asset from Compound protocol to DeepWatersRouter contract
        uint result = cToken.redeemUnderlying(_amount);
        require(result == 0, compoundCTokenError[result]);
        
        if (_asset == ETH_ADDRESS) {
            address(vault).transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(address(vault), _amount);
        }
        
        compoundRouterLoanBalances[_asset] = compoundRouterLoanBalances[_asset].sub(_amount);
        
        emit RedeemFromCompound(_asset, _amount, block.timestamp);
    }
    
    function getCompoundMarketAddress(address _asset)
        public 
        returns (address)
    {
        require(compoundComptroller.isComptroller(), "Wrong comptroller address");
        address[] memory compoundMarkets = compoundComptroller.getAllMarkets();
        
        CTokenInterface compoundMarket;
        bool compoundMarketFound;
        
        for (uint256 j = 0; j < compoundMarkets.length; j++) {
            compoundMarket = CTokenInterface(compoundMarkets[j]);
            
            if (_asset == ETH_ADDRESS) {
                if (keccak256(abi.encodePacked(compoundMarket.symbol())) == 
                        keccak256(abi.encodePacked('cETH'))) {
                    compoundMarketFound = true;
                    break;
                }
            } else {
                if (keccak256(abi.encodePacked(compoundMarket.symbol())) !=
                        keccak256(abi.encodePacked('cETH')) && 
                        compoundMarket.underlying() == _asset) {
                    compoundMarketFound = true;
                    break;
                }
            }
        }
        
        // verification of an asset in Compound protocol
        require(compoundMarketFound, "The asset is not supported by the Compound protocol");
        
        return address(compoundMarket);
    }
    
    function updateAWETH() internal {
        address WETHAddress = aaveWETHGateway.getWETHAddress();
        ( , , , , , , , aWETH, , , , ) = aaveLendingPool.getReserveData(WETHAddress);
        require(aWETH != address(0), "aWETH does not exist");
    }
    
    function setAaveLendingPool(address _newAaveLendingPool) external onlyOwner {
        aaveLendingPool = ILendingPool(_newAaveLendingPool);
        updateAWETH();
    }
    
    function setAaveWETHGateway(address _newAaveWETHGateway) external onlyOwner {
        aaveWETHGateway = IWETHGateway(_newAaveWETHGateway);
        updateAWETH();
    }
    
    function setCompoundComptroller(address _newCompoundComptroller) external onlyOwner {
        compoundComptroller = ComptrollerInterface(_newCompoundComptroller);
    }
}