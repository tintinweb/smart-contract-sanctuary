/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC1155 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _amount, uint256 indexed _id);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

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
    
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}

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
     * - the calling contract must have an ETH balance of at least `value`.
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

contract Proxy is Ownable {

    address public impl;

    fallback() external {
        address _impl = impl;
        assembly {
            let ptr := mload(0x40)
 
            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())
 
             // (2) forward call to logic contract
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
 
            // (3) retrieve return data
            returndatacopy(ptr, 0, size)
 
            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }   
    }

    function setImplementation(address _newImpl) public onlyOwner {
        impl = _newImpl;
    }
    
    function getBlockNumber() public view returns(uint) {
        return block.number;
    }
}


contract INftUtils {
    mapping(uint => uint) public higherTierCards;
    mapping(uint => uint) public lowerTierCards;
    mapping(uint => uint) public goatCards;
}


contract NftStakingUtils is Proxy, INftUtils {

    //_boosts - 1e18 = 100%
    function setGoatCards(uint[] calldata _ids, uint[] calldata _boosts) public onlyOwner {
        for(uint i = 0; i < _ids.length; i++) {
            goatCards[_ids[i]] = _boosts[i];
        }
    }
    
    function setHigherTierCards(uint[] calldata _ids, uint[] calldata _prices) public onlyOwner {
        for(uint i = 0; i < _ids.length; i++) {
            higherTierCards[_ids[i]] = _prices[i];
        }
    }

    function setLowerTierCards(uint[] calldata _ids, uint[] calldata _prices) public onlyOwner {
        for(uint i = 0; i < _ids.length; i++) {
            lowerTierCards[_ids[i]] = _prices[i];
        }
    }
    
    function getCardPrices(uint[] calldata _ids) public view returns(uint[] memory res) {
        res = new uint[](_ids.length);
        for(uint i = 0; i < _ids.length; i++) {
            if(higherTierCards[_ids[i]] > 0) {
                res[i] = higherTierCards[_ids[i]];
            } else {
                res[i] = lowerTierCards[_ids[i]];
            }
        }
    }
}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//NFT-rinkeby - 0x849178B18477D860a058E62b39Dd7d4375e9470d
//UTILS-rinkeby - 0x9d9CFeEb17eFb8de5651de46fb5B6d253c371B1E
//LMT - rinkeby - 0x6dfE64783253Cf1a8C99E4727080025A4bf0FcD7
//STAKING-1 -0x36E95bb8AdC1b6f78FaaAD947d44997791D126b4

