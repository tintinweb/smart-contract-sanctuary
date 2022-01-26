// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IHedgeCore } from "./interfaces/IHedgeCore.sol";
import { ISToken } from "./interfaces/ISToken.sol";
import { IStaking } from "./interfaces/IStaking.sol";
import { IOracleMaster } from "./interfaces/IOracleMaster.sol";
import { AddressProvider } from "./AddressProvider.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IHedgeToken } from "./interfaces/IHedgeToken.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/// @dev hedge core for vesq
contract HedgeCore is IHedgeCore, ReentrancyGuard, Pausable {
	using SafeERC20 for IERC20;

	AddressProvider public immutable addressProvider;
	IERC20 public immutable sToken;

	IHedgeToken public shortToken; // <
	IHedgeToken public longToken; // >=

	address public gauge; // onlyOwner can change
	address public hedgeTarget;

	HedgeInfo public hedgeInfo;
	uint256 public override currSTokenEpoch; // current sToken epoch number
	uint256 public constant RESTRICTED_PERIOD = 14400;
	uint256 public constant PRECISION = 1E27;

	// gauge related
	uint256 public toGaugeRatio; // 1000 means 1%.   div by 10^5 to get the actual number (e.g. 0.01)
	uint256 public constant RATIO_PRECISION = 1E5;

	// log related
	Log[] public logs;
	Rebase[] public longRebases;
	Rebase[] public shortRebases;

	bool public initialized;

	modifier onlyDAO() {
		require(msg.sender == addressProvider.getDAO(), "HC: RESTRICTED ACCESS!");
		_;
	}

	modifier onlyEmergencyAdmin() {
		require(msg.sender == addressProvider.getEmergencyAdmin(), "HC: RESTRICTED ACCESS!");
		_;
	}

	modifier onlyInitialized() {
		require(initialized, "HC: NOT INITIALIZED");
		_;
	}

	modifier onlyAfterRebase() {
		(uint256 newSTokenEpoch, , , ) = _stakingContractEpoch();
		require(currSTokenEpoch < newSTokenEpoch, "HC: STOKEN NOT REBASED YET");
		_;
	}

	modifier onlyBeforeLockedTime() {
		require(block.timestamp <= hedgeInfo.rebaseEndTime - RESTRICTED_PERIOD, "HC: DEPOSIT RESTRICTED");
		_;
	}

	///@dev Hedge contract for vesq on polygon
	constructor(
		string memory name_,
		address addressProvider_,
		address sToken_,
		address hedgeTarget_
	) {
		require(bytes(name_).length != 0, "HC: STR EMPTY!");
		require(AddressProvider(addressProvider_).getDAO() != address(0), "HC: AP INV");
		require(IERC20(hedgeTarget_).totalSupply() > 0, "HC: TGT TOKEN INV");
		addressProvider = AddressProvider(addressProvider_);
		sToken = IERC20(sToken_);
		hedgeTarget = hedgeTarget_;
	}

	// -------------------- core logic -------------------- //
	///@dev for frontend. prevent frontend rug
	function deposit(uint256 shortAmount_, uint256 longAmount_) public override nonReentrant onlyInitialized whenNotPaused onlyBeforeLockedTime {
		_depositFor(msg.sender, shortAmount_, longAmount_);
	}

	///@dev only available at unlocked period
	function depositFor(
		address user_,
		uint256 shortAmount_,
		uint256 longAmount_
	) public override nonReentrant onlyInitialized whenNotPaused onlyBeforeLockedTime {
		_depositFor(user_, shortAmount_, longAmount_);
	}

	function withdrawTo(
		address recipent_,
		uint256 shortAmount_,
		uint256 longAmount_
	) public override nonReentrant onlyInitialized {
		_withdrawTo(recipent_, shortAmount_, longAmount_);
	}

	///@dev for frontend. prevent frontend rug
	function withdraw(uint256 shortAmount_, uint256 longAmount_) public override nonReentrant onlyInitialized {
		_withdrawTo(msg.sender, shortAmount_, longAmount_);
	}

	function swap(bool fromLongToShort_, uint256 amount_) public override nonReentrant onlyInitialized whenNotPaused onlyBeforeLockedTime {
		_swap(fromLongToShort_, amount_);
	}

	function startNewHedge() public override nonReentrant onlyInitialized whenNotPaused onlyAfterRebase {
		_startNewHedge();
	}

	// ---------------- ADMIN OR DAO ONLY ------------------ //
	function initGnesisHedge(address shortToken_, address longToken_) public override onlyDAO {
		_initGnesisHedge(shortToken_, longToken_);
	}

	// no fee if gauge is zero address
	function updateGaugeAndRatio(address newGauge_, uint256 ratio_) public onlyDAO {
		gauge = newGauge_;
		require(ratio_ <= uint256(20000), "HC: RATIO  INV"); // <= 20%
		toGaugeRatio = ratio_;
	}

	function setPause(bool paused_) public onlyEmergencyAdmin {
		if (paused_) {
			_pause();
		} else {
			_unpause();
		}
	}

	/**
	 * @dev rescue leftover tokens
	 * @notice only DAO can call, and will be send back to DAO
	 * @param token_ reserve curreny
	 * @param amount_ amount of reserve token to transfer
	 */
	function rescueTokens(address token_, uint256 amount_) external onlyDAO whenPaused {
		address dao = addressProvider.getDAO();
		SafeERC20.safeTransfer(IERC20(token_), dao, amount_);
	}

	// ----------------external view funtions -------------------- //
	function shortRebasesLen() external view returns (uint256) {
		return shortRebases.length;
	}

	function longRebasesLen() external view returns (uint256) {
		return longRebases.length;
	}

	function logsLen() external view returns (uint256) {
		return logs.length;
	}

	function hedgeCoreStatus() external view override returns (bool isUnlocked_) {
		isUnlocked_ = (block.timestamp <= hedgeInfo.rebaseEndTime - RESTRICTED_PERIOD) ? true : false;
	}

	function isSTokenRebased() external view override returns (bool) {
		(uint256 newSTokenEpoch, , , ) = _stakingContractEpoch();
		return newSTokenEpoch > currSTokenEpoch ? true : false;
	}

	// ------------------ private functions --------------------- //

	function _depositFor(
		address user_,
		uint256 shortAmount_,
		uint256 longAmount_
	) private {
		require(shortAmount_ + longAmount_ != 0, "HC: AMOUNT ZR");
		require(user_ != address(0), "HC: ADDR ZR");

		// stoken is not feeOnTransfer token so no need to check pre and post balance
		sToken.safeTransferFrom(user_, address(this), shortAmount_ + longAmount_);

		// mint user sToken to game token for LONG and SHORT
		if (shortAmount_ != 0) {
			shortToken.mint(user_, shortAmount_);
		}
		if (longAmount_ != 0) {
			longToken.mint(user_, longAmount_);
		}

		// emit deposit event and game status
		emit Logger(_sTokenRebase(), shortRebases.length, longRebases.length);
		emit Deposited(user_, shortAmount_, longAmount_);
	}

	function _withdrawTo(
		address recipent_,
		uint256 shortAmount_,
		uint256 longAmount_
	) private {
		require(shortAmount_ + longAmount_ != 0, "HC: AMOUNT ZR");
		require(recipent_ != address(0), "HC: ADDR ZR");

		// burn user short & long token
		if (shortAmount_ != 0) {
			shortToken.burn(msg.sender, shortAmount_);
		}
		if (longAmount_ != 0) {
			longToken.burn(msg.sender, longAmount_);
		}

		// convert game token to sToken for LONG and SHORT burn user token
		sToken.safeTransfer(recipent_, shortAmount_ + longAmount_);
		// emit withdraw event and game status
		emit Logger(_sTokenRebase(), shortRebases.length, longRebases.length);
		emit Withrawed(recipent_, shortAmount_, longAmount_);
	}

	function _swap(bool fromLongToShort_, uint256 amount_) private {
		require(amount_ > 0, "HC: AMOUNT ZR");
		if (fromLongToShort_) {
			longToken.burn(msg.sender, amount_);
			shortToken.mint(msg.sender, amount_);
		} else {
			shortToken.burn(msg.sender, amount_);
			longToken.mint(msg.sender, amount_);
		}

		emit Logger(_sTokenRebase(), shortRebases.length, longRebases.length);
		emit Swaped(msg.sender, fromLongToShort_, amount_);
	}

	function _startNewHedge() private {
		require(shortToken.totalSupply() > 0 && longToken.totalSupply() > 0, "HC: BOTH NON ZERO TOTAL SUPPLY");
		(uint256 currHedgeTokenPrice, uint256 curHedgeTargetPrice) = _fetchPrice();

		bool isLong;
		if ((currHedgeTokenPrice * PRECISION) / curHedgeTargetPrice >= (hedgeInfo.hedgeTokenPrice * PRECISION) / hedgeInfo.hedgeTargetPrice) {
			isLong = true;
		}
		// calculate rebase amount
		uint256 rebaseTotalAmount;
		uint256 oldAmount = shortToken.totalSupply() + longToken.totalSupply();
		if (sToken.balanceOf(address(this)) > oldAmount) {
			// in case of underflow
			rebaseTotalAmount = sToken.balanceOf(address(this)) - oldAmount;
		}
		uint256 toGauge = (rebaseTotalAmount * toGaugeRatio) / RATIO_PRECISION;
		// no fee if gauge is address(0)
		if (gauge == address(0)) {
			toGauge == 0;
		} else if (toGauge != 0) {
			sToken.safeTransfer(gauge, toGauge);
		}

		uint256 rebaseDistributeAmount = rebaseTotalAmount - toGauge;

		// start new game
		hedgeInfo.hedgeTokenPrice = currHedgeTokenPrice;
		hedgeInfo.hedgeTargetPrice = curHedgeTargetPrice;

		(currSTokenEpoch, , , hedgeInfo.rebaseEndTime) = _stakingContractEpoch();
		// update hedge core log
		_rebaseHedgeToken(isLong, rebaseDistributeAmount);
		_storeLog(isLong);

		// emit result
		emit HedgeLog(logs.length, isLong, rebaseTotalAmount);
	}

	function _rebaseHedgeToken(bool isLong_, uint256 amountRebased_) private returns (bool) {
		Rebase memory currRebase;
		// modifies value
		currRebase.amountRebased = amountRebased_;
		currRebase.rebase = logs.length + 1; // cause log length increse after this
		currRebase.timestampOccured = block.timestamp;

		// update token idx
		if (isLong_) {
			uint256 longIdx = ((longToken.totalSupply() + amountRebased_) * PRECISION) / longToken.rawTotalSupply();
			longToken.updateIdx(longIdx);
			currRebase.tokenIdx = longIdx;
			longRebases.push(currRebase);
		} else {
			uint256 shortIdx = ((shortToken.totalSupply() + amountRebased_) * PRECISION) / shortToken.rawTotalSupply();
			shortToken.updateIdx(shortIdx);
			currRebase.tokenIdx = shortIdx;
			shortRebases.push(currRebase);
		}

		return true;
	}

	function _initGnesisHedge(address shortToken_, address longToken_) private {
		require(!initialized, "HC: initialized!");
		shortToken = IHedgeToken(shortToken_);
		longToken = IHedgeToken(longToken_);
		require(shortToken.core() == address(this) && longToken.core() == address(this), "HC: HGE TOKEN INV");

		// get price ratio
		(hedgeInfo.hedgeTokenPrice, hedgeInfo.hedgeTargetPrice) = _fetchPrice();
		// record next rebase info
		(currSTokenEpoch, , , hedgeInfo.rebaseEndTime) = _stakingContractEpoch();
		// set state to initalized
		initialized = true;
		emit Initialized(msg.sender);
	}

	function _storeLog(bool isLong_) private returns (bool) {
		Log memory log;
		log.isLong = isLong_;
		if (isLong_) {
			log.hedgeTokenRebase = longRebases.length;
		} else {
			log.hedgeTokenRebase = shortRebases.length;
		}

		log.sTokenRebase = _sTokenRebase();

		logs.push(log);

		return true;
	}

	function _sTokenRebase() private view returns (uint256 rebase_) {
		(rebase_, , , ) = _stakingContractEpoch();
	}

	function _fetchPrice() private view returns (uint256 hedgeTokenPrice_, uint256 hedgeTargetPrice_) {
		address oracleMaster = addressProvider.getOracleMaster();
		hedgeTokenPrice_ = IOracleMaster(oracleMaster).queryInfo(_token());
		hedgeTargetPrice_ = IOracleMaster(oracleMaster).queryInfo(hedgeTarget);
	}

	function _token() private view returns (address) {
		address stakingContract = ISToken(address(sToken)).stakingContract();
		return IStaking(stakingContract).VSQ();
	}

	function _stakingContractEpoch()
		private
		view
		returns (
			uint256 number_,
			uint256 distribute_,
			uint256 length_,
			uint256 endTime_
		)
	{
		address stakingContract = ISToken(address(sToken)).stakingContract();
		(number_, distribute_, length_, endTime_) = IStaking(stakingContract).epoch();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IHedgeCore {
	event Initialized(address indexed initializer);
	event Rebased(uint256 indexed rebase_);
	event Logger(uint256 sTokenRebase, uint256 indexed shortRebase_, uint256 indexed longRebased_);
	event Deposited(address indexed user_, uint256 indexed shortAmount_, uint256 indexed longAmount_);
	event Withrawed(address indexed to_, uint256 indexed shortAmount_, uint256 indexed longAmount_);
	event Swaped(address indexed user_, bool indexed fromLongToShort_, uint256 indexed amount_);
	event HedgeLog(uint256 epoch, bool isLong, uint256 rebaseTotalAmount);

	// soft-hedge data
	struct HedgeInfo {
		uint256 hedgeTokenPrice;
		uint256 hedgeTargetPrice;
		uint256 rebaseEndTime;
	}

	struct Log {
		bool isLong; // the win side
		uint256 hedgeTokenRebase; // rebase cnt of win side
		uint256 sTokenRebase; // sToken rebase cnt
	}

	struct Rebase {
		uint256 amountRebased;
		uint256 rebase; // times of rebased
		uint256 timestampOccured;
		uint256 tokenIdx; // idx of our HedgeToken
	}

	function deposit(uint256 shortAmount_, uint256 longAmount_) external;

	function depositFor(
		address user_,
		uint256 shortAmount_,
		uint256 longAmount_
	) external;

	function withdraw(uint256 shortAmount_, uint256 longAmount_) external;

	function withdrawTo(
		address recipent_,
		uint256 shortAmount_,
		uint256 longAmount_
	) external;

	function swap(bool fromLongToShort_, uint256 amount_) external;

	function currSTokenEpoch() external view returns (uint256);

	function hedgeCoreStatus() external view returns (bool);

	function isSTokenRebased() external view returns (bool);

	function startNewHedge() external;

	function initGnesisHedge(address shortToken_, address longToken_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISToken is IERC20 {
	function index() external view returns (uint256);

	function stakingContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IStaking {
	function epoch()
		external
		view
		returns (
			uint256 number,
			uint256 distribute,
			uint256 length,
			uint256 endTime
		);

	function VSQ() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracleMaster {
	function queryInfo(address token_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
contract AddressProvider is Ownable {
	event DAOSet(address indexed dao_);
	event EmergencyAdminSet(address indexed newAddr_);
	event AddressSet(bytes32 id, address indexed newAddr_);

	mapping(bytes32 => address) private _addresses;
	bytes32 private constant DAO = "DAO";
	bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
	bytes32 private constant ORACLE_MASTER = "ORACLE_MASTER";

	function getAddress(bytes32 id_) external view returns (address) {
		return _addresses[id_];
	}

	function setAddress(bytes32 id_, address newAddress_) external onlyOwner {
		require(bytes32(id_).length != 0, "AP: ZERO INPUT");
		require(newAddress_ != address(0), "AP: ZR ADDR");
		_addresses[id_] = newAddress_;
		emit AddressSet(id_, newAddress_);
	}

	/// @dev get & set emergency admin
	function getEmergencyAdmin() external view returns (address) {
		return _addresses[EMERGENCY_ADMIN];
	}

	function setEmergencyAdmin(address emergencyAdmin_) external onlyOwner {
		require(emergencyAdmin_ != address(0), "AP: ZR ADDR");
		_addresses[EMERGENCY_ADMIN] = emergencyAdmin_;
		emit EmergencyAdminSet(emergencyAdmin_);
	}

	/// @dev get & set dao
	function getDAO() external view returns (address) {
		return _addresses[DAO];
	}

	function setDAO(address dao_) external onlyOwner {
		require(dao_ != address(0), "AP: ZR ADDR");
		_addresses[DAO] = dao_;
		emit DAOSet(dao_);
	}

	/// @dev get & set dao
	function getOracleMaster() external view returns (address) {
		return _addresses[ORACLE_MASTER];
	}

	function setOracleMaster(address newAddr_) external onlyOwner {
		require(newAddr_ != address(0), "AP: ZR ADDR");
		_addresses[ORACLE_MASTER] = newAddr_;
		emit AddressSet(ORACLE_MASTER, newAddr_);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHedgeToken is IERC20 {
	function core() external view returns (address);

	function idx() external view returns (uint256);

	function mint(address user_, uint256 amount_) external;

	function burn(address user_, uint256 amount_) external;

	function updateIdx(uint256 idx_) external;

	function rawTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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