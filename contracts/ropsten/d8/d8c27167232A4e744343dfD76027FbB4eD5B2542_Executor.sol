// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.10;

import "./Config.sol";
import "./Registry.sol";
import "./dapphub/DSProxyFactory.sol";
import "./CentralLogger.sol";
import "./interfaces/IBorrowerOperations.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/ICollSurplusPool.sol";
import "./interfaces/ILUSDToken.sol";
import "./LiquityMath.sol";

/// @title APUS execution logic
/// @dev Should be called as delegatecall from APUS smart account proxy
contract Executor is LiquityMath{

	// ================================================================================
	// WARNING!!!!
	// Executor must not have or store any stored variables (constant and immutable variables are not stored).
	// It could conflict with proxy storage as it is called via delegatecall from proxy.
	// ================================================================================

	/// @notice Registry's contracts IDs
	bytes32 private constant PROXY_FACTORY_ID = keccak256("ProxyFactory");
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");

	/// @notice APUS registry address
	address internal immutable registry;


	/// @notice Modifier will fail if function is not called within Apus proxy contract
	/// @dev Mofifier gets proxy factory address from Apus registry and checks if current address is valid Apus proxy
	modifier onlyProxy() {
		address proxyFactory = Registry(registry).getAddress(PROXY_FACTORY_ID);
		require(DSProxyFactory(proxyFactory).isProxy(address(this)), "Executor has to be called within valid Proxy");
		_;
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _borrowerOperations,
		address _troveManager,
		address _collSurplusPool,
		address _lusdToken
	) {
		registry = _registry;
		BorrowerOperations = IBorrowerOperations(_borrowerOperations);
		TroveManager = ITroveManager(_troveManager);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
		LUSDToken = ILUSDToken(_lusdToken);
	}

	// ------------------------------------------ Liquity functions ------------------------------------------

	// L1 Liquity deployed contracts addresses
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	/* solhint-disable const-name-snakecase */
	IBorrowerOperations private immutable BorrowerOperations;
	ITroveManager private immutable TroveManager;
	ICollSurplusPool private immutable CollSurplusPool;
    ILUSDToken private immutable LUSDToken;
	/* solhint-enable const-name-snakecase */

	/// @notice Sends LUSD amount from Smart Account to _LUSDTo account. Sends total balance if uint256.max is given as the amount.
	/* solhint-disable-next-line var-name-mixedcase */
	function sendLUSD(address _LUSDTo, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(address(this));
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
        if (_LUSDTo != address(this) && _amount != 0) {
			// LUSDToken.transfer reverts on recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
            LUSDToken.transfer(_LUSDTo, _amount);
		}
	}

	/// @notice Pulls LUSD amount from `_from` address to Smart Account. Pulls total balance if uint256.max is given as the amount.
	function pullLUSDFrom(address _from, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(_from);
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
		if (_from != address(this) && _amount != 0) {
			// function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
			// LUSDToken.transfer reverts on allowance issue, recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
			LUSDToken.transferFrom(_from, address(this), _amount);
		}
	}

	/// @notice Gets the LUSD balance of the account
	function getLUSDBalance(address _acc) internal view returns (uint256) {
		return LUSDToken.balanceOf(_acc);
	}


	/// @notice Open a new credit line using Liquity protocol by depositing ETH collateral and borrowing LUSD.
	/// @dev Value is amount of ETH to deposit into Liquity Trove
	/// @param _LUSDRequestedDebt Amount of LUSD caller wants to borrow and withdraw.
	/// @param _LUSDTo Address that will receive the generated LUSD.
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _caller msg.sender in the gatekeeper
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDAmount instead of _LUSDRequestedDebt
	/* solhint-disable-next-line var-name-mixedcase */
	function openCreditLineLiquity(uint256 _LUSDRequestedDebt, address _LUSDTo, address _upperHint, address _lowerHint, address _caller) external payable onlyProxy {

		// Assertions and relevant reverts are done within Liquity protocol
		// Re-entrancy is avoided by calling the openTrove (cannot open the additional trove for the same smart account)
		
		Config config = Config(Registry(registry).getAddress(CONFIG_ID));

		uint256 mintedLUSD;
		uint256 neededLUSDAmount;
		uint256 expectedLiquityProtocolRate;

		{ // scope to avoid stack too deep errors
			uint16 acr = config.adoptionContributionRate();

			expectedLiquityProtocolRate = TroveManager.getBorrowingRateWithDecay();

			neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequestedDebt, expectedLiquityProtocolRate, acr);

			uint256 previousLUSDBalance = getLUSDBalance(address(this));

			BorrowerOperations.openTrove{value: msg.value}(
				LIQUITY_PROTOCOL_MAX_BORROWING_FEE,
				neededLUSDAmount,
				_upperHint,
				_lowerHint
			);

			mintedLUSD = getLUSDBalance(address(this)) - previousLUSDBalance;
		}

		// Can send only what was minted
		// assert (_LUSDRequestedDebt <= mintedLUSD); // asserts in adoptionContributionLUSD calculation by avoiding underflow
		uint256 adoptionContributionLUSD = mintedLUSD - _LUSDRequestedDebt;

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "openCreditLineLiquity",
			abi.encode(_LUSDRequestedDebt, _LUSDTo, _upperHint, _lowerHint, neededLUSDAmount, mintedLUSD, expectedLiquityProtocolRate)
		);

		// Send LUSD to the Adoption DAO
		sendLUSD(config.adoptionDAOAddress(), adoptionContributionLUSD);

		// Send LUSD to the requested address
		// Must be located at the end to avoid withdrawal by re-entrancy into potential LUSD withdrawal function
		sendLUSD(_LUSDTo, _LUSDRequestedDebt);
	}


	/// @notice Closes the Liquity trove
	/// @param _LUSDfrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _caller msg.sender in the gatekeeper
	/// @dev Closing Liquity Credit Line pulls required LUSD and therefore requires approval on LUSD spending
	/// @dev TODO elaborate potential use of EIP 2612 permit, which LUSD implemented
	/* solhint-disable-next-line var-name-mixedcase */
	function closeCreditLineLiquity(address _LUSDfrom, address payable _collateralTo, address _caller) external onlyProxy {

		uint256 collateral = TroveManager.getTroveColl(address(this));

		// getTroveDebt returns composite debt including 200 LUSD gas compensation
		// Liquity Trove cannot have less than 2000 LUSD total composite debt
		// @dev Substraction is safe since solidity 0.8 reverts on underflow
		uint256 debtToRepay = TroveManager.getTroveDebt(address(this)) - LIQUITY_LUSD_GAS_COMPENSATION;

		// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
		// Pull LUSD from _from (typically EOA) to Smart Account proxy
		pullLUSDFrom(_LUSDfrom, debtToRepay);

		// Closing trove results in ETH to be stored on Smart Account proxy
		BorrowerOperations.closeTrove(); 

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "closeCreditLineLiquity",
			abi.encode(_LUSDfrom, _collateralTo, debtToRepay, collateral)
		);

		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.closeTrove() fails on re-entrancy since Trove would be closed in re-entrancy
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: collateral }("");
		require(success, "Sending collateral ETH failed");

	}

	/// @notice Claims remaining collateral from the user's closed Liquity Trove due to a redemption or a liquidation with ICR > MCR in Recovery Mode
	/// @param _collateralTo Address that will receive the claimed collateral ETH.
	/// @param _caller msg.sender in the gatekeeper
	function claimRemainingCollateralLiquity(address payable _collateralTo, address _caller) external onlyProxy {
		
		uint256 remainingCollateral = CollSurplusPool.getCollateral(address(this));

		// Reverts if there is no collateral to claim 
		BorrowerOperations.claimCollateral();

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "claimRemainingCollateralLiquity",
			abi.encode(_collateralTo, remainingCollateral)
		);

		// Send claimed ETH
		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.claimCollateral() reverts on re-entrancy since there will be no residual collateral to claim
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: remainingCollateral }("");
		require(success, "Sending of claimed collateral failed.");
	}

	/// @notice Allows to add ETH collateral to borrower's Credit line (Liquity Trove) and thus increase CR (decrease LTV ratio).
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function addCollateralLiquity(address _upperHint, address _lowerHint) external payable onlyProxy {
		BorrowerOperations.addColl{value: msg.value}(_upperHint, _lowerHint);
	}



}

