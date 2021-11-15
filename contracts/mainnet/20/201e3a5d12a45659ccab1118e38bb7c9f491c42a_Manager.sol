// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/access/OwnableUpgradeable.sol";
import "../openzeppelin/proxy/utils/Initializable.sol";
import "./Registry.sol";
import "./TokenFactory.sol";

/**
 * FOR THE AUDITOR
 * This contract was designed with the idea that it would be owned by
 * another multi-party governance-like contract such as a multi-sig
 * or a yet-to-be researched governance protocol to be placed on top of
 */

/**
 * @title Manager contract for receiving proposals and creating tokens
 * @dev For receiving token proposals and creating said tokens from such parameters.
 * @dev State is separated onto Registry contract
 * @dev To set up a working version of the entire platform, first create TokenFactory,
 * Registry, then transfer ownership to the Manager contract. Ensure as well that TokenVesting is
 * created for a valid TokenFactory. See the hardhat
 * test, especially test/manager.js to understand how this would be done offline.
 */
contract Manager is Initializable, OwnableUpgradeable {
	using SafeMath for uint256;

	Registry public RegistryInstance;
	TokenFactory public TokenFactoryInstance;

	event LogTokenFactoryChanged(address oldTF, address newTF);
	event LogRegistryChanged(address oldR, address newR);
	event LogManagerMigrated(address indexed newManager);

	/**
	 * @dev Constructor on Manager
	 * @param _registry address Address of Registry contract
	 * @param _tokenFactory address Address of TokenFactory contract
	 * @notice It is recommended that all the component contracts be launched before Manager
	 */
	function initialize(address _registry, address _tokenFactory)
		public
		initializer
	{
		require(
			_registry != address(0) && _tokenFactory != address(0),
			"Params can't be ZERO"
		);
		__Ownable_init();
		TokenFactoryInstance = TokenFactory(_tokenFactory);
		RegistryInstance = Registry(_registry);
	}

	/**
	 * @dev Submit Token Proposal
	 * @param _name string Name parameter of Token
	 * @param _symbol string Symbol parameter of Token
	 * @param _decimals uint8 Decimals parameter of Token, restricted to < 18
	 * @param _totalSupply uint256 Total Supply paramter of Token
	 * @param _initialPercentage uint8 Initial percentage of total supply that the Vesting Beneficiary will receive from launch, restricted to < 100
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for, restricted to > 1
	 * @param _vestingBeneficiary address Address of the Vesting Beneficiary
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return hashIndex bytes32 Hash Index which is composed by the keccak256(name, symbol, msg.sender)
	 */

	function submitProposal(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		uint8 _initialPlatformPercentage
	)
		public
		validatePercentage(_initialPercentage)
		validatePercentage(_initialPlatformPercentage)
		validateDecimals(_decimals)
		isInitialized()
		returns (bytes32 hashIndex)
	{
		hashIndex = RegistryInstance.submitProposal(
			_name,
			_symbol,
			_decimals,
			_totalSupply,
			_initialPercentage,
			_vestingPeriodInDays,
			_vestingBeneficiary,
			msg.sender,
			_initialPlatformPercentage
		);
	}

	function submitReferral(
		bytes32 _hashIndex,
		address _referral,
		uint8 _referralPercentage
	) public validatePercentage(_referralPercentage) isInitialized() {
		RegistryInstance.submitProposalReferral(
			_hashIndex,
			_referral,
			_referralPercentage
		);
	}

	/**
	 * @dev Approve Token Proposal
	 * @param _hashIndex bytes32 Hash Index of Token Proposal, given by keccak256(name, symbol, msg.sender)
	 */
	function approveProposal(bytes32 _hashIndex)
		external
		isInitialized()
		onlyOwner
	{
		Registry.Creator memory approvedProposal =
			RegistryInstance.getCreatorByIndex(_hashIndex);

		Registry.CreatorReferral memory approvedProposalReferral =
			RegistryInstance.getCreatorReferralByIndex(_hashIndex);

		uint16 initialPercentage =
			uint16(approvedProposal.initialPercentage) +
				uint16(approvedProposal.initialPlatformPercentage) +
				uint16(approvedProposalReferral.referralPercentage);
		require(
			initialPercentage <= uint16(type(uint8).max),
			"Invalid uint8 value"
		);
		validatePercentageFunc(uint8(initialPercentage));

		address ac =
			TokenFactoryInstance.createToken(
				approvedProposal.name,
				approvedProposal.symbol,
				approvedProposal.decimals,
				approvedProposal.totalSupply,
				approvedProposal.initialPercentage,
				approvedProposal.vestingPeriodInDays,
				approvedProposal.vestingBeneficiary,
				approvedProposal.initialPlatformPercentage,
				approvedProposalReferral.referral,
				approvedProposalReferral.referralPercentage
			);
		bool success = RegistryInstance.approveProposal(_hashIndex, ac);
		require(success, "Registry approve proposal has to succeed");
	}

	/*
	 * CHANGE PLATFORM VARIABLES AND INSTANCES
	 */

	function setPlatformWallet(address _newPlatformWallet)
		external
		onlyOwner
		isInitialized()
	{
		TokenFactoryInstance.setPlatformWallet(_newPlatformWallet);
	}

	/*
	 * CHANGE VESING BENEFICIARY
	 */

	function setVestingAddress(address _token, address _vestingBeneficiary)
		public
	{
		require(
			_vestingBeneficiary != address(0),
			"MANAGER: beneficiary can not be zero"
		);
		TokenFactoryInstance.setVestingAddress(
			msg.sender,
			_token,
			_vestingBeneficiary
		);
	}

	function setVestingReferral(address _token, address _vestingReferral)
		public
	{
		require(
			_vestingReferral != address(0),
			"MANAGER: beneficiary can not be zero"
		);
		TokenFactoryInstance.setVestingReferral(
			msg.sender,
			_token,
			_vestingReferral
		);
	}

	// --------------------------------------------
	// This are to keep compatibility with Owner version sol050
	// --------------------------------------------
	function parseAddr(bytes memory data) public pure returns (address parsed) {
		assembly {
			parsed := mload(add(data, 32))
		}
	}

	function getTokenVestingStatic(address tokenFactoryContract)
		internal
		view
		returns (address)
	{
		bytes memory callcodeTokenVesting =
			abi.encodeWithSignature("getTokenVesting()");
		(bool success, bytes memory returnData) =
			address(tokenFactoryContract).staticcall(callcodeTokenVesting);
		require(
			success,
			"input address has to be a valid TokenFactory contract"
		);
		return parseAddr(returnData);
	}

	// --------------------------------------------
	// --------------------------------------------

	function setTokenFactory(address _newTokenFactory) external onlyOwner {
		require(
			OwnableUpgradeable(_newTokenFactory).owner() == address(this),
			"new TokenFactory has to be owned by Manager"
		);
		require(
			getTokenVestingStatic(_newTokenFactory) ==
				address(TokenFactoryInstance.TokenVestingInstance()),
			"TokenVesting has to be the same"
		);
		TokenFactoryInstance.migrateTokenFactory(_newTokenFactory);
		require(
			OwnableUpgradeable(getTokenVestingStatic(_newTokenFactory))
				.owner() == address(_newTokenFactory),
			"TokenFactory does not own TokenVesting"
		);
		emit LogTokenFactoryChanged(
			address(TokenFactoryInstance),
			address(_newTokenFactory)
		);
		TokenFactoryInstance = TokenFactory(_newTokenFactory);
	}

	function setRegistry(address _newRegistry) external onlyOwner {
		require(
			OwnableUpgradeable(_newRegistry).owner() == address(this),
			"new Registry has to be owned by Manager"
		);
		emit LogRegistryChanged(address(RegistryInstance), _newRegistry);
		RegistryInstance = Registry(_newRegistry);
	}

	function setTokenVesting(address _newTokenVesting) external onlyOwner {
		TokenFactoryInstance.setTokenVesting(_newTokenVesting);
	}

	function migrateManager(address _newManager)
		external
		onlyOwner
		isInitialized()
	{
		RegistryInstance.transferOwnership(_newManager);
		TokenFactoryInstance.transferOwnership(_newManager);
		emit LogManagerMigrated(_newManager);
	}

	function validatePercentageFunc(uint8 percentage) internal pure {
		require(
			percentage >= 0 && percentage <= 100,
			"has to be above 0 and below 100"
		);
	}

	modifier validatePercentage(uint8 percentage) {
		require(
			percentage >= 0 && percentage <= 100,
			"has to be above 0 and below 100"
		);
		_;
	}

	modifier validateDecimals(uint8 decimals) {
		require(
			decimals >= 0 && decimals <= 18,
			"has to be above or equal 0 and below 19"
		);
		_;
	}

	modifier isInitialized() {
		require(initialized(), "manager not initialized");
		_;
	}

	function initialized() public view returns (bool) {
		address tokenVestingInstance =
			address(TokenFactoryInstance.TokenVestingInstance());
		return
			(RegistryInstance.owner() == address(this)) &&
			(TokenFactoryInstance.owner() == address(this));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	function __Ownable_init() internal initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal initializer {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
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

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.7.0;

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
		require(
			_initializing || !_initialized,
			"Initializable: contract is already initialized"
		);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/proxy/utils/Initializable.sol";
import "../openzeppelin/access/OwnableUpgradeable.sol";
import "./ILegacyRegistry.sol";

/**
 * @title Registry contract for storing token proposals
 * @dev For storing token proposals. This can be understood as a state contract with minimal CRUD logic.
 */
contract Registry is Initializable, OwnableUpgradeable {
	struct Creator {
		address token;
		string name;
		string symbol;
		uint256 totalSupply;
		uint256 vestingPeriodInDays;
		address proposer;
		address vestingBeneficiary;
		uint8 initialPlatformPercentage;
		uint8 decimals;
		uint8 initialPercentage;
		bool approved;
	}

	struct CreatorReferral {
		address referral;
		uint8 referralPercentage;
	}

	mapping(bytes32 => Creator) public rolodex;
	mapping(bytes32 => CreatorReferral) public creatorReferral;
	mapping(string => bytes32) nameToIndex;
	mapping(string => bytes32) symbolToIndex;

	address legacyRegistry;

	event LogProposalSubmit(
		string name,
		string symbol,
		address proposer,
		bytes32 indexed hashIndex
	);

	event LogProposalReferralSubmit(
		address referral,
		uint8 referralPercentage,
		bytes32 indexed hashIndex
	);

	event LogProposalImported(
		string name,
		string symbol,
		address proposer,
		bytes32 indexed hashIndex
	);
	event LogProposalApprove(string name, address indexed tokenAddress);

	function initialize() public initializer {
		__Ownable_init();
	}

	/**
	 * @dev Submit token proposal to be stored, only called by Owner, which is set to be the Manager contract
	 * @param _name string Name of token
	 * @param _symbol string Symbol of token
	 * @param _decimals uint8 Decimals of token
	 * @param _totalSupply uint256 Total Supply of token
	 * @param _initialPercentage uint8 Initial Percentage of total supply to Vesting Beneficiary
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for
	 * @param _vestingBeneficiary address Address of Vesting Beneficiary
	 * @param _proposer address Address of Proposer of Token, also the msg.sender of function call in Manager contract
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return hashIndex bytes32 It will return a hash index which is calculated as keccak256(_name, _symbol, _proposer)
	 */
	function submitProposal(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		address _proposer,
		uint8 _initialPlatformPercentage
	) public onlyOwner returns (bytes32 hashIndex) {
		nameDoesNotExist(_name);
		symbolDoesNotExist(_symbol);
		hashIndex = keccak256(abi.encodePacked(_name, _symbol, _proposer));
		rolodex[hashIndex] = Creator({
			token: address(0),
			name: _name,
			symbol: _symbol,
			decimals: _decimals,
			totalSupply: _totalSupply,
			proposer: _proposer,
			vestingBeneficiary: _vestingBeneficiary,
			initialPercentage: _initialPercentage,
			vestingPeriodInDays: _vestingPeriodInDays,
			approved: false,
			initialPlatformPercentage: _initialPlatformPercentage
		});

		emit LogProposalSubmit(_name, _symbol, msg.sender, hashIndex);
	}

	function submitProposalReferral(
		bytes32 _hashIndex,
		address _referral,
		uint8 _referralPercentage
	) public onlyOwner {
		creatorReferral[_hashIndex] = CreatorReferral({
			referral: _referral,
			referralPercentage: _referralPercentage
		});
		emit LogProposalReferralSubmit(
			_referral,
			_referralPercentage,
			_hashIndex
		);
	}

	/**
	 * @dev Approve token proposal, only called by Owner, which is set to be the Manager contract
	 * @param _hashIndex bytes32 Hash Index of Token proposal
	 * @param _token address Address of Token which has already been launched
	 * @return bool Whether it has completed the function
	 * @dev Notice that the only things that have changed from an approved proposal to one that is not
	 * is simply the .token and .approved object variables.
	 */
	function approveProposal(bytes32 _hashIndex, address _token)
		external
		onlyOwner
		returns (bool)
	{
		Creator memory c = rolodex[_hashIndex];
		nameDoesNotExist(c.name);
		symbolDoesNotExist(c.symbol);
		rolodex[_hashIndex].token = _token;
		rolodex[_hashIndex].approved = true;
		nameToIndex[c.name] = _hashIndex;
		symbolToIndex[c.symbol] = _hashIndex;
		emit LogProposalApprove(c.name, _token);
		return true;
	}

	//Getters

	function getIndexByName(string memory _name) public view returns (bytes32) {
		return nameToIndex[_name];
	}

	function getIndexBySymbol(string memory _symbol)
		public
		view
		returns (bytes32)
	{
		return symbolToIndex[_symbol];
	}

	function getCreatorByIndex(bytes32 _hashIndex)
		external
		view
		returns (Creator memory)
	{
		return rolodex[_hashIndex];
	}

	function getCreatorReferralByIndex(bytes32 _hashIndex)
		external
		view
		returns (CreatorReferral memory)
	{
		return creatorReferral[_hashIndex];
	}

	function getCreatorByName(string memory _name)
		external
		view
		returns (Creator memory)
	{
		bytes32 _hashIndex = nameToIndex[_name];
		return rolodex[_hashIndex];
	}

	function getCreatorBySymbol(string memory _symbol)
		external
		view
		returns (Creator memory)
	{
		bytes32 _hashIndex = symbolToIndex[_symbol];
		return rolodex[_hashIndex];
	}

	//Assertive functions

	function nameDoesNotExist(string memory _name) internal view {
		require(nameToIndex[_name] == 0x0, "Name already exists");
	}

	function symbolDoesNotExist(string memory _name) internal view {
		require(symbolToIndex[_name] == 0x0, "Symbol already exists");
	}

	// Import functions
	function importByIndex(bytes32 _hashIndex, address _oldRegistry)
		external
		onlyOwner
	{
		Registry old = Registry(_oldRegistry);
		Creator memory proposal = old.getCreatorByIndex(_hashIndex);
		nameDoesNotExist(proposal.name);
		symbolDoesNotExist(proposal.symbol);

		rolodex[_hashIndex] = proposal;
		if (proposal.approved) {
			nameToIndex[proposal.name] = _hashIndex;
			symbolToIndex[proposal.symbol] = _hashIndex;
		}
		emit LogProposalImported(
			proposal.name,
			proposal.symbol,
			proposal.proposer,
			_hashIndex
		);
	}

	// Legacy registry tools

	function setLegacyRegistryAddress(address _legacyRegistry)
		external
		onlyOwner
	{
		legacyRegistry = _legacyRegistry;
	}

	function legacyProposalsByIndex(bytes32 hashIndex)
		external
		view
		returns (Creator memory)
	{
		ILegacyRegistry legacy = ILegacyRegistry(legacyRegistry);
		ILegacyRegistry.Creator memory legacyCreator =
			legacy.rolodex(hashIndex);
		Creator memory creator =
			Creator({
				token: legacyCreator.token,
				name: legacyCreator.name,
				symbol: legacyCreator.symbol,
				decimals: legacyCreator.decimals,
				totalSupply: legacyCreator.totalSupply,
				proposer: legacyCreator.proposer,
				vestingBeneficiary: legacyCreator.vestingBeneficiary,
				initialPercentage: legacyCreator.initialPercentage,
				vestingPeriodInDays: legacyCreator.vestingPeriodInWeeks * 7,
				approved: legacyCreator.approved,
				initialPlatformPercentage: 0
			});

		return creator;
	}

	function legacyProposals(string memory _name)
		external
		view
		returns (Creator memory)
	{
		ILegacyRegistry legacy = ILegacyRegistry(legacyRegistry);
		bytes32 hashIndex = legacy.getIndexSymbol(_name);
		return this.legacyProposalsByIndex(hashIndex);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/proxy/utils/Initializable.sol";
import "../openzeppelin/access/OwnableUpgradeable.sol";
import "../openzeppelin/utils/math/SafeMath.sol";

import "../token/SocialMoney.sol";
import "./ITokenVesting.sol";

/**
 * @title TokenFactory contract for creating tokens from token proposals
 * @dev For creating tokens from pre-set parameters. This can be understood as a contract factory.
 */
contract TokenFactory is Initializable, OwnableUpgradeable {
	using SafeMath for uint256;

	address public rollWallet;
	ITokenVesting public TokenVestingInstance;

	event LogTokenCreated(
		string name,
		string symbol,
		address indexed token,
		address vestingBeneficiary
	);

	// ===============================
	// Aux functions
	// ===============================
	function calculateProportions(
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint8 _initialPlatformPercentage,
		uint8 _referralPercentage
	) public pure returns (uint256[4] memory proportions) {
		proportions[0] = (_totalSupply).mul(_initialPercentage).div(100); //Initial Supply to Creator
		proportions[1] = 0; //Supply to Platform
		proportions[3] = 0; //Supply to Referral
		proportions[2] = (_totalSupply).sub(proportions[0]); // Remaining Supply to vest on
	}

	function validateProportions(
		uint256[4] memory proportions,
		uint256 _totalSupply
	) private pure {
		require(
			proportions[0].add(proportions[1]).add(proportions[2]).add(
				proportions[3]
			) == _totalSupply,
			"The supply must be same as the proportion, sanity check."
		);
	}

	function validateTokenVestingOwner(address a1, address a2) public view {
		require(
			OwnableUpgradeable(a1).owner() == a2,
			"new TokenVesting not owned by TokenFactory"
		);
	}

	/**
	 * @dev Scale some percentages to a new 100%
	 * @dev Calculates the percentage of each param as part of a total. If all are zero consider the first one as a 100%.
	 */
	function scalePercentages(
		uint256 _totalSupply,
		uint8 p0,
		uint8 p1,
		uint8 p2
	) public pure returns (uint256[3] memory proportions) {
		uint256 _vestingSupply = _totalSupply.sub(
			(_totalSupply).mul(p0).div(100)
		);

		proportions[1] = 0;
		proportions[2] = 0;
		if (p1 > 0) {
			proportions[1] = _totalSupply.mul(p1).div(100);
		}
		if (p2 > 0) {
			proportions[2] = _totalSupply.mul(p2).div(100);
		}
		proportions[0] = _vestingSupply.sub(proportions[1]).sub(proportions[2]);
	}

	/**
	 * @dev Constructor method
	 * @param _tokenVesting address Address of tokenVesting contract. If set to address(0), it will create one instead.
	 * @param _rollWallet address Roll Wallet address for sending out proportion of tokens alloted to it.
	 */
	function initialize(address _tokenVesting, address _rollWallet)
		public
		initializer
	{
		require(
			_rollWallet != address(0),
			"Roll Wallet address must be non zero"
		);
		__Ownable_init();
		rollWallet = _rollWallet;
		TokenVestingInstance = ITokenVesting(_tokenVesting);
	}

	/**
	 * @dev Create token method
	 * @param _name string Name parameter of Token
	 * @param _symbol string Symbol parameter of Token
	 * @param _decimals uint8 Decimals parameter of Token, restricted to < 18
	 * @param _totalSupply uint256 Total Supply paramter of Token
	 * @param _initialPercentage uint8 Initial percentage of total supply that the Vesting Beneficiary will receive from launch, restricted to < 100
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for, restricted to > 1
	 * @param _vestingBeneficiary address Address of the Vesting Beneficiary
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return token address Address of token that has been created by those parameters
	 */
	function createToken(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		uint8 _initialPlatformPercentage,
		address _referral,
		uint8 _referralPercentage
	) public onlyOwner returns (address token) {
		uint256 totalPerc =
			uint256(_initialPercentage)
				.add(uint256(_initialPlatformPercentage))
				.add(uint256(_referralPercentage));

		require(
			_initialPercentage == 100 ||
				(_initialPercentage < 100 && _vestingPeriodInDays > 0),
			"Not valid vesting percentage"
		);

		uint256[4] memory proportions =
			calculateProportions(
				_totalSupply,
				_initialPercentage,
				_initialPlatformPercentage,
				_referralPercentage
			);
		validateProportions(proportions, _totalSupply);
		SocialMoney sm =
			new SocialMoney(
				_name,
				_symbol,
				_decimals,
				proportions,
				_vestingBeneficiary,
				rollWallet,
				address(TokenVestingInstance),
				_referral
			);

		if (_vestingPeriodInDays > 0) {
			TokenVestingInstance.addToken(
				address(sm),
				[_vestingBeneficiary, rollWallet, _referral],
				scalePercentages(
					_totalSupply,
					_initialPercentage,
					_initialPlatformPercentage,
					_referralPercentage
				),
				_vestingPeriodInDays
			);
		}
		token = address(sm);
		emit LogTokenCreated(_name, _symbol, address(sm), _vestingBeneficiary);
	}

	function setPlatformWallet(address _newPlatformWallet) external onlyOwner {
		require(_newPlatformWallet != address(0), "Wallet can't be ZERO");
		rollWallet = _newPlatformWallet;
	}

	function migrateTokenFactory(address _newTokenFactory) external onlyOwner {
		OwnableUpgradeable(address(TokenVestingInstance)).transferOwnership(
			_newTokenFactory
		);
	}

	function setTokenVesting(address _newTokenVesting) external onlyOwner {
		validateTokenVestingOwner(_newTokenVesting, address(this));
		TokenVestingInstance = ITokenVesting(_newTokenVesting);
	}

	function getTokenVesting() external view returns (address) {
		return address(TokenVestingInstance);
	}

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external onlyOwner {
		TokenVestingInstance.setVestingAddress(
			_vestingBeneficiary,
			_token,
			_newVestingBeneficiary
		);
	}

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external onlyOwner {
		TokenVestingInstance.setVestingReferral(
			_vestingBeneficiary,
			_token,
			_vestingReferral
		);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/utils/Initializable.sol";

/*
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

	function __Context_init_unchained() internal initializer {}

	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}

	uint256[50] private __gap;
}

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title LegacyRegistry contract interface
 * @dev Just for to have the interface to read old contracts
 */

interface ILegacyRegistry {
	struct Creator {
		address token;
		string name;
		string symbol;
		uint8 decimals;
		uint256 totalSupply;
		address proposer;
		address vestingBeneficiary;
		uint8 initialPercentage;
		uint256 vestingPeriodInWeeks;
		bool approved;
	}

	function rolodex(bytes32) external view returns (Creator memory);

	function getIndexSymbol(string memory _symbol)
		external
		view
		returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		uint256 c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b > a) return (false, 0);
		return (true, a - b);
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) return (true, 0);
		uint256 c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a / b);
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a % b);
	}

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
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
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
		if (a == 0) return 0;
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
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
		require(b > 0, "SafeMath: division by zero");
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting when dividing by zero.
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
		require(b > 0, "SafeMath: modulo by zero");
		return a % b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {trySub}.
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
		return a - b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryDiv}.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting with custom message when dividing by zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryMod}.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
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
		require(b > 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title Template contract for social money, to be used by TokenFactory
 */

contract SocialMoney is ERC20 {
	using SafeMath for uint256;

	/**
     * @dev Constructor on SocialMoney
     * @param _name string Name parameter of Token
     * @param _symbol string Symbol parameter of Token
     * @param _decimals uint8 Decimals parameter of Token
     * @param _proportions uint256[3] Parameter that dictates how totalSupply will be divvied up,
                            _proportions[0] = Vesting Beneficiary Initial Supply
                            _proportions[1] = Roll Supply
                            _proportions[2] = Vesting Beneficiary Vesting Supply
							_proportions[3] = Referral
     * @param _vestingBeneficiary address Address of the Vesting Beneficiary
     * @param _platformWallet Address of Roll platform wallet
     * @param _tokenVestingInstance address Address of Token Vesting contract
	 * @param _referral Roll 1.5
     */
	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256[4] memory _proportions,
		address _vestingBeneficiary,
		address _platformWallet,
		address _tokenVestingInstance,
		address _referral
	) ERC20(_name, _symbol) {
		_setupDecimals(_decimals);

		uint256 totalProportions =
			_proportions[0].add(_proportions[1]).add(_proportions[2]).add(
				_proportions[3]
			);

		_mint(_vestingBeneficiary, _proportions[0]);
		_mint(_platformWallet, _proportions[1]);
		_mint(_tokenVestingInstance, _proportions[2]);
		if (_referral != address(0)) {
			_mint(_referral, _proportions[3]);
		}

		//Sanity check that the totalSupply is exactly where we want it to be
		require(totalProportions == totalSupply(), "Error on totalSupply");
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

interface ITokenVesting {
	event Released(
		address indexed token,
		address vestingBeneficiary,
		uint256 amount
	);
	event LogTokenAdded(
		address indexed token,
		address vestingBeneficiary,
		uint256 vestingPeriodInDays
	);

	event LogBeneficiaryUpdated(
		address indexed token,
		address vestingBeneficiary
	);

	struct VestingInfo {
		address vestingBeneficiary;
		uint256 totalBalance;
		uint256 beneficiariesCount;
		uint256 start;
		uint256 stop;
	}

	struct Beneficiary {
		address beneficiary;
		uint256 proportion;
		uint256 streamId;
		uint256 remaining;
	}

	function addToken(
		address _token,
		address[3] calldata _beneficiaries,
		uint256[3] calldata _proportions,
		uint256 _vestingPeriodInDays
	) external;

	function release(address _token, address _beneficiary) external;

	function releaseableAmount(address _token) external view returns (uint256);

	function releaseableAmountByAddress(address _token, address _beneficiary)
		external
		view
		returns (uint256);

	function vestedAmount(address _token) external view returns (uint256);

	function getVestingInfo(address _token)
		external
		view
		returns (VestingInfo memory);

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external;

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external;

	function getAllTokensByBeneficiary(address _beneficiary)
		external
		view
		returns (address[] memory);

	function releaseAll(address _beneficiary) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "../../utils/math/SafeMath.sol";
import "./IERC20.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
	 * a default value of 18.
	 *
	 * To select a different value for {decimals}, use {_setupDecimals}.
	 *
	 * All three of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = 18;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view virtual returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view virtual returns (uint8) {
		return _decimals;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _balances[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20}.
	 *
	 * Requirements:
	 *
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for ``sender``'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue)
		public
		virtual
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue)
		public
		virtual
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"ERC20: decreased allowance below zero"
			)
		);
		return true;
	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(
			amount,
			"ERC20: transfer amount exceeds balance"
		);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(
			amount,
			"ERC20: burn amount exceeds balance"
		);
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
	 *
	 * This internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Sets {decimals} to a value other than the default one of 18.
	 *
	 * WARNING: This function should only be called from the constructor. Most
	 * applications that interact with token contracts will not expect
	 * {decimals} to ever change, and may work incorrectly if it does.
	 */
	function _setupDecimals(uint8 decimals_) internal virtual {
		_decimals = decimals_;
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be to transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

