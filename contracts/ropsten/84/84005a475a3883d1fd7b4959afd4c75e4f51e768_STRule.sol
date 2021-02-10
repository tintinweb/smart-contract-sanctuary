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
	string  public standard = "SmartTrust Rule v1.3c";

	uint256 public ruleID;
	address public assetTokenAddress;

	uint256[] public beneficiaryIDs;

	mapping(uint256 => bool) public beneficiaryIDExists;

	// beneficiaryID => etheretum address of wallet
	//mapping (uint256 => address) beneficiaryAddress;
	address[] public beneficiaryAddresses;

	// beneficiaryID => tokens
	//mapping (uint256 => uint256) beneficiaryTokens;
	uint256[] public beneficiaryTokens;

	// States of a condition
	enum ConditionState {
		None,	// does not exist
		Unmet,	// condition not met
		Met		// condition has been met
	}

	mapping(uint256 => ConditionState) public conditions;

	uint256 public conditionsCount;
	uint256 public conditionsMet;

	// Whether the rule has been executed and if so, the timestamp
	uint256 public executed;

	// Whether the rule has been registered with asset and if so, the timestamp
	uint256 public registered;

	// Profiling info on contract creation
	uint256 public blockNumber;
	uint256 public creation;

	modifier onlyUnexecuted() {
		require(executed == 0, "Already executed");
		_;
	}

	modifier onlyExistingCondition(uint256 _conditionID) {
		require(conditions[_conditionID] != ConditionState.None, "Condition does not exist");
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
		uint256 timestamp
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

	function beneficiaryAdd(uint256 _beneficiaryID, address _beneficiaryAddress, uint256 _tokens)
		public
		onlyTrustee()
		onlyUnexecuted()
		returns (bool success)
	{
		require(!beneficiaryIDExists[_beneficiaryID], "Beneficiary already exists");

		beneficiaryIDs.push(_beneficiaryID);
		beneficiaryAddresses.push(_beneficiaryAddress);
		beneficiaryTokens.push(_tokens);
		beneficiaryIDExists[_beneficiaryID] = true;

		emit BeneficiaryAdd(_beneficiaryID, _beneficiaryAddress, _tokens);
		return true;
	}

	function beneficiaryRemove(uint256 _beneficiaryID)
		public
		onlyTrustee()
		onlyUnexecuted()
		returns (bool success)
	{
		require(beneficiaryIDExists[_beneficiaryID], "Beneficiary does not exist");

		for (uint256 i = 0; i < beneficiaryIDs.length; i++) {
			if (beneficiaryIDs[i] == _beneficiaryID) {
				delete beneficiaryIDs[i];
				delete beneficiaryAddresses[i];
				delete beneficiaryTokens[i];
				beneficiaryIDExists[_beneficiaryID] = false;

				emit BeneficiaryRemove(_beneficiaryID);
				break;
			}
		}
		return true;
	}

	function beneficiaryCount()
		public
		view
		returns (uint256 count)
	{
		return beneficiaryIDs.length;
	}

	function conditionAdd(uint256 _conditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
	{
		require(conditions[_conditionID] == ConditionState.None, "Condition already exists");

		conditions[_conditionID] = ConditionState.Unmet;
		conditionsCount++;

		emit ConditionAdd(_conditionID, now);
	}

	function conditionRemove(uint256 _conditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
		onlyExistingCondition(_conditionID)
	{
		require(conditionsCount - conditionsMet > 1, "Cannot delete last unmet condition");

		if (conditions[_conditionID] == ConditionState.Met) conditionsMet--;

		conditions[_conditionID] = ConditionState.None;
		conditionsCount--;

		emit ConditionRemove(_conditionID, now);
	}

	function conditionMet(uint256 _conditionID)
		public
		onlyTrustee()
		onlyUnexecuted()
		onlyExistingCondition(_conditionID)
	{
		require(conditions[_conditionID] == ConditionState.Unmet, "Condition already met");

		conditions[_conditionID] = ConditionState.Met;
		conditionsMet++;
		emit ConditionMet(_conditionID, now);

		if (conditionsCount == conditionsMet) _ruleExecute();
	}

	function _ruleExecute()
		internal
		onlyRegistered()
	{
		IRepartitionSTAToken asset = IRepartitionSTAToken(assetTokenAddress);
		require(!asset.isRepartitioned(), "Asset already repartitioned");

		// Invoke repartitioning for Asset tokens
		asset.repartitionExecute(beneficiaryAddresses, beneficiaryTokens);

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