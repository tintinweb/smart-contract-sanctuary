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

// File: contracts/external/farming/DMGYieldFarmingData.sol

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


contract DMGYieldFarmingData is Initializable {

    // /////////////////////////
    // BEGIN State Variables
    // /////////////////////////

    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    address internal _owner;

    address internal _dmgToken;
    address internal _guardian;
    address internal _dmmController;
    address[] internal _supportedFarmTokens;
    /// @notice How much DMG is earned every second of farming. This number is represented as a fraction with 18
    //          decimal places, whereby 0.01 == 1000000000000000.
    uint internal _dmgGrowthCoefficient;

    bool internal _isFarmActive;
    uint internal _seasonIndex;
    mapping(address => uint16) internal _tokenToRewardPointMap;
    mapping(address => mapping(address => bool)) internal _userToSpenderToIsApprovedMap;
    mapping(uint => mapping(address => mapping(address => uint))) internal _seasonIndexToUserToTokenToEarnedDmgAmountMap;
    mapping(uint => mapping(address => mapping(address => uint64))) internal _seasonIndexToUserToTokenToDepositTimestampMap;
    mapping(address => address) internal _tokenToUnderlyingTokenMap;
    mapping(address => uint8) internal _tokenToDecimalsMap;
    mapping(address => uint) internal _tokenToIndexPlusOneMap;
    mapping(address => mapping(address => uint)) internal _addressToTokenToBalanceMap;
    mapping(address => bool) internal _globalProxyToIsTrustedMap;

    // /////////////////////////
    // END State Variables
    // /////////////////////////

    // /////////////////////////
    // Events
    // /////////////////////////

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // /////////////////////////
    // Functions
    // /////////////////////////

    function initialize(address owner) public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;

        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
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
        require(newOwner != address(0), "DMGYieldFarmingData::transferOwnership: INVALID_OWNER");

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // /////////////////////////
    // Modifiers
    // /////////////////////////

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "DMGYieldFarmingData: NOT_OWNER");
        _;
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
        require(localCounter == _guardCounter, "DMGYieldFarmingData: REENTRANCY");
    }

    // /////////////////////////
    // Constants
    // /////////////////////////

    uint8 public constant POINTS_DECIMALS = 2;

    uint16 public constant POINTS_FACTOR = 10 ** uint16(POINTS_DECIMALS);

    uint8 public constant DMG_GROWTH_COEFFICIENT_DECIMALS = 18;

    uint public constant DMG_GROWTH_COEFFICIENT_FACTOR = 10 ** uint(DMG_GROWTH_COEFFICIENT_DECIMALS);

    uint8 public constant USD_VALUE_DECIMALS = 18;

    uint public constant USD_VALUE_FACTOR = 10 ** uint(USD_VALUE_DECIMALS);

}

// File: contracts/external/farming/v1/IDMGYieldFarmingV1.sol

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
 * The interface for DMG "Yield Farming" - A process through which users may earn DMG by locking up their mTokens in
 * Uniswap pools, and staking the Uniswap pool's equity token in this contract.
 *
 * Yield farming in the DMM Ecosystem entails "rotation periods" in which a season is active, in order to incentivize
 * deposits of underlying tokens into the protocol.
 */
interface IDMGYieldFarmingV1 {

    // ////////////////////
    // Events
    // ////////////////////

    event GlobalProxySet(address indexed proxy, bool isTrusted);

    event TokenAdded(address indexed token, address indexed underlyingToken, uint8 underlyingTokenDecimals, uint16 points);
    event TokenRemoved(address indexed token);

    event FarmSeasonBegun(uint indexed seasonIndex, uint dmgAmount);
    event FarmSeasonEnd(uint indexed seasonIndex, address dustRecipient, uint dustyDmgAmount);

    event DmgGrowthCoefficientSet(uint coefficient);
    event RewardPointsSet(address indexed token, uint16 points);

    event Approval(address indexed user, address indexed spender, bool isTrusted);

