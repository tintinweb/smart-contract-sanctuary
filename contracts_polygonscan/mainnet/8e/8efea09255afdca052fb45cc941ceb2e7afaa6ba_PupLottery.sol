/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: Lottery.sol



// @title: PolyPup Punks NFT
// @author: Neothon

//	.______     ______    __      ____    ____ .______    __    __  .______      .______    __    __  .__   __.  __  ___      _______.
//	|   _  \   /  __  \  |  |     \   \  /   / |   _  \  |  |  |  | |   _  \     |   _  \  |  |  |  | |  \ |  | |  |/  /     /       |
//	|  |_)  | |  |  |  | |  |      \   \/   /  |  |_)  | |  |  |  | |  |_)  |    |  |_)  | |  |  |  | |   \|  | |  '  /     |   (----`
//	|   ___/  |  |  |  | |  |       \_    _/   |   ___/  |  |  |  | |   ___/     |   ___/  |  |  |  | |  . `  | |    <       \   \
//	|  |      |  `--'  | |  `----.    |  |     |  |      |  `--'  | |  |         |  |      |  `--'  | |  |\   | |  .  \  .----)   |
//	| _|       \______/  |_______|    |__|     | _|       \______/  | _|         | _|       \______/  |__| \__| |__|\__\ |_______/

pragma solidity ^0.8.4;








interface PupPunks {
	function ownerOf(uint256) external view returns (address);

	function walletOfOwner(address) external view returns (uint256[] memory);
}

