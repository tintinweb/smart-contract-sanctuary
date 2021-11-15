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