    event BeginFarming(address indexed owner, address indexed token, uint depositedAmount);
    event EndFarming(address indexed owner, address indexed token, uint withdrawnAmount, uint earnedDmgAmount);

    event WithdrawOutOfSeason(address indexed owner, address indexed token, address indexed recipient, uint amount);

    // ////////////////////
    // Admin Functions
    // ////////////////////

    /**
     * Sets the `proxy` as a trusted contract, allowing it to interact with the user, on the user's behalf.
     *
     * @param proxy     The address that can interact on the user's behalf.
     * @param isTrusted True if the proxy is trusted or false if it's not (should be removed).
     */
    function approveGloballyTrustedProxy(address proxy, bool isTrusted) external;

    /**
     * @return  true if the provided `proxy` is globally trusted and may interact with the yield farming contract on a
     *          user's behalf or false otherwise.
     */
    function isGloballyTrustedProxy(address proxy) external view returns (bool);

    /**
     * @param token                     The address of the token to be supported for farming.
     * @param underlyingToken           The token to which this token is pegged. IE a Uniswap-V2 LP equity token for
     *                                  DAI-mDAI has an underlying token of DAI.
     * @param underlyingTokenDecimals   The number of decimals that the `underlyingToken` has.
     * @param points                    The amount of reward points for the provided token.
     */
    function addAllowableToken(address token, address underlyingToken, uint8 underlyingTokenDecimals, uint16 points) external;

    /**
     * @param token     The address of the token that will be removed from farming.
     */
    function removeAllowableToken(address token) external;

    /**
     * Changes the reward points for the provided token. Reward points are a weighting system that enables certain
     * tokens to accrue DMG faster than others, allowing the protocol to prioritize certain deposits.
     */
    function setRewardPointsByToken(address token, uint16 points) external;

    /**
     * Sets the DMG growth coefficient to use the new parameter provided. This variable is used to define how much
     * DMG is earned every second, for each point accrued.
     */
    function setDmgGrowthCoefficient(uint dmgGrowthCoefficient) external;

    /**
     * Begins the farming process so users that accumulate DMG by locking tokens can start for this rotation. Calling
     * this function increments the currentSeasonIndex, starting a new season. This function reverts if there is
     * already an active season.
     *
     * @param dmgAmount The amount of DMG that will be used to fund this campaign.
     */
    function beginFarmingSeason(uint dmgAmount) external;

    /**
     * Ends the active farming process if the admin calls this function. Otherwise, anyone may call this function once
     * all DMG have been drained from the contract.
     *
     * @param dustRecipient The recipient of any leftover DMG in this contract, when the campaign finishes.
     */
    function endActiveFarmingSeason(address dustRecipient) external;

    // ////////////////////
    // Misc Functions
    // ////////////////////

    /**
     * @return  The tokens that the farm supports.
     */
    function getFarmTokens() external view returns (address[] memory);

    /**
     * @return  True if the provided token is supported for farming, or false if it's not.
     */
    function isSupportedToken(address token) external view returns (bool);

    /**
     * @return  True if there is an active season for farming, or false if there isn't one.
     */
    function isFarmActive() external view returns (bool);

    /**
     * The address that acts as a "secondary" owner with quicker access to function calling than the owner. Typically,
     * this is the DMMF.
     */
    function guardian() external view returns (address);

    /**
     * @return The DMG token.
     */
    function dmgToken() external view returns (address);

    /**
     * @return  The growth coefficient for earning DMG while farming. Each unit represents how much DMG is earned per
     *          point
     */
    function dmgGrowthCoefficient() external view returns (uint);

    /**
     * @return  The amount of points that the provided token earns for each unit of token deposited. Defaults to `1`
     *          if the provided `token` does not exist or does not have a special weight. This number is `2` decimals.
     */
    function getRewardPointsByToken(address token) external view returns (uint16);

