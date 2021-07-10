/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed


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
        return sub(a, b, "SafeMath: subtraction overflow");
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC20 {

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

struct Sale {
    address seller; //address of the person who created the sale
    address tokenContract; //address of the contract the NFT is from
    uint256 tokenId; //token ID of the NFT
    uint256 listPrice; //the LIST price (amount that would be paid if Milk or BNB used) in BUSD equivalent decimals
    bool running;
}


contract ButterNFTMarket is Context {
    using SafeMath for uint256;
    using Address for address;
    
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    
    receive() external payable {}
    
    
    //Ownable stuff
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    event SaleCreated(uint256 saleID);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    
    //Tokens stuff
    address wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address milkAddress = 0xb7CEF49d89321e22dd3F51a212d58398Ad542640;
    address butterAddress = 0x0110fF9e7E4028a5337F07841437B92d5bf53762;
    
    address pancakeAddress = 0x1B96B92314C44b159149f7E0303511fB2Fc4774f;
    
    address butterLPaddress = 0xE1BD982AFea7FbA7A5B875e0a226cc38c7E9A7F2;
    address milkLPaddress = 0x18e13207EF3032275cBCA9F210B2fB513D3bA1b1;
    address burnAddress = 0x0000000000000000000000000000000000000001;
    
    IERC20 wbnb = IERC20(wbnbAddress);
    IERC20 busd = IERC20(busdAddress);
    IERC20 milk = IERC20(milkAddress);
    IERC20 butter = IERC20(butterAddress);
    
    //sales info
    mapping (uint256 => Sale) private sales;
    uint256 salesCount = 0;
    bool allowNewSales = true;
    bool testing = true; //Allows only deployer to make/buy sales
    
    
    
    //price calc stuff
    function getButterPrice() public view returns (uint256)
    {
        //Returns 1 BUSD equivalent of BUTTER
        uint256 butterBNBamount = wbnb.balanceOf(butterLPaddress);
        uint256 butterAmount = butter.balanceOf(butterLPaddress);
        
        //Find BNB price in BUSD
        uint256 bnbAmount = wbnb.balanceOf(pancakeAddress);
        uint256 busdAmount = busd.balanceOf(pancakeAddress);
        uint256 bnbPrice = busdAmount.div(bnbAmount);
        
        //Normalize decimals to BNB/BUSD decimals, find amount of Butter 1 BNB is worth
        butterAmount = butterAmount.mul(10**9);
        uint256 butterPerBNB = butterAmount.div(butterBNBamount);
        
        //Find amount of Butter 1 BUSD is worth
        uint256 butterPerBUSD = butterPerBNB.div(bnbPrice);
        butterPerBUSD = butterPerBUSD.mul(10**9); //add back Butter decimals
        return butterPerBUSD;
    }
    
    function getMilkPrice() public view returns (uint256)
    {
        //Returns 1 BUSD equivalent of MILK
        uint256 milkBNBamount = wbnb.balanceOf(milkLPaddress);
        uint256 milkAmount = milk.balanceOf(milkLPaddress);
        
        //Find BNB price in BUSD
        uint256 bnbAmount = wbnb.balanceOf(pancakeAddress);
        uint256 busdAmount = busd.balanceOf(pancakeAddress);
        uint256 bnbPrice = busdAmount.div(bnbAmount);
        
        //Normalize decimals to BNB/BUSD decimals, find amount of Butter 1 BNB is worth
        milkAmount = milkAmount.mul(10**9);
        uint256 milkPerBNB = milkAmount.div(milkBNBamount);
        
        //Find amount of Butter 1 BUSD is worth
        uint256 milkPerBUSD = milkPerBNB.div(bnbPrice);
        milkPerBUSD = milkPerBUSD.mul(10**9); //add back Butter decimals
        return milkPerBUSD;
    }
    
    function getButterPerBNB() public view returns (uint256)
    {
        //returns how many butter (1x10^9) you'd get for 1 BNB (1x10^18)
        uint256 butterBNBamount = wbnb.balanceOf(butterLPaddress);
        uint256 butterAmount = butter.balanceOf(butterLPaddress);
        
        //Normalize decimals to BNB/BUSD decimals, find amount of Butter 1 BNB is worth
        butterAmount = butterAmount.mul(10**9);
        uint256 butterPerBNB = butterAmount.div(butterBNBamount);
        
        return butterPerBNB.mul(10**9);
    }
    
    function getMilkPerBNB() public view returns (uint256)
    {
        uint256 milkBNBamount = wbnb.balanceOf(milkLPaddress);
        uint256 milkAmount = milk.balanceOf(milkLPaddress);
        
        //Normalize decimals to BNB/BUSD decimals, find amount of Butter 1 BNB is worth
        milkAmount = milkAmount.mul(10**9);
        uint256 milkPerBNB = milkAmount.div(milkBNBamount);
        
        return milkPerBNB.mul(10**9);
    }
    
    function getBNBPrice() public view returns (uint256)
    {
        //Find BNB price in BUSD
        uint256 bnbAmount = wbnb.balanceOf(pancakeAddress);
        uint256 busdAmount = busd.balanceOf(pancakeAddress);
        uint256 bnbPrice = busdAmount.div(bnbAmount);
        
        return bnbPrice;
    }
    
    
    //These function return how much should be charged for each payment method taking in the LIST price (with 18 decimals)
    function salePriceButter(uint256 salePrice) public view returns (uint256)
    {
        //Returns the amount of Butter to meet a sale price in BNB
        uint256 butterPerBNB = getButterPerBNB();
        
        uint256 butterForSale = butterPerBNB.mul(salePrice).div(10**18);
        
        
        
        return butterForSale.mul(87733).div(100000);
    }
    
    function salePriceMilk(uint256 salePrice) public view returns (uint256)
    {
        //Returns the amount of Milk to meet a sale price in BUSD
        uint256 milkPerBNB = getMilkPerBNB();
        
        uint256 milkForSale = milkPerBNB.mul(salePrice).div(10**18);
        
        //account for fees to ensure that seller always gets their desired amount from sale
        return milkForSale;
    }
    
    function salePriceBNB(uint256 salePrice) public view returns (uint256)
    {
        //Returns the amount of Milk to meet a sale price in BUSD
       // uint256 busdPerBNB = getBNBPrice();
        
        //uint256 priceBeforeFees = salePrice.div(busdPerBNB);
        
        //account for fees to ensure that seller always gets their desired amount from sale
        //return priceBeforeFees;
        return salePrice;
    }
    
    function getSale(uint256 index) public view returns(address seller, address tokenContract, uint256 tokenId, uint256 listPrice,  bool running)
    {
        return(sales[index].seller, sales[index].tokenContract, sales[index].tokenId, sales[index].listPrice,  sales[index].running);
    }
    
    function getSaleCount() public view returns (uint256)
    {
        return salesCount;
    }
    
    function newSale(address tokenContract, uint256 tokenId, uint256 listPrice) public
    {
        require(allowNewSales, "New sales cannot currently be created");
        if(testing)
        {
            require(msg.sender == owner());
        }
        IERC721 nft = IERC721(tokenContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You must own the NFT you wish to sell");
        //create a new sale object
        Sale memory createdSale = Sale(msg.sender, tokenContract, tokenId, listPrice, true);
        
        //now take the NFT from the seller
        nft.transferFrom(msg.sender, address(this), tokenId);
        
        //add the sale to the list of sales
        sales[salesCount] = (createdSale);
        
        emit SaleCreated(salesCount);
        
        salesCount = salesCount.add(1);
        
    }
    
    function endSale(uint256 index) public
    {
        require(sales[index].running && sales[index].seller == msg.sender, "You must have been the person to create this sale and that sale cannot have already ended");
        IERC721 nft = IERC721(sales[index].tokenContract);
        
        //return the NFT to the seller
        nft.approve(msg.sender, sales[index].tokenId);
        nft.transferFrom(address(this), msg.sender, sales[index].tokenId);
        
        //mark the sales as over
        sales[index].running = false;
    }
    
    function adminEndSale(uint256 index) public onlyOwner
    {
        //ends a sale and transfers the NFT back to the owner
        require(sales[index].running, "This sale must be running");
        IERC721 nft = IERC721(sales[index].tokenContract);
        
        //return the NFT to the seller
        nft.approve(sales[index].seller, sales[index].tokenId);
        nft.transferFrom(address(this), sales[index].seller, sales[index].tokenId);
        
        //mark the sales as over
        sales[index].running = false;
    }
    
    function buyWithButter(uint256 index) public
    {
        require(sales[index].running, "This sale is not running");
        if(testing)
        {
            require(msg.sender == owner());
        }
        require(butter.balanceOf(msg.sender) >= salePriceButter(sales[index].listPrice), "You do not have sufficient butter");
        
        //transfer butter to the NFT seller
        uint256 collectedButter = butter.balanceOf(address(this));
        butter.transferFrom(msg.sender, address(this), salePriceButter(sales[index].listPrice));
        collectedButter = butter.balanceOf(address(this)).sub(collectedButter);
        butter.transfer(sales[index].seller, collectedButter);
        
        //transfer the NFT to the buyer
        IERC721 nft = IERC721(sales[index].tokenContract);
        nft.approve(msg.sender, sales[index].tokenId);
        nft.transferFrom(address(this), msg.sender, sales[index].tokenId);
        
        //mark the sales as complete
        sales[index].running = false;
    }
    
    function buyWithMilk(uint256 index) public
    {
        require(sales[index].running, "This sale is not running");
        if(testing)
        {
            require(msg.sender == owner());
        }
        require(milk.balanceOf(msg.sender) >= salePriceMilk(sales[index].listPrice), "You do not have sufficient milk");
        
        //transfer Milk to the contract
        uint256 collectedMilk = milk.balanceOf(address(this));
        milk.transferFrom(msg.sender, address(this), salePriceMilk(sales[index].listPrice));
        collectedMilk = milk.balanceOf(address(this)).sub(collectedMilk);
        
        //swap that milk for butter
        uint256 collectedButter = butter.balanceOf(address(this));
        swapMilkForButter(collectedMilk);
        collectedButter = butter.balanceOf(address(this)).sub(collectedButter);
        
        //send that butter to the seller
        butter.transfer( sales[index].seller, collectedButter);
        
        //transfer the NFT to the buyer
        IERC721 nft = IERC721(sales[index].tokenContract);
        nft.approve(msg.sender, sales[index].tokenId);
        nft.transferFrom(address(this), msg.sender, sales[index].tokenId);
        
        //mark the sales as complete
        sales[index].running = false;
    }
    
    function buyWithBNB(uint256 index) public payable
    {
        require(sales[index].running, "This sale is not running");
        if(testing)
        {
            require(msg.sender == owner());
        }
        require(msg.sender.balance >= salePriceBNB(sales[index].listPrice), "You do not have sufficient BNB");
        require(msg.value >= salePriceBNB(sales[index].listPrice), "Insuffienct BNB value");
        
        //swap BNB for butter
        uint256 collectedButter = butter.balanceOf(address(this));
        
        
         // make the swap
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = butterAddress;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0, // accept any amount of Butter
            path,
            address(this),
            block.timestamp
        );
        
        collectedButter = butter.balanceOf(address(this)).sub(collectedButter);
        
        uint256 transferableButter = collectedButter.mul(329).div(375);
        uint256 burnableButter = collectedButter - transferableButter;
        
        //send that butter to the seller
        butter.transfer(sales[index].seller, transferableButter);
        butter.transfer(burnAddress, burnableButter);
        
        //transfer the NFT to the buyer
        IERC721 nft = IERC721(sales[index].tokenContract);
        nft.approve(msg.sender, sales[index].tokenId);
        nft.transferFrom(address(this), msg.sender, sales[index].tokenId);
        
        //mark the sales as complete
        sales[index].running = false;
    }
    
    
    //internal functions
    function swapMilkForButter(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = milkAddress;
        path[1] = uniswapV2Router.WETH();
        path[2] = butterAddress;

        milk.approve(address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Butter
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapBNBForButter() private  {
         // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = butterAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
            0, // accept any amount of Butter
            path,
            address(this),
            block.timestamp
        );
    }
    
    
    
    //owner only functions
    function toggleSales(bool salesActive) public onlyOwner
    {
        allowNewSales = salesActive;
    }
    
    function toggleTesting(bool testingActive) public onlyOwner
    {
        testing = testingActive;
    }
    
    function getSalesAllowed() public view returns (bool)
    {
        return allowNewSales;
    }
    
    function getTesting() public view returns (bool)
    {
        return testing;
    }
    
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        uniswapV2Router = _uniswapV2Router;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
}