// SPDX-License-Identifier: GNU-3
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title APUS config contract
/// @notice Holds global variables for the rest of APUS ecosystem
contract Config is Ownable {

	/// @notice Adoption Contribution Rate, where 100% = 10000 = ACR_DECIMAL_PRECISION. 
	/// @dev Percent value where 0 -> 0%, 10 -> 0.1%, 100 -> 1%, 250 -> 2.5%, 550 -> 5.5%, 1000 -> 10%, 0xffff -> 655.35%
	/// @dev Example: x * adoptionContributionRate / ACR_DECIMAL_PRECISION
	uint16 public adoptionContributionRate;

	/// @notice Adoption DAO multisig address
	address payable public adoptionDAOAddress;

	/// @notice Emit when owner changes Adoption Contribution Rate
	/// @param caller Who changed the Adoption Contribution Rate (i.e. who was owner at that moment)
	/// @param previousACR Previous Adoption Contribution Rate
	/// @param newACR New Adoption Contribution Rate
	event ACRChanged(address indexed caller, uint16 previousACR, uint16 newACR);

	/// @notice Emit when owner changes Adoption DAO address
	/// @param caller Who changed the Adoption DAO address (i.e. who was owner at that moment)
	/// @param previousAdoptionDAOAddress Previous Adoption DAO address
	/// @param newAdoptionDAOAddress New Adoption DAO address
	event AdoptionDAOAddressChanged(address indexed caller, address previousAdoptionDAOAddress, address newAdoptionDAOAddress);

	/* solhint-disable-next-line func-visibility */
	constructor(address payable _adoptionDAOAddress, uint16 _initialACR) Ownable() {
		adoptionContributionRate = _initialACR;
		adoptionDAOAddress = _adoptionDAOAddress;
	}


	/// @notice Change Adoption Contribution Rate
	/// @dev Only owner can change Adoption Contribution Rate
	/// @dev Emits `ACRChanged` event
	/// @param _newACR Adoption Contribution Rate
	function setAdoptionContributionRate(uint16 _newACR) external onlyOwner {
		uint16 _previousACR = adoptionContributionRate;
		adoptionContributionRate = _newACR;
		emit ACRChanged(msg.sender, _previousACR, _newACR);
	}

	/// @notice Change Adoption DAO address
	/// @dev Only owner can change Adoption DAO address
	/// @dev Emits `AdoptionDAOAddressChanged` event
	function setAdoptionDAOAddress(address payable _newAdoptionDAOAddress) external onlyOwner {
		address payable _previousAdoptionDAOAddress = adoptionDAOAddress;
		adoptionDAOAddress = _newAdoptionDAOAddress;
		emit AdoptionDAOAddressChanged(msg.sender, _previousAdoptionDAOAddress, _newAdoptionDAOAddress);
	}

}

