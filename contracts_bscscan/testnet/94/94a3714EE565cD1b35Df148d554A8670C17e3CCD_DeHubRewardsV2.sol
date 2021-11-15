// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./abstracts/DeHubRewardsUpgradeable.sol";
import "./interfaces/IDEHUB.sol";
import "./libraries/Percent.sol";

/**
* @dev V2 upgrade template. Use this if update is needed in the future.
*/
contract DeHubRewardsV2 is DeHubRewardsUpgradeable {
	using Percent for uint;
	// DeHub Main Contract
	IDEHUB public dehubToken;
	// LP address
	address public uniswapV2Pair;
	// Distribution feature toggle
	bool public isDistributionEnabled;
	// This will hold maximum claimable BNB amount for a distribution cycle.
	uint public claimableDistribution;
	// Will show total BNB claimed from the beginning of distribution launch.
	uint public totalClaimed;
	// Will show total BNB claimed for teh current cycle.
	uint public totalClaimedDuringCycle;
	// Will keep the record about the last claim by holder.
	mapping(address => uint) internal claimedTimestamp;
	// Record of when was the last cycle set
	uint public lastCycleResetTimestamp;
	// Amount of hours for a claim cycle. Cycle will be reset after this passes.
	uint public claimCycleHours;
	// Calculated next reset timestamp
	uint public nextCycleResetTimestamp;

	event ReceivedBNB(uint amount, address from);
	event ClaimedBNBRewards(uint bnbClaimed, address claimant);
	event SentBNBRewards(uint bnbSent, address holder);
	event PulledBNB(uint amount, address puller, address destination);

	receive() external payable {
		emit ReceivedBNB(msg.value, _msgSender());
	}

	/**
	* @notice External function allows to enable the reward distribution feature.
	* Some BNB must be already accumulated for this to work.
	* NOTE: Can be used to reset the cycle from the outside too.
	* @param cycleHours set or reset the hours for the distribution cycle
	* @return amount of BNB set as claimable for this cycle
	*/
	function enableRewardDistribution(uint cycleHours) 
		external 
		onlyOwner 
		returns(uint) 
	{
		require(uniswapV2Pair != address(0), "LP address is not set!");
		require(cycleHours > 0, "Cycle hours can't be 0.");
		require(address(this).balance > 0, "Don't have BNB for distribution.");
		isDistributionEnabled = true;
		resetClaimDistributionCycle(cycleHours, false);
		return claimableDistribution;
	}

	/**
	* @notice External function allowing to stop reward distribution.
	* NOTE: must call enableRewardDistribution() to start it again.
	*/
	function disableRewardDistribution() external onlyOwner returns(bool) {
		isDistributionEnabled = false;
		return true;
	}

	/**
	* @notice Tells if reward claim cycle has ended since the last reset.
	*/
	function hasCyclePassed() public view returns(bool) {
		uint timeSinceReset = block.timestamp - lastCycleResetTimestamp;

		return timeSinceReset > claimCycleHours * (60 * 60);
	}

	/**
	* @notice Tells if the address has already claimed during the current cycle.
	* If user has claimed in his own cycle, we still need to check if potentially
	* the global cycle has passed already and this user would trigger the reset.
	* If that's the case, we can say that he has not claimed yet in this cycle.
	*/
	function hasAlreadyClaimed(address holderAddr) public view returns(bool) {
		uint lastClaim = claimedTimestamp[holderAddr];
		uint timeSinceLastClaim = block.timestamp - lastClaim;
		bool didClaim = timeSinceLastClaim < claimCycleHours * (60 * 60);

		if (!didClaim) {
			return false;
		} else {
			bool willReset = hasCyclePassed();

			if (willReset) {
				return false;
			} else {
				return true;
			}
		}
	}

	/**
	* @notice Calculate claimable share for a specific holder.
	* Note: can be used to calculate potential share based on the custom 
	* circulating supply and lp tokens.
	*/
	function calcClaimableShare(
		address _holderAddr,
		uint _circulatingSupply,
		uint _lpTokens,
		uint _claimableDistribution
	) public view returns(uint) {
		uint totalHoldingAmount = _circulatingSupply - _lpTokens;
		uint holderAmount = dehubToken.balanceOf(_holderAddr);
		uint bnbShare = totalHoldingAmount.percent(holderAmount, 18);
		uint bnbToSend = bnbShare.percentOf(_claimableDistribution, 1 * 10 ** 18);







		return bnbToSend;
	}

	/**
	* @notice Calculates a share of BNB belonging to a holder based on his holdings,
	* current circulating supply and tokens stored in LP. (This )
	*/
	function calcCurrentClaimableShare(address holderAddr) public view returns(uint) {
		uint circulatingSupply = dehubToken.totalCirculatingSupply();
		uint lpTokens = dehubToken.balanceOf(uniswapV2Pair);
		uint bnbToSend = calcClaimableShare(
			holderAddr, 
			circulatingSupply, 
			lpTokens, 
			claimableDistribution
		);
		return bnbToSend;
	}

	/**
	* @notice Resets the reward claim cycle with a new hours value. 
	* Assigns new 'claimableDistribution' and resets lastCycleResetTimestamp.
	*/
	function resetClaimDistributionCycle(uint cycleHours, bool hardReset) 
		internal
	{
		require(cycleHours > 0, "Cycle hours can't be 0.");

		claimCycleHours = cycleHours;
		// Update the total for the historic record
		totalClaimed += totalClaimedDuringCycle;
		// First sync main accumulator


		// Don't forget to reset total for cycle!
		totalClaimedDuringCycle = 0;
		// Set claimable with current BNB balance
		claimableDistribution = address(this).balance;

		// Reset time stamp
		uint adjustedResetTimestamp = block.timestamp;

		uint cycleSeconds = cycleHours * (60 * 60);
		if (lastCycleResetTimestamp > 0) {
			uint timeSinceReset = block.timestamp - lastCycleResetTimestamp;
			uint overtime = timeSinceReset > cycleSeconds ? timeSinceReset - cycleSeconds : 0;
			adjustedResetTimestamp = block.timestamp - overtime;





		}
		lastCycleResetTimestamp = hardReset ? 0 : adjustedResetTimestamp;
		nextCycleResetTimestamp = adjustedResetTimestamp + cycleSeconds;

	}

	function _claimReward(address claimant) 
		internal
		returns(uint)
	{
		require(dehubToken.balanceOf(claimant) > 0, "Address has no DeHub tokens!");
		require(isDistributionEnabled, "Distribution is disabled.");
		
		bool doHardReset = hasAlreadyClaimed(claimant);
		if (hasCyclePassed()) {
				// Reset with same cycle hours.
				resetClaimDistributionCycle(claimCycleHours, doHardReset);
		} else {
			require(!hasAlreadyClaimed(claimant), "Already claimed in the current cycle.");
		}

		uint bnbShare = calcCurrentClaimableShare(claimant);
		payable(claimant).transfer(bnbShare);

		claimedTimestamp[claimant] = block.timestamp;
		totalClaimedDuringCycle += bnbShare;
		return bnbShare;
	}

	/**
	* @notice Set the main DeHub token address.
	*/
	function setDehubToken(address contractAddr) external onlyOwner {
		require(contractAddr != address(0), "Address must be provided.");
		dehubToken = IDEHUB(contractAddr);
	}

	/**
	* @notice Set manually LP pair address, which will be substracted from the 
	* claimable share calculation.
	*/
	function setLPAddress(address _lpAddr) external onlyOwner{
		require(_lpAddr != address(0), "Address can't be 0.");
		uniswapV2Pair = _lpAddr;
	}

	/**
	* @notice Convenience function, returns BNB balance of the contract.
	*/
	function bnbAccumulatedForDistribution() external view returns(uint) {
		return address(this).balance;
	}

	/**
	* @notice Allows any holder to call this function and claim the a share of BNB 
	* belonging to him basec on the holding amount, current claimable amount.
	* Claiming can be done only once per cycle.
	*/
	function claimReward() 
		external
		nonReentrant
		returns(uint)
	{
		address sender = _msgSender();
		uint bnbShare = _claimReward(sender);
		emit ClaimedBNBRewards(bnbShare, sender);
		return bnbShare;
	}

	/**
	* @notice Allows the owner of the contract to send rewards to the holder 
	* manually.
	*/
	function sendReward(address holderAddr) 
		external
		onlyOwner
		nonReentrant
		returns(uint)
	{
		uint bnbShare = _claimReward(holderAddr);
		emit SentBNBRewards(bnbShare, holderAddr);
		return bnbShare;
	}

	/**
	* @notice Allows the owner to pull BNB from the contract.
	* Just in case updates the claimableDistribution variable so that it is in
	* sync with a new BNB balance.
	*/
	function pullBnb(uint amount, address to) 
		external 
		onlyOwner 
		nonReentrant 
	{
		require(!isDistributionEnabled, "Distribution must be disabled first!");
		require(amount > 0, "Amount can't be 0.");
		require(to != address(0), "Can't sed BNB to zero address.");
		require(address(this).balance >= amount, "Amount is more than balance!");

		payable(to).transfer(amount);
		// Update claimable distribution the new balance
		claimableDistribution = address(this).balance;

		emit PulledBNB(amount, _msgSender(), to);
	}

	/**
	* @dev Must call this jsut after the upgrade deployement, to update state 
	* variables and execute other upgrade logic.
	* Ref: https://github.com/OpenZeppelin/openzeppelin-upgrades/issues/62
	*/
	function upgradeToV2() public {
		require(version < 2, "DeHubRewards: Already upgraded to version 2");
		version = 2;

	}

	function resetRewardDistribution(uint cycleHours) 
		external 
		onlyOwner 
		returns(uint) 
	{
		require(uniswapV2Pair != address(0), "LP address is not set!");
		require(cycleHours > 0, "Cycle hours can't be 0.");
		require(address(this).balance > 0, "Don't have BNB for distribution.");
		isDistributionEnabled = true;
		resetClaimDistributionCycle(cycleHours, true);
		return claimableDistribution;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract DeHubRewardsUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using AddressUpgradeable for address;

	uint public version;

	function initialize() public initializer {
		__Ownable_init();
		__ReentrancyGuard_init();
		__UUPSUpgradeable_init();
		version = 1;

	}

	function _authorizeUpgrade(address newImplementation)
		internal
		onlyOwner
		override
	{}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDEHUB {
  // function _buybackFee (  ) external view returns ( uint256 );
  // function _collateralFee (  ) external view returns ( uint256 );
  // function _distributionFee (  ) external view returns ( uint256 );
  // function _expensesFee (  ) external view returns ( uint256 );
  // function _liquidityFee (  ) external view returns ( uint256 );
  // function _taxFee (  ) external view returns ( uint256 );
  // function accumulatedForBuyback (  ) external view returns ( uint256 );
  // function accumulatedForCollateral (  ) external view returns ( uint256 );
  // function accumulatedForDistribution (  ) external view returns ( uint256 );
  // function accumulatedForExpenses (  ) external view returns ( uint256 );
  // function accumulatedForLiquidity (  ) external view returns ( uint256 );
  // function addAddressToLPs ( address lpAddr ) external;
  // function addInitialLiquidity ( uint256 tokenAmount, uint256 bnbAmount ) external;
  // function allowance ( address ownr, address spender ) external view returns ( uint256 );
  // function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  // function bnbAccumulatedForBuyback (  ) external view returns ( uint256 );
  // function bnbAccumulatedForCollateral (  ) external view returns ( uint256 );
  // function bnbAccumulatedForDistribution (  ) external view returns ( uint256 );
  // function buyback ( uint256 bnbAmount ) external;
  // function calcClaimableShare ( address holderAddr ) external view returns ( uint256 );
  // function claimCycleHours (  ) external view returns ( uint256 );
  // function claimReward (  ) external returns ( uint256 );
  // function claimableDistribution (  ) external view returns ( uint256 );
  // function collateralWallet (  ) external view returns ( address );
  // function collateralize ( uint256 bnbAmount ) external;
  function deadAddr (  ) external view returns ( address );
  // function decimals (  ) external pure returns ( uint8 );
  // function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  // function devShare (  ) external view returns ( uint256 );
  // function devWallet (  ) external view returns ( address );
  // function disableAllFeesTemporarily (  ) external;
  // function disableRewardDistribution (  ) external returns ( bool );
  // function disableSellLimit (  ) external;
  // function enableRewardDistribution ( uint256 cycleHours ) external returns ( uint256 );
  // function enableSellLimit (  ) external;
  // function hasAlreadyClaimed ( address holderAddr ) external view returns ( bool );
  // function hasCyclePassed (  ) external view returns ( bool );
  // function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  // function initDEXRouter ( address router ) external;
  // function isDistributionEnabled (  ) external view returns ( bool );
  // function isSellLimitEnabled (  ) external view returns ( bool );
  // function lastCycleResetTimestamp (  ) external view returns ( uint256 );
  // function licensingShare (  ) external view returns ( uint256 );
  // function licensingWallet (  ) external view returns ( address );
  // function liquidityPools ( address ) external view returns ( bool );
  // function marketingShare (  ) external view returns ( uint256 );
  // function marketingWallet (  ) external view returns ( address );
  // function maxSellAllowanceMultiplier (  ) external view returns ( uint256 );
  // function maxSellAllowancePerCycle (  ) external view returns ( uint256 );
  // function maxTxAmount (  ) external view returns ( uint256 );
  // function maxWalletSize (  ) external view returns ( uint256 );
  // function minToBuyback (  ) external view returns ( uint256 );
  // function minToCollateral (  ) external view returns ( uint256 );
  // function minToDistribution (  ) external view returns ( uint256 );
  // function minToExpenses (  ) external view returns ( uint256 );
  // function minToLiquify (  ) external view returns ( uint256 );
  // function name (  ) external pure returns ( string memory );
  // function owner (  ) external view returns ( address );
  // function reflectionFromToken ( uint256 tAmount, bool deductTransferFee ) external view returns ( uint256 );
  // function removeAddressFromLPs ( address lpAddr ) external;
  // function renounceOwnership (  ) external;
  // function restoreAllFees (  ) external;
  // function sellAllowanceLeft (  ) external view returns ( uint256 );
  // function sellCycleHours (  ) external view returns ( uint256 );
  // function setBuybackFee ( uint256 fee ) external;
  // function setCollateralFee ( uint256 fee ) external;
  // function setCollateralWallet ( address wallet ) external;
  // function setDevWallet ( address wallet, uint256 share ) external;
  // function setDistributionFee ( uint256 fee ) external;
  // function setExpensesFee ( uint256 fee ) external;
  // function setLicensingWallet ( address wallet, uint256 share ) external;
  // function setLiquidityFee ( uint256 fee ) external;
  // function setMarketingWallet ( address wallet, uint256 share ) external;
  // function setMaxSellAllowanceMultiplier ( uint256 mult ) external;
  // function setMinToBuyback ( uint256 minTokens ) external;
  // function setMinToCollateral ( uint256 minTokens ) external;
  // function setMinToDistribution ( uint256 minTokens ) external;
  // function setMinToExpenses ( uint256 minTokens ) external;
  // function setMinToLiquify ( uint256 minTokens ) external;
  // function setReflectionFee ( uint256 fee ) external;
  // function setSellCycleHours ( uint256 hoursCycle ) external;
  function specialAddresses ( address ) external view returns ( bool );
  // function symbol (  ) external pure returns ( string memory);
  // function toggleLimitExemptions ( address addr, bool allToggle, bool txToggle, bool walletToggle, bool sellToggle, bool feesToggle ) external;
  // function toggleSpecialWallets ( address specialAddr, bool toggle ) external;
  // function tokenFromReflection ( uint256 rAmount ) external view returns ( uint256 );
  function totalCirculatingSupply (  ) external view returns ( uint256 );
  // function totalClaimed (  ) external view returns ( uint256 );
  // function totalClaimedDuringCycle (  ) external view returns ( uint256 );
  // function totalFees (  ) external view returns ( uint256 );
  // function totalSupply (  ) external pure returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  // function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  // function transferOwnership ( address newOwner ) external;
  // function triggerExpensify (  ) external;
  // function triggerLiquify (  ) external;
  // function triggerSellForBuyback (  ) external;
  // function triggerSellForCollateral (  ) external;
  // function triggerSellForDistribution (  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Percent {

	/**
	* @dev Returns numerator percentage of denominator. Uses precision for rounding.
	* e.x. 350.percent(150, 3), 4, will retun 4286, which is 42.86%
	* e.x. 350.percent(150, 3), 3 will return 429, which is 42.9%
	* e.x. 350.percent(150, 3), 2 will return 43, which is 43%
	@param denominator number which we calculate percentage of
	@param numerator number we calculate percentage for
	@param precision decimal point shift
	*/
	function percent( 
		uint denominator, 
		uint numerator,
		uint precision
	) 
		internal
		pure 
		returns(uint) 
	{
		uint _numerator = numerator * 10 ** (precision + 1);
		// with rounding of last digit
		uint _quotient = ((_numerator / denominator) + 5) / 10;
		return ( _quotient);
	}

	/**
	* @dev Returns a number calculated as a percentage y of value x. 
	* Use scale based on the y.
	* e.x 429.percentOf(350, 1000) will return 150
	* e.x 429.percentOf(350, 10000) will return 15
	*/
	function percentOf(
		uint y, 
		uint x, 
		uint128 scale
	) 
		internal 
		pure 
		returns(uint) 
	{
		uint a = x / scale;
		uint b = x % scale;
		uint c = y / scale;
		uint d = y % scale;
		uint result = a * c * scale + a * d + b * c + b * d / scale;
		return result;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

