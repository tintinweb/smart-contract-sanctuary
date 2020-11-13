// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

// File: contracts/protocol/interfaces/IDmmEther.sol

pragma solidity ^0.5.0;

interface IDmmEther {

    /**
     * @return The address for WETH being used by this contract.
     */
    function wethToken() external view returns (address);

    /**
     * Sends ETH from msg.sender to this contract to mint mETH.
     */
    function mintViaEther() external payable returns (uint);

    /**
     * Redeems the corresponding amount of mETH (from msg.sender) for WETH instead of ETH and sends it to `msg.sender`
     */
    function redeemToWETH(uint amount) external returns (uint);

}

// File: contracts/protocol/interfaces/InterestRateInterface.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

interface InterestRateInterface {

    /**
      * @dev Returns the current interest rate for the given DMMA and corresponding total supply & active supply
      *
      * @param dmmTokenId The DMMA whose interest should be retrieved
      * @param totalSupply The total supply fot he DMM token
      * @param activeSupply The supply that's currently being lent by users
      * @return The interest rate in APY, which is a number with 18 decimals
      */
    function getInterestRate(uint dmmTokenId, uint totalSupply, uint activeSupply) external view returns (uint);

}

// File: contracts/protocol/interfaces/IUnderlyingTokenValuator.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

interface IUnderlyingTokenValuator {

    /**
      * @dev Gets the tokens value in terms of USD.
      *
      * @return The value of the `amount` of `token`, as a number with the same number of decimals as `amount` passed
      *         in to this function.
      */
    function getTokenValue(address token, uint amount) external view returns (uint);

}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/utils/Blacklistable.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;


/**
 * @dev Allows accounts to be blacklisted by the owner of the contract.
 *
 *  Taken from USDC's contract for blacklisting certain addresses from owning and interacting with the token.
 */
