/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: Address

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

// Part: Context

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

// Part: IERC20

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

// Part: ReentrancyGuard

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

// Part: Ownable

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

// File: CryptoboxManager.sol

contract CryptoboxManager is Context, Ownable, ReentrancyGuard {
	using Address for address payable;

	constructor (address _authAddress, address payable _jackpotWallet) {
		authAddress = _authAddress;
		jackpotWallet = _jackpotWallet;
	}

	event Bet(uint256 indexed bet, uint256 amount, address account, uint256 cryptoboxID, uint256 seed);
	event UpdateCryptobox(uint256 indexed id, address asset, uint256 price);

	mapping(uint256 => bool) public shardConsumed;

	mapping(uint256 => address) public cryptoboxAsset;
	mapping(uint256 => uint256) public cryptoboxPrice;
	mapping(uint256 => uint256) public cryptoboxShardPrice;
	mapping(uint256 => uint256) public jackpot;
	mapping(uint256 => uint256) public jackpotStart;
	mapping(uint256 => uint256) public jackpotIncrementPercent;

	address public authAddress;
	address payable public jackpotWallet;
	address payable[] public feeWallets;
	uint256[] public feePercents;

	uint256 public totalBets;
	mapping(uint256 => address) public claimedBet;
	mapping(uint256 => uint256) public claimedBetAmount;

	function _bet(address account, uint256 cryptoboxID, uint256 seed, uint256 bets) internal {
		require(cryptoboxPrice[cryptoboxID] > 0, "Invalid Cryptobox");
		require(bets > 0, "Must place bets");
		totalBets++;
		claimedBet[totalBets] = account;
		claimedBetAmount[totalBets] = bets;
		emit Bet(totalBets, bets, account, cryptoboxID, seed);
	}

	function submitBet(uint256 cryptoboxID, uint256 seed, uint256 bets) public payable nonReentrant {
		_bet(_msgSender(), cryptoboxID, seed, bets);
		uint256 cost = cryptoboxPrice[cryptoboxID] * bets;
		uint256 jackpotIncrement = cost * jackpotIncrementPercent[cryptoboxID] / 100;
		jackpot[cryptoboxID] += jackpotIncrement;

		// Fees:
		// jackpot increment is sent to the jackpots wallet
		// other fees are sent to fee wallets
		// remaining value is stored in the contract to cover operation costs
		if (cryptoboxAsset[cryptoboxID] == address(0)) {
			require(msg.value == cost, "Incorrect payment.");
			jackpotWallet.sendValue(jackpotIncrement);
			for (uint i = 0; i < feeWallets.length; i++)
				feeWallets[i].sendValue(cost * feePercents[i] / 100);
		} else {
			IERC20 asset = IERC20(cryptoboxAsset[cryptoboxID]);
			asset.transferFrom(_msgSender(), jackpotWallet, jackpotIncrement);
			uint256 totalFees = jackpotIncrement;
			for (uint i = 0; i < feeWallets.length; i++) {
				uint256 fee = cost * feePercents[i] / 100;
				asset.transferFrom(_msgSender(), feeWallets[i], fee);
				totalFees += fee;
			}
			asset.transferFrom(_msgSender(), address(this), cost - totalFees);
		}
	}

	function submitBetWithShard(uint256 cryptoboxID, uint256 seed, uint256 bets, uint256 shardID, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
		require(cryptoboxShardPrice[cryptoboxID] == 1, "Cryptobox is not priced at 1 shard.");
		bytes32 hash = keccak256(abi.encode("CryptoboxManager_shard", _msgSender(), shardID));
		address signer = ecrecover(hash, v, r, s);
		require(signer == authAddress, "Invalid signature");
		require(!shardConsumed[shardID], "Shard has already been used.");
		shardConsumed[shardID] = true;
		_bet(_msgSender(), cryptoboxID, seed, bets);
	}

	function submitBetWithShards(uint256 cryptoboxID, uint256 seed, uint256 bets, uint256[] calldata shardIDs, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
		uint256 cost = cryptoboxShardPrice[cryptoboxID] * bets;
		require(shardIDs.length == cost, "Incorrect amount of shards.");
		bytes32 hash = keccak256(abi.encode("CryptoboxManager_shards", _msgSender(), shardIDs));
		address signer = ecrecover(hash, v, r, s);
		require(signer == authAddress, "Invalid signature");
		for (uint i = 0; i < shardIDs.length; i++) {
			require(!shardConsumed[shardIDs[i]], "Shard has already been used.");
			shardConsumed[shardIDs[i]] = true;
		}
		_bet(_msgSender(), cryptoboxID, seed, bets);
	}

	function redeem(address asset, uint256 amount, uint256 bet, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
		require(amount != 0, "Nothing to redeem.");
		require(claimedBet[bet] == _msgSender(), "Invalid bet");
		bytes32 hash = keccak256(abi.encode("CryptoboxManager_redeem", asset, amount, bet));
		address signer = ecrecover(hash, v, r, s);
		require(signer == authAddress, "Invalid signature");
		claimedBet[bet] = address(0);
		if (asset == address(0))
			payable(_msgSender()).sendValue(amount);
		else
			IERC20(asset).transfer(_msgSender(), amount);
	}

	function setAuthAddress(address _address) public onlyOwner {
		authAddress = _address;
	}

	function setJackpotWallet(address payable wallet) public onlyOwner {
		jackpotWallet = wallet;
	}

	function setFees(address payable[] calldata wallets, uint256[] calldata percents) public onlyOwner {
		require(wallets.length == percents.length, "Array lengths must match.");
		feeWallets = wallets;
		feePercents = percents;
	}

	// TODO Remove if not useful
	function setFees2(address payable[] memory wallets, uint256[] memory percents) public onlyOwner {
		require(wallets.length == percents.length, "Array lengths must match.");
		delete feeWallets;
		delete feePercents;
		for (uint i = 0; i < wallets.length; i++) {
			feeWallets[i] = wallets[i];
			feePercents[i] = percents[i];
		}
	}

	function setFeeByIndex(uint256 index, uint256 percent) public onlyOwner {
		feePercents[index] = percent;
	}

	function updateCryptobox(uint256 id, address assetAddress, uint256 price, uint256 shardPrice, uint256 initialJackpotAmount, uint256 _jackpotIncrementPercent) public onlyOwner {
		if (cryptoboxPrice[id] == 0)
			jackpot[id] = initialJackpotAmount;
		cryptoboxPrice[id] = price;
		cryptoboxShardPrice[id] = shardPrice;
		cryptoboxAsset[id] = assetAddress;
		jackpotStart[id] = initialJackpotAmount;
		jackpotIncrementPercent[id] = _jackpotIncrementPercent;
		emit UpdateCryptobox(id, assetAddress, price);
	}

	function resetJackpot(uint256 cryptoboxID) public onlyOwner {
		jackpot[cryptoboxID] = jackpotStart[cryptoboxID];
	}

	function insertBNB() public payable onlyOwner {}

	function removeBNB(uint256 amount) public onlyOwner {
		payable(_msgSender()).sendValue(amount);
	}

	// TODO test this just to be sure
	function approveWithdraw(address asset, uint256 amount) public onlyOwner {
		IERC20(asset).approve(_msgSender(), amount);
	}
}