contract NftStaking is Proxy, IERC1155TokenReceiver {
    
    
    
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    INftUtils public utils;

    IERC1155 public nft;
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    string public name;

    uint public totalStaked;
    uint public totalPoolSize;
    
    struct ApyStruct {
        uint amount;
        uint apy;
    }

    ApyStruct[] public apyStruct;

    uint public unstakeFee;
    uint public unstakeFeeDuration;
    address public feeReceiverAddress;

    mapping(address => uint) public userLastStakeTime;
    mapping(address => uint[]) public higherTierCardsStaked;
    mapping(address => uint[]) public lowerTierCardsStaked;

    mapping(address => uint) public tokensStaked;
    mapping(address => uint) public lastUserClaim;
    mapping(address => uint) public userApy;

    uint public totalHigherTierCardsPerUser;
    uint public totalLowerTierCardsPerUser;

    event Staked(address indexed userAddress, uint[] ids, uint tokenAmount);
    event Withdrawn(address indexed userAddress, uint[] ids, uint tokenAmount, uint fee);
    event RewardClaimed(address indexed userAddress, uint requiredRewardAmount, uint rewardAmount);

    modifier updateState(address _userAddress) {
        updateUser(_userAddress);
        _;
    }
    
    function getUserCardsStaked(address _userAddress) public view returns(uint[] memory, uint[] memory) {
        return (higherTierCardsStaked[_userAddress], lowerTierCardsStaked[_userAddress]);
    }
    
    function getPoolData(address /*_userAddress*/) public view returns(uint _totalStaked, uint _poolSize, uint _remaining, uint _roiMin, uint _roiMax) {
        _totalStaked = totalStaked;
        _poolSize = totalPoolSize;
        _remaining = totalPoolSize - totalStaked;
        
        if(apyStruct.length > 0) {
            _roiMin = apyStruct[0].apy;
            _roiMax = apyStruct[apyStruct.length-1].apy;
        }
        
       // _stakedNft = higherTierCardsStaked[_userAddress].length + lowerTierCardsStaked[_userAddress].length;
    //     _stakedTokens = tokensStaked[_userAddress];
       // _earnedReward = getReward(_userAddress);
        
    }
    
    function getPoolData2(address _userAddress) public view returns(uint _earnedReward, uint _roi, uint _roiBoost, uint _stakedNft, uint _userStakedTokens) {
       // _totalStaked = totalStaked;
       // _poolSize = totalPoolSize;
       // _remaining = totalPoolSize - totalStaked;
        _roi = getTotalApy(_userAddress);
        _roiBoost = getBoostedApy(_userAddress);
        _stakedNft = higherTierCardsStaked[_userAddress].length + lowerTierCardsStaked[_userAddress].length;
        _userStakedTokens = tokensStaked[_userAddress];
        _earnedReward = getReward(_userAddress);
        
    }

    function updateUsers(address[] calldata _userAddresses) public {
        for(uint i = 0; i < _userAddresses.length; i++) {
            updateUser(_userAddresses[i]);
        }
    }

    function update() public {
        updateUser(msg.sender);
    }

    function updateUser(address _userAddress) public {
        uint reward = getReward(_userAddress);
        uint balance = rewardToken.balanceOf(address(this));

        uint userReward = reward < balance ? reward : balance;
        lastUserClaim[_userAddress] = block.timestamp;
        
        if(userReward > 0) {
            rewardToken.safeTransfer(_userAddress, userReward);
            emit RewardClaimed(_userAddress, reward, userReward);
        }
    }

    function init(string memory _name, address _utilsAddress, IERC1155 _nft, IERC20 _stakingToken, IERC20 _rewardToken, uint _totalPoolSize) public onlyOwner {
        name = _name;
        nft = _nft;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;

        utils = INftUtils(_utilsAddress);
        totalPoolSize = _totalPoolSize;

        unstakeFeeDuration = 7 days;
        unstakeFee = 0.02e18; //2%
        feeReceiverAddress = msg.sender;
        
        totalHigherTierCardsPerUser = 5;
        totalLowerTierCardsPerUser = 10;
        
        
        // setApyStruct();
    }

    function getReward(address _userAddress) public view returns(uint) {
        return (block.timestamp - lastUserClaim[msg.sender])
        .mul(tokensStaked[_userAddress].mul(getTotalApy(_userAddress)) / 1e18 / (30 days));
    }


    function stakeCards(uint[] calldata _ids) public updateState(msg.sender) {
        uint totalPrice;

        for(uint i = 0; i < _ids.length; i++) {
            bool isHigherTier;
            uint price;

            uint higherTierPrice = utils.higherTierCards(_ids[i]);
            if(higherTierPrice > 0) {
                isHigherTier = true;
                price = higherTierPrice;
            } else {
                uint lowerTierPrice = utils.lowerTierCards(_ids[i]);
                require(lowerTierPrice != 0, "card is not stakable");
                price = lowerTierPrice;
            }

            if(isHigherTier) {
                require(higherTierCardsStaked[msg.sender].length < totalHigherTierCardsPerUser, "exceed higher tier staking limit");
                higherTierCardsStaked[msg.sender].push(_ids[i]);
            } else {
                require(lowerTierCardsStaked[msg.sender].length < totalLowerTierCardsPerUser, "exceed lower tier staking limit");
                lowerTierCardsStaked[msg.sender].push(_ids[i]);
            }

            nft.safeTransferFrom(msg.sender, address(this), _ids[i], 1, "0x");
            totalPrice += price;
        }

        stakingToken.safeTransferFrom(msg.sender, address(this), totalPrice);
        tokensStaked[msg.sender] += totalPrice;
        totalStaked += totalPrice;
        
        require(tokensStaked[msg.sender] >= apyStruct[0].amount, "total stake less than minimum");
        require(totalStaked <= totalPoolSize, "exceed pool limit");
        
        bool isGoatExists;
        for(uint i = 0; i < higherTierCardsStaked[msg.sender].length; i++) {
            if(utils.goatCards(higherTierCardsStaked[msg.sender][i]) > 0) {
                if(!isGoatExists) {
                    isGoatExists = true;
                } else {
                    revert("cannot stake more than 1 goat card");
                }
            }
        }

        lastUserClaim[msg.sender] = block.timestamp;
            
        userLastStakeTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, _ids, totalPrice);
    }

    function withdraw(uint[] calldata _ids) public updateState(msg.sender) {
        uint totalPrice;

        for(uint i = 0; i < _ids.length; i++) {
            require(_ids[i] != 0, "invalid input");

            uint price;
            bool found;

            for(uint j = 0; j < higherTierCardsStaked[msg.sender].length; j++) {
                if(higherTierCardsStaked[msg.sender][j] == _ids[i]) {
                    found = true;
                    price = utils.higherTierCards(_ids[i]);
                    higherTierCardsStaked[msg.sender][j] = 0;
                    break;
                }
            }

            if(!found) {
                for(uint j = 0; j < lowerTierCardsStaked[msg.sender].length; j++) {
                    if(lowerTierCardsStaked[msg.sender][j] == _ids[i]) {
                        found = true;
                        price = utils.lowerTierCards(_ids[i]);
                        lowerTierCardsStaked[msg.sender][j] = 0;
                        break;
                    }
                }
            }

            require(found, "token is not staked");
            nft.safeTransferFrom(address(this), msg.sender, _ids[i], 1, "0x");
            totalPrice += price;
        }

        tokensStaked[msg.sender] -= totalPrice;
        totalStaked -= totalPrice;

        uint _fee;
        if(block.timestamp < userLastStakeTime[msg.sender].add(unstakeFeeDuration) 
            && rewardToken.balanceOf(address(this)) > 0) //You do not pay unstaking fee when staking event is over
        {
            //charge fee
            _fee = totalPrice.mul(unstakeFee).div(1e18);
            stakingToken.safeTransfer(feeReceiverAddress, _fee);
        }

        stakingToken.safeTransfer(msg.sender, totalPrice.sub(_fee));

        uint[] memory _higherTierCardsStaked = higherTierCardsStaked[msg.sender];
        uint[] memory _lowerTierCardsStaked = lowerTierCardsStaked[msg.sender];

        higherTierCardsStaked[msg.sender] = new uint[](0);
        lowerTierCardsStaked[msg.sender] = new uint[](0);

        for(uint i = 0; i < _higherTierCardsStaked.length; i++) {
            if(_higherTierCardsStaked[i] > 0) {
                higherTierCardsStaked[msg.sender].push(_higherTierCardsStaked[i]);
            }
        }

        for(uint i = 0; i < _lowerTierCardsStaked.length; i++) {
            if(_lowerTierCardsStaked[i] > 0) {
                lowerTierCardsStaked[msg.sender].push(_lowerTierCardsStaked[i]);
            }
        }

        emit Withdrawn(msg.sender, _ids, totalPrice, _fee);
    }
    
    function setApyStruct() internal {
        apyStruct.push(ApyStruct({amount: 2000e18,    apy: 0.02e18})); //1e18 - 100%
        apyStruct.push(ApyStruct({amount: 10000e18,   apy: 0.05e18}));
        apyStruct.push(ApyStruct({amount: 20000e18,   apy: 0.085e18}));
        apyStruct.push(ApyStruct({amount: 40000e18,   apy: 0.1e18}));
        apyStruct.push(ApyStruct({amount: 60000e18,   apy: 0.115e18}));
        apyStruct.push(ApyStruct({amount: 80000e18,   apy: 0.13e18}));
        apyStruct.push(ApyStruct({amount: 100000e18,  apy: 0.145e18}));
        apyStruct.push(ApyStruct({amount: 120000e18,  apy: 0.16e18}));
        apyStruct.push(ApyStruct({amount: 140000e18,  apy: 0.175e18}));
    }
    
    function getApyByStake(uint _amount) public view returns(uint) {
        if(apyStruct.length == 0 || _amount < apyStruct[0].amount) {
            return 0;
        }

        for(uint i = 0; i < apyStruct.length; i++) {
            if(_amount <= apyStruct[i].amount) {
                return apyStruct[i].apy;
            }
        }

        return apyStruct[apyStruct.length-1].apy;
    }

    //Only one goat card gives boosted APY
    function getBoostedApy(address _userAddress) public view returns(uint) {
        for(uint i = 0; i < higherTierCardsStaked[_userAddress].length; i++) {
            uint boosted = utils.goatCards(higherTierCardsStaked[_userAddress][i]);
            if(boosted > 0) {
                return boosted;
            }
        }

        return 0;
    }
    
    function getTotalApy(address _userAddress) public view returns(uint) {
        uint baseAPY = getApyByStake(tokensStaked[_userAddress]);
        uint boostedApy = getBoostedApy(_userAddress);

        return baseAPY * (1e18 + boostedApy) / 1e18;
    }
    
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external override returns(bytes4) {
         return IERC1155TokenReceiver.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external override returns(bytes4) {
        return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
    
    function supportsInterface(bytes4 _interfaceID) override external view returns (bool) {
        bytes4 INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
        bytes4 INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
        
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
            return true;
        }
        return false;
    }

}