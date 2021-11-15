// File: contracts/libraries/TokenList.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract TokenList {

    // "Listed" (hard-coded) tokens
    address private constant KingAddr = 0x5a731151d6510Eb475cc7a0072200cFfC9a3bFe5;
    address private constant KingNftAddr = 0x4c9c971fbEFc93E0900988383DC050632dEeC71E;
    address private constant QueenNftAddr = 0x3068b3313281f63536042D24562896d080844c95;
    address private constant KnightNftAddr = 0xF85C874eA05E2225982b48c93A7C7F701065D91e;
    address private constant KingWerewolfNftAddr = 0x39C8788B19b0e3CeFb3D2f38c9063b03EB1E2A5a;
    address private constant QueenVampzNftAddr = 0x440116abD7338D9ccfdc8b9b034F5D726f615f6d;
    address private constant KnightMummyNftAddr = 0x91cC2cf7B0BD7ad99C0D8FA4CdfC93C15381fb2d;
    //
    address private constant UsdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant UsdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant DaiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WbtcAddr = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant NewKingAddr = 0xd2057d71fE3F5b0dc1E3e7722940E1908Fc72078;

    // Index of _extraTokens[0] + 1
    uint256 private constant extraTokensStartId = 33;

    enum TokenType {unknown, Erc20, Erc721, Erc1155}

    struct Token {
        address addr;
        TokenType _type;
    }

    // Extra tokens (addition to the hard-coded tokens list)
    Token[] private _extraTokens;

    function _listedToken(
        uint8 tokenId
    ) internal pure virtual returns(address, TokenType) {
        if (tokenId == 1) return (KingAddr, TokenType.Erc20);
        if (tokenId == 2) return (UsdtAddr, TokenType.Erc20);
        if (tokenId == 3) return (UsdcAddr, TokenType.Erc20);
        if (tokenId == 4) return (DaiAddr, TokenType.Erc20);
        if (tokenId == 5) return (WethAddr, TokenType.Erc20);
        if (tokenId == 6) return (WbtcAddr, TokenType.Erc20);
        if (tokenId == 7) return (NewKingAddr, TokenType.Erc20);

        if (tokenId == 16) return (KingNftAddr, TokenType.Erc721);
        if (tokenId == 17) return (QueenNftAddr, TokenType.Erc721);
        if (tokenId == 18) return (KnightNftAddr, TokenType.Erc721);
        if (tokenId == 19) return (KingWerewolfNftAddr, TokenType.Erc721);
        if (tokenId == 20) return (QueenVampzNftAddr, TokenType.Erc721);
        if (tokenId == 21) return (KnightMummyNftAddr, TokenType.Erc721);

        return (address(0), TokenType.unknown);
    }

    function _tokenAddr(uint8 tokenId) internal view returns(address) {
        (address addr, ) = _token(tokenId);
        return addr;
    }

    function _token(
        uint8 tokenId
    ) internal view returns(address, TokenType) {
        if (tokenId < extraTokensStartId) return _listedToken(tokenId);

        uint256 i = tokenId - extraTokensStartId;
        Token memory token = _extraTokens[i];
        return (token.addr, token._type);
    }

    function _addTokens(
        address[] memory addresses,
        TokenType[] memory types
    ) internal {
        require(
            addresses.length + _extraTokens.length + extraTokensStartId <= 256,
            "TokList:TOO_MANY_TOKENS"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "TokList:INVALID_TOKEN_ADDRESS");
            require(types[i] != TokenType.unknown, "TokList:INVALID_TOKEN_TYPE");
            _extraTokens.push(Token(addresses[i], types[i]));
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// License: MIT

pragma solidity ^0.6.0;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// License: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// License: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: @openzeppelin/contracts/introspection/IERC165.sol

// License: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// License: MIT

pragma solidity ^0.6.2;


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

// File: @openzeppelin/contracts/utils/Address.sol

// License: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// License: MIT

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// License: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts/KingDecks.sol











/**
 * It accepts deposits of a pre-defined ERC-20 token(s), the "deposit" token.
 * The deposit token will be repaid with another ERC-20 token, the "repay"
 * token (e.g. a stable-coin), at a pre-defined rate.
 *
 * On top of the deposit token, a particular NFT (ERC-721) instance may be
 * required to be deposited as well. If so, this exact NFT will be returned.
 *
 * Note the `treasury` account that borrows and repays tokens.
 */
contract KingDecks is Ownable, ReentrancyGuard, TokenList {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // On a deposit withdrawal, a user receives the "repay" token
    // (but not the originally deposited ERC-20 token).
    // The amount (in the  "repay" token units) to be repaid is:
    // `amountDue = Deposit.amount * TermSheet.rate/1e+6`                (1)

    // If interim withdrawals allowed, the amount which can not be withdrawn
    // before the deposit period ends is:
    // `minBalance = Deposit.amountDue * Deposit.lockedShare / 65535`    (2)
    //
    // (note: `TermSheet.earlyRepayableShare` defines `Deposit.lockedShare`)

    // Limit on the deposited ERC-20 token amount
    struct Limit {
        // Min token amount to deposit
        uint224 minAmount;
        // Max deposit amount multiplier, scaled by 1e+4
        // (no limit, if set to 0):
        // `maxAmount = minAmount * maxAmountFactor/1e4`
        uint32 maxAmountFactor;
    }

    // Terms of deposit(s)
    struct TermSheet {
        // Remaining number of deposits allowed under this term sheet
        // (if set to zero, deposits disabled; 255 - no limitations applied)
        uint8 availableQty;
        // ID of the ERC-20 token to deposit
        uint8 inTokenId;
        // ID of the ERC-721 token (contract) to deposit
        // (if set to 0, no ERC-721 token is required to be deposited)
        uint8 nfTokenId;
        // ID of the ERC-20 token to return instead of the deposited token
        uint8 outTokenId;
        // Maximum amount that may be withdrawn before the deposit period ends,
        // in 1/255 shares of the deposit amount.
        // The amount linearly increases from zero to this value with time.
        // (if set to zero, early withdrawals are disabled)
        uint8 earlyRepayableShare;
        // Fees on early withdrawal, in 1/255 shares of the amount withdrawn
        // (fees linearly decline to zero towards the repayment time)
        // (if set to zero, no fees charged)
        uint8 earlyWithdrawFees;
        // ID of the deposit amount limit (equals to: index in `_limits` + 1)
        // (if set to 0, no limitations on the amount applied)
        uint16 limitId;
        // Deposit period in hours
        uint16 depositHours;
        // Min time between interim (early) withdrawals
        // (if set to 0, no limits on interim withdrawal time)
        uint16 minInterimHours;
        // Rate to compute the "repay" amount, scaled by 1e+6 (see (1))
        uint64 rate;
        // Bit-mask for NFT IDs (in the range 1..64) allowed to deposit
        // (if set to 0, no limitations on NFT IDs applied)
        uint64 allowedNftNumBitMask;
    }

    // Parameters of a deposit
    struct Deposit {
        uint176 amountDue;      // Amount due, in "repay" token units
        uint32 maturityTime;    // Time the final withdrawal is allowed since
        uint32 lastWithdrawTime;// Time of the most recent interim withdrawal
        uint16 lockedShare;     // in 1/65535 shares of `amountDue` (see (2))
        // Note:
        // - the depositor account and the deposit ID linked via mappings
        // - other props (eg.: `termsId`) encoded within the ID of a deposit
    }

    // Deposits of a user
    struct UserDeposits {
        // Set of (unique) deposit IDs
        uint256[] ids;
        // Mapping from deposit ID to deposit data
        mapping(uint256 => Deposit) data;
    }

    // Number of deposits made so far
    uint32 public depositQty;

    // Account that controls the tokens deposited
    address public treasury;

    // Limits on "deposit" token amount
    Limit[] private _limits;

    // Info on each TermSheet
    TermSheet[] internal _termSheets;

    // Mappings from a "repay" token ID to the total amount due
    mapping(uint256 => uint256) public totalDue; // in "repay" token units

    // Mapping from user account to user deposits
    mapping(address => UserDeposits) internal _deposits;

    event NewDeposit(
        uint256 indexed inTokenId,
        uint256 indexed outTokenId,
        address indexed user,
        uint256 depositId,
        uint256 termsId,
        uint256 amount, // amount deposited (in deposit token units)
        uint256 amountDue, // amount to be returned (in "repay" token units)
        uint256 maturityTime // UNIX-time when the deposit is unlocked
    );

    // User withdraws the deposit
    event Withdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount // amount sent to user (in deposit token units)
    );

    event InterimWithdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount, // amount sent to user (in "repay" token units)
        uint256 fees // withheld fees (in "repay" token units)
    );

    // termsId is the index in the `_termSheets` array + 1
    event NewTermSheet(uint256 indexed termsId);
    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);

    constructor(address _treasury) public {
        _setTreasury(_treasury);
    }

    function depositIds(
        address user
    ) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserDeposits storage userDeposits = _deposits[user];
        return userDeposits.ids;
    }

    function depositData(
        address user,
        uint256 depositId
    ) external view returns(uint256 termsId, Deposit memory params) {
        params = _deposits[_nonZeroAddr(user)].data[depositId];
        termsId = 0;
        if (params.maturityTime !=0) {
            (termsId, , , ) = _decodeDepositId(depositId);
        }
    }

    function termSheet(
        uint256 termsId
    ) external view returns (TermSheet memory) {
        return _termSheets[_validTermsID(termsId) - 1];
    }

    function termSheetsNum() external view returns (uint256) {
        return _termSheets.length;
    }

    function allTermSheets() external view returns(TermSheet[] memory) {
        return _termSheets;
    }

    function depositLimit(
        uint256 limitId
    ) external view returns (Limit memory) {
        return _limits[_validLimitID(limitId) - 1];
    }

    function depositLimitsNum() external view returns (uint256) {
        return _limits.length;
    }

    function getTokenData(
        uint256 tokenId
    ) external view returns(address, TokenType) {
        return _token(uint8(tokenId));
    }

    function isAcceptableNft(
        uint256 termsId,
        address nftContract,
        uint256 nftId
    ) external view returns(bool) {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        if (tS.nfTokenId != 0 && _tokenAddr(tS.nfTokenId) == nftContract) {
            return _isAllowedNftId(nftId, tS.allowedNftNumBitMask);
        }
        return false;
    }

    function idsToBitmask(
        uint256[] memory ids
    ) pure external returns(uint256 bitmask) {
        bitmask = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(id != 0 && id <= 64, "KDecks:unsupported NFT ID");
            bitmask = bitmask | (id == 1 ? 1 : 2 << (id - 2));
        }
    }

    function computeEarlyWithdrawal(
        address user,
        uint256 depositId
    ) external view returns (uint256 amountToUser, uint256 fees) {
        Deposit memory _deposit = _deposits[user].data[depositId];
        require(_deposit.amountDue != 0, "KDecks:unknown or repaid deposit");

        (uint256 termsId, , , ) = _decodeDepositId(depositId);
        TermSheet memory tS = _termSheets[termsId - 1];

        (amountToUser, fees, ) = _computeEarlyWithdrawal(_deposit, tS, now);
    }

    function deposit(
        uint256 termsId,    // term sheet ID
        uint256 amount,     // amount in deposit token units
        uint256 nftId       // ID of the NFT instance (0 if no NFT required)
    ) public nonReentrant {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        require(tS.availableQty != 0, "KDecks:terms disabled or unknown");

        if (tS.availableQty != 255) {
            _termSheets[termsId - 1].availableQty = --tS.availableQty;
            if ( tS.availableQty == 0) emit TermsDisabled(termsId);
        }

        if (tS.limitId != 0) {
            Limit memory l = _limits[tS.limitId - 1];
            require(amount >= l.minAmount, "KDecks:too small deposit amount");
            if (l.maxAmountFactor != 0) {
                require(
                    amount <=
                        uint256(l.minAmount).mul(l.maxAmountFactor) / 1e4,
                    "KDecks:too big deposit amount"
                );
            }
        }

        uint256 serialNum = depositQty + 1;
        depositQty = uint32(serialNum); // overflow risk ignored

        uint256 depositId = _encodeDepositId(
            serialNum,
            termsId,
            tS.outTokenId,
            tS.nfTokenId,
            nftId
        );

        uint256 amountDue = amount.mul(tS.rate).div(1e6);
        require(amountDue < 2**178, "KDecks:O2");
        uint32 maturityTime = safe32(now.add(uint256(tS.depositHours) *3600));

        if (tS.nfTokenId == 0) {
            require(nftId == 0, "KDecks:unexpected non-zero nftId");
        } else {
            require(
                nftId < 2**16 &&
                _isAllowedNftId(nftId, tS.allowedNftNumBitMask),
                "KDecks:disallowed NFT instance"
            );
            IERC721(_tokenAddr(tS.nfTokenId))
                .safeTransferFrom(msg.sender, address(this), nftId, _NFT_PASS);
        }

        IERC20(_tokenAddr(tS.inTokenId))
            .safeTransferFrom(msg.sender, treasury, amount);

        // inverted and re-scaled from 255 to 65535
        uint256 lockedShare = uint(255 - tS.earlyRepayableShare) * 65535/255;
        _registerDeposit(
            _deposits[msg.sender],
            depositId,
            Deposit(
                uint176(amountDue),
                maturityTime,
                safe32(now),
                uint16(lockedShare)
            )
        );
        totalDue[tS.outTokenId] = totalDue[tS.outTokenId].add(amountDue);

        emit NewDeposit(
            tS.inTokenId,
            tS.outTokenId,
            msg.sender,
            depositId,
            termsId,
            amount,
            amountDue,
            maturityTime
        );
    }

    // Entirely withdraw the deposit (when the deposit period ends)
    function withdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, false);
    }

    // Early withdrawal of the unlocked "repay" token amount (beware of fees!!)
    function interimWithdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, true);
    }

    function addTerms(TermSheet[] memory termSheets) public onlyOwner {
        for (uint256 i = 0; i < termSheets.length; i++) {
            _addTermSheet(termSheets[i]);
        }
    }

    function updateAvailableQty(
        uint256 termsId,
        uint256 newQty
    ) external onlyOwner {
        require(newQty <= 255, "KDecks:INVALID_availableQty");
        _termSheets[_validTermsID(termsId) - 1].availableQty = uint8(newQty);
        if (newQty == 0) {
            emit TermsDisabled(termsId);
        } else {
            emit TermsEnabled(termsId);
        }
    }

    function addLimits(Limit[] memory limits) public onlyOwner {
        // Risk of `limitId` (16 bits) overflow ignored
        for (uint256 i = 0; i < limits.length; i++) {
            _addLimit(limits[i]);
        }
    }

    function addTokens(
        address[] memory addresses,
        TokenType[] memory types
    ) external onlyOwner {
        _addTokens(addresses, types);
    }

    function setTreasury(address _treasury) public onlyOwner {
        _setTreasury(_treasury);
    }

    // Save occasional airdrop or mistakenly transferred tokens
    function transferFromContract(IERC20 token, uint256 amount, address to)
        external
        onlyOwner
    {
        _revertZeroAddress(to);
        token.safeTransfer(to, amount);
    }

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Equals to `bytes4(keccak256("KingDecks"))`
    bytes private constant _NFT_PASS = abi.encodePacked(bytes4(0xb0e68bdd));

    // Implementation of the ERC721 Receiver
    function onERC721Received(address, address, uint256, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        // Only accept transfers with _NFT_PASS passed as `data`
        return (data.length == 4 && data[0] == 0xb0 && data[3] == 0xdd)
        ? _ERC721_RECEIVED
        : bytes4(0);
    }

    // Other parameters, except `serialNum`, encoded for gas saving & UI sake
    function _encodeDepositId(
        uint256 serialNum,  // Incremental num, unique for every deposit
        uint256 termsId,    // ID of the applicable term sheet
        uint256 outTokenId, // ID of the ERC-20 token to repay deposit in
        uint256 nfTokenId,  // ID of the deposited ERC-721 token (contract)
        uint256 nftId       // ID of the deposited ERC-721 token instance
    ) internal pure returns (uint256 depositId) {
        depositId = nftId
        | (nfTokenId << 16)
        | (outTokenId << 24)
        | (termsId << 32)
        | (serialNum << 48);
    }

    function _decodeDepositId(uint256 depositId) internal pure
    returns (
        uint16 termsId,
        uint8 outTokenId,
        uint8 nfTokenId,
        uint16 nftId
    ) {
        termsId = uint16(depositId >> 32);
        outTokenId = uint8(depositId >> 24);
        nfTokenId = uint8(depositId >> 16);
        nftId = uint16(depositId);
    }

    function _withdraw(uint256 depositId, bool isInterim) internal {
        UserDeposits storage userDeposits = _deposits[msg.sender];
        Deposit memory _deposit = userDeposits.data[depositId];

        require(_deposit.amountDue != 0, "KDecks:unknown or repaid deposit");

        uint256 amountToUser;
        uint256 amountDue = 0;
        uint256 fees = 0;

        (
            uint16 termsId,
            uint8 outTokenId,
            uint8 nfTokenId,
            uint16 nftId
        ) = _decodeDepositId(depositId);

        if (isInterim) {
            TermSheet memory tS = _termSheets[termsId - 1];
            require(
                now >= uint256(_deposit.lastWithdrawTime) + tS.minInterimHours * 3600,
                "KDecks:withdrawal not yet allowed"
            );

            uint256 lockedShare;
            (amountToUser, fees, lockedShare) = _computeEarlyWithdrawal(
                _deposit,
                tS,
                now
            );
            amountDue = uint256(_deposit.amountDue).sub(amountToUser).sub(fees);
            _deposit.lockedShare = uint16(lockedShare);

            emit InterimWithdraw(msg.sender, depositId, amountToUser, fees);
        } else {
            require(now >= _deposit.maturityTime, "KDecks:deposit is locked");
            amountToUser = uint256(_deposit.amountDue);

            if (nftId != 0) {
                IERC721(_tokenAddr(nfTokenId)).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId,
                    _NFT_PASS
                );
            }
            _deregisterDeposit(userDeposits, depositId);

            emit Withdraw(msg.sender, depositId, amountToUser);
        }

        _deposit.lastWithdrawTime = safe32(now);
        _deposit.amountDue = uint176(amountDue);
        userDeposits.data[depositId] = _deposit;

        totalDue[outTokenId] = totalDue[outTokenId]
            .sub(amountToUser)
            .sub(fees);

        IERC20(_tokenAddr(outTokenId))
            .safeTransferFrom(treasury, msg.sender, amountToUser);
    }

    function _computeEarlyWithdrawal(
        Deposit memory d,
        TermSheet memory tS,
        uint256 timeNow
    ) internal pure returns (
        uint256 amountToUser,
        uint256 fees,
        uint256 newlockedShare
    ) {
        require(d.lockedShare != 65535, "KDecks:early withdrawals banned");

        amountToUser = 0;
        fees = 0;
        newlockedShare = 0;

        if (timeNow > d.lastWithdrawTime && timeNow < d.maturityTime) {
            // values are too small for overflow; if not, safemath used
            {
                uint256 timeSincePrev = timeNow - d.lastWithdrawTime;
                uint256 timeLeftPrev = d.maturityTime - d.lastWithdrawTime;
                uint256 repayable = uint256(d.amountDue)
                    .mul(65535 - d.lockedShare)
                    / 65535;

                amountToUser = repayable.mul(timeSincePrev).div(timeLeftPrev);
                newlockedShare = uint256(65535).sub(
                    repayable.sub(amountToUser)
                    .mul(65535)
                    .div(uint256(d.amountDue).sub(amountToUser))
                );
            }
            {
                uint256 term = uint256(tS.depositHours) * 3600; // can't be 0
                uint256 timeLeft = d.maturityTime - timeNow;
                fees = amountToUser
                    .mul(uint256(tS.earlyWithdrawFees))
                    .mul(timeLeft)
                    / term // fee rate linearly drops to 0
                    / 255; // `earlyWithdrawFees` scaled down

            }
            amountToUser = amountToUser.sub(fees); // fees withheld
        }
    }

    function _addTermSheet(TermSheet memory tS) internal {
        ( , TokenType _type) = _token(tS.inTokenId);
        require(_type == TokenType.Erc20, "KDecks:INVALID_DEPOSIT_TOKEN");
        ( , _type) = _token(tS.outTokenId);
        require(_type == TokenType.Erc20, "KDecks:INVALID_REPAY_TOKEN");
        if (tS.nfTokenId != 0) {
            (, _type) = _token(tS.nfTokenId);
            require(_type == TokenType.Erc721, "KDecks:INVALID_NFT_TOKEN");
        }
        if (tS.earlyRepayableShare == 0) {
            require(
                tS.earlyWithdrawFees == 0 && tS.minInterimHours == 0,
                "KDecks:INCONSISTENT_PARAMS"
            );
        }

        if (tS.limitId != 0) _validLimitID(tS.limitId);
        require(
             tS.depositHours != 0 && tS.rate != 0,
            "KDecks:INVALID_ZERO_PARAM"
        );

        // Risk of termsId (16 bits) overflow ignored
        _termSheets.push(tS);

        emit NewTermSheet(_termSheets.length);
        if (tS.availableQty != 0 ) emit TermsEnabled(_termSheets.length);
    }

    function _addLimit(Limit memory l) internal {
        require(l.minAmount != 0, "KDecks:INVALID_minAmount");
        _limits.push(l);
    }

    function _isAllowedNftId(
        uint256 nftId,
        uint256 allowedBitMask
    ) internal pure returns(bool) {
        if (allowedBitMask == 0) return true;
        uint256 idBitMask = nftId == 1 ? 1 : (2 << (nftId - 2));
        return (allowedBitMask & idBitMask) != 0;
    }

    function _registerDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId,
        Deposit memory _deposit
    ) internal {
        userDeposits.data[depositId] = _deposit;
        userDeposits.ids.push(depositId);
    }

    function _deregisterDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId
    ) internal {
        _removeArrayElement(userDeposits.ids, depositId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _setTreasury(address _treasury) internal {
        _revertZeroAddress(_treasury);
        treasury = _treasury;
    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "KDecks:ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(
            termsId != 0 && termsId <= _termSheets.length,
            "KDecks:INVALID_TERMS_ID"
        );
        return termsId;
    }

    function _validLimitID(uint256 limitId) private view returns (uint256) {
        require(
            limitId != 0 && limitId <= _limits.length,
            "KDecks:INVALID_LIMITS_ID"
        );
        return limitId;
    }

    function safe32(uint256 n) private pure returns (uint32) {
        require(n < 2**32, "KDecks:UNSAFE_UINT32");
        return uint32(n);
    }
}

