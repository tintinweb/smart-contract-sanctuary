/**
 *Submitted for verification at polygonscan.com on 2021-12-12
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: contracts/FashionShow.sol



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

interface Polypunk {
	function ownerOf(uint256) external view returns (address);

	function balanceOf(address) external view returns (uint256[] memory);
}

contract FashionShow is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	IERC20 public collarToken;

	address payable public developer;
	address public puppunksAddress = 0xe19F2634524dd1455193Cf21572A09F7157F431d;
	address public polypunkAddress = 0x320f537da591da33Dd1A04dCB062434e3D176D3E;

	uint256 public constant LEADERBOARD_LIMIT = 10;
	bool private isContestOn = false;
	bool private puppunkRequired = false;
	bool private puppunkExtraPat = true;
	uint256 public deadline;
	uint256 public devPercentage = 20;
	uint256 public collarFees;

	struct Person {
		uint256[] pattedPups;
		bool inContest;
	}

	struct Ranking {
		PupMeta pup;
		uint256 pupId;
	}
	struct Player {
		uint256 pupId;
		address owner;
	}

	struct PupMeta {
		uint256 pats;
		address owner;
		bool wonOnce;
	}

	Ranking[] private winners;

	// Mappings for pats
	mapping(address => Person) people;
	mapping(uint256 => PupMeta) pupPats;
	mapping(uint256 => Ranking) leaderboard;

	// Mappings for per id contestant
	mapping(uint256 => address) inContest;
	mapping(uint256 => bool) alreadyWon;

	// Arrays
	Player[] playerArray;
	uint256[] pupsInContest;

	/**
	 * Events Emitted
	 */

	event PupPunkAddressUpdated();
	event PolypunkAddressUpdated();
	event DevSharePercentageUpdated();
	event FeesUpdated(uint256 _newFees);
	event PatPup(address indexed user, uint256 indexed pupPunkId, uint256 count);
	event ContestBegins(uint256 deadline);
	event ContestEnded();
	event ContestDataReseted();
	event LeaderboardUpdated(uint256 _pupId);
	event WinnerAlotted(address indexed _winner, uint256 _prize, uint256 _pupId);
	event PlayerEnrolled(address indexed _player, uint256 _fees);
	event DevFees(uint256 _devShare);
	event Received(address _sender, uint256 _amount);
	event PuppunkRequiredToggleUpdated();
	event PuppunkExtraPatToggleUpdated();

	constructor(
		address _pupPunksAddress,
		address _polyPunkAddress,
		uint256 _fees,
		address _devAddress
	) {
		puppunksAddress = _pupPunksAddress;
		polypunkAddress = _polyPunkAddress;
		collarFees = _fees;
		developer = payable(_devAddress);
	}

	/**
	 * Update PupPunk Contract Address
	 */
	function updatePupPunksAddress(address contractAddress) external onlyOwner {
		puppunksAddress = contractAddress;
		emit PupPunkAddressUpdated();
	}

	/**
	 * Update PolyPunk Contract Address
	 */
	function updatePolypunkAddress(address contractAddress) external onlyOwner {
		polypunkAddress = contractAddress;
		emit PupPunkAddressUpdated();
	}

	/**
	 * Update Pup Benefit
	 */
	function updatePuppunkRequired(bool status) external onlyOwner {
		puppunkRequired = status;
		emit PuppunkRequiredToggleUpdated();
	}

	/**
	 * Update Pup extra pat
	 */
	function updatePuppunkExtraPat(bool status) external onlyOwner {
		puppunkExtraPat = status;
		emit PuppunkExtraPatToggleUpdated();
	}

	/**
	 * Update Burn Percentage
	 */
	function updateDevShare(uint256 _newDevPercentage) external onlyOwner {
		devPercentage = _newDevPercentage;
		emit DevSharePercentageUpdated();
	}

	/**
	 * Update PupPunks Contract Address
	 */
	function updateFees(uint256 _fees) external onlyOwner {
		collarFees = _fees;
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
		// clear players mapping
		for (uint256 i = 0; i < playerArray.length; i++) {
			delete inContest[playerArray[i].pupId];
			delete people[playerArray[i].owner];
			delete playerArray[i];
		}
		delete playerArray;

		// clear contest ranking
		for (uint256 i = 0; i < LEADERBOARD_LIMIT; i++) {
			delete leaderboard[i];
		}
		// clear contest pup pats
		for (uint256 i = 0; i < pupsInContest.length; i++) {
			delete pupPats[pupsInContest[i]];
		}

		emit ContestDataReseted();
	}

	function pat(uint256 _pupId) external nonReentrant {
		_processPat(_pupId);
	}

	function _processPat(uint256 _pupId) internal {
		// Usual checks for allowing to pat
		require(_pupId > 0 && _pupId <= 10000, 'Invalid pup id');
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can pat and not a contract
		require(!_alreadyPatted(_pupId), 'User has already liked once');
		require(inContest[_pupId] != address(0), 'Punk not in the fashion show');

		/**
		 * Checking if contest flag is still on and the deadline has passed.
		 * If so, then I am resetting deadline and allotting the top most pup in leaderboard as winner
		 */
		if (isContestOn) {
			if (block.timestamp > deadline) {
				isContestOn = false;
				deadline = 0;
				_setWinnerPup();
			}
		}
		if (pupPats[_pupId].owner == address(0)) {
			_setOwnerAddress(_pupId);
		}

		// Upgrading pat count on pup
		pupPats[_pupId].pats += 1;
		_leaderboardSort(_pupId);
		pupsInContest.push(_pupId);

		// Effect of patting
		people[msg.sender].pattedPups.push(_pupId);
		emit PatPup(msg.sender, _pupId, pupPats[_pupId].pats);
	}

	function _processPatWhenOwnsPupPunk(uint256 _pupId) internal {
		// Usual checks for allowing to pat
		require(_pupId > 0 && _pupId <= 10000, 'Invalid pup id');
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can pat and not a contract
		require(!_alreadyPatted(_pupId), 'User has already liked once');
		require(inContest[_pupId] != address(0), 'Punk not in the fashion show');

		/**
		 * Checking if contest flag is still on and the deadline has passed.
		 * If so, then I am resetting deadline and allotting the top most pup in leaderboard as winner
		 */
		if (isContestOn) {
			if (block.timestamp > deadline) {
				isContestOn = false;
				deadline = 0;
				_setWinnerPup();
			}
		}
		if (pupPats[_pupId].owner == address(0)) {
			_setOwnerAddress(_pupId);
		}

		// Upgrading pat count on pup
		pupPats[_pupId].pats += 1;
		_leaderboardSort(_pupId);
		pupsInContest.push(_pupId);

		// Effect of patting
		emit PatPup(address(0), _pupId, pupPats[_pupId].pats);
	}

	/**
	 * Everytime a pup is patted, it's respective owner is fetched
	 * and set to the PupMeta structure. If owner doesn't exist, an
	 * empty address is assigned.
	 */
	function _setOwnerAddress(uint256 _pupId) internal {
		Polypunk punkContract = Polypunk(polypunkAddress);

		address ownerAdd = address(0);
		try punkContract.ownerOf(_pupId) returns (address addr) {
			ownerAdd = addr;
		} catch Error(
			string memory /*reason*/
		) {
			// This is executed in case
			// revert was called inside getData
			// and a reason string was provided.
			ownerAdd = address(0);
		} catch (
			bytes memory /*lowLevelData*/
		) {
			// This is executed in case revert() was used
			// or there was a failing assertion, division
			// by zero, etc. inside getData.
			ownerAdd = address(0);
		}

		pupPats[_pupId].owner = ownerAdd;
	}

	function _setWinnerPup() internal {
		require(block.timestamp > deadline, "Contest hasn't ended yet");

		/**
		 *  Alotting new winner from the top of the leaderboard
		 *  No duplicate winner allowed.
		 *  Owner address should be present in active player contest mapping
		 *  Owner address should not be empty
		 *  If no valid topmost entry found, no winner is set for that contest.
		 */

		if (
			!pupPats[leaderboard[0].pupId].wonOnce &&
			people[pupPats[leaderboard[0].pupId].owner].inContest &&
			pupPats[leaderboard[0].pupId].owner != address(0)
		) {
			// Pushing winner in winner array
			winners.push(leaderboard[0]);

			// Setting pup in main pup array as won once
			pupPats[leaderboard[0].pupId].wonOnce = true;

			// Transfering reward to winner

			// collarToken.safeTransfer(
			// 	pupPats[leaderboard[0].pupId].owner,
			// 	collarToken.balanceOf(address(this))
			// );
			Address.sendValue(
				payable(pupPats[leaderboard[0].pupId].owner),
				address(this).balance
			);
			emit WinnerAlotted(
				pupPats[leaderboard[0].pupId].owner,
				address(this).balance,
				leaderboard[0].pupId
			);
		}
	}

	/**
	 * Main sorting of the leaderboard.
	 * Doing it in real time when a pat happens. Finding it's relevant location
	 * and shifting all the other entries.
	 */
	function _leaderboardSort(uint256 _pupId) internal {
		if (leaderboard[LEADERBOARD_LIMIT - 1].pup.pats >= pupPats[_pupId].pats) {
			//didn't make it to leaderboard
			return;
		}

		for (uint256 i = 0; i < LEADERBOARD_LIMIT; i++) {
			if (leaderboard[i].pup.pats < pupPats[_pupId].pats) {
				// resort leaderboard
				if (leaderboard[i].pupId != _pupId) {
					bool duplicate = false;
					Ranking memory currentRanking = leaderboard[i];
					for (uint256 j = i + 1; j < LEADERBOARD_LIMIT + 1; j++) {
						if (leaderboard[j].pupId == _pupId) {
							duplicate = true;
							delete leaderboard[j];
						}
						if (duplicate) {
							leaderboard[j] = currentRanking;
							currentRanking = leaderboard[j + 1];
						} else {
							Ranking memory nextRanking = leaderboard[j];
							leaderboard[j] = currentRanking;
							currentRanking = nextRanking;
						}
					}
				}
				// Add new high score
				leaderboard[i] = Ranking({pup: pupPats[_pupId], pupId: _pupId});
				emit LeaderboardUpdated(_pupId);
				return;
			}
			if (leaderboard[i].pupId == _pupId) {
				// user already is in the leaderboard with higher or equal score
				return;
			}
		}
	}

	/**
	 * Converting the leaderboard mapping to an array before sending
	 */
	function getLeaderboard() public view returns (Ranking[] memory) {
		Ranking[] memory rankings = new Ranking[](LEADERBOARD_LIMIT);
		for (uint256 i = 0; i < LEADERBOARD_LIMIT; i++) {
			rankings[i] = leaderboard[i];
		}
		return rankings;
	}

	/**
	 *  Get Active Players
	 */
	// TODO: Fetch pups of players and only return the ones who have not won before
	function getParticipants() public view returns (Player[] memory) {
		return playerArray;
	}

	/**
	 * Returns the winners list. In oldest to newest order.
	 */
	function getWinnerList() public view returns (Ranking[] memory) {
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
		return inContest[_id] == msg.sender;
	}

	/**
	 * Return if contest is active or not
	 */
	function isContestActive() public view returns (bool) {
		return block.timestamp <= deadline;
	}

	/**
	 * Returns the pat count for a particular pup
	 */
	function getPats(uint256 _pupId)
		public
		view
		returns (uint256 count, bool patted)
	{
		// Added only callable from a user so that people don't abuse the pat system.
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can mint and not a contract

		return (pupPats[_pupId].pats, _alreadyPatted(_pupId));
	}

	/**
	 * Checks if a pup has already been patted before
	 */
	function _alreadyPatted(uint256 _pupId) internal view virtual returns (bool) {
		bool contains = false;
		for (uint256 i = 0; i < people[msg.sender].pattedPups.length; i++) {
			if (_pupId == people[msg.sender].pattedPups[i]) {
				contains = true;
			}
		}
		return contains;
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

	/*
		Checks if this particular user owns this particular punk
	*/
	function isOwnerOfPunk(uint256 _id) internal view returns (bool) {
		require(tx.origin == msg.sender, 'Caller cannot be a contract'); // Only EOA can pat and not a contract

		Polypunk punkContract = Polypunk(polypunkAddress);
		bool _isOwner = false;

		try punkContract.ownerOf(_id) returns (address _owner) {
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
	 * Logic for fees and rewards starts here.
	 */

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function enterShow(uint256 _id) external payable nonReentrant {
		_processDeposit(_id);
	}

	function getBalance() public view returns (uint256) {
		// uint256 bal = collarToken.balanceOf(address(this));
		return address(this).balance; // returns the contract balance
	}

	/**
	 *	@dev Accepting collar as contest fees
	 *	burning 20% of collar and registering user
	 *  as part of contest
	 */

	function _processDeposit(uint256 _id) internal {
		require(
			msg.value >= collarFees,
			'Amount deposited should be equal or more than the minimum fees'
		);
		require(block.timestamp <= deadline, 'Contest should be active');
		require(msg.sender != owner(), 'Nope, admins cannot participate :(');
		require(isOwnerOfPunk(_id), 'You do not own this punk');
		require(!isAContestParticipant(_id), 'Punk already in show! Get more punks');
		require(!alreadyWon[_id], 'Sorry, this punk has already won the show once!');
		if (puppunkRequired) {
			require(ownsAPupPunk(), 'You need a PupPunk to enter show');
		}

		// Burning 20% of amount paid
		uint256 devAmount = (msg.value * devPercentage) / 100;
		uint256 depositAmount = msg.value - devAmount;

		// Transfer values to contract and dev fees
		Address.sendValue(payable(address(this)), depositAmount);
		Address.sendValue(developer, devAmount);

		// Populate contest data
		people[msg.sender].inContest = true;
		playerArray.push(Player(_id, msg.sender));
		inContest[_id] = msg.sender;
		if (puppunkExtraPat) {
			if (ownsAPupPunk()) {
				_processPatWhenOwnsPupPunk(_id);
			}
		}

		emit DevFees(devAmount);
		emit PlayerEnrolled(msg.sender, depositAmount);
	}
}