// SPDX-License-Identifier: GNU-3
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Registry contract for whole Apus ecosystem
/// @notice Holds addresses of all essential Apus contracts
contract Registry is Ownable {

	/// @notice Stores address under its id
	/// @dev Id is keccak256 hash of its string representation
	mapping (bytes32 => address) public addresses;

	/// @notice Emit when owner registers address
	/// @param id Keccak256 hash of its string id representation
	/// @param previousAddress Previous address value under given id
	/// @param newAddress New address under given id
	event AddressRegistered(bytes32 indexed id, address indexed previousAddress, address indexed newAddress);


	constructor() Ownable() {

	}


	/// @notice Getter for registered addresses
	/// @dev Returns zero address if address have not been registered before
	/// @param _id Registered address identifier
	function getAddress(bytes32 _id) external view returns(address) {
		return addresses[_id];
	}


	/// @notice Register address under given id
	/// @dev Only owner can register addresses
	/// @dev Emits `AddressRegistered` event
	/// @param _id Keccak256 hash of its string id representation
	/// @param _address Registering address
	function registerAddress(bytes32 _id, address _address) external onlyOwner {
		require(_address != address(0), "Registered address cannot be zero address");
		address _previousAddress = addresses[_id];
		addresses[_id] = _address;
		emit AddressRegistered(_id, _previousAddress, _address);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./DSProxy.sol";

abstract contract DSProxyFactory {
    function build(address owner) public virtual returns (DSProxy proxy);
    function build() public virtual returns (DSProxy proxy);
    function isProxy(address proxy) public virtual view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

/// @title Central logger contract
/// @notice Log collector with only 1 purpose - to emit the event. Can be called from any contract
/** @dev Use like this:
*
* bytes32 internal constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
* address centralLoggerAddress = Registry(registry).getAddress(CENTRAL_LOGGER_ID);
* CentralLogger internal constant logger = CentralLogger(centralLoggerAddress);
*
* Or directly:
*   CentralLogger internal constant logger = CentralLogger(0xDEPLOYEDADDRESS);
*
* logger.log(
*            address(this),
*            msg.sender,
*            "openCreditLine",
*            abi.encode(msg.value, param1, param2)
*        );
*
* DO NOT USE delegateCall as it defies the centralisation purpose of this logger.
*/
contract CentralLogger {

	/// @notice Contracts' registry address
	address private immutable registry;

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

	/* solhint-disable-next-line func-visibility */
	constructor(address _registry) {
		registry = _registry;
	}

    /// @notice Log the event centraly
    /// @dev For gas impact see https://www.evm.codes/#a3
    /// @param _logName length must be less than 32 bytes
    function log(
        address _contract,
        address _caller,
        string memory _logName,
        bytes memory _data
    ) public {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

// Common interface for the Liquity Trove management.
interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;


// Common interface for the Trove Manager.
interface ITroveManager {
    
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;


interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event EtherSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC2612.sol";

interface ILUSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BaseMath.sol";

/// @title Business calculation logic related to the Liquity protocol
/// @dev To be inherited only
contract LiquityMath is BaseMath {

    // Maximum protocol fee as defined in the Liquity contracts
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L48
    uint256 internal constant LIQUITY_PROTOCOL_MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // Amount of LUSD to be locked in Liquity's gas pool on opening troves
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L334
    uint256 internal constant LIQUITY_LUSD_GAS_COMPENSATION = 200e18;

	/// @notice Calculates the needed amount of LUSD parameter for Liquity protocol when borrowing LUSD
    /// @param _LUSDRequestedAmount Amount the user wants to withdraw
    /// @param _expectedLiquityProtocolRate Current / expected borrowing rate of the Liquity protocol
    /// @param _adoptionContributionRate Adoption Contribution Rate in uint16 form (xxyy defines xx.yy %). LPR is applied when ACR < LPR. Thus LPR is always used When AR is set to 0.
    /* solhint-disable-next-line var-name-mixedcase */
    function calcNeededLiquityLUSDAmount(uint256 _LUSDRequestedAmount, uint256 _expectedLiquityProtocolRate, uint16 _adoptionContributionRate) internal pure returns (
        uint256 neededLiquityLUSDAmount
    ) {

        // Normalise ACR 1e4 -> 1e18
        uint256 acr = DECIMAL_PRECISION / ACR_DECIMAL_PRECISION * _adoptionContributionRate;

        // Apply Liquity protocol rate when ACR is lower
        acr = acr < _expectedLiquityProtocolRate ? _expectedLiquityProtocolRate : acr;

        // Includes requested debt and adoption contribution which covers also liquity protocol fee
        uint256 expectedDebtToRepay = _LUSDRequestedAmount * acr / DECIMAL_PRECISION + _LUSDRequestedAmount;

        // = x / ( 1 + fee rate<0.005 - 0.05> )
        neededLiquityLUSDAmount = DECIMAL_PRECISION * expectedDebtToRepay / ( DECIMAL_PRECISION + _expectedLiquityProtocolRate ); 

        // Cannot mint less than requested.
        assert(neededLiquityLUSDAmount >= _LUSDRequestedAmount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./DSAuth.sol";

abstract contract DSProxy is DSAuth {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) {
        require(setCache(_cacheAddr), "Cache not set");
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        virtual
        returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public payable virtual returns (bool);
}

abstract contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view virtual returns (address);

    function write(bytes memory _code) public virtual returns (address target);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./DSAuthority.sol";

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

abstract contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public virtual;

    function setAuthority(DSAuthority authority_) public virtual;

    function isAuthorized(address src, bytes4 sig) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

abstract contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BaseMath {

    /// @notice Constant for the fractional arithmetics. Similar to 1 ETH = 1e18 wei.
    uint256 constant internal DECIMAL_PRECISION = 1e18;

    /// @notice Constant for the fractional arithmetics with ACR.
    uint256 constant internal ACR_DECIMAL_PRECISION = 1e4;

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    // source: https://github.com/paulrberg/prb-math/blob/86c068e21f9ba229025a77b951bd3c4c4cf103da/contracts/PRBMath.sol#L591
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

}