contract Blacklistable is Ownable {

    string public constant BLACKLISTED = "BLACKLISTED";

    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the creator of this contract
    */
    modifier onlyBlacklister() {
        require(msg.sender == owner(), "MUST_BE_BLACKLISTER");
        _;
    }

    /**
     * @dev Throws if `account` is blacklisted
     *
     * @param account The address to check
    */
    modifier notBlacklisted(address account) {
        require(blacklisted[account] == false, BLACKLISTED);
        _;
    }

    /**
     * @dev Checks if `account` is blacklisted. Reverts with `BLACKLISTED` if blacklisted.
    */
    function checkNotBlacklisted(address account) public view {
        require(!blacklisted[account], BLACKLISTED);
    }

    /**
     * @dev Checks if `account` is blacklisted
     *
     * @param account The address to check
    */
    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    /**
     * @dev Adds `account` to blacklist
     *
     * @param account The address to blacklist
    */
    function blacklist(address account) public onlyBlacklister {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Removes account from blacklist
     *
     * @param account The address to remove from the blacklist
    */
    function unBlacklist(address account) public onlyBlacklister {
        blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

}

// File: contracts/protocol/interfaces/IDmmController.sol

pragma solidity ^0.5.0;




interface IDmmController {

    event TotalSupplyIncreased(uint oldTotalSupply, uint newTotalSupply);
    event TotalSupplyDecreased(uint oldTotalSupply, uint newTotalSupply);

    event AdminDeposit(address indexed sender, uint amount);
    event AdminWithdraw(address indexed receiver, uint amount);

    /**
     * @dev Creates a new mToken using the provided data.
     *
     * @param underlyingToken   The token that should be wrapped to create a new DMMA
     * @param symbol            The symbol of the new DMMA, IE mDAI or mUSDC
     * @param name              The name of this token, IE `DMM: DAI`
     * @param decimals          The number of decimals of the underlying token, and therefore the number for this DMMA
     * @param minMintAmount     The minimum amount that can be minted for any given transaction.
     * @param minRedeemAmount   The minimum amount that can be redeemed any given transaction.
     * @param totalSupply       The initial total supply for this market.
     */
    function addMarket(
        address underlyingToken,
        string calldata symbol,
        string calldata name,
        uint8 decimals,
        uint minMintAmount,
        uint minRedeemAmount,
        uint totalSupply
    ) external;

    /**
     * @dev Creates a new mToken using the already-existing token.
     *
     * @param dmmToken          The token that should be added to this controller.
     * @param underlyingToken   The token that should be wrapped to create a new DMMA.
     */
    function addMarketFromExistingDmmToken(
        address dmmToken,
        address underlyingToken
    ) external;

    /**
     * @param newController The new controller who should receive ownership of the provided DMM token IDs.
     */
    function transferOwnershipToNewController(
        address newController
    ) external;

    /**
     * @dev Enables the corresponding DMMA to allow minting new tokens.
     *
     * @param dmmTokenId  The DMMA that should be enabled.
     */
    function enableMarket(uint dmmTokenId) external;

    /**
     * @dev Disables the corresponding DMMA from minting new tokens. This allows the market to close over time, since
     *      users are only able to redeem tokens.
     *
     * @param dmmTokenId  The DMMA that should be disabled.
     */
    function disableMarket(uint dmmTokenId) external;

    /**
     * @dev Sets the new address that will serve as the guardian for this controller.
     *
     * @param newGuardian   The new address that will serve as the guardian for this controller.
     */
    function setGuardian(address newGuardian) external;

    /**
     * @dev Sets a new contract that implements the `DmmTokenFactory` interface.
     *
     * @param newDmmTokenFactory  The new contract that implements the `DmmTokenFactory` interface.
     */
    function setDmmTokenFactory(address newDmmTokenFactory) external;

    /**
     * @dev Sets a new contract that implements the `DmmEtherFactory` interface.
     *
     * @param newDmmEtherFactory  The new contract that implements the `DmmEtherFactory` interface.
     */
    function setDmmEtherFactory(address newDmmEtherFactory) external;

    /**
     * @dev Sets a new contract that implements the `InterestRate` interface.
     *
     * @param newInterestRateInterface  The new contract that implements the `InterestRateInterface` interface.
     */
    function setInterestRateInterface(address newInterestRateInterface) external;

    /**
     * @dev Sets a new contract that implements the `IOffChainAssetValuator` interface.
     *
     * @param newOffChainAssetValuator The new contract that implements the `IOffChainAssetValuator` interface.
     */
    function setOffChainAssetValuator(address newOffChainAssetValuator) external;

    /**
     * @dev Sets a new contract that implements the `IOffChainAssetValuator` interface.
     *
     * @param newOffChainCurrencyValuator The new contract that implements the `IOffChainAssetValuator` interface.
     */
    function setOffChainCurrencyValuator(address newOffChainCurrencyValuator) external;

    /**
     * @dev Sets a new contract that implements the `UnderlyingTokenValuator` interface
     *
     * @param newUnderlyingTokenValuator The new contract that implements the `UnderlyingTokenValuator` interface
     */
    function setUnderlyingTokenValuator(address newUnderlyingTokenValuator) external;

    /**
     * @dev Allows the owners of the DMM Ecosystem to withdraw funds from a DMMA. These withdrawn funds are then
     *      allocated to real-world assets that will be used to pay interest into the DMMA.
     *
     * @param newMinCollateralization   The new min collateralization (with 18 decimals) at which the DMME must be in
     *                                  order to add to the total supply of DMM.
     */
    function setMinCollateralization(uint newMinCollateralization) external;

    /**
     * @dev Allows the owners of the DMM Ecosystem to withdraw funds from a DMMA. These withdrawn funds are then
     *      allocated to real-world assets that will be used to pay interest into the DMMA.
     *
     * @param newMinReserveRatio   The new ratio (with 18 decimals) that is used to enforce a certain percentage of assets
     *                          are kept in each DMMA.
     */
    function setMinReserveRatio(uint newMinReserveRatio) external;

    /**
     * @dev Increases the max supply for the provided `dmmTokenId` by `amount`. This call reverts with
     *      INSUFFICIENT_COLLATERAL if there isn't enough collateral in the Chainlink contract to cover the controller's
     *      requirements for minimum collateral.
     */
    function increaseTotalSupply(uint dmmTokenId, uint amount) external;

    /**
     * @dev Increases the max supply for the provided `dmmTokenId` by `amount`.
     */
    function decreaseTotalSupply(uint dmmTokenId, uint amount) external;

    /**
     * @dev Allows the owners of the DMM Ecosystem to withdraw funds from a DMMA. These withdrawn funds are then
     *      allocated to real-world assets that will be used to pay interest into the DMMA.
     *
     * @param dmmTokenId        The ID of the DMM token whose underlying will be funded.
     * @param underlyingAmount  The amount underlying the DMM token that will be deposited into the DMMA.
     */
    function adminWithdrawFunds(uint dmmTokenId, uint underlyingAmount) external;

    /**
     * @dev Allows the owners of the DMM Ecosystem to deposit funds into a DMMA. These funds are used to disburse
     *      interest payments and add more liquidity to the specific market.
     *
     * @param dmmTokenId        The ID of the DMM token whose underlying will be funded.
     * @param underlyingAmount  The amount underlying the DMM token that will be deposited into the DMMA.
     */
    function adminDepositFunds(uint dmmTokenId, uint underlyingAmount) external;

    /**
     * @return  All of the DMM token IDs that are currently in the ecosystem. NOTE: this is an unfiltered list.
     */
    function getDmmTokenIds() external view returns (uint[] memory);

    /**
     * @dev Gets the collateralization of the system assuming 1-year's worth of interest payments are due by dividing
     *      the total value of all the collateralized assets plus the value of the underlying tokens in each DMMA by the
     *      aggregate interest owed (plus the principal), assuming each DMMA was at maximum usage.
     *
     * @return  The 1-year collateralization of the system, as a number with 18 decimals. For example
     *          `1010000000000000000` is 101% or 1.01.
     */
    function getTotalCollateralization() external view returns (uint);

    /**
     * @dev Gets the current collateralization of the system assuming by dividing the total value of all the
     *      collateralized assets plus the value of the underlying tokens in each DMMA by the aggregate interest owed
     *      (plus the principal), using the current usage of each DMMA.
     *
     * @return  The active collateralization of the system, as a number with 18 decimals. For example
     *          `1010000000000000000` is 101% or 1.01.
     */
    function getActiveCollateralization() external view returns (uint);

    /**
     * @dev Gets the interest rate from the underlying token, IE DAI or USDC.
     *
     * @return  The current interest rate, represented using 18 decimals. Meaning `65000000000000000` is 6.5% APY or
     *          0.065.
     */
    function getInterestRateByUnderlyingTokenAddress(address underlyingToken) external view returns (uint);

    /**
     * @dev Gets the interest rate from the DMM token, IE DMM: DAI or DMM: USDC.
     *
     * @return  The current interest rate, represented using 18 decimals. Meaning, `65000000000000000` is 6.5% APY or
     *          0.065.
     */
    function getInterestRateByDmmTokenId(uint dmmTokenId) external view returns (uint);

    /**
     * @dev Gets the interest rate from the DMM token, IE DMM: DAI or DMM: USDC.
     *
     * @return  The current interest rate, represented using 18 decimals. Meaning, `65000000000000000` is 6.5% APY or
     *          0.065.
     */
    function getInterestRateByDmmTokenAddress(address dmmToken) external view returns (uint);

    /**
     * @dev Gets the exchange rate from the underlying to the DMM token, such that
     *      `DMM: Token = underlying / exchangeRate`
     *
     * @return  The current exchange rate, represented using 18 decimals. Meaning, `200000000000000000` is 0.2.
     */
    function getExchangeRateByUnderlying(address underlyingToken) external view returns (uint);

    /**
     * @dev Gets the exchange rate from the underlying to the DMM token, such that
     *      `DMM: Token = underlying / exchangeRate`
     *
     * @return  The current exchange rate, represented using 18 decimals. Meaning, `200000000000000000` is 0.2.
     */
    function getExchangeRate(address dmmToken) external view returns (uint);

    /**
     * @dev Gets the DMM token for the provided underlying token. For example, sending DAI returns DMM: DAI.
     */
    function getDmmTokenForUnderlying(address underlyingToken) external view returns (address);

    /**
     * @dev Gets the underlying token for the provided DMM token. For example, sending DMM: DAI returns DAI.
     */
    function getUnderlyingTokenForDmm(address dmmToken) external view returns (address);

    /**
     * @return True if the market is enabled for this DMMA or false if it is not enabled.
     */
    function isMarketEnabledByDmmTokenId(uint dmmTokenId) external view returns (bool);

    /**
     * @return True if the market is enabled for this DMM token (IE DMM: DAI) or false if it is not enabled.
     */
    function isMarketEnabledByDmmTokenAddress(address dmmToken) external view returns (bool);

    /**
     * @return True if the market is enabled for this underlying token (IE DAI) or false if it is not enabled.
     */
    function getTokenIdFromDmmTokenAddress(address dmmTokenAddress) external view returns (uint);

    /**
     * @dev Gets the DMM token contract address for the provided DMM token ID. For example, `1` returns the mToken
     *      contract address for that token ID.
     */
    function getDmmTokenAddressByDmmTokenId(uint dmmTokenId) external view returns (address);

    function blacklistable() external view returns (Blacklistable);

    function underlyingTokenValuator() external view returns (IUnderlyingTokenValuator);

}

// File: contracts/protocol/interfaces/IDmmToken.sol

pragma solidity ^0.5.0;


/**
 * Basically an interface except, contains the implementation of the type-hashes for offline signature generation.
 *
 * This contract contains the signatures and documentation for all publicly-implemented functions in the DMM token.
 */
interface IDmmToken {

    /*****************
     * Events
     */

    event Mint(address indexed minter, address indexed recipient, uint amount);
    event Redeem(address indexed redeemer, address indexed recipient, uint amount);
    event FeeTransfer(address indexed owner, address indexed recipient, uint amount);

    event TotalSupplyIncreased(uint oldTotalSupply, uint newTotalSupply);
    event TotalSupplyDecreased(uint oldTotalSupply, uint newTotalSupply);

    event OffChainRequestValidated(address indexed owner, address indexed feeRecipient, uint nonce, uint expiry, uint feeAmount);

    /*****************
     * Functions
     */

    /**
     * @dev The controller that deployed this parent
     */
    function controller() external view returns (IDmmController);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @return  The min amount that can be minted in a single transaction. This amount corresponds with the number of
     *          decimals that this token has.
     */
    function minMintAmount() external view returns (uint);

    /**
     * @return  The min amount that can be redeemed from DMM to underlying in a single transaction. This amount
     *          corresponds with the number of decimals that this token has.
     */
    function minRedeemAmount() external view returns (uint);

    /**
      * @dev The amount of DMM that is in circulation (outside of this contract)
      */
    function activeSupply() external view returns (uint);

    /**
     * @dev Attempts to add `amount` to the total supply by issuing the tokens to this contract. This call fires a
     *      Transfer event from the 0x0 address to this contract.
     */
    function increaseTotalSupply(uint amount) external;

    /**
     * @dev Attempts to remove `amount` from the total supply by destroying those tokens that are held in this
     *      contract. This call reverts with TOO_MUCH_ACTIVE_SUPPLY if `amount` is not held in this contract.
     */
    function decreaseTotalSupply(uint amount) external;

    /**
     * @dev An admin function that lets the ecosystem's organizers deposit the underlying token around which this DMMA
     *      wraps to this contract. This is used to replenish liquidity and after interest payouts are made from the
     *      real-world assets.
     */
    function depositUnderlying(uint underlyingAmount) external returns (bool);

    /**
     * @dev An admin function that lets the ecosystem's organizers withdraw the underlying token around which this DMMA
     *      wraps from this contract. This is used to withdraw deposited tokens, to be allocated to real-world assets
     *      that produce income streams and can cover interest payments.
     */
    function withdrawUnderlying(uint underlyingAmount) external returns (bool);

    /**
      * @dev The timestamp at which the exchange rate was last updated.
      */
    function exchangeRateLastUpdatedTimestamp() external view returns (uint);

    /**
      * @dev The timestamp at which the exchange rate was last updated.
      */
    function exchangeRateLastUpdatedBlockNumber() external view returns (uint);

    /**
     * @dev The exchange rate from underlying to DMM. Invert this number to go from DMM to underlying. This number
     *      has 18 decimals.
     */
    function getCurrentExchangeRate() external view returns (uint);

    /**
     * @dev The current nonce of the provided `owner`. This `owner` should be the signer for any gasless transactions.
     */
    function nonceOf(address owner) external view returns (uint);

    /**
     * @dev Transfers the token around which this DMMA wraps from msg.sender to the DMMA contract. Then, sends the
     *      corresponding amount of DMM to the msg.sender. Note, this call reverts with INSUFFICIENT_DMM_LIQUIDITY if
     *      there is not enough DMM available to be minted.
     *
     * @param amount The amount of underlying to send to this DMMA for conversion to DMM.
     * @return The amount of DMM minted.
     */
    function mint(uint amount) external returns (uint);

    /**
     * @dev Transfers the token around which this DMMA wraps from sender to the DMMA contract. Then, sends the
     *      corresponding amount of DMM to recipient. Note, an allowance must be set for sender for the underlying
     *      token that is at least of size `amount` / `exchangeRate`. This call reverts with INSUFFICIENT_DMM_LIQUIDITY
     *      if there is not enough DMM available to be minted. See #MINT_TYPE_HASH. This function gives the `owner` the
     *      illusion of committing a gasless transaction, allowing a relayer to broadcast the transaction and
     *      potentially collect a fee for doing so.
     *
     * @param owner         The user that signed the off-chain message.
     * @param recipient     The address that will receive the newly-minted DMM tokens.
     * @param nonce         An auto-incrementing integer that prevents replay attacks. See #nonceOf(address) to get the
     *                      owner's current nonce.
     * @param expiry        The timestamp, in unix seconds, at which the signed off-chain message expires. A value of 0
     *                      means there is no expiration.
     * @param amount        The amount of underlying that should be minted by `owner` and sent to `recipient`.
     * @param feeAmount     The amount of DMM to be sent to feeRecipient for sending this transaction on behalf of
     *                      owner. Can be 0, which means the user won't be charged a fee. Must be <= `amount`.
     * @param feeRecipient  The address that should receive the fee. A value of 0x0 will send the fees to `msg.sender`.
     *                      Note, no fees are sent if the feeAmount is 0, regardless of what feeRecipient is.
     * @param v             The ECDSA V parameter.
     * @param r             The ECDSA R parameter.
     * @param s             The ECDSA S parameter.
     * @return  The amount of DMM minted, minus the fees paid. To get the total amount minted, add the `feeAmount` to
     *          the returned amount from this function call.
     */
    function mintFromGaslessRequest(
        address owner,
        address recipient,
        uint nonce,
        uint expiry,
        uint amount,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint);

    /**
     * @dev Transfers DMM from msg.sender to this DMMA contract. Then, sends the corresponding amount of token around
     *      which this DMMA wraps to the msg.sender. Note, this call reverts with INSUFFICIENT_UNDERLYING_LIQUIDITY if
     *      there is not enough DMM available to be redeemed.
     *
     * @param amount    The amount of DMM to be transferred from msg.sender to this DMMA.
     * @return          The amount of underlying redeemed.
     */
    function redeem(uint amount) external returns (uint);

    /**
     * @dev Transfers DMM from `owner` to the DMMA contract. Then, sends the corresponding amount of token around which
     *      this DMMA wraps to `recipient`. Note, an allowance must be set for sender for the underlying
     *      token that is at least of size `amount`. This call reverts with INSUFFICIENT_UNDERLYING_LIQUIDITY
     *      if there is not enough underlying available to be redeemed. See #REDEEM_TYPE_HASH. This function gives the
     *      `owner` the illusion of committing a gasless transaction, allowing a relayer to broadcast the transaction
     *      and potentially collect a fee for doing so.
     *
     * @param owner         The user that signed the off-chain message.
     * @param recipient     The address that will receive the newly-redeemed DMM tokens.
     * @param nonce         An auto-incrementing integer that prevents replay attacks. See #nonceOf(address) to get the
     *                      owner's current nonce.
     * @param expiry        The timestamp, in unix seconds, at which the signed off-chain message expires. A value of 0
     *                      means there is no expiration.
     * @param amount        The amount of DMM that should be redeemed for `owner` and sent to `recipient`.
     * @param feeAmount     The amount of DMM to be sent to feeRecipient for sending this transaction on behalf of
     *                      owner. Can be 0, which means the user won't be charged a fee. Must be <= `amount`
     * @param feeRecipient  The address that should receive the fee. A value of 0x0 will send the fees to `msg.sender`.
     *                      Note, no fees are sent if the feeAmount is 0, regardless of what feeRecipient is.
     * @param v             The ECDSA V parameter.
     * @param r             The ECDSA R parameter.
     * @param s             The ECDSA S parameter.
     * @return  The amount of underlying redeemed.
     */
    function redeemFromGaslessRequest(
        address owner,
        address recipient,
        uint nonce,
        uint expiry,
        uint amount,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint);

    /**
     * @dev Sets an allowance for owner with spender using an offline-generated signature. This function allows a
     *      relayer to send the transaction, giving the owner the illusion of committing a gasless transaction. See
     *      #PERMIT_TYPEHASH.
     *
     * @param owner         The user that signed the off-chain message.
     * @param spender       The contract/wallet that can spend DMM tokens on behalf of owner.
     * @param nonce         An auto-incrementing integer that prevents replay attacks. See #nonceOf(address) to get the
     *                      owner's current nonce.
     * @param expiry        The timestamp, in unix seconds, at which the signed off-chain message expires. A value of 0
     *                      means there is no expiration.
     * @param allowed       True if the spender can spend funds on behalf of owner or false to revoke this privilege.
     * @param feeAmount     The amount of DMM to be sent to feeRecipient for sending this transaction on behalf of
     *                      owner. Can be 0, which means the user won't be charged a fee.
     * @param feeRecipient  The address that should receive the fee. A value of 0x0 will send the fees to `msg.sender`.
     *                      Note, no fees are sent if the feeAmount is 0, regardless of what feeRecipient is.
     * @param v             The ECDSA V parameter.
     * @param r             The ECDSA R parameter.
     * @param s             The ECDSA S parameter.
     */
    function permit(
        address owner,
        address spender,
        uint nonce,
        uint expiry,
        bool allowed,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Transfers DMM from the `owner` to `recipient` using an offline-generated signature. This function allows a
     *      relayer to send the transaction, giving the owner the illusion of committing a gasless transaction. See
     *      #TRANSFER_TYPEHASH. This function gives the `owner` the illusion of committing a gasless transaction,
     *      allowing a relayer to broadcast the transaction and potentially collect a fee for doing so.
     *
     * @param owner         The user that signed the off-chain message and originator of the transfer.
     * @param recipient     The address that will receive the transferred DMM tokens.
     * @param nonce         An auto-incrementing integer that prevents replay attacks. See #nonceOf(address) to get the
     *                      owner's current nonce.
     * @param expiry        The timestamp, in unix seconds, at which the signed off-chain message expires. A value of 0
     *                      means there is no expiration.
     * @param amount        The amount of DMM that should be transferred from `owner` and sent to `recipient`.
     * @param feeAmount     The amount of DMM to be sent to feeRecipient for sending this transaction on behalf of
     *                      owner. Can be 0, which means the user won't be charged a fee.
     * @param feeRecipient  The address that should receive the fee. A value of 0x0 will send the fees to `msg.sender`.
     *                      Note, no fees are sent if the feeAmount is 0, regardless of what feeRecipient is.
     * @param v             The ECDSA V parameter.
     * @param r             The ECDSA R parameter.
     * @param s             The ECDSA S parameter.
     * @return              True if the transfer was successful or false if it failed.
     */
    function transferFromGaslessRequest(
        address owner,
        address recipient,
        uint nonce,
        uint expiry,
        uint amount,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

// File: contracts/protocol/interfaces/IWETH.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

interface IWETH {

    function deposit() external payable;

    function withdraw(uint wad) external;

}

// File: contracts/external/referral/ReferralTrackerData.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;







/**
 * @dev This proxy contract is used for industry partners so we can track their usage of the protocol.
 */
contract ReferralTrackerData is Initializable, Ownable {

    // *************************
    // ***** State Variables
    // *************************

    address internal _weth;

}

// File: contracts/external/referral/v1/IReferralTrackerV1.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

interface IReferralTrackerV1 {

    // *************************
    // ***** Events
    // *************************

    event ProxyMint(
        address indexed referrer,
        address indexed minter,
        address indexed receiver,
        uint amount,
        uint underlyingAmount
    );

    event ProxyRedeem(
        address indexed referrer,
        address indexed redeemer,
        address indexed receiver,
        uint amount,
        uint underlyingAmount
    );

    // *************************
    // ***** User Functions
    // *************************

    /**
     * @return  The amount of mTokens received
     */
    function mintViaEther(
        address referrer,
        address mETH
    ) external payable returns (uint);

    /**
     * @return  The amount of mTokens received
     */
    function mint(
        address referrer,
        address mToken,
        uint underlyingAmount
    ) external returns (uint);

    /**
     * @return  The amount of mTokens received
     */
    function mintFromGaslessRequest(
        address referrer,
        address mToken,
        address owner,
        address recipient,
        uint nonce,
        uint expiry,
        uint amount,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint);

    /**
     * @return  The amount of underlying received
     */
    function redeem(
        address referrer,
        address mToken,
        uint amount
    ) external returns (uint);

    /**
     * @return  The amount of underlying received
     */
    function redeemToEther(
        address referrer,
        address mToken,
        uint amount
    ) external returns (uint);

    /**
     * @return  The amount of underlying received
     */
    function redeemFromGaslessRequest(
        address referrer,
        address mToken,
        address owner,
        address recipient,
        uint nonce,
        uint expiry,
        uint amount,
        uint feeAmount,
        address feeRecipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint);

}

// File: contracts/external/referral/v1/IReferralTrackerV1Initializable.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

/**
 * @dev This proxy contract is used for industry partners so we can track their usage of the protocol.
 */
interface IReferralTrackerV1Initializable {

    function initialize(
        address owner,
        address weth
    ) external;

}

// File: contracts/external/referral/v1/ReferralTrackerImplV1.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;










/**
 * @dev This proxy contract is used for industry partners so we can track their usage of the protocol.
 */
contract ReferralTrackerImplV1 is IReferralTrackerV1, IReferralTrackerV1Initializable, ReferralTrackerData {

    using SafeERC20 for IERC20;

    function initialize(
        address __owner,
        address __weth
    ) external initializer {
        _transferOwnership(__owner);
        _weth = __weth;
    }

    function() external payable {
        require(
            msg.sender == _weth,
            "ReferralTrackerProxy::default INVALID_SENDER"
        );
    }

    function mintViaEther(
        address __referrer,
        address __mETH
    ) public payable returns (uint) {
        require(
            IDmmEther(__mETH).wethToken() == _weth,
            "ReferralTrackerProxy::mintViaEther: INVALID_TOKEN"
        );

        uint amount = IDmmEther(__mETH).mintViaEther.value(msg.value)();
        IERC20(__mETH).safeTransfer(msg.sender, amount);
        emit ProxyMint(__referrer, msg.sender, msg.sender, amount, msg.value);
        return amount;
    }

    function mint(
        address __referrer,
        address __mToken,
        uint __underlyingAmount
    ) external returns (uint) {
        address underlyingToken = IDmmToken(__mToken).controller().getUnderlyingTokenForDmm(__mToken);
        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), __underlyingAmount);

        _checkApprovalAndIncrementIfNecessary(underlyingToken, __mToken);

        uint amountMinted = IDmmToken(__mToken).mint(__underlyingAmount);
        IERC20(__mToken).safeTransfer(msg.sender, amountMinted);

        emit ProxyMint(__referrer, msg.sender, msg.sender, amountMinted, __underlyingAmount);

        return amountMinted;
    }

    function mintFromGaslessRequest(
        address __referrer,
        address __mToken,
        address __owner,
        address __recipient,
        uint __nonce,
        uint __expiry,
        uint __amount,
        uint __feeAmount,
        address __feeRecipient,
        uint8 __v,
        bytes32 __r,
        bytes32 __s
    ) external returns (uint) {
        uint dmmAmount = IDmmToken(__mToken).mintFromGaslessRequest(
            __owner,
            __recipient,
            __nonce,
            __expiry,
            __amount,
            __feeAmount,
            __feeRecipient,
            __v,
            __r,
            __s
        );

        emit ProxyMint(__referrer, __owner, __recipient, dmmAmount, __amount);
        return dmmAmount;
    }

    function redeem(
        address __referrer,
        address __mToken,
        uint __amount
    ) external returns (uint) {
        IERC20(__mToken).safeTransferFrom(msg.sender, address(this), __amount);

        // We don't need an allowance to perform a redeem using mTokens. Therefore, no allowance check is placed here.
        uint underlyingAmountRedeemed = IDmmToken(__mToken).redeem(__amount);

        address underlyingToken = IDmmToken(__mToken).controller().getUnderlyingTokenForDmm(__mToken);
        IERC20(underlyingToken).safeTransfer(msg.sender, underlyingAmountRedeemed);

        emit ProxyRedeem(__referrer, msg.sender, msg.sender, __amount, underlyingAmountRedeemed);

        return underlyingAmountRedeemed;
    }

    function redeemToEther(
        address __referrer,
        address __mToken,
        uint __amount
    ) external returns (uint) {
        require(
            IDmmEther(__mToken).wethToken() == _weth,
            "ReferralTrackerProxy::redeemToEther: INVALID_TOKEN"
        );

        IERC20(__mToken).safeTransferFrom(msg.sender, address(this), __amount);

        // We don't need an allowance to perform a redeem using mTokens. Therefore, no allowance check is placed here.
        uint underlyingAmountRedeemed = IDmmToken(__mToken).redeem(__amount);

        IWETH(_weth).withdraw(underlyingAmountRedeemed);
        Address.sendValue(msg.sender, underlyingAmountRedeemed);

        emit ProxyRedeem(__referrer, msg.sender, msg.sender, __amount, underlyingAmountRedeemed);

        return underlyingAmountRedeemed;
    }

    function redeemFromGaslessRequest(
        address __referrer,
        address __mToken,
        address __owner,
        address __recipient,
        uint __nonce,
        uint __expiry,
        uint __amount,
        uint __feeAmount,
        address __feeRecipient,
        uint8 __v,
        bytes32 __r,
        bytes32 __s
    ) external returns (uint) {
        uint underlyingAmount = IDmmToken(__mToken).redeemFromGaslessRequest(
            __owner,
            __recipient,
            __nonce,
            __expiry,
            __amount,
            __feeAmount,
            __feeRecipient,
            __v,
            __r,
            __s
        );

        emit ProxyRedeem(__referrer, __owner, __recipient, __amount, underlyingAmount);
        return underlyingAmount;
    }

    // ******************************
    // ***** Internal Functions
    // ******************************

    function _checkApprovalAndIncrementIfNecessary(
        address __underlyingToken,
        address __mToken
    ) internal {
        uint allowance = IERC20(__underlyingToken).allowance(address(this), __mToken);
        if (allowance == 0) {
            IERC20(__underlyingToken).safeApprove(__mToken, uint(- 1));
        }
    }

}