    /**
     * @return  The number of decimals that the underlying token has.
     */
    function getTokenDecimalsByToken(address token) external view returns (uint8);

    /**
     * @return  The index into the array returned from `getFarmTokens`, plus 1. 0 if the token isn't found. If the
     *          index returned is non-zero, subtract 1 from it to get the real index into the array.
     */
    function getTokenIndexPlusOneByToken(address token) external view returns (uint);

    // ////////////////////
    // User Functions
    // ////////////////////

    /**
     * Approves the spender from `msg.sender` to transfer funds into the contract on the user's behalf. If `isTrusted`
     * is marked as false, removes the spender.
     */
    function approve(address spender, bool isTrusted) external;

    /**
     * True if the `spender` can transfer tokens on the user's behalf to this contract.
     */
    function isApproved(address user, address spender) external view returns (bool);

    /**
     * Begins a farm by transferring `amount` of `token` from `user` to this contract and adds it to the balance of
     * `user`. `user` must be either 1) msg.sender or 2) a wallet who has approved msg.sender as a proxy; else this
     * function reverts. `funder` must fit into the same criteria as `user`; else this function reverts
     */
    function beginFarming(address user, address funder, address token, uint amount) external;

    /**
     * Ends a farm by transferring all of `token` deposited by `from` to `recipient`, from this contract, as well as
     * all earned DMG for farming `token` to `recipient`. `from` must be either 1) msg.sender or 2) an approved
     * proxy; else this function reverts.
     *
     * @return  The amount of `token` withdrawn and the amount of DMG earned for farming. Both values are sent to
     *          `recipient`.
     */
    function endFarmingByToken(address from, address recipient, address token) external returns (uint, uint);

    /**
     * Withdraws all of `msg.sender`'s tokens from the farm to `recipient`. This function reverts if there is an active
     * farm. `user` must be either 1) msg.sender or 2) an approved proxy; else this function reverts.
     */
    function withdrawAllWhenOutOfSeason(address user, address recipient) external;

    /**
     * Withdraws all of `user` `token` from the farm to `recipient`. This function reverts if there is an active farm and the token is NOT removed.
     * `user` must be either 1) msg.sender or 2) an approved proxy; else this function reverts.
     *
     * @return The amount of tokens sent to `recipient`
     */
    function withdrawByTokenWhenOutOfSeason(
        address user,
        address recipient,
        address token
    ) external returns (uint);

    /**
     * @return  The amount of DMG that this owner has earned in the active farm. If there are no active season, this
     *          function returns `0`.
     */
    function getRewardBalanceByOwner(address owner) external view returns (uint);

    /**
     * @return  The amount of DMG that this owner has earned in the active farm for the provided token. If there is no
     *          active season, this function returns `0`.
     */
    function getRewardBalanceByOwnerAndToken(address owner, address token) external view returns (uint);

    /**
     * @return  The amount of `token` that this owner has deposited into this contract. The user may withdraw this
     *          non-zero balance by invoking `endFarming` or `endFarmingByToken` if there is an active farm. If there is
     *          NO active farm, the user may withdraw his/her funds by invoking
     */
    function balanceOf(address owner, address token) external view returns (uint);

    /**
     * @return  The most recent timestamp at which the `owner` deposited `token` into the yield farming contract for
     *          the current season. If there is no active season, this function returns `0`.
     */
    function getMostRecentDepositTimestampByOwnerAndToken(address owner, address token) external view returns (uint64);

    /**
     * @return  The most recent indexed amount of DMG earned by the `owner` for the deposited `token` which is being
     *          farmed for the most-recent season. If there is no active season, this function returns `0`.
     */
    function getMostRecentIndexedDmgEarnedByOwnerAndToken(address owner, address token) external view returns (uint);

}

// File: contracts/external/farming/v1/IDMGYieldFarmingV1Initializable.sol

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

interface IDMGYieldFarmingV1Initializable {

