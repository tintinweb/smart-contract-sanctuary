/**
 *Submitted for verification at snowtrace.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        assembly {
            size := extcodesize(account)
        }
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract NodeManager is Ownable, IERC721, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;

    struct NodeEntity {
        string name;
        uint64 mintTime;
        uint64 claimTime;
        uint64 nodeId;
        uint64 rewardAvailable;
    }

    mapping(address => uint256) private _balances;
    mapping(uint64 => address) private _owners;
    mapping(uint64 => string) private _uris;
    mapping(uint64 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    NodeEntity[] _nodes;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint64 public nodePrice;
    uint64 public rewardPerNode;
    uint128 public claimTime;
    string public defaultUri = "";

    bool public autoDistri = true;
    bool public distribution = false;

    uint256 public gasForDistribution = 300000;
    uint256 public lastDistributionCount = 0;
    uint256 public lastIndexProcessed = 0;

    constructor(uint64 _nodePrice, uint64 _rewardPerNode, uint128 _claimTime) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
    }

    function totalNodesCreated() view external returns (uint) {
        return _nodes.length;
    }

    function distributeRewards() private returns (uint256, uint256, uint256) {
        distribution = true;
        uint256 numberOfnodeOwners = _nodes.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 localLastIndex = lastIndexProcessed;
        uint256 iterations = 0;
        uint64 newClaimTime = uint64(block.timestamp);
        uint256 claims = 0;
        NodeEntity storage _node;

        while (gasUsed < gasForDistribution && iterations < numberOfnodeOwners) {
            localLastIndex++;
            if (localLastIndex >= _nodes.length) {
                localLastIndex = 0;
            }
            _node = _nodes[localLastIndex];

            if (claimable(_node)) {
                _node.rewardAvailable += rewardPerNode;
                _node.claimTime = newClaimTime;
                claims++;
            }
            iterations++;
            uint256 newGasLeft = gasleft();
            gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            gasLeft = newGasLeft;
        }

        lastIndexProcessed = localLastIndex;
        distribution = false;
        return (iterations, claims, lastIndexProcessed);
    }

    function addNode(address account, uint amount, uint claim) onlyOwner external {
        for (uint256 i = 0; i < amount; i++) {
            uint64 nodeId = uint64(_nodes.length);
            _nodesOfUser[account].push(
                NodeEntity({
                    name: "Migated",
                    mintTime: 1639166400,
                    claimTime: uint64(claim),
                    nodeId: nodeId,
                    rewardAvailable: 1
                })
            );
            _owners[nodeId] = account;
            _balances[account] += 1;
        }
    }

    function createNode(address account, string memory nodeName, bool skipDistribution) onlyOwner external {
        uint64 nodeId = uint64(_nodes.length);
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                mintTime: uint64(block.timestamp),
                claimTime: uint64(block.timestamp),
                nodeId: nodeId,
                rewardAvailable: 0
            })
        );
        _owners[nodeId] = account;
        _balances[account] += 1;
        if (autoDistri && !distribution && !skipDistribution) {
            distributeRewards();
        }
    }

    function _cashoutAllNodesReward(address account) external onlyOwner returns (uint256){
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            NodeEntity storage _node = nodes[i];
            rewardsTotal += _node.rewardAvailable;
            _node.rewardAvailable = 0;
        }
        return rewardsTotal;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.claimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account) external view returns (uint256) {
        if(isNodeOwner(account)){
            uint256 nodesCount;
            uint256 rewardCount = 0;

            NodeEntity[] storage nodes = _nodesOfUser[account];
            nodesCount = nodes.length;

            for (uint256 i = 0; i < nodesCount; i++) {
                rewardCount += nodes[i].rewardAvailable;
            }

            return rewardCount;
        } else {
            return 0;
        }
    }

    function _getNodesIdsOf(address account) external view returns (string memory) {
        if(isNodeOwner(account)) {
            NodeEntity[] memory nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            NodeEntity memory _node;
            string memory _ids = uint2str(nodes[0].nodeId);
            string memory separator = "#";

            for (uint256 i = 1; i < nodesCount; i++) {
                _node = nodes[i];

                _ids = string(
                    abi.encodePacked(
                        _ids,
                        separator,
                        uint2str(_node.nodeId)
                    )
                );
            }
            return _ids;
        } else {
            return "";
        }
    }

    function _getNodesNamesOf(address account) external view returns (string memory) {
        if(isNodeOwner(account)) {
            NodeEntity[] memory nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            NodeEntity memory _node;
            string memory names = nodes[0].name;
            string memory separator = "#";
            for (uint256 i = 1; i < nodesCount; i++) {
                _node = nodes[i];
                names = string(abi.encodePacked(names, separator, _node.name));
            }
            return names;
        } else {
            return "";
        }
    }

    function _getNodesCreationTimeOf(address account) external view returns (string memory) {
        if(isNodeOwner(account)) {
            NodeEntity[] memory nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            NodeEntity memory _node;
            string memory _creationTimes = uint2str(nodes[0].mintTime);
            string memory separator = "#";

            for (uint256 i = 1; i < nodesCount; i++) {
                _node = nodes[i];

                _creationTimes = string(
                    abi.encodePacked(
                        _creationTimes,
                        separator,
                        uint2str(_node.mintTime)
                    )
                );
            }
            return _creationTimes;
        } else {
            return "";
        }
    }

    function _getNodesRewardAvailableOf(address account) external view returns (string memory) {
        if(isNodeOwner(account)) {
            NodeEntity[] memory nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            NodeEntity memory _node;
            string memory _rewardsAvailable = uint2str(nodes[0].rewardAvailable);
            string memory separator = "#";

            for (uint256 i = 1; i < nodesCount; i++) {
                _node = nodes[i];

                _rewardsAvailable = string(
                    abi.encodePacked(
                        _rewardsAvailable,
                        separator,
                        uint2str(_node.rewardAvailable)
                    )
                );
            }
            return _rewardsAvailable;
        } else {
            return "";
        }
    }

    function _getNodesLastClaimTime(address account) external view returns (string memory) {
        if(isNodeOwner(account)) {
            NodeEntity[] memory nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            NodeEntity memory _node;
            string memory _lastClaimTimes = uint2str(nodes[0].mintTime);
            string memory separator = "#";

            for (uint256 i = 1; i < nodesCount; i++) {
                _node = nodes[i];

                _lastClaimTimes = string(
                    abi.encodePacked(
                        _lastClaimTimes,
                        separator,
                        uint2str(_node.claimTime)
                    )
                );
            }
            return _lastClaimTimes;
        } else {
            return "";
        }
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeNodePrice(uint64 newNodePrice) onlyOwner external {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint64 newPrice) onlyOwner external {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint64 newTime) onlyOwner external {
        claimTime = newTime;
    }

    function _changeAutoDistri(bool newMode) onlyOwner external {
        autoDistri = newMode;
    }

    function _changeGasDistri(uint256 newGasDistri) onlyOwner external {
        gasForDistribution = newGasDistri;
    }

    function _setTokenUriFor(uint64 nodeId, string memory uri) onlyOwner external {
        _uris[nodeId] = uri;
    }

    function _setDefaultTokenUri(string memory uri) onlyOwner external {
        defaultUri = uri;
    }

    function isNodeOwner(address account) private view returns (bool) {
        return balanceOf(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _distributeRewards() external returns (uint256, uint256,uint256) {
        return distributeRewards();
    }


    function name() external override pure returns (string memory) {
        return "Army";
    }

    function symbol() external override pure returns (string memory) {
        return "ARMY";
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        string memory uri = _uris[uint64(tokenId)];
        if(bytes(uri).length == 0) {
            return defaultUri;
        } else {
            return uri;
        }
    }

    function balanceOf(address owner) public override view returns (uint256 balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view returns (address owner) {
        address theOwner = _owners[uint64(tokenId)];
        require(theOwner != address(0), "ERC721: owner query for nonexistent token");
        return theOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to,uint256 tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address operator){
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[uint64(tokenId)];
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[uint64(tokenId)] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[uint64(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[uint64(tokenId)] != address(0);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

contract Pool is Ownable {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function pay(address _to, uint _amount) external onlyOwner returns (bool) {
        return token.transfer(_to, _amount);
    }
}

contract NodeHelper is Ownable {
    NodeManager public manager;
    IUniswapV2Router02 public router;
    IERC20 public token;

    address public team;
    Pool public pool;

    uint public teamFee = 10;
    uint public poolFee = 70;
    uint public liquidityFee = 20;

    bool private swapLiquify = true;
    uint256 public swapTokensAmount = 30;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    bool private swapping = false;
    
    mapping(address => uint) _amounts;
    mapping(address => uint) _claims;

    constructor(address _manager, address _router, address _token) {
        manager = NodeManager(_manager);
        router = IUniswapV2Router02(_router);
        token = IERC20(_token);
        pool = new Pool(_token);
    }

    function setDefaultFees(uint256[] memory fees) public onlyOwner {
        teamFee = fees[0];
        poolFee = fees[1];
        liquidityFee = fees[2];
    }

    function updateSwapTokensAmount(uint256 _swap_) external onlyOwner {
        swapTokensAmount = _swap_;
    }

    function updateRouter(address _router) public onlyOwner {
        router = IUniswapV2Router02(_router);
    }

    function updateTeamAddress(address payable _team) external onlyOwner {
        team = _team;
    }

    function updatePoolAddress(address _pool) external onlyOwner {
        pool.pay(address(owner()), token.balanceOf(address(pool)));
        pool = new Pool(_pool);
    }

    function updateLiquiditFee(uint256 _fee) external onlyOwner {
        poolFee = _fee;
    }

    function updateTeamFee(uint256 _fee) external onlyOwner {
        teamFee = _fee;
    }

    function changeSwapLiquify(bool _liquify) public onlyOwner {
        swapLiquify = _liquify;
    }

    function _swap(uint contractTokenBalance) internal {
        swapping = true;

        uint256 teamTokens = (contractTokenBalance * teamFee) / 100;
        token.transfer(team, teamTokens);

        uint256 poolTokens = (contractTokenBalance * poolFee) / 100;
        token.transfer(address(pool), poolTokens);

        uint256 liquidityTokens = contractTokenBalance * liquidityFee / 100;
        swapAndLiquify(liquidityTokens);

        swapTokensForEth(token.balanceOf(address(this)));
        swapping = false;
    }

    function createNodeWithTokens(string memory name) public {
        require(bytes(name).length > 0 && bytes(name).length < 33, "NODE CREATION: 0 < NAME SIZE < 33");
        address sender = _msgSender();
        require(sender != address(0), "NODE CREATION:  Creation from the zero address");
        require(sender != team, "NODE CREATION: Team cannot create node");
        uint256 nodePrice = manager.nodePrice() * 10 ** 18;
        require(token.balanceOf(sender) >= nodePrice, "NODE CREATION: Balance too low for creation.");
        uint256 contractTokenBalance = token.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

        if (swapAmountOk && swapLiquify && !swapping && sender != owner()) {
            _swap(contractTokenBalance);
        }

        token.transferFrom(_msgSender(), address(this), nodePrice);
        manager.createNode(sender, name, false);
    }

    function createMultipleNodeWithTokens(string memory name, uint amount) public {
        require(bytes(name).length > 0 && bytes(name).length < 33, "NODE CREATION: 0 < NAME SIZE < 33");
        address sender = _msgSender();
        require(sender != address(0), "NODE CREATION:  Creation from the zero address");
        require(sender != team, "NODE CREATION: Team cannot create node");
        uint256 nodePrice = manager.nodePrice() * 10 ** 18;
        require(token.balanceOf(sender) >= nodePrice * amount, "NODE CREATION: Balance too low for creation.");
        uint256 contractTokenBalance = token.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

        if (swapAmountOk && swapLiquify && !swapping && sender != owner()) {
            _swap(contractTokenBalance);
        }

        token.transferFrom(_msgSender(), address(this), nodePrice);
        for (uint256 i = 0; i < amount; i++) {
            manager.createNode(sender, name, true);   
        }
    }

    function createMultipleNodeWithTokensAndName(string[] memory names, uint amount) public {
        require(names.length == amount, "You need to provide exactly matching names");
        address sender = _msgSender();
        require(sender != address(0), "NODE CREATION:  creation from the zero address");
        require(sender != team, "NODE CREATION: futur and rewardsPool cannot create node");
        uint256 nodePrice = manager.nodePrice() * 10 ** 18;
        require(token.balanceOf(sender) >= nodePrice * amount, "NODE CREATION: Balance too low for creation.");
        uint256 contractTokenBalance = token.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

        if (swapAmountOk && swapLiquify && !swapping && sender != owner()) {
            _swap(contractTokenBalance);
        }

        token.transferFrom(_msgSender(), address(this), nodePrice);
        for (uint256 i = 0; i < amount; i++) {
            string memory name = names[i];
            require(bytes(name).length > 0 && bytes(name).length < 33, "NODE CREATION: NAME SIZE INVALID");
            manager.createNode(sender, name, true); 
        }
    }

    function claim() public {
        address sender = _msgSender();
        require(sender != address(0), "MANIA CSHT:  creation from the zero address");
        require(sender != team, "MANIA CSHT: futur and rewardsPool cannot cashout rewards");
        uint256 rewardAmount = manager._cashoutAllNodesReward(sender) * 10 ** 18;
        require(rewardAmount > 0,"MANIA CSHT: You don't have enough reward to cash out");

        pool.pay(sender, rewardAmount);
    }

    function changeNodePrice(uint64 _price) onlyOwner external {
        manager._changeNodePrice(_price);
    }

    function changeNodeReward(uint64 _reward) onlyOwner external {
        manager._changeRewardPerNode(_reward);
    }

    function changeClaimTime(uint64 _time) onlyOwner external {
        manager._changeClaimTime(_time);
    }

    function changeAutoDistribution(bool _distribution) onlyOwner external {
        manager._changeAutoDistri(_distribution);
    }

    function changeGasDistribution(uint _gas) onlyOwner external {
        manager._changeGasDistri(_gas);
    }

    function setTokenUriFor(uint64 _id, string calldata _uri) onlyOwner external {
        manager._setTokenUriFor(_id, _uri);
    }

    function setTokenUri(string calldata _uri) onlyOwner external {
        manager._setDefaultTokenUri(_uri);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WAVAX();

        token.approve(address(router), tokenAmount);

        router.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        token.approve(address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(token),
            tokenAmount,
            0,
            0,
            address(owner()),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 received = address(this).balance - initialBalance;

        addLiquidity(otherHalf, received);

        emit SwapAndLiquify(half, received, otherHalf);
    }

    function _allowMigrate(address[] calldata _account, uint[] calldata _amount) onlyOwner external {
        for (uint256 i = 0; i < _account.length; i++) {
            _amounts[_account[i]] = _amount[i];
        }
    }

    function migrate(uint _amount, uint _claim) external {
        uint avaibleAmount = _amounts[msg.sender];
        require(avaibleAmount <= _amount, "You cannot receive more than you are allowed to");
        _amounts[msg.sender] = avaibleAmount - _amount;
        manager.addNode(msg.sender, _amount, _claim);
    }
}