/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

/*
________                __        _____
\______ \ _____ _______|  | __   /  _  \    ____   ____
 |    |  \\__  \\_  __ \  |/ /  /  /_\  \  / ___\_/ __ \
 |    `   \/ __ \|  | \/    <  /    |    \/ /_/  >  ___/
/_______  (____  /__|  |__|_ \ \____|__  /\___  / \___  >
        \/     \/           \/         \//_____/      \/
                    ________   _____
                    \_____  \_/ ____\
                     /   |   \   __\
                    /    |    \  |
                    \_______  /__|
                            \/
         __________                        __
         \______   \ ____ _____    _______/  |_
          |    |  _// __ \\__  \  /  ___/\   __\
          |    |   \  ___/ / __ \_\___ \  |  |
          |______  /\___  >____  /____  > |__|
                 \/     \/     \/     \/
________________________________________________________
                         INFO:                          |
________________________________________________________|
This contract is published by RISING CORPORATION for    |
the DarkAgeOfBeast network ( DAOB ) on BSC.             |
Name        : MasterChef                                |
Token link  : SWAMPWOLF                                 |
Solidity    : 0.8.6                                     |
Contract    : 0x0000000000000000000000000000000000000000|
________________________________________________________|
                  WEBSITE AND SOCIAL:                   |
________________________________________________________|
website :   https://wolfswamp.daob.finance/             |
Twitter :   https://twitter.com/DarkAgeOfBeast          |
Medium  :   https://medium.com/@daob.wolfswamp          |
Reddit  :   https://www.reddit.com/r/DarkAgeOfTheBeast/ |
Pint    :   https://www.pinterest.fr/DarkAgeOfBeast/    |
fb      :   https://www.facebook.com/WolfSwamp          |
TG_off  :   https://t.me/DarkAgeOfBeastOfficial         |
TG_chat :   https://t.me/Darkageofbeast                 |
GitBook :   https://docs.daob.finance/wolfswamp/        |
________________________________________________________|
                 SECURITY AND FEATURES:                 |
________________________________________________________|
The administrator can use certain functions.            |
All sensitive functions are limited.                    |
The deposit function accepts tokens with a transaction  |
fee to prevent attacks.                                 |
Each pool has its own token balance, allowing multiple  |
pools to be integrated for the same token and avoiding  |
the problems associated with manually adding tokens to  |
the contract.                                           |
The update of the token emission per block is automated.|
The update of the harvest time is automated.            |
All LP tokens present in the contract and not included  |
in a pool will be used as reward for LP holders.        |
            !  THERE ARE NO HIDDEN FEES  !              |
________________________________________________________|
                     ! WARNING !                        |
________________________________________________________|
Any token manually transferred to this contract will be |
lost for life.                                          |
This contract does not allow tokens to be reclaimed.    |
________________________________________________________|
            Creative Commons (CC) license:              |
________________________________________________________|
You can reuse this contract by mentioning at the top :  |
    https://creativecommons.org/licenses/by-sa/4.0/     |
        CC BY MrRise from RisingCorporation.            |
________________________________________________________|

Thanks !
Best Regards !
by MrRise
2021-07-21
*/



pragma solidity 0.8.6;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
     * - the calling contract must have an BNB balance of at least `value`.
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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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



// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity 0.8.6;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.8.6;

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
    function _isOwner() internal view {
        require(owner() == _msgSender(), "Not the owner");
    }
    modifier onlyOwner() {
        _isOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. This can only be called by the current owner.
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
     * This can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File: contracts\interfaces\IPancakeFactory.sol

pragma solidity >=0.5.0;



interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\interfaces\IPancakePair.sol

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\interfaces\IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity 0.8.6;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/libs/SafeBEP20.sol

pragma solidity 0.8.6;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File: contracts/libs/IDarkAgeOfBeastReferral.sol

pragma solidity 0.8.6;

interface IDarkAgeOfBeastReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}


// File: contracts/libs/IDarkAgeOfBeast.sol

pragma solidity 0.8.6;

interface IDarkAgeOfBeast {
    /**
     * @dev Return the equipment bonus for farming in basis points.
     */
    function getUserEquipmentBonus(address user) external view returns (uint256);

}