    function initialize(
        address dmgToken,
        address guardian,
        address dmmController,
        uint dmgGrowthCoefficient,
        address[] calldata allowableTokens,
        address[] calldata underlyingTokens,
        uint8[] calldata tokenDecimals,
        uint16[] calldata points
    ) external;

}

// File: contracts/external/farming/v1/DMGYieldFarmingV1.sol

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










contract DMGYieldFarmingV1 is IDMGYieldFarmingV1, IDMGYieldFarmingV1Initializable, DMGYieldFarmingData {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    modifier isSpenderApproved(address user) {
        require(
            msg.sender == user || _globalProxyToIsTrustedMap[msg.sender] || _userToSpenderToIsApprovedMap[user][msg.sender],
            "DMGYieldFarmingV1: UNAPPROVED"
        );

        _;
    }

    modifier farmIsActive {
        require(_isFarmActive, "DMGYieldFarming: FARM_NOT_ACTIVE");
        _;
    }

    modifier requireIsFarmToken(address token) {
        require(_tokenToIndexPlusOneMap[token] != 0, "DMGYieldFarming: TOKEN_UNSUPPORTED");
        _;
    }

    modifier farmIsNotActive {
        require(!_isFarmActive, "DMGYieldFarming: FARM_IS_ACTIVE");
        _;
    }

    function initialize(
        address dmgToken,
        address guardian,
        address dmmController,
        uint dmgGrowthCoefficient,
        address[] memory allowableTokens,
        address[] memory underlyingTokens,
        uint8[] memory tokenDecimals,
        uint16[] memory points
    )
    initializer
    public {
        DMGYieldFarmingData.initialize(guardian);

        require(
            allowableTokens.length == points.length,
            "DMGYieldFarming::initialize: INVALID_LENGTH"
        );
        require(
            points.length == underlyingTokens.length,
            "DMGYieldFarming::initialize: INVALID_LENGTH"
        );
        require(
            underlyingTokens.length == tokenDecimals.length,
            "DMGYieldFarming::initialize: INVALID_LENGTH"
        );

        _dmgToken = dmgToken;
        _guardian = guardian;
        _dmmController = dmmController;

        _verifyDmgGrowthCoefficient(dmgGrowthCoefficient);
        _dmgGrowthCoefficient = dmgGrowthCoefficient;
        _seasonIndex = 1;
        // gas savings by starting it at 1.
        _isFarmActive = false;

        for (uint i = 0; i < allowableTokens.length; i++) {
            require(
                allowableTokens[i] != address(0),
                "DMGYieldFarming::initialize: INVALID_UNDERLYING"
            );
            require(
                underlyingTokens[i] != address(0),
                "DMGYieldFarming::initialize: INVALID_UNDERLYING"
            );

            _supportedFarmTokens.push(allowableTokens[i]);
            _tokenToIndexPlusOneMap[allowableTokens[i]] = i + 1;
            _tokenToUnderlyingTokenMap[allowableTokens[i]] = underlyingTokens[i];
            _tokenToDecimalsMap[allowableTokens[i]] = tokenDecimals[i];

            _verifyPoints(points[i]);
            _tokenToRewardPointMap[allowableTokens[i]] = points[i];
        }
    }

    // ////////////////////
    // Admin Functions
    // ////////////////////

    function approveGloballyTrustedProxy(
        address proxy,
        bool isTrusted
    )
    public
    nonReentrant
    onlyOwner {
        _globalProxyToIsTrustedMap[proxy] = isTrusted;
        emit GlobalProxySet(proxy, isTrusted);
    }

    function isGloballyTrustedProxy(
        address proxy
    ) public view returns (bool) {
        return _globalProxyToIsTrustedMap[proxy];
    }

    function addAllowableToken(
        address token,
        address underlyingToken,
        uint8 underlyingTokenDecimals,
        uint16 points
    )
    public
    nonReentrant
    onlyOwner {
        uint index = _tokenToIndexPlusOneMap[token];
        require(
            index == 0,
            "DMGYieldFarming::addAllowableToken: TOKEN_ALREADY_SUPPORTED"
        );
        _tokenToIndexPlusOneMap[token] = _supportedFarmTokens.push(token);
        _tokenToRewardPointMap[token] = points;
        _tokenToDecimalsMap[token] = underlyingTokenDecimals;
        emit TokenAdded(token, underlyingToken, underlyingTokenDecimals, points);
    }

    function removeAllowableToken(
        address token
    )
    public
    nonReentrant
    farmIsNotActive
    onlyOwner {
        uint index = _tokenToIndexPlusOneMap[token];
        require(
            index != 0,
            "DMGYieldFarming::removeAllowableToken: TOKEN_NOT_SUPPORTED"
        );
        _tokenToIndexPlusOneMap[token] = 0;
        _tokenToRewardPointMap[token] = 0;
        delete _supportedFarmTokens[index - 1];
        emit TokenRemoved(token);
    }

    function setRewardPointsByToken(
        address token,
        uint16 points
    )
    public
    nonReentrant
    onlyOwner {
        _verifyPoints(points);
        _tokenToRewardPointMap[token] = points;
        emit RewardPointsSet(token, points);
    }

    function setDmgGrowthCoefficient(
        uint dmgGrowthCoefficient
    )
    public
    nonReentrant
    onlyOwner {
        _verifyDmgGrowthCoefficient(dmgGrowthCoefficient);

        _dmgGrowthCoefficient = dmgGrowthCoefficient;
        emit DmgGrowthCoefficientSet(dmgGrowthCoefficient);
    }

    function beginFarmingSeason(
        uint dmgAmount
    )
    public
    nonReentrant
    onlyOwner {
        require(!_isFarmActive, "DMGYieldFarming::beginFarmingSeason: FARM_ALREADY_ACTIVE");

        _seasonIndex += 1;
        _isFarmActive = true;
        IERC20(_dmgToken).safeTransferFrom(msg.sender, address(this), dmgAmount);

        emit FarmSeasonBegun(_seasonIndex, dmgAmount);
    }

    function endActiveFarmingSeason(
        address dustRecipient
    )
    public
    nonReentrant {
        uint dmgBalance = IERC20(_dmgToken).balanceOf(address(this));
        // Anyone can end the farm if the DMG balance has been drawn down to 0.
        require(
            dmgBalance == 0 || msg.sender == owner() || msg.sender == _guardian,
            "DMGYieldFarming: FARM_ACTIVE or INVALID_SENDER"
        );

        _isFarmActive = false;
        if (dmgBalance > 0) {
            IERC20(_dmgToken).safeTransfer(dustRecipient, dmgBalance);
        }

        emit FarmSeasonEnd(_seasonIndex, dustRecipient, dmgBalance);
    }

    // ////////////////////
    // Misc Functions
    // ////////////////////

    function getFarmTokens() public view returns (address[] memory) {
        return _supportedFarmTokens;
    }

    function isSupportedToken(address token) public view returns (bool) {
        return _tokenToIndexPlusOneMap[token] > 0;
    }

    function isFarmActive() public view returns (bool) {
        return _isFarmActive;
    }

    function guardian() public view returns (address) {
        return _guardian;
    }

    function dmgToken() public view returns (address) {
        return _dmgToken;
    }

    function dmgGrowthCoefficient() public view returns (uint) {
        return _dmgGrowthCoefficient;
    }

    function getRewardPointsByToken(
        address token
    ) public view returns (uint16) {
        uint16 rewardPoints = _tokenToRewardPointMap[token];
        return rewardPoints == 0 ? POINTS_FACTOR : rewardPoints;
    }

    function getTokenDecimalsByToken(
        address token
    ) public view returns (uint8) {
        return _tokenToDecimalsMap[token];
    }

    function getTokenIndexPlusOneByToken(
        address token
    ) public view returns (uint) {
        return _tokenToIndexPlusOneMap[token];
    }

    // ////////////////////
    // User Functions
    // ////////////////////

    function approve(
        address spender,
        bool isTrusted
    ) public {
        _userToSpenderToIsApprovedMap[msg.sender][spender] = isTrusted;
        emit Approval(msg.sender, spender, isTrusted);
    }

    function isApproved(
        address user,
        address spender
    ) public view returns (bool) {
        return _userToSpenderToIsApprovedMap[user][spender];
    }

    function beginFarming(
        address user,
        address funder,
        address token,
        uint amount
    )
    public
    farmIsActive
    requireIsFarmToken(token)
    isSpenderApproved(user)
    nonReentrant {
        require(
            funder == msg.sender || funder == user,
            "DMGYieldFarmingV1::beginFarming: INVALID_FUNDER"
        );

        if (amount > 0) {
            // In case the user is reusing a non-zero balance they had before the start of this farm.
            IERC20(token).safeTransferFrom(funder, address(this), amount);
        }

        // We reindex before adding to the user's balance, because the indexing process takes the user's CURRENT
        // balance and applies their earnings, so we can account for new deposits.
        _reindexEarningsByTimestamp(user, token);

        if (amount > 0) {
            _addressToTokenToBalanceMap[user][token] = _addressToTokenToBalanceMap[user][token].add(amount);
        }

        emit BeginFarming(user, token, amount);
    }

    function endFarmingByToken(
        address user,
        address recipient,
        address token
    )
    public
    farmIsActive
    requireIsFarmToken(token)
    isSpenderApproved(user)
    nonReentrant
    returns (uint, uint) {
        uint balance = _addressToTokenToBalanceMap[user][token];
        require(balance > 0, "DMGYieldFarming::endFarmingByToken: ZERO_BALANCE");

        uint earnedDmgAmount = _getTotalRewardBalanceByUserAndToken(user, token, _seasonIndex);
        require(earnedDmgAmount > 0, "DMGYieldFarming::endFarmingByToken: ZERO_EARNED");

        address dmgToken = _dmgToken;
        uint contractDmgBalance = IERC20(dmgToken).balanceOf(address(this));
        _endFarmingByToken(user, recipient, token, balance, earnedDmgAmount, contractDmgBalance);

        earnedDmgAmount = _transferDmgOut(recipient, earnedDmgAmount, dmgToken, contractDmgBalance);

        return (balance, earnedDmgAmount);
    }

    function withdrawAllWhenOutOfSeason(
        address user,
        address recipient
    )
    public
    farmIsNotActive
    isSpenderApproved(user)
    nonReentrant {
        address[] memory farmTokens = _supportedFarmTokens;
        for (uint i = 0; i < farmTokens.length; i++) {
            _withdrawByTokenWhenOutOfSeason(user, recipient, farmTokens[i]);
        }
    }

    function withdrawByTokenWhenOutOfSeason(
        address user,
        address recipient,
        address token
    )
    isSpenderApproved(user)
    nonReentrant
    public returns (uint) {
        require(
            !_isFarmActive || _tokenToIndexPlusOneMap[token] == 0,
            "DMGYieldFarmingV1::withdrawByTokenWhenOutOfSeason: FARM_ACTIVE_OR_TOKEN_SUPPORTED"
        );

        return _withdrawByTokenWhenOutOfSeason(user, recipient, token);
    }

    function getRewardBalanceByOwner(
        address owner
    ) public view returns (uint) {
        if (_isFarmActive) {
            return _getTotalRewardBalanceByUser(owner, _seasonIndex);
        } else {
            return 0;
        }
    }

    function getRewardBalanceByOwnerAndToken(
        address owner,
        address token
    ) public view returns (uint) {
        if (_isFarmActive) {
            return _getTotalRewardBalanceByUserAndToken(owner, token, _seasonIndex);
        } else {
            return 0;
        }
    }

    function balanceOf(
        address owner,
        address token
    ) public view returns (uint) {
        return _addressToTokenToBalanceMap[owner][token];
    }

    function getMostRecentDepositTimestampByOwnerAndToken(
        address owner,
        address token
    ) public view returns (uint64) {
        if (_isFarmActive) {
            return _seasonIndexToUserToTokenToDepositTimestampMap[_seasonIndex][owner][token];
        } else {
            return 0;
        }
    }

    function getMostRecentIndexedDmgEarnedByOwnerAndToken(
        address owner,
        address token
    ) public view returns (uint) {
        if (_isFarmActive) {
            return _seasonIndexToUserToTokenToEarnedDmgAmountMap[_seasonIndex][owner][token];
        } else {
            return 0;
        }
    }

    function getMostRecentBlockTimestamp() public view returns (uint64) {
        return uint64(block.timestamp);
    }

    // ////////////////////
    // Internal Functions
    // ////////////////////

    /**
     * @return  The dollar value of `tokenAmount`, formatted as a number with 18 decimal places
     */
    function _getUsdValueByTokenAndTokenAmount(
        address token,
        uint tokenAmount
    ) internal view returns (uint) {
        uint8 decimals = _tokenToDecimalsMap[token];
        address underlyingToken = _tokenToUnderlyingTokenMap[token];

        tokenAmount = tokenAmount
        .mul(IERC20(underlyingToken).balanceOf(token)) /* For Uniswap pools, underlying tokens are held in the pool's contract. */
        .div(IERC20(token).totalSupply(), "DMGYieldFarmingV1::_getUsdValueByTokenAndTokenAmount: INVALID_TOTAL_SUPPLY")
        .mul(2) /* The user deposits effectively 2x the amount, to account for both sides of the pool. Assuming the pool is at (or close to it) equilibrium, this 2x suffices as an estimate */;

        if (decimals < 18) {
            tokenAmount = tokenAmount.mul((10 ** (18 - uint(decimals))));
        } else if (decimals > 18) {
            tokenAmount = tokenAmount.div((10 ** (uint(decimals) - 18)));
        }

        return IDmmController(_dmmController).underlyingTokenValuator().getTokenValue(
            underlyingToken,
            tokenAmount
        );
    }

    /**
     * @dev Transfers the user's `token` balance out of this contract, re-indexes the balance for the token to be zero.
     */
    function _endFarmingByToken(
        address user,
        address recipient,
        address token,
        uint tokenBalance,
        uint earnedDmgAmount,
        uint contractDmgBalance
    ) internal {
        IERC20(token).safeTransfer(recipient, tokenBalance);

        _addressToTokenToBalanceMap[user][token] = _addressToTokenToBalanceMap[user][token].sub(tokenBalance);
        _seasonIndexToUserToTokenToEarnedDmgAmountMap[_seasonIndex][user][token] = 0;
        _seasonIndexToUserToTokenToDepositTimestampMap[_seasonIndex][user][token] = uint64(block.timestamp);

        if (earnedDmgAmount > contractDmgBalance) {
            earnedDmgAmount = contractDmgBalance;
        }

        emit EndFarming(user, token, tokenBalance, earnedDmgAmount);
    }

    function _withdrawByTokenWhenOutOfSeason(
        address user,
        address recipient,
        address token
    ) internal returns (uint) {
        uint amount = _addressToTokenToBalanceMap[user][token];
        if (amount > 0) {
            _addressToTokenToBalanceMap[user][token] = 0;
            IERC20(token).safeTransfer(recipient, amount);
        }

        emit WithdrawOutOfSeason(user, token, recipient, amount);

        return amount;
    }

    function _reindexEarningsByTimestamp(
        address user,
        address token
    ) internal {
        uint64 previousIndexTimestamp = _seasonIndexToUserToTokenToDepositTimestampMap[_seasonIndex][user][token];
        if (previousIndexTimestamp != 0) {
            uint dmgEarnedAmount = _getUnindexedRewardsByUserAndToken(user, token, previousIndexTimestamp);
            if (dmgEarnedAmount > 0) {
                _seasonIndexToUserToTokenToEarnedDmgAmountMap[_seasonIndex][user][token] = _seasonIndexToUserToTokenToEarnedDmgAmountMap[_seasonIndex][user][token].add(dmgEarnedAmount);
            }
        }
        _seasonIndexToUserToTokenToDepositTimestampMap[_seasonIndex][user][token] = uint64(block.timestamp);
    }

    function _getTotalRewardBalanceByUser(
        address owner,
        uint seasonIndex
    ) internal view returns (uint) {
        address[] memory supportedFarmTokens = _supportedFarmTokens;
        uint totalDmgEarned = 0;
        for (uint i = 0; i < supportedFarmTokens.length; i++) {
            totalDmgEarned = totalDmgEarned.add(_getTotalRewardBalanceByUserAndToken(owner, supportedFarmTokens[i], seasonIndex));
        }
        return totalDmgEarned;
    }

    function _getUnindexedRewardsByUserAndToken(
        address owner,
        address token,
        uint64 previousIndexTimestamp
    ) internal view returns (uint) {
        uint balance = _addressToTokenToBalanceMap[owner][token];
        if (balance > 0 && previousIndexTimestamp > 0) {
            uint usdValue = _getUsdValueByTokenAndTokenAmount(token, balance);
            uint16 points = getRewardPointsByToken(token);
            return _calculateRewardBalance(
                usdValue,
                points,
                _dmgGrowthCoefficient,
                block.timestamp,
                previousIndexTimestamp
            );
        } else {
            return 0;
        }
    }

    function _getTotalRewardBalanceByUserAndToken(
        address owner,
        address token,
        uint seasonIndex
    ) internal view returns (uint) {
        // The proceeding mapping contains the aggregate of the indexed earned amounts.
        uint64 previousIndexTimestamp = _seasonIndexToUserToTokenToDepositTimestampMap[seasonIndex][owner][token];
        return _getUnindexedRewardsByUserAndToken(owner, token, previousIndexTimestamp)
        .add(_seasonIndexToUserToTokenToEarnedDmgAmountMap[seasonIndex][owner][token]);
    }

    function _verifyDmgGrowthCoefficient(
        uint dmgGrowthCoefficient
    ) internal pure {
        require(
            dmgGrowthCoefficient > 0,
            "DMGYieldFarming::_verifyDmgGrowthCoefficient: INVALID_GROWTH_COEFFICIENT"
        );
    }

    function _verifyPoints(
        uint16 points
    ) internal pure {
        require(
            points > 0,
            "DMGYieldFarming::_verifyPoints: INVALID_POINTS"
        );
    }

    function _transferDmgOut(
        address recipient,
        uint amount,
        address dmgToken,
        uint contractDmgBalance
    ) internal returns (uint) {
        if (contractDmgBalance < amount) {
            IERC20(dmgToken).safeTransfer(recipient, contractDmgBalance);
            return contractDmgBalance;
        } else {
            IERC20(dmgToken).safeTransfer(recipient, amount);
            return amount;
        }
    }

    function _calculateRewardBalance(
        uint usdValue,
        uint16 points,
        uint dmgGrowthCoefficient,
        uint currentTimestamp,
        uint previousIndexTimestamp
    ) internal pure returns (uint) {
        if (usdValue == 0) {
            return 0;
        } else {
            uint elapsedTime = currentTimestamp.sub(previousIndexTimestamp);
            // The number returned here has 18 decimal places (same as USD value), which is the same number as DMG.
            // Perfect.
            return elapsedTime
            .mul(dmgGrowthCoefficient)
            .div(DMG_GROWTH_COEFFICIENT_FACTOR)
            .mul(points)
            .div(POINTS_FACTOR)
            .mul(usdValue);
        }
    }

}