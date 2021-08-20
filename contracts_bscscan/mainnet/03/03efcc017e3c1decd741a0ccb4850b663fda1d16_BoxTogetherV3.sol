/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/*
$$\      $$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$\  $$\      $$\  $$$$$$\  $$$$$$$\  
$$$\    $$$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$$\  $$ |$$  __$$\ $$ | $\  $$ |$$  __$$\ $$  __$$\ 
$$$$\  $$$$ |$$ /  $$ |$$ /  \__|$$ /  $$ |$$ |  $$ |$$ /  $$ |$$$$\ $$ |$$ /  \__|$$ |$$$\ $$ |$$ /  $$ |$$ |  $$ |
$$\$$\$$ $$ |$$$$$$$$ |$$ |      $$$$$$$$ |$$$$$$$  |$$ |  $$ |$$ $$\$$ |\$$$$$$\  $$ $$ $$\$$ |$$$$$$$$ |$$$$$$$  |
$$ \$$$  $$ |$$  __$$ |$$ |      $$  __$$ |$$  __$$< $$ |  $$ |$$ \$$$$ | \____$$\ $$$$  _$$$$ |$$  __$$ |$$  ____/ 
$$ |\$  /$$ |$$ |  $$ |$$ |  $$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |\$$$ |$$\   $$ |$$$  / \$$$ |$$ |  $$ |$$ |      
$$ | \_/ $$ |$$ |  $$ |\$$$$$$  |$$ |  $$ |$$ |  $$ | $$$$$$  |$$ | \$$ |\$$$$$$  |$$  /   \$$ |$$ |  $$ |$$ |      
\__|     \__|\__|  \__| \______/ \__|  \__|\__|  \__| \______/ \__|  \__| \______/ \__/     \__|\__|  \__|\__|      
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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
            'SafeBEP20: approve from non-zero to non-zero allowance'
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
            'SafeBEP20: decreased allowance below zero'
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

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

library SortitionSumTreeFactory {

    struct SortitionSumTree {
        uint K;
        uint[] stack;
        uint[] nodes;
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* ========== STATE VARIABLES ========== */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = Math.min(tree.IDsToNodeIndexes[_ID], tree.nodes.length - 1);

        if (treeIndex == 0) {
            if (_value != 0) {
                if (tree.stack.length == 0) {
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {
            if (_value == 0) {
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                tree.stack.push(treeIndex);

                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {// New, non zero value.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns (bytes32 ID, uint weight) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)
            for (uint i = 1; i <= tree.K; i++) {
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue;
                else {
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
        weight = tree.nodes[treeIndex];
    }

    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns (uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = Math.min(tree.IDsToNodeIndexes[_ID], tree.nodes.length - 1);

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

interface ICakeMasterChef {
    function deposit(uint256 _poolId, uint256 _amount) external;

    function withdraw(uint256 _poolId, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function emergencyWithdraw(uint256 _pid) external;
}

interface IChocoChef {
    function deposit(uint256 _amount) external;
    
    function withdraw(uint256 _amount) external;
    
    function userInfo(address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingReward(address _user) external view returns (uint256);
}

interface IPotController {
    function numbersDrawn(uint potId, bytes32 requestId, uint256 randomness) external;
}

interface IRNGenerator {
    function getRandomNumber(uint _potId) external returns(bytes32 requestId);
}

contract PotController is IPotController {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    /* ========== CONSTANT ========== */

    uint constant private MAX_TREE_LEAVES = 5;
    /**  @dev RNG
      *  BSC Mainnet: 0x022a45D2649eC65E0654D7c22DC218e69e5BB71B
      *  BSC Testnet: 0x83f7e8Cf941d32bEB10EA426A3172FCD1675ea1c
     */
    IRNGenerator private RNGenerator = IRNGenerator(0x022a45D2649eC65E0654D7c22DC218e69e5BB71B);

    /* ========== STATE VARIABLES ========== */

    SortitionSumTreeFactory.SortitionSumTrees private _sortitionSumTree;
    bytes32 private _requestId;  // random number

    mapping(uint => uint) _randomness;  // (potId => ramdomNumber)
    uint public potId;

    /* ========== MODIFIERS ========== */

    modifier onlyRandomGenerator() {
        require(msg.sender == address(RNGenerator), "Only random generator");
        _;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function createTree(bytes32 key) internal {
        _sortitionSumTree.createTree(key, MAX_TREE_LEAVES);
    }

    function getWeight(bytes32 key, bytes32 _ID) internal view returns (uint) {
        return _sortitionSumTree.stakeOf(key, _ID);
    }

    function setWeight(bytes32 key, uint weight, bytes32 _ID) internal {
        _sortitionSumTree.set(key, weight, _ID);
    }

    function draw(bytes32 key, uint randomNumber) internal view returns (address, uint) {
        (bytes32 ID, uint weight) = _sortitionSumTree.draw(key, randomNumber);
        return (address(uint(ID)), weight);
    }

    function getRandomNumber() internal {
        _requestId = RNGenerator.getRandomNumber(potId);
    }

    /* ========== CALLBACK FUNCTIONS ========== */

    function numbersDrawn(uint _potId, bytes32 requestId, uint randomness) override external onlyRandomGenerator {
        if (_requestId == requestId && potId == _potId) {
            _randomness[_potId] = randomness;
        }
    }
}

contract BoxTogetherV3 is Ownable, PotController {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT ========== */

    enum PotState {
        Wait,
        Open,
        Closed,
        Ready,
        Draw,
        Dist
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 index;      // users array index
        uint256 lastMovePotId;
    }

    struct PoolInfo {
        IBEP20 stakingToken;        // Address of LP token contract.
        address masterChef;         // MasterChef or SmartChef/ChocoChef for Strategy
        uint256 pid;                // MasterChef pool Id
        bool isMaster;              // MasterChef or SmartChef
        address syrup;              // If Chef is MasterChef and pid = 0, need to know syrup token
        IBEP20 rewardToken;         // Need to know reward token for use reward distribution
    }

    // Pot Info for pot history
    struct PotInfo {
        uint256 potId;              // Pot id
        uint256 startBlock;         // Pot start block
        uint256 endBlock;           // Pot end block, no more tickets will be distributed after endBlock
        uint256 totalDeposits;      // Total deposited amount when pot closing
        uint256 date;               // Pot rewards distribute time
        address[] winners;          // Pot winner accounts
        uint256[] winnerWeights;    // Winner ticket count
        uint256 rewardPerUser;      // totalRewards/winners.length
        uint256 totalRewards;       // Total distributed rewards
        uint256 totalWeight;        // Total weight
    }
    
    /* ========== STATE VARIABLES ========== */

    // important addresses
    address deployer;
    address feeTreasury;

    IBEP20 public stakingToken;
    PoolInfo public poolInfo;

    mapping (address => UserInfo) public userInfo;  // Info of each user that stakes LP tokens.
    mapping (uint256 => PotInfo) private _histories;

    address[] public oldUsers;                     // Old Pot participants
    address[] public activeUsers;                  // New Pot participants
    uint256 public WINNER_COUNT = 1;
    uint256 usersCount;
    
    uint256 public startBlock;              // The block number when pot starts.
    uint256 public endBlock;                // The block number when pot ends.
    uint256 public potBlockHeight;          // Pot Block height for pot period
    uint256 public totalDeposits = 0;       // Total deposits for default pool
    uint256 public totalWeight = 0;         // Total weight sum in SortitionSumTrees
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public feeRatio = 2000;              // Burn fee :20%
    uint256 public distributorRewardRatio = 100; // Dist. & Prepare methods caller reward, cut from burn fee :1%
    bool public testPeriod = true;          // Owner can be set as false when trust this contract.

    uint256 public maxPrepareDrawPartUserLength = 250;
    uint256 public prepareDrawPart = 0;

    // private vars
    PotState private _currentPotState;
    address[] private _callers;
    bytes32 private _treeKey = keccak256("MacaronSwap/BoxTogether");
    
    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event DrawRewardsDistributed(uint potId, address[] winner);

    constructor(
        IBEP20 _stakingToken,
        uint256 _startBlock,
        uint256 _potBlockHeight,
        uint256 _minAmount,
        uint256 _maxAmount,
        address _masterChef,
        uint256 _pid,
        bool _isMaster,
        address _syrup,
        IBEP20 _rewardToken,
        address _feeTreasury
    ) public {
        stakingToken = _stakingToken;
        potId = 1;
        _currentPotState = PotState.Open;
        startBlock = _startBlock;
        potBlockHeight = _potBlockHeight;
        endBlock = _startBlock.add(_potBlockHeight);
        minAmount = _minAmount;
        maxAmount = _maxAmount;

        // staking pool
        poolInfo = PoolInfo({
            stakingToken: _stakingToken,
            masterChef: _masterChef,
            pid: _pid,
            isMaster: _isMaster,
            syrup: _syrup,
            rewardToken: _rewardToken
        });

        deployer = msg.sender;
        feeTreasury = _feeTreasury;
        
        require(_masterChef != address(0), "_masterChef can't be 0x");
        IBEP20(_stakingToken).safeApprove(address(_masterChef), type(uint256).max);
        
        if(_isMaster) {
            require(_syrup != address(0), "_syrup can't be 0x");
            IBEP20(_syrup).safeApprove(address(_masterChef), type(uint256).max);    
        }

        createTree(_treeKey);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyValidState(PotState _state) {
        require(getPotState() == _state, "Invalid pot state");
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Get current pot state
     */
    function getPotState() public view returns (PotState) {
        if(startBlock > block.number) {
            return PotState.Wait;
        }
        if(endBlock > block.number) {
            return PotState.Open;
        }
        if(_currentPotState == PotState.Open) {
            return PotState.Closed;
        }
        if(_currentPotState == PotState.Ready && getRandomness() > 0) {
            return PotState.Draw;
        }
        return _currentPotState;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingTickets(address _user) public view returns (uint256) {
        if(block.number < startBlock)
            return 0;
        
        UserInfo storage user = userInfo[_user];
        uint256 currWeight = getWeight(_user);
        uint256 leftBlock = endBlock.sub(Math.min(endBlock, block.number));
        uint256 subWeight = user.amount.mul(leftBlock);
        return currWeight.sub(subWeight);
    }

    function balanceOfPool() public view returns (uint256) {
        uint256 stakeTokenBal = IBEP20(poolInfo.stakingToken).balanceOf(address(this));
        if(poolInfo.isMaster) {
            (uint256 amount, ) = ICakeMasterChef(poolInfo.masterChef).userInfo(poolInfo.pid, address(this));
            uint256 pending = _isSameRewardWithStakingToken() ? balanceOfPoolPending() : 0;
            return amount.add(stakeTokenBal).add(pending);
        }
        else {
            (uint256 amount, ) = IChocoChef(poolInfo.masterChef).userInfo(address(this));
            uint256 pending = _isSameRewardWithStakingToken() ? balanceOfPoolPending() : 0;
            return amount.add(stakeTokenBal).add(pending);
        }        
    }

    function balanceOfPoolPending() public view returns (uint256) {
        if(poolInfo.isMaster) {
            return ICakeMasterChef(poolInfo.masterChef).pendingCake(poolInfo.pid, address(this));
        }
        else {
            return IChocoChef(poolInfo.masterChef).pendingReward(address(this));
        }
    }

    function balanceOfRewards() public view returns (uint256) {
        if(_isSameRewardWithStakingToken()) {
            return balanceOfPool().sub(totalDeposits);
        }
        else {
            uint256 rewardTokenBal = IBEP20(poolInfo.rewardToken).balanceOf(address(this));
            return balanceOfPoolPending().add(rewardTokenBal);
        }
    }

    function potHistoryOf(uint _potId) public view returns (PotInfo memory) {
        return _histories[_potId];
    }

    function userLength() public view returns (uint256) {
        return usersCount;
    }

    function getWeight(address _account) public view returns (uint256) {
        bytes32 accountID = bytes32(uint256(_account));
        return getWeight(_treeKey, accountID);
    }
    
    //todo: delete
    function getRandomness(uint _potId) public view returns (uint) {
        return _randomness[_potId];
    }
    
    function getRandomness() public view returns (uint) {
        return _randomness[potId];
    }
    
    function getLastWinners() public view returns (address[] memory) {
        return _histories[potId-1].winners;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /* ========== EXTERNAL & PUBLIC FUNCTIONS ========== */

    function setDistributorRewardRatio(uint256 _ratio) external onlyOwner {
        require(_ratio < feeRatio, "Invalid fee range: Reward ratio must be smaller than feeRatio");
        distributorRewardRatio = _ratio;
    }

    function setFeeTreasury(address _feeTreasury) external onlyOwner {
        require(_feeTreasury != address(0), "_feeTreasury can't be 0x");
        feeTreasury = feeTreasury;
    }

    function setWinnerCount(uint256 _winnerCount) external onlyOwner {
        WINNER_COUNT = _winnerCount;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyOwner {
        require(_feeRatio <= 100, "Invalid fee range");
        require(_feeRatio > distributorRewardRatio, "Invalid fee range: Fee ratio must be bigger than distributorRewardRatio");
        feeRatio = _feeRatio;
    }

    function setPotBlockHeight(uint256 _height) external onlyOwner onlyValidState(PotState.Dist) {
        // update oldUsers weights
        for(uint256 i = 0; i < oldUsers.length; i++) {
            address account = oldUsers[i];
            UserInfo storage user = userInfo[account];
            
            if(user.lastMovePotId == potId) {
                continue;
            }
            
            bytes32 accountID = bytes32(uint256(account));
            uint256 currWeight = getWeight(account);

            totalWeight = totalWeight.sub(currWeight);
            
            // Calculate weight for new weight
            uint256 weight = user.amount.mul(_height);
            totalWeight = totalWeight.add(weight);
            setWeight(_treeKey, weight, accountID);
        }
        potBlockHeight = _height;
    }

    function setAmountMinMax(uint _min, uint _max) external onlyOwner {
        minAmount = _min;
        maxAmount = _max;
    }

    function setPrepareDrawPartUserLength(uint256 _length) external onlyOwner {
        maxPrepareDrawPartUserLength = _length;
    }

    // EMERGENCY ONLY. If tokens stuck  when potstate not in Open, Use this for emergency withdraw activate.
    function setCurrentPotState(PotState _potState) external onlyOwner {
        _currentPotState = _potState;
    }
    
    function setEndBlock(uint256 _endBlock) external onlyOwner {
        require(block.number > endBlock, "Pot end time waiting!");
        require(userLength() == 0, "There are users for waiting draw!");
        endBlock = _endBlock;
    }

    function setTestPeriod(bool _testPeriod) external onlyOwner {
        require(testPeriod == true, "You can not start test period again!");
        testPeriod = _testPeriod;
    }
  
    // Stake STAKING tokens to BoxTogether
    function deposit(uint256 _amount) external onlyValidState(PotState.Open) notContract {
        address account = msg.sender;
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[account];

        uint256 userAmount = user.amount.add(_amount);

        require(_amount > 0 && userAmount >= minAmount && userAmount <= maxAmount, "Deposit mix/max issue: invalid input amount");

        pool.stakingToken.safeTransferFrom(address(account), address(this), _amount);
        
        // Update userInfo
        user.amount = userAmount;
        totalDeposits = totalDeposits.add(_amount);
        
        //Calculate weight
        uint256 currWeight = getWeight(account);
        uint256 newAddWeight = _amount.mul(endBlock.sub(block.number));
        bytes32 accountID = bytes32(uint256(account));
        uint256 weight = currWeight.add(newAddWeight);

        setWeight(_treeKey, weight, accountID);
        totalWeight = totalWeight.add(newAddWeight);
        
        // Stake CLP to PC
        strategyDeposit(pool, _amount);
        
        // Add user to array for navigate in users
        if(currWeight == 0) {
            // first time deposit
            activeUsers.push(account);
            usersCount++;
        }
        else {
            // old user or second time deposit in current pot
            if(user.lastMovePotId != potId) {
                //old user
                activeUsers.push(account);
            }
        }
        
        user.lastMovePotId = potId;
        
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw STAKING tokens from BoxTogether.
    function withdraw() external onlyValidState(PotState.Open) notContract {
        address account = msg.sender;
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[account];
        
        uint256 userAmount = user.amount;
        require(userAmount > 0, "User amount must be bigger than zero!");

        // Update userInfo
        user.amount = 0;
        totalDeposits = totalDeposits.sub(userAmount);
        
        //Calculate weight
        uint256 currWeight = getWeight(account);
        uint256 newSubWeight = userAmount.mul(endBlock.sub(block.number));
        bytes32 accountID = bytes32(uint256(account));
        uint256 weight = currWeight.sub(newSubWeight);

        setWeight(_treeKey, weight, accountID);
        totalWeight = totalWeight.sub(newSubWeight);
        
        // Unstake CLP from PC
        _strategyWithdraw(pool, userAmount);
        
        // Add user to active users array
        if(user.lastMovePotId != potId) {
            //old user
            activeUsers.push(account);
        }
        
        user.lastMovePotId = potId;
        
        pool.stakingToken.safeTransfer(address(msg.sender), userAmount);

        emit Withdraw(msg.sender, userAmount);
    }

    function refundAll() external onlyOwner {
        unstakeAll();
        
        PoolInfo storage pool = poolInfo;
        
        for(uint256 i = 0; i < oldUsers.length; i++) {
            address account = oldUsers[i];
            UserInfo storage user = userInfo[account];
            if(user.amount == 0) {
                continue;
            }
            uint256 amount = user.amount;
            user.amount = 0;
            pool.stakingToken.safeTransfer(address(account), amount);
            totalDeposits = totalDeposits.sub(amount);
        }
        delete oldUsers;
        
        for(uint256 i = 0; i < activeUsers.length; i++) {
            address account = activeUsers[i];
            UserInfo storage user = userInfo[account];
            if(user.amount == 0) {
                continue;
            }
            uint256 amount = user.amount;
            user.amount = 0;
            pool.stakingToken.safeTransfer(address(account), amount);
            totalDeposits = totalDeposits.sub(amount);
        }
        delete activeUsers;
        usersCount = 0;
        createTree(_treeKey);
        totalWeight = 0;
        
        uint256 stakeTokenBal = IBEP20(poolInfo.stakingToken).balanceOf(address(this));
        pool.stakingToken.safeTransfer(owner(), stakeTokenBal);
    }

    function unstakeAll() public onlyOwner {
        PoolInfo storage pool = poolInfo;
        
        if(pool.isMaster) {
            (uint256 _stakedAmount, ) = ICakeMasterChef(pool.masterChef).userInfo(pool.pid, address(this));
            if(pool.pid == 0) {
                ICakeMasterChef(pool.masterChef).leaveStaking(_stakedAmount);
            }
            else {
                ICakeMasterChef(pool.masterChef).withdraw(pool.pid, _stakedAmount);
            }
        }
        else {
            (uint256 _stakedAmount, ) = IChocoChef(pool.masterChef).userInfo(address(this));
            IChocoChef(pool.masterChef).withdraw(_stakedAmount);
        }
    }

    /**
     * @notice Withdraw unexpected tokens sent to the owner
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        if(testPeriod == false) {
            require(_token != address(stakingToken), "Token cannot be same as deposit token");
        }

        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).safeTransfer(msg.sender, amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function strategyDeposit(PoolInfo memory pool, uint256 _amount) internal {
        uint256 _stakeBal = IBEP20(stakingToken).balanceOf(address(this));

        require(_stakeBal >= _amount, 'Strategy: amount did not deposit');

        if (_stakeBal > 0) {
            if(pool.isMaster) {
                if(pool.pid == 0) {
                    // MasterChef default pool
                    ICakeMasterChef(pool.masterChef).enterStaking(_stakeBal);
                    uint256 _syrupBal = IBEP20(pool.syrup).balanceOf(address(this));
                    require(_syrupBal >= _stakeBal, 'Strategy: wrong syrup amount');
                }
                else {
                    // MasterChef other pools
                    ICakeMasterChef(pool.masterChef).deposit(pool.pid, _stakeBal);
                }
            }
            else {
                // SmartChef, SmartChefInitizable or ChocoChef
                IChocoChef(pool.masterChef).deposit(_stakeBal);
            }
        }
    }
    
    function _strategyWithdraw(PoolInfo memory pool, uint256 _amount) internal {        
        uint256 _balance = IBEP20(stakingToken).balanceOf(address(this));
        
        if (_balance < _amount) {
            if(pool.isMaster) {
                (uint256 _stakedAmount, ) = ICakeMasterChef(pool.masterChef).userInfo(pool.pid, address(this));
                require(_amount <= _stakedAmount, 'ICakeMasterChef _strategyWithdraw: _amount greater than _stakedAmount');
        
                if(pool.pid == 0) {
                    // MasterChef default pool
                    ICakeMasterChef(pool.masterChef).leaveStaking(_amount);
                }
                else {
                    // MasterChef other pools
                    ICakeMasterChef(pool.masterChef).withdraw(pool.pid, _amount);
                }
            }
            else {
                // SmartChef, SmartChefInitizable or ChocoChef
                (uint256 _stakedAmount, ) = IChocoChef(pool.masterChef).userInfo(address(this));
                require(_amount <= _stakedAmount, 'IChocoChef _strategyWithdraw: _amount greater than _stakedAmount');
        
                IChocoChef(pool.masterChef).withdraw(_amount);
            }
        }        
    }
    
    function _harvestPendingRewards() internal {
         if(poolInfo.isMaster) {
            if(poolInfo.pid == 0) {
                ICakeMasterChef(poolInfo.masterChef).enterStaking(0);
            }
            else {
                ICakeMasterChef(poolInfo.masterChef).deposit(poolInfo.pid, 0);
            }
        }
        else {
            IChocoChef(poolInfo.masterChef).deposit(0);
        }
    }

    function _isSameRewardWithStakingToken() internal view returns (bool) {
        return address(poolInfo.stakingToken) == address(poolInfo.rewardToken);
    }

    /* ========== LOTTERY DRAW FUNCTIONS ========== */

    /**
     * @notice Prepare current pot for draw. Collect tickets and prepare for startDraw.
     */
    function preparePotForDraw() external onlyValidState(PotState.Closed) notContract {
        require(block.number > endBlock, "Pot end time waiting!");
        require(userLength() > 0, "There is no user for draw!");

        _currentPotState = PotState.Ready;
        
        getRandomNumber();

        // Collect callers for reward
        _callers.push(msg.sender);
    }

    /**
     * @notice Distribute rewards to winners
     */
    function distributeDrawRewards(bool _openNow) external onlyValidState(PotState.Draw) notContract {
        require(_randomness[potId] > 0, "Random number waiting from oracle!");

        _currentPotState = PotState.Dist;

        uint256 userCount = userLength();
        uint256 winnerCount = Math.min(WINNER_COUNT, userCount);

        _callers.push(msg.sender);

        uint256 totalRewards = balanceOfRewards();
        uint256 callerFee = totalRewards.mul(distributorRewardRatio).div(10000);
        uint256 fee = totalRewards.mul(feeRatio).div(10000);
        require(callerFee < fee, "Caller Fee must be smaller than fee.");

        if(_isSameRewardWithStakingToken()) {
            _strategyWithdraw(poolInfo, totalRewards);
        }
        else {
            _harvestPendingRewards();
        }
        
        totalRewards = totalRewards.sub(fee);
            
        if (fee > 0) {
            // Send to burn treasury rest of fee
            poolInfo.rewardToken.safeTransfer(feeTreasury, fee.sub(callerFee));
            
            // Send caller fee to callers
            uint256 feePerCaller = callerFee.div(_callers.length);

            do {
                address caller = _callers[_callers.length-1];                
                poolInfo.rewardToken.safeTransfer(caller, feePerCaller);    
                _callers.pop();
            }
            while(_callers.length > 0);
        }
        
        uint256 rewardPerUser = winnerCount == 0 ? 0 : totalRewards.div(winnerCount);

        PotInfo memory history;
        history.startBlock = startBlock;
        history.endBlock = endBlock;
        history.totalDeposits = totalDeposits;
        history.date = block.timestamp;
        history.winners = new address[](winnerCount);
        history.winnerWeights = new uint256[](winnerCount);
        history.rewardPerUser = rewardPerUser;
        history.totalRewards = totalRewards;
        history.totalWeight = totalWeight;
        
        for (uint i = 0; i < winnerCount; i++) {
            uint rn = uint256(keccak256(abi.encode(_randomness[potId], i))).mod(totalWeight);
            (address selected, uint weight) = draw(_treeKey, rn);
            poolInfo.rewardToken.safeTransfer(selected, rewardPerUser);
            
            history.winners[i] = selected;
            history.winnerWeights[i] = weight;
        }
        _histories[potId] = history;

        emit DrawRewardsDistributed(potId, history.winners);
         
        // Open new pot after distribute
        if(_openNow) {
            _openNewPot();
        }
    }

    // For stuck cases
    function openNewPot() external {
        _openNewPot();
    }

    /**
     * @notice Calculate active users weight for next pot and enable deposit and wd functions.
     */
    function _openNewPot() private onlyValidState(PotState.Dist)  {
        uint256 startIndex = maxPrepareDrawPartUserLength.mul(prepareDrawPart);
        uint256 endIndex = Math.min(maxPrepareDrawPartUserLength.add(startIndex), activeUsers.length);
        prepareDrawPart = prepareDrawPart + 1;
        if(endIndex == activeUsers.length) {
            _currentPotState = PotState.Open;
            startBlock = block.number;
            endBlock = block.number.add(potBlockHeight);
            potId = potId + 1;
            prepareDrawPart = 0;
        }

        for(uint256 i = startIndex; i < endIndex; i++) {
            address account = activeUsers[i];
            UserInfo storage user = userInfo[account];
            
            bytes32 accountID = bytes32(uint256(account));
            uint256 currWeight = getWeight(account);

            totalWeight = totalWeight.sub(currWeight);
            
            if(user.amount > 0) {
                // Calculate weight for new pot and move to oldUsers list
                uint256 weight = user.amount.mul(potBlockHeight);
                totalWeight = totalWeight.add(weight);
                setWeight(_treeKey, weight, accountID);
                
                if(user.index == 0) {
                    // new user
                    oldUsers.push(account);
                    user.index = oldUsers.length;   // set as length for not been zero
                }
            }
            else {
                if(user.index > 0) {
                    // old user left the pot
                    address lastUser = oldUsers[oldUsers.length-1];
                    oldUsers[user.index-1] = lastUser;
                    userInfo[lastUser].index = user.index;
                    oldUsers.pop();
                    user.index = 0;
                }
                
                setWeight(_treeKey, 0, accountID);
            }
        }
        
        if(endIndex == activeUsers.length) {
            delete activeUsers;
            usersCount = oldUsers.length;

            strategyDeposit(poolInfo, 0);
        }
    }
}