contract PupLottery is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	IERC20 public collarToken;

	address public collarAddress = 0x8DF26a1BD9bD98e2eC506fc9d8009954716A05DC;
	address public deadAddress = 0x000000000000000000000000000000000000dEaD;
	address public puppunksAddress = 0xf09e7Af8b380cD01BD0d009F83a6b668A47742ec;
	address public constant pairAddress =
		0x853Ee4b2A13f8a742d64C8F088bE7bA2131f670d; // USDC/WETH QuickSwap Pair Address

	uint256 public constant LEADERBOARD_LIMIT = 10;
	bool private isContestOn = false;
	uint256 public deadline;
	uint256 public burnPercentage = 20;
	uint256 public entryFees;

	struct Player {
		uint256 pupId;
		address owner;
	}

	uint256 internal nonce = 0;
	Player[] private winners;
	uint256[] internal indices;

	// Arrays
	Player[] private players;

	// Mappings for lottery
	mapping(uint256 => address) inLottery;
	mapping(uint256 => bool) alreadyWon;

	/**
	 * Events Emitted
	 */

	event PupPunkAddressUpdated();
	event CollarAddressUpdated();
	event BurnPercentageUpdated();
	event FeesUpdated(uint256 _newFees);
	event PatPup(address indexed user, uint256 indexed pupPunkId, uint256 count);
	event ContestBegins(uint256 deadline);
	event ContestEnded();
	event ContestDataReseted();
	event LeaderboardUpdated(uint256 _pupId);
	event ContestLeaderboardUpdated(uint256 _pupId);
	event WinnerAlotted(address indexed _winner, uint256 _prize, uint256 _pupId);
	event PlayerEnrolled(
		address indexed _player,
		uint256 indexed _id,
		uint256 _fees
	);
	event FeesPartlyBurned(uint256 _burnAmount);
	event Received(address _sender, uint256 _amount);

	constructor(
		address _collarAddress,
		address _pupPunksAddress,
		uint256 _fees
	) {
		collarToken = IERC20(_collarAddress);
		puppunksAddress = _pupPunksAddress;
		entryFees = _fees;
	}

	/**
	 * Update Collar Contract Address
	 */
	function updatePupPunksAddress(address contractAddress) external onlyOwner {
		puppunksAddress = contractAddress;
		emit PupPunkAddressUpdated();
	}

	/**
	 * Update Collar Contract Address
	 */
	function updateCollarAddress(address _collarAdr) external onlyOwner {
		collarAddress = _collarAdr;
		emit PupPunkAddressUpdated();
	}

	/**
	 * Update Burn Percentage
	 */
	function updateBurnPercentage(uint256 _burnRate) external onlyOwner {
		burnPercentage = _burnRate;
		emit BurnPercentageUpdated();
	}

	/**
	 * Update PupPunks Contract Address
	 */
	function updateFees(uint256 _fees) external onlyOwner {
		entryFees = _fees;
		emit FeesUpdated(_fees);
	}

	/**
	 * Contest Begin only owner allowed
	 */
	function contestStart(uint256 numberOfDays) external onlyOwner {
		require(isContestOn == false, 'Contest is already on!');
		isContestOn = true;
		deadline = block.timestamp + (numberOfDays * 1 minutes);
		emit ContestBegins(deadline);
	}

	/**
	 * Only owner can end the contest at any time.
	 * If the contest has already not ended, add the winning pup from the leaderboard
	 */
	function endContest() external onlyOwner {
		if (isContestOn) {
			isContestOn = false;
			deadline = 0;
			_setWinnerPup();
			_resetContestData(); // resetting all contest data as contest ends
		}
		emit ContestEnded();
	}

	/**
	 * Reset data structures use for contest
	 */
	function _resetContestData() internal {
		// clear players addresses
		// TODO reset players array
		// players = new Player[]();

		// clear inLottery mapping
		for (uint256 i = 0; i < players.length; i++) {
			delete inLottery[players[i].pupId];
			delete players[i];
		}
		delete players;
		emit ContestDataReseted();
	}

	/**
	 * Set Winner
	 */
	function _setWinnerPup() internal {
		require(block.timestamp > deadline, "Contest hasn't ended yet");

		/**
		 *  Alotting new winner from the top of the leaderboard
		 *  No duplicate winner allowed.
		 *  Owner address should be present in active player contest mapping
		 *  Owner address should not be empty
		 *  Winner choosen randomly.
		 *  Atleast one player should be in the lottery. Otherwise it doesn't set winner
		 */
		if (players.length > 0) {
			uint256 winnerId = _randomIndex();

			// Pushing winner in winner array
			winners.push(Player(players[winnerId].pupId, players[winnerId].owner));
			alreadyWon[players[winnerId].pupId] = true;

			// Transfering reward to winner
			collarToken.safeTransfer(
				players[winnerId].owner,
				collarToken.balanceOf(address(this))
			);

			emit WinnerAlotted(
				players[winnerId].owner,
				collarToken.balanceOf(address(this)),
				players[winnerId].pupId
			);
		}
	}

	/**
	 * Returns a random index within the unminited token id range
	 */
	function _randomIndex() internal returns (uint256) {
		uint256 totalSize = players.length;
		//Fetching current balances of USDC/WETH QS Pair for increasing Randomness Entropy
		(uint256 balance1, uint256 balance2) = getCurrentBalanceQSPair();
		uint256 value = uint256(
			keccak256(
				abi.encodePacked(
					nonce,
					msg.sender,
					balance1,
					balance2,
					block.difficulty,
					block.timestamp
				)
			)
		) % totalSize;
		nonce++;
		return value;
	}

	/**
	 * @dev Getting current reserves of USDC and WETH pairs on QuickSwap
	 */
	function getCurrentBalanceQSPair() public view returns (uint256, uint256) {
		IUniswapV2Pair pair = IUniswapV2Pair(
			pairAddress // Address of USDC/WETH Pair on QuickSwap
		);
		(uint256 res0, uint256 res1, ) = pair.getReserves();
		return (res0, res1);
	}

	/**
	 *  Get Active Players
	 */
	// TODO: Fetch pups of players and only return the ones who have not won before
	function getParticipants() public view returns (Player[] memory) {
		return players;
	}

	/**
	 *  Get Active Players Count
	 */
	// TODO: Fetch pups of players and only return the ones who have not won before
	function getParticipantsCount() public view returns (uint256) {
		return players.length;
	}

	/**
	 *  Get Active Players
	 */
	// TODO: Fetch pups of players and only return the ones who have not won before
	function getPupsInLottery() public view returns (Player[] memory) {
		return players;
	}

	/**
	 * Returns the winners list. In oldest to newest order.
	 */
	function getWinnerList() public view returns (Player[] memory) {
		return winners;
	}

	/**
	 * Retruns the deadline of the contest.
	 */
	function getDeadline() public view returns (uint256 endtime) {
		return deadline;
	}

	/**
	 * Is user in contest
	 */
	function isAContestParticipant(uint256 _id) public view returns (bool) {
		return inLottery[_id] == msg.sender;
	}

	/**
	 * Return if contest is active or not
	 */
	function isContestActive() public view returns (bool) {
		return block.timestamp <= deadline;
	}

	/**
	 * Checking if a owner owns a puppunk
	 */
	function ownsAPupPunk() internal view virtual returns (bool) {
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can pat and not a contract

		PupPunks pupContract = PupPunks(puppunksAddress);
		bool _hasPups = false;

		try pupContract.walletOfOwner(msg.sender) returns (uint256[] memory pups) {
			if (pups.length > 0) _hasPups = true;
		} catch Error(
			string memory /*reason*/
		) {
			// This is executed in case
			// revert was called inside getData
			// and a reason string was provided.
			_hasPups = false;
		} catch (
			bytes memory /*lowLevelData*/
		) {
			// This is executed in case revert() was used
			// or there was a failing assertion, division
			// by zero, etc. inside getData.
			_hasPups = false;
		}

		return _hasPups;
	}

	/**
	 * Logic for fees and rewards starts here.
	 */

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function getBalance() public view returns (uint256) {
		uint256 bal = collarToken.balanceOf(address(this));
		return bal; // returns the contract balance
	}

	function deposit(uint256 _amount, uint256 _id) external {
		if (msg.sender == owner()) {
			collarToken.safeTransferFrom(msg.sender, address(this), _amount);
		} else {
			_processDeposit(_amount, _id);
		}
	}

	function isOwnerOfPup(uint256 _id) internal view returns (bool) {
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can pat and not a contract

		PupPunks pupContract = PupPunks(puppunksAddress);
		bool _isOwner = false;

		try pupContract.ownerOf(_id) returns (address _owner) {
			if (_owner == msg.sender) _isOwner = true;
		} catch Error(
			string memory /*reason*/
		) {
			// This is executed in case
			// revert was called inside getData
			// and a reason string was provided.
			_isOwner = false;
		} catch (
			bytes memory /*lowLevelData*/
		) {
			// This is executed in case revert() was used
			// or there was a failing assertion, division
			// by zero, etc. inside getData.
			_isOwner = false;
		}

		return _isOwner;
	}

	/**
	 *	@dev Accepting collar as contest fees
	 *	burning 20% of collar and registering user
	 *  as part of contest
	 */

	function _processDeposit(uint256 _amount, uint256 _id) internal {
		require(
			_amount >= entryFees,
			'Amount deposited should be equal or more than the minimum fees'
		);
		require(block.timestamp <= deadline, 'Contest should be active');
		require(msg.sender != owner(), 'Nope, admins cannot participate :(');
		require(isOwnerOfPup(_id), 'You do not own this pup');
		require(!isAContestParticipant(_id), 'Pup already in lottery! Get more pups');
		require(
			!alreadyWon[_id],
			'Sorry, this pup has already won the lottery once!'
		);

		// Burning 20% of amount paid
		uint256 burnAmount = (_amount * burnPercentage) / 100;
		uint256 depositAmount = _amount - burnAmount;
		collarToken.safeTransferFrom(msg.sender, deadAddress, burnAmount);
		collarToken.safeTransferFrom(msg.sender, address(this), depositAmount);

		// Registering user address in contest
		players.push(Player(_id, msg.sender));
		inLottery[_id] = msg.sender;

		emit FeesPartlyBurned(burnAmount);
		emit PlayerEnrolled(msg.sender, _id, depositAmount);
	}
}