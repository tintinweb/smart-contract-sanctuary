// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol"; // required for modifier
import "./Registry.sol";
import "./dapphub/DSProxyFactory.sol";
import "./dapphub/DSProxy.sol";
import "./Config.sol";
import "./LiquityMath.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/IHintHelpers.sol";
import "./interfaces/ISortedTroves.sol";
import "./interfaces/ICollSurplusPool.sol";

/// @title Gatekeeper contract works as a gatekeeper into APUS protocol ecosystem
/// @notice The main motivation of gatekeeper is to give user understandable transaction to sign and to chain common sequence of transactions thus saving gas.
/// @dev It encodes all arguments and calls given user's smart account proxy with any additional arguments
contract Gatekeeper is Ownable, LiquityMath {

	/* solhint-disable var-name-mixedcase */

	/// @notice Registry's contracts IDs
	bytes32 private constant EXECUTOR_ID = keccak256("Executor");
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant AUTHORITY_ID = keccak256("Authority");
	bytes32 private constant PROXY_FACTORY_ID = keccak256("ProxyFactory");

	/// @notice APUS registry address
	address internal immutable registry;


	/// @notice Event raised when a new Smart Account is created. 
	event SmartAccountCreated(
		address owner,
		address smartAccountAddress
	);


	/// @notice Modifier will fail if message sender is not proxy owner
	/// @param _proxy Proxy address that should be owned
	modifier onlyProxyOwner(address payable _proxy) {
		require(DSProxy(_proxy).owner() == msg.sender, "Sender has to be proxy owner");
		_;
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _troveManager,
		address _hintHelpers,
		address _sortedTroves,
		address _collSurplusPool
	) Ownable() {
		registry = _registry;
		TroveManager = ITroveManager(_troveManager);
		HintHelpers = IHintHelpers(_hintHelpers);
		SortedTroves = ISortedTroves(_sortedTroves);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
	}

	/// @notice Execute proxy call with encoded transaction data
	/// @dev Proxy delegates call to executor address which is obtained from registry contract
	/// @param _proxy Proxy address to execute encoded transaction
	/// @param _data Transaction data to execute
	function _execute(address payable _proxy, bytes memory _data) internal onlyProxyOwner(_proxy) {
		_execute(_proxy, 0, _data);
	}

	/// @notice Execute proxy call with encoded transaction data and eth value
	/// @dev Proxy delegates call to executor address which is obtained from registry contract
	/// @param _proxy Proxy address to execute encoded transaction
	/// @param _value Value of eth to transfer with function call
	/// @param _data Transaction data to execute
	function _execute(address payable _proxy, uint256 _value, bytes memory _data) internal onlyProxyOwner(_proxy) {
		DSProxy(_proxy).execute{ value: _value }(Registry(registry).getAddress(EXECUTOR_ID), _data);
	}

	/// @notice Execute proxy call with encoded transaction data and eth value by anyone
	/** 
	 * @dev Proxy delegates call to executor address which is obtained from registry contract
	 *
	 * This is the DANGEROUS version as it enables the proxy call to be performed by anyone!
	 *
	 * However suitable for cases when user wants to provide ETH from other (proxy non-owning) accounts.
	 */
	/// @param _proxy Proxy address to execute encoded transaction
	/// @param _value Value of eth to transfer with function call
	/// @param _data Transaction data to execute
	function _executeByAnyone(address payable _proxy, uint256 _value, bytes memory _data) internal {
		DSProxy(_proxy).execute{ value: _value }(Registry(registry).getAddress(EXECUTOR_ID), _data);
	}

	// Gatekeeper MUST NOT be able to receive ETH from sender to itself
	// in 0.8.x function() is split to receive() and fallback(); if both are undefined -> tx reverts

	// ------------------------------------------ User functions ------------------------------------------


	/// @notice Creates the Smart Account directly. Its new address is emitted to the event.
	/// It is cheaper to open Smart Account while opening Credit Line.
	function openSmartAccount() external {
		_openSmartAccount();
	}

	/// @notice Builds the new MakerDAO's proxy aka Smart Account with enabled calls from this Gatekeeper
	function _openSmartAccount() internal returns (address payable) {

		// Use MakerDAO's proxy factory
		// DSProxyFactory constant internal DSProxyFactory = IDSProxyFactory(0xA26e15C895EFc0616177B7c1e7270A4C7D51C997);
		address proxyFactory = Registry(registry).getAddress(PROXY_FACTORY_ID);
		
		// Deploy a new MakerDAO's proxy onto blockchain
		DSProxy smartAccount = DSProxyFactory(proxyFactory).build();

		// Enable gatekeeper's user functions to call the Smart Account	
		DSAuthority gatekeeperAuthority = DSAuthority(Registry(registry).getAddress(AUTHORITY_ID));
		smartAccount.setAuthority(gatekeeperAuthority); 

		// Set owner of MakerDAO's proxy aka Smart Account to be the user
		smartAccount.setOwner(msg.sender);

		// Emit centraly at this contract
		emit SmartAccountCreated(msg.sender, address(smartAccount));
				
		return payable(smartAccount);
	}


	// L1 Liquity deployed contracts addresses
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	/* solhint-disable const-name-snakecase */
	ITroveManager immutable private TroveManager;
	IHintHelpers immutable private HintHelpers;
	ISortedTroves immutable private SortedTroves;
	ICollSurplusPool immutable private CollSurplusPool;
	/* solhint-enable const-name-snakecase */

	// TODO Liquity contracts on Rinkeby are on different addresses !!!!


	/// @notice Calculates Liquity sorting hints based on the provided NICR
	function getLiquityHints(uint256 NICR) internal view returns (
		address upperHint,
		address lowerHint
	) {
		// Get an approximate address hint from the deployed HintHelper contract.
		uint256 numTroves = SortedTroves.getSize();
		uint256 numTrials = sqrt(numTroves) * 15;
		(address approxHint, , ) = HintHelpers.getApproxHint(NICR, numTrials, 0x41505553);

		// Use the approximate hint to get the exact upper and lower hints from the deployed SortedTroves contract
		(upperHint, lowerHint) = SortedTroves.findInsertPosition(NICR, approxHint, approxHint);
	}

	/// @notice Calculates LUSD expected debt to repay (includes _LUSDRequested, Adoption Contribution, Liquity protocol fee)
	function getLiquityExpectedDebtToRepay(uint256 _LUSDRequested) internal view returns (uint256 expectedDebtToRepay) {
		Config config = Config(Registry(registry).getAddress(CONFIG_ID));
		uint16 acr = config.adoptionContributionRate();

		uint256 expectedLiquityProtocolRate = TroveManager.getBorrowingRateWithDecay();

		uint256 neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequested, expectedLiquityProtocolRate, acr);

		uint256 expectedLiquityProtocolFee = TroveManager.getBorrowingFeeWithDecay(neededLUSDAmount);

		expectedDebtToRepay = neededLUSDAmount + expectedLiquityProtocolFee;
	}

	/// @notice Makes a gasless calculation to get the data for the Credit Line's initial setup on Liquity protocol
    /// @param _LUSDRequested Requested LUSD amount to be taken by borrower. In e18 (1 LUSD = 1e18).
    /// @param _collateralAmount Amount of ETH to be deposited into the Credit Line. In wei (1 ETH = 1e18).
	/// @return expectedDebtToRepay Total amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
    function calculateInitialLiquityParameters(uint256 _LUSDRequested, uint256 _collateralAmount) public view returns (
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		expectedDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequested);

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = _collateralAmount * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);
    }

	/// @notice Makes a gasless calculation to get the data for the Credit Line's adjustement on Liquity protocol
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed. The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution and protocol's fees are applied in the form of additional debt in case of requested debt increase.
	/// @param _isCollateralIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _collateralChange Amount of ETH collateral to be withdrawn or added. The increase or decrease is indicated by _isCollateralIncrease.
	/// @return newCollateral Calculated future collateral.
	/// @return expectedDebtToRepay Total future amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total future debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @dev bools and uints are used to avoid typecasting and overflow issues and to explicitely signal the direction
	function calculateChangedLiquityParameters(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		bool _isCollateralIncrease,
		uint256 _collateralChange,
		address payable _smartAccount
	)  public view returns (
		uint256 newCollateral,
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the current LUSD debt and ETH collateral
		(uint256 currentCompositeDebt, uint256 currentCollateral, , ) = TroveManager.getEntireDebtAndColl(_smartAccount);

		uint256 currentDebtToRepay = currentCompositeDebt - LIQUITY_LUSD_GAS_COMPENSATION;

		if (_isCollateralIncrease) {
			newCollateral = currentCollateral + _collateralChange;
		} else {
			newCollateral = currentCollateral - _collateralChange;
		}

		if (_isDebtIncrease) {
			uint256 additionalDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequestedChange);
			expectedDebtToRepay = currentDebtToRepay + additionalDebtToRepay;
		} else {
			expectedDebtToRepay = currentDebtToRepay - _LUSDRequestedChange;
		}

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = newCollateral * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);

	}

	/// @notice Opens a new Credit Line using Liquity protocol by depositing ETH collateral and borrowing LUSD.
	/// Creates the new Smart Account (MakerDAO's proxy) if requested.
	/// Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _LUSDRequested Amount of LUSD caller wants to borrow and withdraw. In e18 (1 LUSD = 1e18).
	/// @param _LUSDTo Address that will receive the generated LUSD. Can be different to save gas on transfer.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _smartAccount Smart Account address. When 0x0000...00 sender requests to open a new Smart Account.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Value is amount of ETH to deposit into Liquity protocol.
	function openCreditLineLiquity(uint256 _LUSDRequested, address _LUSDTo, address _upperHint, address _lowerHint, address payable _smartAccount) external payable {

		// By submitting 0x00..0 as the smartAccount address the caller wants to open a new Smart Account during this 1 transaction and thus saving gas.
		_smartAccount = (_smartAccount == address(0)) ? _openSmartAccount() : _smartAccount;

		_execute(_smartAccount, msg.value, abi.encodeWithSignature(
			"openCreditLineLiquity(uint256,address,address,address,address)",
			_LUSDRequested, _LUSDTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Allows a borrower to repay all LUSD debt, withdraw all their ETH collateral, and close their Credit Line on Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn ETH.
	/// @param _smartAccount Smart Account address
	function closeCreditLineLiquity(address _LUSDFrom, address payable _collateralTo, address payable _smartAccount) public {

		_execute(_smartAccount, 
			abi.encodeWithSignature(
				"closeCreditLineLiquity(address,address,address)",
				_LUSDFrom,
				_collateralTo, 
				msg.sender
		));

	}

	/// @notice Allows a borrower to repay all LUSD debt, withdraw all their ETH collateral, and close their Credit Line on Liquity protocol.
	/// @param _smartAccount Smart Account address
	/// @dev This is a convenient facade function for borrower to avoid sending ETH to invalid address by mistake. Use the one with all parameters.
	function closeCreditLineLiquity(address payable _smartAccount) external {
		closeCreditLineLiquity(msg.sender, payable(msg.sender), _smartAccount);
	}

	/// @notice Enables a borrower to simultaneously change both their collateral and debt.
	/// Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed.
	///			The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution and protocol's fees are applied in the form of additional debt in case of requested debt increase.
	/// @param _LUSDFrom Address where the LUSD is being pulled from in case of to repaying debt.
	/// 		Approval of LUSD transfers for given Smart Account is required.
	/// @param _LUSDTo Address that will receive the generated LUSD.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDAmount instead of _LUSDRequestedAdditionally
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	function adjustCreditLineLiquity(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		address _LUSDFrom,
		address _LUSDTo,
		uint256 _collWithdrawal,
		address payable _collateralTo,
		address _upperHint, address _lowerHint,
		address payable _smartAccount) external payable {

		_execute(_smartAccount, msg.value, abi.encodeWithSignature(
			"adjustCreditLineLiquity(bool,uint256,address,address,uint256,address,address,address,address)",
			_isDebtIncrease, _LUSDRequestedChange, _LUSDFrom, _LUSDTo, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Gasless check if there is anything to be claimed after the forced closure of the Liquity Credit Line
	function checkClaimableCollateralLiquity(address _smartAccount) external view returns (uint256) {
		return CollSurplusPool.getCollateral(_smartAccount);
	}

	/// @notice Claims remaining collateral from the user's closed Credit Line (Liquity protocol) due to a redemption or a liquidation.
	/// @param _collateralTo Address that will receive the claimed collateral ETH.
	/// @param _smartAccount Smart Account address
	function claimRemainingCollateralLiquity(address payable _collateralTo, address payable _smartAccount) external {
		_execute(_smartAccount, abi.encodeWithSignature(
			"claimRemainingCollateralLiquity(address,address)",
			_collateralTo,
			msg.sender
		));
	}


	/// @notice Allows ANY ADDRESS (calling and paying) to add ETH collateral to borrower's Credit Line (Liquity protocol) and thus increase CR (decrease LTV ratio).
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function addCollateralLiquity(address _upperHint, address _lowerHint, address payable _smartAccount) external payable {

		// Must be executable by anyone in order to be able to provide ETH by addresses, which do not own smart account proxy
		_executeByAnyone(_smartAccount, msg.value, abi.encodeWithSignature(
			"addCollateralLiquity(address,address,address)",
			_upperHint, _lowerHint, msg.sender
		));
	}

	/// @notice Withdraws amount of ETH collateral from the Credit Line and transfer to _collateralTo address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function withdrawCollateralLiquity(uint256 _collWithdrawal, address payable _collateralTo, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_execute(_smartAccount, abi.encodeWithSignature(
			"withdrawCollateralLiquity(uint256,address,address,address,address)",
			_collWithdrawal, _collateralTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Issues amount of LUSD from the liquity's protocol to the provided address.
	/// This increases the debt on the Credit Line, decreases CR (increases LTV).
	/// @param _LUSDRequestedChange Amount of LUSD to further borrow.
	/// @param _LUSDTo Address that will receive the generated LUSD. When 0 msg.sender is used.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated new debt instead of _LUSDRequestedChange
	function borrowLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDTo, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_execute(_smartAccount, abi.encodeWithSignature(
			"borrowLUSDLiquity(uint256,address,address,address,address)",
			_LUSDRequestedChange, _LUSDTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Enables ANYONE (calling and repaying) to partially repay the debt by the given amount of LUSD.
	/// Approval of LUSD transfers for given Smart Account is required.
	/// Use closeCreditLineLiquity to repay whole debt.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid. Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated new debt instead of _LUSDRequestedChange
	function repayLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_executeByAnyone(_smartAccount, 0, abi.encodeWithSignature(
			"repayLUSDLiquity(uint256,address,address,address,address)",
			_LUSDRequestedChange, _LUSDFrom, _upperHint, _lowerHint, msg.sender
		));

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

interface IHintHelpers {

    function getRedemptionHints(
        uint _LUSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedLUSDamount
        );

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed);

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint);

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
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