// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./IRepartitionSTAToken.v3.2.sol";
import "./IRegistrableSTRule.v1.3.sol";
import "./TrusteeManagedSC.v0.2.sol";

contract STRule is
	IRegistrableSTRule,
	TrusteeManagedSC
{
	string  public name = "SmartTrust Rule";
	string  public symbol = "STR";
	string  public standard = "SmartTrust Rule v1.4";

	uint256 public ruleID;
	address public assetTokenAddress;

	// Whether the rule has been executed and if so, the timestamp
	uint256 public executed;

	// Whether the rule has been registered with asset and if so, the timestamp
	uint256 public registered;

	// Profiling info on contract creation
	uint256 public blockNumber;
	uint256 public creation;

	// States of a condition
	enum ConditionState {
		None,	// does not exist
		Unmet,	// condition not met
		Met		// condition has been met
	}

	// Type of a condition
	enum ConditionSubtype {
		None,              // does not defined
		Subconditions,     // has sub-conditions
		Beneficiaries      // has beneficiaries
	}

	// Structure of a condition
	struct Condition {
		uint256 conditionID;
		ConditionState state;
		ConditionSubtype subtype;
		address[] beneficiaryAddresses;
		uint256[] beneficiaryTokens;
		uint256 parentConditionID;
	}

	// Array of a conditions
	Condition[] public conditions;

	modifier onlyUnexecuted() {
		require(executed == 0, "Already executed");
		_;
	}

	modifier onlyExistingCondition(uint256 _conditionID) {
		require(conditionExists(_conditionID), "Condition does not exist");
		_;
	}

	modifier onlyAsset() {
		require(assetTokenAddress == msg.sender, "Not asset token");
		_;
	}

	modifier onlyRegistered() {
		require(registered != 0, "Not yet registered");
		_;
	}

	event RuleRegistered(
		uint256 timestamp
	);

	event BeneficiaryAdd(
		uint256 indexed beneficiaryID,
		address indexed beneficiaryAddress,
		uint256 tokens
	);

	event BeneficiaryRemove(
		uint256 indexed beneficiaryID
	);

	event ConditionAdd(
		uint256 indexed conditionId,
		uint256 timestamp,
		address[] _beneficiaries,
		uint256[] _tokens,
		uint256 _parentConditionID
	);

	event ConditionRemove(
		uint256 indexed conditionId,
		uint256 timestamp
	);

	event ConditionMet(
		uint256 indexed conditionId,
		uint256 timestamp
	);

	event RuleExecute(
		uint256 timestamp
	);

	constructor (uint256 _ruleID, address _assetTokenAddress, address[] memory _trustees) public {
		_trusteeAdd(msg.sender);

		// Add all Trustees of Trust
		for (uint256 i = 0; i < _trustees.length; i++) {
			_trusteeAdd(_trustees[i]);
		}

		ruleID = _ruleID;
		assetTokenAddress = _assetTokenAddress;

		blockNumber = block.number;
		creation = now;
	}

	function conditionsUpdate(uint256[] memory _conditionsIDforAdd, uint256[] memory _parentConditionsID, address[] memory _beneficiariesAddresses, uint256[] memory _beneficiariesTokens, uint256[] memory _conditionsIDForRemove)
		public
		onlyTrustee()
		onlyUnexecuted()
	{
		uint256 beneficiaries_count = _beneficiariesAddresses.length;
		// For each new condition
		for (uint256 i = 0; i < _conditionsIDforAdd.length; i++) {
			// extract tokens for each beneficiaries
			uint256[] storage tokens;
			uint256 tokens_sum = 0;
			for (uint256 j = 0; j < beneficiaries_count; j++) {
				uint256 t = _beneficiariesTokens[ (i * beneficiaries_count) + j ];
				tokens.push(t);
				tokens_sum = tokens_sum + t;
			}
			if (tokens_sum > 0) {
				conditionAdd(_conditionsIDforAdd[i], _beneficiariesAddresses, tokens, _parentConditionsID[i]);
			} else {
				address[] storage emptyAddresses;
				uint256[] storage emptyTokens;
				conditionAdd(_conditionsIDforAdd[i], emptyAddresses, emptyTokens, _parentConditionsID[i]);
			}
		}
		for (uint256 i = 0; i < _conditionsIDForRemove.length; i++) {
			conditionRemove(_conditionsIDForRemove[i]);
		}
	}

	function conditionExists(uint256 _conditionID)
		public
		view
		returns (bool status)
	{
		for (uint256 i = 0; i < conditions.length; i++) {
			if (conditions[i].conditionID == _conditionID) return true;
		}
		return false;
	}

	function _conditionGetIndex(uint256 _conditionID)
		internal
		view
		returns (uint256 index, bool exists)
	{
		for (uint256 i = 0; i < conditions.length; i++) {
			if (conditions[i].conditionID == _conditionID) {
				return (i, true);
			}
		}
		return (0, false);
	}

	function conditionAdd(uint256 _conditionID, address[] memory _beneficiaries, uint256[] memory _tokens, uint256 _parentConditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
	{
		require(!conditionExists(_conditionID), "Condition already exists");

		ConditionSubtype st = ConditionSubtype.None;
		if (_beneficiaries.length > 0) st = ConditionSubtype.Beneficiaries;

		conditions.push( Condition(_conditionID, ConditionState.None, st, _beneficiaries, _tokens, _parentConditionID) );
		if (_parentConditionID > 0) _conditionSetSubtype(_parentConditionID, ConditionSubtype.Subconditions);

		emit ConditionAdd(_conditionID, now, _beneficiaries, _tokens, _parentConditionID);
	}

	function _conditionSetSubtype(uint256 _conditionID, ConditionSubtype _subtype)
		internal
		onlyUnexecuted()
	{
		(uint256 index, bool exists) = _conditionGetIndex(_conditionID);
		if (exists) conditions[index].subtype = _subtype;
	}

	function conditionRemove(uint256 _conditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
		onlyExistingCondition(_conditionID)
	{
		_conditionRemove(_conditionID);
	}

	function _conditionRemove(uint256 _conditionID)
		internal
		onlyUnexecuted()
	{
		_conditionRemoveChildren(_conditionID);
		for (uint256 i = 0; i < conditions.length; i++) {
			if (conditions[i].conditionID == _conditionID) {
				delete conditions[i];
			}
		}
		emit ConditionRemove(_conditionID, now);
	}

	function _conditionRemoveChildren(uint256 _parentConditionID)
		internal
		onlyUnexecuted()
	{
		if (_parentConditionID <= 0) return;
		for (uint256 i = 0; i < conditions.length; i++) {
			if (conditions[i].parentConditionID == _parentConditionID) {
				_conditionRemove(conditions[i].conditionID);
			}
		}
	}

	function conditionMet(uint256 _conditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
		onlyExistingCondition(_conditionID)
	{
		(uint256 condition_index, bool exists) = _conditionGetIndex(_conditionID);
		require(exists, "Condition not exists");
		require(conditions[condition_index].state == ConditionState.Unmet, "Condition already met");

		conditions[condition_index].state = ConditionState.Met;
		emit ConditionMet( conditions[condition_index].conditionID, now);

		_ruleCheckForExecute();
	}

	function _conditionPathIsMet(uint256 _conditionID)
		internal
		onlyUnexecuted()
		returns (bool is_met)
	{
		(uint256 index, bool exists) = _conditionGetIndex(_conditionID);
		require(exists, "Condition not exists");
		if (conditions[index].parentConditionID <= 0) {
			return conditions[index].state == ConditionState.Met;
		} else {
			return (conditions[index].state == ConditionState.Met) && _conditionPathIsMet( conditions[index].parentConditionID );
		}
	}

	function _ruleCheckForExecute()
		internal
		onlyUnexecuted()
	{
		for (uint256 i = 0; i < conditions.length; i++) {
			if (conditions[i].subtype == ConditionSubtype.Beneficiaries) {
				if (_conditionPathIsMet(conditions[i].conditionID)) {
					_ruleExecute(conditions[i].beneficiaryAddresses, conditions[i].beneficiaryTokens);
					break;
				}
			}
		}
	}

	function _ruleExecute(address[] memory _addresses, uint256[] memory _tokens)
		internal
		onlyRegistered()
	{
		IRepartitionSTAToken asset = IRepartitionSTAToken(assetTokenAddress);
		require(!asset.isRepartitioned(), "Asset already repartitioned");

		// Invoke repartitioning for Asset tokens
		asset.repartitionExecute(_addresses, _tokens);

		executed = now;
		emit RuleExecute(executed);
	}

	/**
	 * @dev Returns whether the Rule has been registered with the Asset Token.
	 */
	function isRegistered()
		public
		view
		override
		returns (bool status)
	{
		return (registered != 0);
	}

	/**
	 * @dev Accept registration confirmation invoked from Asset Token.
	 */
	function confirmRegistration()
		external
		override
		onlyAsset()
	{
		require(registered == 0);

		registered = now;
		emit RuleRegistered(registered);
	}

	function trusteeAdd(address _trustee)
		public
		override(IRegistrableSTRule, TrusteeManagedSC)
		onlyAsset()
	{
		TrusteeManagedSC._trusteeAdd(_trustee);
	}

	function trusteeRemove(address _trustee)
		public
		override(IRegistrableSTRule, TrusteeManagedSC)
		onlyAsset()
	{
		TrusteeManagedSC._trusteeRemove(_trustee);
	}

}