// File: contracts\interfaces\ISwapAndLiquify.sol

pragma solidity 0.8.6;

interface ISwapAndLiquify {

    function swapSwampWolfForBnb(uint256 swampWolfAmount) external  ;
    function swapSwampWolfForOtherToken(uint256 swampWolfAmount, address otherTokenAddress) external  ;
    function addBnbLiquidity(uint256 swampWolfAmount, uint256 bnbAmount) external ;
    function addOtherLiquidity(uint256 swampWolfAmount, address otherTokenAddress, uint256 otherTokenAmount) external ;

}

// File: contracts\interfaces\PayReferral.sol
interface IPayReferral {

    // Events
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    // Functions
    function safePayReferralCommission(address _user, uint256 _pending) external;

}

// File: contracts\interfaces\ISwampWolfToken.sol

pragma solidity 0.8.6;

interface ISwampWolfToken is IBEP20  {

    // Events
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TransferTaxRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event BurnAfterSwapRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed admin, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed admin, uint256 previousAmount, uint256 newAmount);
    event SwampWolfSwapRouterUpdated(address indexed admin, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event NewTradingPairAdded( address SwampWolf, address otherToken);

    // Functions
    function masterBurn(uint256 _amount) external ;
    function burnUnsoldPresale(uint256 _amount) external ;
    function isSwapPair(address token) external view returns (bool) ;
    function mint(address _to, uint256 _amount) external ;
    function lpAddress() external view returns (address) ;
    function setNewTradingPair(address _address, bool _enabled) external ;

}

library BlockLibrary {
    using SafeMath for uint256;

    /**
     * @dev Display the current SWAMPWOLF / block.
     * Increase phase 10 days :
     * swampWolfPerBlock is increased by 1 every hours up till it reach  243 SWAMPWOLF / block.
     * When 243 SWAMPWOLF / block is reached we decrease it.
     * Decrease phase 5 days :
     * swampWolfPerBlock is divide by 3 every day up till it reach 1  SWAMPWOLF / block.
     *
     */
    function swampWolfPerBlock(uint256 _startBlock) public view returns (uint256) {
        // Block till update tokens per block ( 60sec x 60 min / 3sec : time per block  )
        uint256 blockToUpdate = 60 * 60 / 3;
        // Block since startBlock
        uint256 blockSinceStart = block.number - _startBlock;
        // Block before deflationary
        uint256 blockBeforeDeflationary = blockToUpdate * 242;
        // New token per block calculate with the startBlock
        uint256 newTokenPerBlock;
        if(blockSinceStart <= blockBeforeDeflationary){
            newTokenPerBlock = ( blockSinceStart.sub(blockSinceStart.mod(blockToUpdate))).div(blockToUpdate);
        }
        else{
            // Block till deflationary update tokens per block ( 24h x 60sec x 60 min / 3sec : time per block )
            uint256 newBlockToUpdate = 24 * 60 * 60 / 3;
            uint256 blockSinceDeflate = block.number.sub( _startBlock.add( blockBeforeDeflationary) );
            uint256 deflateNumber = ( blockSinceDeflate.sub( blockSinceDeflate.mod( newBlockToUpdate ) ) ).div( newBlockToUpdate );
            if (deflateNumber >= 5){
                newTokenPerBlock = 0;
            }
            else{
                newTokenPerBlock = 243;
                uint8 i = 0;
                while(i < deflateNumber){
                    newTokenPerBlock = newTokenPerBlock.div(3);
                    i++;
                }
            }
        }
        // SWAMPWOLF tokens created per block ( default: 1 + 1 every hours till 243 then divide by 3 every days till 1 per block )
        uint256 swampWolfPerBlockCalc = newTokenPerBlock.add(1) * 10 ** 18;
        return swampWolfPerBlockCalc;
    }
}


// File: contracts/MasterChef.sol

pragma solidity 0.8.6;

