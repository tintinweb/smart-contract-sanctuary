/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
        bytes  memory buffer = new  bytes (digits);
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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library AddressUpgradeable {
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

library SafeMathUpgradeable {
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

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

interface IERC165Upgradeable {
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

interface IERC721Upgradeable is IERC165Upgradeable {
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

interface IERC20Upgradeable {
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

interface IUniswapV2Router is IUniswapV2Router01 {
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

contract BearXNFTStaking is OwnableUpgradeable{

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    
    //-------------constant value------------------//
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    uint256 constant DURATION_FOR_REWARDS = 2 minutes;
    uint256 constant DURATION_FOR_STOP_REWARDS = 3650 days;

    address public BearXNFTAddress;
    address public ROOTxTokenAddress;  
    address public SROOTxTokenAddress;
    uint256 public totalStakes;  

    uint256 public MaxSROOTXrate;
    uint256 public MinSROOTXrate;
    uint256 public MaxRate;
    uint256 public MinRate;
    uint256 public maxprovision;
    uint256 public RateValue;
    uint256 public SROOTRateValue;

    struct stakingInfo {
        uint256 nft_id;
        uint256 stakedDate;
        uint256 claimedDate_SROOT;
        uint256 claimedDate_WETH;
        uint256 claimedDate_ROOTX;
    }

    mapping(address => stakingInfo[]) internal stakes;
    address[] internal stakers;
    bytes32 public encodedFunction;

    // constructor(address _bearxnftaddress, address _rootxtokenaddress, address _srootxtokenaddress)
    // {
    //     BearXNFTAddress = _bearxnftaddress;
    //     ROOTxTokenAddress = _rootxtokenaddress;
    //     SROOTxTokenAddress = _srootxtokenaddress;
    //     totalStakes = 0; 
    //     MaxSROOTXrate = 100*10**18;
    //     MinSROOTXrate = 50*10**18;
    //     MaxRate = 11050*10**18;
    //     MinRate = 500*10**18;
    //     maxprovision = 3000;
    //     DURATION_FOR_REWARDS = 2 minutes;
    //     DURATION_FOR_STOP_REWARDS = 3650 days;
    //     RateValue = ((MaxRate - MinRate) / maxprovision);
    //     SROOTRateValue = (( MaxSROOTXrate - MinSROOTXrate ) / maxprovision);
        
    // }

    function initialize() public initializer{
        __Ownable_init();
        BearXNFTAddress = 0x2A598Bd4F5a111F57A4fb1D7603a6640942fE068;
        ROOTxTokenAddress = 0x9517dC27417051cB8651D70D6498EBAf7B82D73B;
        SROOTxTokenAddress = 0x10D08A0Cc564bA414419959C6E51fC8C16dcA4Cc;
        totalStakes = 0; 
        MaxSROOTXrate = 100*10**18;
        MinSROOTXrate = 50*10**18;
        MaxRate = 11050*10**18;
        MinRate = 500*10**18;   
        maxprovision = 3000;
        RateValue = ((MaxRate - MinRate) / maxprovision);
        SROOTRateValue = (( MaxSROOTXrate - MinSROOTXrate ) / maxprovision);
    }
    
    function getTotalStake() public view returns (uint256 ){
        return totalStakes;
    }

    function encodeFunction() public{
        encodedFunction = bytes32(keccak256("initialize()"));
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint _amountIn) internal view returns (uint) {
        address[] memory path;
        
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
  
        // same length as path
        uint[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(
            _amountIn,
            path
        );

        return amountOutMins[path.length - 1];
    }

    function setBearXNFTAddress(address _addr) onlyOwner external {
        require(BearXNFTAddress.isContract(), "Address is not contract");
        BearXNFTAddress = _addr;
    
    }

    function setROOTxTokenAddress(address _addr) onlyOwner external {
        require(ROOTxTokenAddress.isContract(), "Address is not contract");
        ROOTxTokenAddress = _addr;
    }

    function setSROOTxTokenAddress(address _addr) onlyOwner external {
        require(SROOTxTokenAddress.isContract(), "Address is not contract");
        SROOTxTokenAddress = _addr;
    }

    function getAPR() public view returns(uint256) {
        uint A = MaxSROOTXrate*(1+1*MaxRate/100);
        uint temp = A - MaxSROOTXrate;
        
        uint APR = (temp/MaxSROOTXrate)/1*1*100;
        return APR;
    }

    function isStaker(address _addr) public view returns (bool, uint256)
    {
        for(uint256 i = 0 ; i < stakers.length ; i += 1)
        {
            if(_addr == stakers[i]) return (true, i);
        }

        return (false,0);
    }

    function addStaker(address _addr) internal {
        (bool _isStaker,) = isStaker(_addr);
        if(!_isStaker) stakers.push(_addr);
    }

    function removeStaker(address _addr) internal {
        (bool _isStaker, uint256 i) = isStaker(_addr);
        if(_isStaker){
            stakers[i] = stakers[stakers.length - 1];
            stakers.pop();
        }
    }

    function stakeOf(address _addr) public view returns(uint256[] memory)
    {
        uint256[] memory _iids = new uint256[](stakes[_addr].length);
        for(uint256 i = 0 ; i < stakes[_addr].length ; i++)
        {
            _iids[i] = stakes[_addr][i].nft_id;
        }
        return _iids;
    }

    function createStake(uint256[] memory _ids) external
    {
        for(uint256 i = 0 ; i < _ids.length ; i++)
        {
            _createStake(_ids[i], msg.sender);
        }
    }

    function _createStake(uint256 _id, address _addr) internal {
        if(MaxRate >= MinRate) {
            MaxRate -= RateValue;
            MaxSROOTXrate -= SROOTRateValue;
        }
        require(IERC721Upgradeable(BearXNFTAddress).ownerOf(_id) ==_addr, "You are not a owner of the nft");
        require(IERC721Upgradeable(BearXNFTAddress).getApproved(_id) == address(this), "You should approve nft to the staking contract");
        IERC721Upgradeable(BearXNFTAddress).transferFrom(_addr, address(this), _id);
        (bool _isStaker,) = isStaker(_addr);
        stakingInfo memory sInfo = stakingInfo(_id,block.timestamp, block.timestamp, block.timestamp, block.timestamp);
        totalStakes = totalStakes.add(1);
        stakes[_addr].push(sInfo);
        if(!_isStaker)
        {
            addStaker(_addr);
        }  
    }

    function unStake(uint256[] memory _ids) public isOnlyStaker{
        _claimOfROOTxToken(msg.sender);
        _claimOfSROOTxToken(msg.sender);
        _claimOfWETH(msg.sender);
        for(uint256 i =0; i<_ids.length; i++){
            IERC721Upgradeable(BearXNFTAddress).transferFrom(address(this),msg.sender,_ids[i]);
            totalStakes--;
            removeNFT(msg.sender, _ids[i]);
        }
    }

    function _claimOfROOTxToken(address _addr) internal {
        uint256 finalOfROOTxToken = 0;
        bool status = false;
        bool flag;
        (uint256 sumofgenesisbear,) = getGenesisBear(_addr);
        if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[_addr].length; i++) {
                uint256 temp = calDay(stakes[_addr][i].claimedDate_ROOTX);
                if(isGenesisBear(stakes[_addr][i].nft_id) &&  temp < 1){
                    flag = false;
                }
            }
            if(flag && stakes[_addr].length != 0){
                finalOfROOTxToken = 10;
                 status = true;
            }
            // require(IERC20Upgradeable(ROOTxTodress).balanceOf(address(this)) >= finalOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
            // IERC20Upgradeable(ROOTxTokenAddress).transfer(msg.sender, finalOfROOTxToken * (10 ** 18));
           
        }
        else {
            for(uint256 i = 0; i < stakes[_addr].length; i ++){
                if(isGenesisBear(stakes[_addr][i].nft_id) ) {
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_ROOTX);
                    finalOfROOTxToken = finalOfROOTxToken.add(dd*10);
                     status = true;
                    // require(IERC20Upgradeable(ROOTxTokenAddress).balanceOf(address(this)) >= claimAmountOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
                    // IERC20Upgradeable(ROOTxTokenAddress).transfer(msg.sender, claimAmountOfROOTxToken * (10 ** 18));
                    // stakes[msg.sender][i].claimedDate = block.timestamp;
                }
            }
           
        }

         require(IERC20Upgradeable(ROOTxTokenAddress).balanceOf(address(this)) >= finalOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
         IERC20Upgradeable(ROOTxTokenAddress).transfer(_addr, finalOfROOTxToken * (10 ** 18));

         for(uint256 i = 0; i < stakes[_addr].length; i ++){
             stakes[_addr][i].claimedDate_ROOTX = block.timestamp;
         }
    }

    function _claimOfSROOTxToken(address _addr) internal {
        uint256 finalOfSROOTxToken = 0;
      
        bool status = false;
        (uint256 sumofgenesisbear,) = getGenesisBear(_addr);
        bool flag = true;
        if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                    finalOfSROOTxToken = finalOfSROOTxToken.add(200*(10**18) * dd);
                     status = true;
                }
            }
            if(flag && stakes[_addr].length != 0){
                for(uint256 i = 0; i < stakes[_addr].length; i ++){
                    if(!isGenesisBear(stakes[_addr][i].nft_id)) continue;

                    if(calDay(stakes[_addr][i].claimedDate_SROOT) <= 3)
                        continue;
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                    finalOfSROOTxToken = finalOfSROOTxToken.add( dd *  MaxSROOTXrate / 2);
                    // finalOfSROOTxToken += claimAmountOfSROOTxToken;
                    
                    status = true;
                  
                }
            }
            //   require(IERC20Upgradeable(SROOTxTokenAddress).balanceOf(address(this)) >= finalOfSROOTxToken, "staking pool has insufficient funds");
            //   IERC20Upgradeable(SROOTxTokenAddress).transfer(msg.sender, finalOfSROOTxToken);
            //   for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
            //         stakes[msg.sender][i].claimedDate = block.timestamp;
            //   }
        }
        else {
            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                    finalOfSROOTxToken = finalOfSROOTxToken.add(200*(10**18));
                     status = true;
                }
            }   
        }


             require(IERC20Upgradeable(SROOTxTokenAddress).balanceOf(address(this)) >= finalOfSROOTxToken, "staking pool has insufficient funds");
              IERC20Upgradeable(SROOTxTokenAddress).transfer(_addr, finalOfSROOTxToken);
              if(status){
                for(uint256 i = 0; i < stakes[_addr].length; i ++){
                    stakes[_addr][i].claimedDate_SROOT = block.timestamp;
                }
              }
    }

    function _claimOfWETH(address _addr) internal {
        uint256 finalOfWETH = 0;
        bool status = false;
     
        (uint256 sumofgenesisbear,) = getGenesisBear(_addr);
         if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                    finalOfWETH = finalOfWETH.add(200*(10**18) * dd);
                    status = true;

                }
            }
                for(uint256 i = 0; i < stakes[_addr].length; i ++){
                    if(!isGenesisBear(stakes[_addr][i].nft_id)) continue;
                   
                    
                    if(calDay(stakes[_addr][i].claimedDate_WETH) <= 3)
                        continue;

                    uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                    uint256 _amountIn = dd * MaxSROOTXrate / 2 ;
                 
                    finalOfWETH = finalOfWETH.add(_amountIn);

                    status = true;
             
                    
                //    stakes[msg.sender][i].claimedDate = block.timestamp;
                }

            // IERC20Upgradeable(SROOTxTokenAddress).approve(UNISWAP_V2_ROUTER, finalOfWETH);

            // address[] memory path;
        
            // path = new address[](2);
            // path[0] = SROOTxTokenAddress;
            // path[1] = WETH;
        
            // IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            //     finalOfWETH,
            //     0,
            //     path,
            //     msg.sender,
            //     block.timestamp
            // );
        }

        else {

            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                    finalOfWETH = finalOfWETH.add(200*(10**18) * dd);
                     status = true;
                }
            }  

        }
        if(finalOfWETH != 0){
            IERC20Upgradeable(SROOTxTokenAddress).approve(UNISWAP_V2_ROUTER, finalOfWETH);

            address[] memory path;
        
            path = new address[](2);
            path[0] = SROOTxTokenAddress;
            path[1] = WETH;
        
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
                finalOfWETH,
                0,
                path,
                _addr,
                block.timestamp
            );
            if(status){
                for(uint256 i = 0; i < stakes[_addr].length; i ++){
                    stakes[_addr][i].claimedDate_WETH = block.timestamp;
                }
            }
        }
            
    }


    function claimOfROOTxToken() external isOnlyStaker returns(uint256, bool){
        uint256 finalOfROOTxToken = 0;
        bool status = false;
        bool flag;
        (uint256 sumofgenesisbear,) = getGenesisBear(msg.sender);
        if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[msg.sender].length; i++) {
                uint256 temp = calDay(stakes[msg.sender][i].claimedDate_ROOTX);
                if(isGenesisBear(stakes[msg.sender][i].nft_id) &&  temp < 1){
                    flag = false;
                }
            }
            if(flag && stakes[msg.sender].length != 0){
                finalOfROOTxToken = 10;
                 status = true;
            }
            // require(IERC20Upgradeable(ROOTxTodress).balanceOf(address(this)) >= finalOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
            // IERC20Upgradeable(ROOTxTokenAddress).transfer(msg.sender, finalOfROOTxToken * (10 ** 18));
           
        }
        else {
            for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
                if(isGenesisBear(stakes[msg.sender][i].nft_id) ) {
                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_ROOTX);
                    finalOfROOTxToken = finalOfROOTxToken.add(dd*10);
                     status = true;
                    // require(IERC20Upgradeable(ROOTxTokenAddress).balanceOf(address(this)) >= claimAmountOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
                    // IERC20Upgradeable(ROOTxTokenAddress).transfer(msg.sender, claimAmountOfROOTxToken * (10 ** 18));
                    // stakes[msg.sender][i].claimedDate = block.timestamp;
                }
            }
           
        }

         require(IERC20Upgradeable(ROOTxTokenAddress).balanceOf(address(this)) >= finalOfROOTxToken * (10 ** 18), "staking pool has insufficient funds");
         IERC20Upgradeable(ROOTxTokenAddress).transfer(msg.sender, finalOfROOTxToken * (10 ** 18));

         for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
             stakes[msg.sender][i].claimedDate_ROOTX = block.timestamp;
         }
        return (finalOfROOTxToken, status);
    }

    function claimOfSROOTxToken() external isOnlyStaker returns(uint256, bool){
        uint256 finalOfSROOTxToken = 0;
      
        bool status = false;
        (uint256 sumofgenesisbear,) = getGenesisBear(msg.sender);
        bool flag = true;
        if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[msg.sender].length; i++){
                if(isSpecialBear(stakes[msg.sender][i].nft_id)){
                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_SROOT);
                    finalOfSROOTxToken = finalOfSROOTxToken.add(200*(10**18) * dd);
                     status = true;
                }
            }
            if(flag && stakes[msg.sender].length != 0){
                for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
                    if(!isGenesisBear(stakes[msg.sender][i].nft_id)) continue;

                    if(calDay(stakes[msg.sender][i].claimedDate_SROOT) <= 3)
                        continue;
                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_SROOT);
                    finalOfSROOTxToken = finalOfSROOTxToken.add( dd *  MaxSROOTXrate / 2);
                    // finalOfSROOTxToken += claimAmountOfSROOTxToken;
                    
                    status = true;
                  
                }
            }
            //   require(IERC20Upgradeable(SROOTxTokenAddress).balanceOf(address(this)) >= finalOfSROOTxToken, "staking pool has insufficient funds");
            //   IERC20Upgradeable(SROOTxTokenAddress).transfer(msg.sender, finalOfSROOTxToken);
            //   for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
            //         stakes[msg.sender][i].claimedDate = block.timestamp;
            //   }
        }
        else {
            for(uint256 i = 0; i < stakes[msg.sender].length; i++){
                if(isSpecialBear(stakes[msg.sender][i].nft_id)){
                    finalOfSROOTxToken = finalOfSROOTxToken.add(200*(10**18));
                     status = true;
                }
            }   
        }


             require(IERC20Upgradeable(SROOTxTokenAddress).balanceOf(address(this)) >= finalOfSROOTxToken, "staking pool has insufficient funds");
              IERC20Upgradeable(SROOTxTokenAddress).transfer(msg.sender, finalOfSROOTxToken);
              if(status){
                for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
                    stakes[msg.sender][i].claimedDate_SROOT = block.timestamp;
                }
              }
        return (finalOfSROOTxToken, status);
    }

    function claimOfWETH() external isOnlyStaker returns(uint256, bool){
        uint256 finalOfWETH = 0;
        bool status = false;
     
        (uint256 sumofgenesisbear,) = getGenesisBear(msg.sender);
         if(sumofgenesisbear >= 5){
            for(uint256 i = 0; i < stakes[msg.sender].length; i++){
                if(isSpecialBear(stakes[msg.sender][i].nft_id)){
                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_WETH);
                    finalOfWETH = finalOfWETH.add(200*(10**18) * dd);
                    status = true;

                }
            }
                for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
                    if(!isGenesisBear(stakes[msg.sender][i].nft_id)) continue;
                   
                    
                    if(calDay(stakes[msg.sender][i].claimedDate_WETH) <= 3)
                        continue;

                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_WETH);
                    uint256 _amountIn = dd * MaxSROOTXrate / 2 ;
                 
                    finalOfWETH = finalOfWETH.add(_amountIn);

                    status = true;
             
                    
            
                }
        }

        else {

            for(uint256 i = 0; i < stakes[msg.sender].length; i++){
                if(isSpecialBear(stakes[msg.sender][i].nft_id)){
                    uint256 dd = calDay(stakes[msg.sender][i].claimedDate_WETH);
                    finalOfWETH = finalOfWETH.add(200*(10**18) * dd);
                     status = true;
                }
            }  

        }
        if(finalOfWETH != 0) {
            IERC20Upgradeable(SROOTxTokenAddress).approve(UNISWAP_V2_ROUTER, finalOfWETH);

            address[] memory path;
        
            path = new address[](2);
            path[0] = SROOTxTokenAddress;
            path[1] = WETH;
        
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
                finalOfWETH,
                0,
                path,
                msg.sender,
                block.timestamp
            );

            if(status){
                for(uint256 i = 0; i < stakes[msg.sender].length; i ++){
                    stakes[msg.sender][i].claimedDate_WETH = block.timestamp;
                }
            }
        }
           
        return (finalOfWETH, status);
    }

    function claimOf(address _addr) public view returns(uint256, uint256,uint256) {
        uint256 claimAmountOfROOTxToken = 0;
        uint256 claimAmountOfSROOTxToken = 0;
        uint256 claimAmountOfWETH = 0;
        (uint256 sumofgenesisbear,) = getGenesisBear(_addr);
        if(sumofgenesisbear >= 5){
///ROOTX
            bool flag = true;
            for(uint256 i = 0; i < stakes[_addr].length; i++) {
                uint256 temp = calDay(stakes[_addr][i].claimedDate_ROOTX);
                if(isGenesisBear(stakes[_addr][i].nft_id) &&  temp < 1){
                    flag = false;
                }
            }
            if(flag && stakes[_addr].length != 0){
                claimAmountOfROOTxToken = 10;
            }
///SROOT 
            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                    claimAmountOfSROOTxToken = claimAmountOfSROOTxToken.add(200*(10**18) * dd);
                }
            }

            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isGenesisBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                    claimAmountOfSROOTxToken = claimAmountOfSROOTxToken.add( dd * MaxSROOTXrate / 2);
                }
                // uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                // claimAmountOfSROOTxToken = claimAmountOfSROOTxToken.add( dd * MaxSROOTXrate / 2);
                // uint256 _amountIn = claimAmountOfSROOTxToken;
                // if(_amountIn == 0) continue;
                // uint256 _amountOutMin = getAmountOutMin(SROOTxTokenAddress, WETH, _amountIn);
                // claimAmountOfWETH = claimAmountOfWETH.add( _amountOutMin);
            }