// MasterChef is the master of SwampWolf. He can make SwampWolf and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SWAMPWOLF is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeBEP20 for IBEP20;
    using Address for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.
        uint256 rewardDebt;         // Reward debt. See explanation below.
        uint256 rewardLockedUp;     // Reward locked up.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 lastDeposit;        // When did the user deposit.
        uint256 lastWithdraw;       // When did the user withdraw.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SWAMPWOLF
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSwampWolfPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSwampWolfPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;                 // Address of LP token contract.
        uint256 allocPoint;             // How many allocation points assigned to this pool. SWAMPWOLF to distribute per block.
        uint256 lastRewardBlock;        // Last block number that SWAMPWOLF distribution occurs.
        uint256 accSwampWolfPerShare;   // Accumulated SWAMPWOLF per share, times 1e12. See below.
        uint16 depositFeeBP;            // Deposit fee in basis points.
        uint256 harvestInterval;        // Harvest interval in seconds.
        uint256 lpTotal;                // Total LP in this pool.
        uint256 lastLpReward;           // Last block timestamp that LP token distribution occurs.
    }



    // The SWAMPWOLF TOKEN!
    ISwampWolfToken public swampWolf;
    // Dev address.
    address private _devAddress;
    // Deposit Fee address
    address private _feeAddress;
    // Marketing Address
    address private _marketingAddress;
    // Quest Address
    address private _questAddress;
    // The block number when SWAMPWOLF mining starts.
    uint256 public startBlock = block.number + (365 * 24 * 60 * 60 / 3);
    // The timestamp when SWAMPWOLF mining starts.
    uint256 public startTime = block.timestamp + (365 * 24 * 60 * 60 ) ;
    // Max harvest interval: 30 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 30 days;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // LP SWAMPWOLF holders arranged by pool.
    mapping(uint256=> address[]) public lpHolders;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // DarkAgeOfBeast contract .
    IDarkAgeOfBeast public darkAgeOfBeast;
    // SwampWolf referral contract .
    IDarkAgeOfBeastReferral public swampWolfReferral;
    // PayReferral contact.
    IPayReferral public payReferral;
    // Referral commission rate in basis points : Default 3%.
    uint16 public referralCommissionRate = 300;
    // Max referral commission rate in basis points : 5%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;
    // Deposit fee in basis points ( default : 4% )
    uint16 public depositFeeBp = 400;
    // Max deposit fee in basis points : 10%.
    uint16 public constant MAXIMUM_DEPOSIT_FEE = 1000;
    // Dev fee rate from deposit fee in basis points ( default : 50% )
    uint16 public devRate = 5000;
    // Marketing fee rate from deposit fee in basis points ( default 25% )
    uint16 public marketingRate = 2500;
    // Quest fee rate from deposit fee in basis points ( default 25% )
    uint16 public questRate = 2500;
    // Fee rate from deposit fee in basis points ( default 0% )
    // if an event or game is set up
    uint16 public feeRate = 0;
    // The administrator can use these functions but they are all limited:
    // add
    // set
    // transferAdmin
    // setDevAddress
    // setQuestAddress
    // setMarketingAddress
    // setFeeAddress
    // setReferralCommissionRateBp
    // setFeeCommissionRatesBp
    // farmingStart
    // setDepositFeeBp
    address private _admin;

    // event
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event LpHoldersRewarded(address indexed user, uint256 indexed pid);

    function _isAdmin() internal view {
        require(_admin == msg.sender, "Not Admin");
    }
    modifier onlyAdmin() {
        _isAdmin();
        _;
    }

    constructor(
        ISwampWolfToken _swampWolf
    ) {
        swampWolf = _swampWolf;
        _feeAddress = msg.sender;
        _devAddress = msg.sender;
        _marketingAddress = msg.sender;
        _questAddress = msg.sender;
        _admin = msg.sender;
    }

    /**
     * @dev Display the current SWAMPWOLF / block for the front-side view.
     *
     */
    function swampWolfPerBlockView() public view returns (uint256){
        return BlockLibrary.swampWolfPerBlock(startBlock);
    }

    /**
     * @dev Display the current harvest interval.
     * harvestInternal = time since farming has started ( MAX 30 days )
     *
     */
    function harvestInterval() public view returns (uint256) {
        // Block since startBlock
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 _harvestInterval = 0 + timeSinceStart;
        if (timeSinceStart > MAXIMUM_HARVEST_INTERVAL){
            _harvestInterval = MAXIMUM_HARVEST_INTERVAL;
        }
        return _harvestInterval;
    }

    /**
     * @dev Get the pool length.
     *
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Add a new lp to the pool.
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function addPool(uint256 _allocPoint, IBEP20 _lpToken,  bool _withUpdate, bool _isSwapPair, uint256 _startingBlock, bool _isStarting, uint16 _customDepositBp ) public onlyAdmin {
        if (_withUpdate) {
            massUpdatePools(_isStarting);
        }
        if(_customDepositBp != 0 && _customDepositBp > MAXIMUM_DEPOSIT_FEE){
            _customDepositBp = MAXIMUM_DEPOSIT_FEE;
        }
        uint16 _depositFeeBP = _customDepositBp != 0 ? _customDepositBp : _isSwapPair || _lpToken == swampWolf ?  0 : depositFeeBp;
        swampWolf.setNewTradingPair(address(_lpToken), _isSwapPair);

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        if(_startingBlock != 0){
            lastRewardBlock = _startingBlock;
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accSwampWolfPerShare: 0,
        depositFeeBP: _depositFeeBP,
        harvestInterval: 0,
        lpTotal: 0,
        lastLpReward: 0
        }));
    }

    /** @dev Update the given pool's SWAMPWOLF allocation point and deposit fee.
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function setPool(uint256 _pid, uint256 _allocPoint, bool _withUpdate, bool _isSwapPair, bool _isStarting , uint16 _customDepositBp) public onlyAdmin {
        if (_withUpdate) {
            massUpdatePools(_isStarting);
        }
        if(_customDepositBp != 0){
            if(_customDepositBp > MAXIMUM_DEPOSIT_FEE){
                _customDepositBp = MAXIMUM_DEPOSIT_FEE;
            }
        }
        address lpAddress = address(poolInfo[_pid].lpToken);
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        swampWolf.setNewTradingPair(lpAddress, _isSwapPair);
        poolInfo[_pid].depositFeeBP = _customDepositBp != 0 ? _customDepositBp : swampWolf.isSwapPair(lpAddress) || poolInfo[_pid].lpToken == swampWolf ? 0 : depositFeeBp;
    }

    /**
     * @dev Return DAOB character equipment reward bonus in basis points.
     *
     */
    function getEquipmentBonus(address _user) public view returns (uint256) {
        uint256 bonus = 0;
        if(address(darkAgeOfBeast) != address(0)){
            uint256 userBonus = darkAgeOfBeast.getUserEquipmentBonus(_user);
            if (userBonus > 0){
                bonus = userBonus;
            }
        }
        return bonus;
    }

    /**
    * @dev View function to see pending SWAMPWOLF on frontend.
    *
    */
    function pendingSwampWolf(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSwampWolfPerShare = pool.accSwampWolfPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpTotal > 0) {
            uint256 SWPerBlock = BlockLibrary.swampWolfPerBlock(startBlock);
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 swampWolfReward = multiplier.mul(SWPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSwampWolfPerShare += swampWolfReward.mul(1e12).div(pool.lpTotal);
        }
        uint256 pending = user.amount.mul(accSwampWolfPerShare).div(1e12).sub(user.rewardDebt);
        uint256 rewardPending = pending.add(user.rewardLockedUp);
        uint256 referralCommission = rewardPending.mul(referralCommissionRate).div(10000);
        uint256 rewardLessCommission =  rewardPending.sub(referralCommission);
        uint256 bonus = rewardLessCommission.mul(getEquipmentBonus(_user)).div(10000);
        return rewardLessCommission.add(bonus);
    }

    /**
     * @dev View function to see if user can harvest SWAMPWOLF.
     *
     */
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending!
     *
     */
    function massUpdatePools(bool _isStarting) public {
        uint256 length = poolInfo.length;
        if( msg.sender != admin() && msg.sender != address(this) && msg.sender != owner() ){
            _isStarting = false;
        }
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
            if(_isStarting){
                poolInfo[pid].lastRewardBlock = block.number;
            }
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     *
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpTotal;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 SWPerBlock = BlockLibrary.swampWolfPerBlock(startBlock);
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 swampWolfReward = multiplier.mul(SWPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 referralReward = swampWolfReward.mul(referralCommissionRate).div(10000);
        uint256 masterReward = swampWolfReward.sub(referralReward);
        swampWolf.mint(address(payReferral), referralReward);
        swampWolf.mint(address(this), masterReward);
        pool.accSwampWolfPerShare = pool.accSwampWolfPerShare.add(swampWolfReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Deposit LP tokens to MasterChef for SWAMPWOLF allocation.
     *
     */
    function deposit(uint256 _pid, uint256 _amount, address _referrer, bool _isCompounding) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(swampWolfReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            swampWolfReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingSwampWolf(_pid, _isCompounding);
        if (_amount > 0) {
            // Check the balance before deposit and after deposit to prevent tax transfer fee attack .
            uint256 beforeDepositBalance = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterDepositBalance = pool.lpToken.balanceOf(address(this));
            _amount = afterDepositBalance.sub(beforeDepositBalance);
            // Check if it is not an SWAMPWOLF/X pool
            if (pool.depositFeeBP != 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                uint256 devPart = depositFee.mul(devRate).div(10000);
                uint256 questPart = depositFee.mul(questRate).div(10000);
                uint256 marketingPart = depositFee.mul(marketingRate).div(10000);
                pool.lpToken.safeTransfer(_devAddress, devPart);
                pool.lpToken.safeTransfer(_questAddress, questPart);
                pool.lpToken.safeTransfer(_marketingAddress, marketingPart);
                if (feeRate != 0){
                    uint256 feePart = depositFee.mul(feeRate).div(10000);
                    pool.lpToken.safeTransfer(_feeAddress, feePart);
                }
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpTotal += _amount.sub(depositFee);
            }
            else {
                user.amount += _amount;
                pool.lpTotal += _amount;
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSwampWolfPerShare).div(1e12);
        lpHolders[_pid].push(msg.sender);
        if(user.lastWithdraw > user.lastDeposit || user.lastDeposit == 0){
            user.lastDeposit = block.timestamp;
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw LP tokens from MasterChef.
     *
     */
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Bad amount");
        updatePool(_pid);
        payOrLockupPendingSwampWolf(_pid, false);
        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpTotal -= _amount;
            if(user.amount == 0){
                uint256 arrayLength = lpHolders[_pid].length;
                for(uint16 i = 0; i < arrayLength; i++ ){
                    if(lpHolders[_pid][i] == msg.sender){
                        lpHolders[_pid][i] = lpHolders[_pid][arrayLength.sub(1)];
                        lpHolders[_pid].pop();
                    }
                }
            }
        }
        user.lastWithdraw = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accSwampWolfPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     *
     */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        user.lastWithdraw = block.timestamp;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.lpTotal -= amount;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @dev Pay or lockup pending SWAMPWOLF.
     *
     */
    function payOrLockupPendingSwampWolf(uint256 _pid, bool _isCompounding) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.nextHarvestUntil == 0) {
            if(swampWolf.isSwapPair(address(pool.lpToken))){
                user.nextHarvestUntil = block.timestamp.add(harvestInterval().div(2));
            }
            else{
                user.nextHarvestUntil = block.timestamp.add(harvestInterval());
            }
        }
        uint256 pending = user.amount.mul(pool.accSwampWolfPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);
                // Reset the lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(harvestInterval());
                // The referral commission
                uint256 totalReferralCommission = totalRewards.mul(referralCommissionRate).div(10000);
                // The total reward without referralCommissionRate
                uint256 rewardsToTransfer = totalRewards.sub( totalReferralCommission );
                // Bonus from Equipment
                uint256 bonus = rewardsToTransfer.mul(getEquipmentBonus(msg.sender)).div(10000);
                // Mint the bonus if it is not zero
                if(bonus > 0){
                    swampWolf.mint(address(this), bonus);
                    rewardsToTransfer += bonus;
                }
                // Send the rewards
                if(_isCompounding){
                    if (rewardsToTransfer > swampWolf.balanceOf(address(this))) {
                        rewardsToTransfer = swampWolf.balanceOf(address(this));
                    }
                    if(_pid != 0){
                        updatePool(0);
                        payOrLockupPendingSwampWolf(0,true);
                    }
                    userInfo[0][msg.sender].amount += rewardsToTransfer;
                    poolInfo[0].lpTotal += rewardsToTransfer;
                    userInfo[0][msg.sender].rewardDebt = userInfo[0][msg.sender].amount.mul(poolInfo[0].accSwampWolfPerShare).div(1e12);
                }
                else{
                    safeSwampWolfTransfer(msg.sender, rewardsToTransfer);
                }
                payReferral.safePayReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    /**
     * @dev Safe swampWolf transfer function, just in case if rounding error causes pool to not have enough SWAMPWOLF.
     *
     */
    function safeSwampWolfTransfer(address _to, uint256 _amount) internal {
        uint256 swampWolfBal = swampWolf.balanceOf(address(this));
        if (_amount > swampWolfBal) {
            swampWolf.transfer(_to, swampWolfBal);
        } else {
            swampWolf.transfer(_to, _amount);
        }
    }

    /**
     * @dev Reward holders of SWAMPWOLF/{otherToken} LP every single day when triggered.
     *
     */
    function rewardLpHolders(uint8 _pid) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        if(swampWolf.isSwapPair(address(pool.lpToken))){
            // Time Since the last LP reward.
            uint256 timeSinceLastReward = (block.timestamp.sub(startTime)).mod(1 days);
            // The last reward time.
            uint256 lastRewardTime = block.timestamp.sub(timeSinceLastReward);
            if(pool.lastLpReward < lastRewardTime){
                // The total lp in contract.
                uint256 lpInContract = pool.lpToken.balanceOf(address(this));
                // The total lp in pool.
                uint256 lpInPool = pool.lpTotal;
                // The lp for reward ( 1% of the total lp for reward ).
                uint256 lpForReward = (lpInContract.sub(lpInPool)).div(100);
                // The number of holders in this pools.
                uint256 arrayLength = lpHolders[_pid].length;
                for(uint16 i = 0; i < arrayLength; i++ ){
                    UserInfo storage user = userInfo[_pid][lpHolders[_pid][i]];
                    if(user.amount > 0){
                        // Last withdraw for this user.
                        uint256 lastWithdraw = user.lastWithdraw;
                        // Time since the last withdraw.
                        uint256 timeSinceLastWithdraw = block.timestamp.sub(lastWithdraw);
                        // If the time since last withdraw is more than 1days.
                        if(timeSinceLastWithdraw > 1 days){
                            // The user's share rate in basis points.
                            uint256 userShareRate = user.amount.div(lpInPool).mul(10000);
                            // The user's reward.
                            uint256 userReward = lpForReward.mul(userShareRate).div(10000);
                            // Compound the LP reward with the current share of this user.
                            updatePool(_pid);
                            payOrLockupPendingSwampWolf(_pid,true);
                            user.amount += userReward;
                            pool.lpTotal += userReward;
                            user.rewardDebt = user.amount.mul(pool.accSwampWolfPerShare).div(1e12);
                            pool.lastLpReward = block.timestamp;
                        }
                    }
                }
            }
        }
        emit LpHoldersRewarded(msg.sender, _pid);
    }

    /**
     * @dev Update fee address .
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function setFeeAddress(address feeAddress_) public onlyAdmin {
        if (feeAddress_ == address(0))
        {
            feeAddress_ = admin();
        }
        _feeAddress = feeAddress_;
    }

    /**
     * @dev Update dev address
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function setDevAddress(address devAddress_) public onlyAdmin {
        if (devAddress_ == address(0))
        {
            devAddress_ = admin();
        }
        _devAddress = devAddress_;
    }

    /**
     * @dev Update marketing address
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function setMarketingAddress(address marketingAddress_) public onlyAdmin {
        if (marketingAddress_ == address(0))
        {
            marketingAddress_ = admin();
        }
        _marketingAddress = marketingAddress_;
    }

    /**
     * @dev Update quest reward address
     *
     * Requirements
     *
     * This can only be called by the Admin.
     */
    function setQuestAddress(address questAddress_) public onlyAdmin {
        if (questAddress_ == address(0))
        {
            questAddress_ = admin();
        }
        _questAddress = questAddress_;
    }

    /**
     * @dev Update the swampWolf referral contract address
     *
     * Requirements
     *
     * This can only be called by the Owner.
     */
    function setSwampWolfReferral(IDarkAgeOfBeastReferral _swampWolfReferral) public onlyOwner {
        swampWolfReferral = _swampWolfReferral;
    }

    /**
     * @dev Update the swampWolf referral contract address
     *
     * Requirements
     *
     * This can only be called by the Owner.
     */
    function setDarkAgeOfBeast(IDarkAgeOfBeast _darkAgeOfBeast) public onlyOwner {
        darkAgeOfBeast = _darkAgeOfBeast;
    }

    /**
     * @dev Update the swampWolf PayReferral contract address
     *
     * Requirements
     *
     * This can only be called by the Owner.
     */
    function setPayReferral(IPayReferral _payReferral) public onlyOwner {
        payReferral = _payReferral;
    }

    /**
     * @dev Update referral commission rate in basis points
     *
     * Requirements
     *
     * This can only be called by the Admin.
     * Must be less than MAXIMUM_REFERRAL_COMMISSION_RATE.
     */
    function setReferralCommissionRateBp(uint16 _referralCommissionRate) public onlyOwner{
        if(_referralCommissionRate > MAXIMUM_REFERRAL_COMMISSION_RATE){
            _referralCommissionRate = MAXIMUM_REFERRAL_COMMISSION_RATE;
        }
        referralCommissionRate = _referralCommissionRate;
    }

    /**
     * @dev Update deposit fee in basis points
     *
     * Requirements
     *
     * This can only be called by the Admin.
     * Must be less than MAXIMUM_DEPOSIT_FEE.
     */
    function setDepositFeeBp(uint16 _depositFeeBp) public onlyOwner{
        if(_depositFeeBp > MAXIMUM_DEPOSIT_FEE){
            _depositFeeBp = MAXIMUM_DEPOSIT_FEE;
        }
        depositFeeBp = _depositFeeBp;
    }

    /**
     * @dev Update the distribution of commissions in basis points.
     *
     * Requirements
     *
     * This can only be called by the Admin.
     * The total of the rates must be 10,000 basis points.
     */
    function setFeeCommissionRatesBp(uint16 _feeRate, uint16 _devRate, uint16 _questRate, uint16 _marketingRate) public onlyOwner {
        uint256 totalRates = _feeRate.add(_devRate).add(_questRate).add(_marketingRate);
        uint16 maxRate = 10000;
        if(totalRates != maxRate){
            _feeRate = 0;
            _devRate = 5000;
            _questRate = 2500;
            _marketingRate = 2500;
        }
        feeRate = _feeRate;
        devRate = _devRate;
        questRate = _questRate;
        marketingRate = _marketingRate;
    }

    /**
     * @dev Start the farm by updating the startTime and startBlock.
     *
     *Requirements
     *
     * This can only be called by the Admin.
     * Current startTime and startBlock need to be bigger than block.timestamp and block.number
     * This can only be called once
     */
    function farmingStart() public onlyAdmin{
        require(startTime > block.timestamp && startBlock > block.number , "Started");
        startTime = block.timestamp;
        startBlock = block.number;
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /*
     * @dev Returns the current dev address.
     */
    function devAddress() public view returns (address) {
        return _devAddress;
    }

    /*
     * @dev Returns the current marketing address.
     */
    function marketingAddress() public view returns (address) {
        return _marketingAddress;
    }

    /*
     * @dev Returns the current quest reward address.
     */
    function questReward() public view returns (address) {
        return _questAddress;
    }

    /*
     * @dev Returns the current fee address.
     * For the purpose of events
     */
    function feeAddress() public view returns (address) {
        return _feeAddress;
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * This can only be called by the current admin.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        if (newAdmin == address(0))
        {
            newAdmin = admin();
        }
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }

}