///WETH
            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isSpecialBear(stakes[_addr][i].nft_id)){
                     uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                    claimAmountOfWETH = claimAmountOfWETH.add(200*(10**18) * dd);
                }
            }

            for(uint256 i = 0; i < stakes[_addr].length; i++){
                if(isGenesisBear(stakes[_addr][i].nft_id)){
                    uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                    claimAmountOfWETH = claimAmountOfWETH.add( dd * MaxSROOTXrate / 2);
                }
            if(claimAmountOfWETH != 0){
             claimAmountOfWETH =  getAmountOutMin(SROOTxTokenAddress, WETH, claimAmountOfWETH);

            }

                // uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                // claimAmountOfSROOTxToken = claimAmountOfSROOTxToken.add( dd * MaxSROOTXrate / 2);
                // uint256 _amountIn = claimAmountOfSROOTxToken;
                // if(_amountIn == 0) continue;
                // uint256 _amountOutMin = getAmountOutMin(SROOTxTokenAddress, WETH, _amountIn);
                // claimAmountOfWETH = claimAmountOfWETH.add( _amountOutMin);
            }
        }
        else {
        ///SROOT
              for(uint256 i = 0; i < stakes[_addr].length; i++){
                    if(isSpecialBear(stakes[_addr][i].nft_id)){
                        uint256 dd = calDay(stakes[_addr][i].claimedDate_SROOT);
                        claimAmountOfSROOTxToken = claimAmountOfSROOTxToken.add(200*(10**18) * dd);
                    }
                }
        ///WETH
                for(uint256 i = 0; i < stakes[_addr].length; i++){
                    if(isSpecialBear(stakes[_addr][i].nft_id)){
                        uint256 dd = calDay(stakes[_addr][i].claimedDate_WETH);
                        claimAmountOfWETH = claimAmountOfWETH.add(200*(10**18) * dd);
                    }
                

                }
                if(claimAmountOfWETH != 0) {
                    claimAmountOfWETH =  getAmountOutMin(SROOTxTokenAddress, WETH, claimAmountOfWETH);
                }

        ///ROOTX
                for(uint256 i = 0; i < stakes[_addr].length; i++){
                    if(isGenesisBear(stakes[_addr][i].nft_id) ) {
                        uint256 dd = calDay(stakes[_addr][i].claimedDate_ROOTX);
                        claimAmountOfROOTxToken = claimAmountOfROOTxToken.add(dd * 10);
                    }
                }
        }
        return (claimAmountOfROOTxToken * (10 ** 18), claimAmountOfSROOTxToken , claimAmountOfWETH);
    }

    function calDay(uint256 ts) internal view returns(uint256) {
        return (block.timestamp - ts) / DURATION_FOR_REWARDS;
    }

    function removeNFT(address _addr, uint256 _id) internal {
        for(uint256 i = 0 ; i < stakes[_addr].length; i++)
        {
            if(stakes[_addr][i].nft_id == _id)
            {
                stakes[_addr][i] = stakes[_addr][stakes[_addr].length - 1];
                stakes[_addr].pop();
            }
        }
        if(stakes[_addr].length <= 0)
        {
            delete stakes[_addr];
            removeStaker(_addr);
        }
    }

    function isClaimable(uint256 _id) internal pure returns(bool) {
        bool returned;
        if(_id < 0) returned = false;
        if(_id >=3700){
            if(_id >= 10000000000000 && _id <= 10000000000005) returned = true;
            else returned = false;
        }
        else returned = true;
        
        return returned;
    }

    function isGenesisBear(uint256 _id) internal pure returns(bool) {
        bool returned;
        if(_id >= 0 && _id <= 3700){
            returned = true;
        }
        else {
            returned = false;
        }
        return returned;
    }

    function isSpecialBear(uint256 _id) internal pure returns(bool) {
        bool returned;
        if(_id >= 1000000000000 && _id <= 1000000000005){
            returned = true;
        }
        return returned;
    }

     function getSpecialBear(address _addr) public view returns(uint256, uint256[] memory) {
        uint256 sumofspecialbear = 0;
        
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(isSpecialBear(stakes[_addr][i].nft_id)){
                sumofspecialbear += 1;
            }
        }
        uint256[] memory nft_ids = new uint256[](sumofspecialbear);
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(isSpecialBear(stakes[_addr][i].nft_id)){ 
                nft_ids[i] = (stakes[_addr][i].nft_id);
            }
        }
        return (sumofspecialbear, nft_ids);
    }

    function getGenesisBear(address _addr) public view returns(uint256, uint256[] memory) {
        uint256 sumofgenesisbear = 0;
        
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(isGenesisBear(stakes[_addr][i].nft_id)){
                sumofgenesisbear += 1;
            }
        }
        uint256[] memory nft_ids = new uint256[](sumofgenesisbear);
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(isGenesisBear(stakes[_addr][i].nft_id)){ 
                nft_ids[i] = (stakes[_addr][i].nft_id);
            }
        }
        return (sumofgenesisbear, nft_ids);
    }

    function isMiniBear(uint256 _id) internal pure returns(bool) {
        if(_id < 10000000000000 ) return false;
        if(_id > 10000000005299 ) return false;
        else return true;
    }

     function getMiniBear(address _addr) public view returns(uint256, uint256[] memory) {
        uint256 sumofminibear = 0;
        
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(!isGenesisBear(stakes[_addr][i].nft_id)){
                sumofminibear += 1;
            }
        }
        uint256[] memory nft_ids = new uint256[](sumofminibear);
        for(uint256 i = 0; i < stakes[_addr].length; i++) {
            if(!isGenesisBear(stakes[_addr][i].nft_id)){
                nft_ids[i] = (stakes[_addr][i].nft_id);
            }
        }
        return (sumofminibear, nft_ids);
    }


    modifier isOnlyStaker() {
        (bool _isStaker, ) = isStaker(msg.sender);
        require(_isStaker, "You are not staker");
        _;
    }

    modifier isOnlyGenesisBear(uint256 _id) {
        require(_id >= 0, "NFT id should be greater than 0");
        require(_id <= 3699, "NFT id should be smaller than 3699");
        _;
    }

    modifier isOnlyMiniBear(uint256 _id) {
        require(_id >= 10000000000000, "NFT id should be greate than 10000000000000" );
        require(_id <= 10000000005299, "NFT id should be smaller than 10000000005299");
        _;
    }

    modifier isOwnerOf(uint256 _id, address _addr){
        bool flag = false;
        for(uint256 i = 0 ; i < stakes[_addr].length; i++)
        {
            if(stakes[_addr][i].nft_id == _id) flag = true;
        }
        if(flag) _; 
    }

    function isVested(address _addr) public view returns(bool) {
        bool status = true;
        
        for(uint256 i = 0; i < stakes[_addr].length; i ++){
            uint256 dd = calDay(stakes[_addr][i].stakedDate);
            if(dd <= 3) continue;
            
            status=false;
        }
    
        return status;
    }
}