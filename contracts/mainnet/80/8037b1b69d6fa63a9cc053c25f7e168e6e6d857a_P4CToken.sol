/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Parts of Four Token
contract P4CToken {
	string public constant name = "Parts of Four Coin";
	string public constant symbol = "P4C";
	uint8 public constant decimals = 18;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	/// @notice The block number this contract was created in. Stored here so web3 scripts can easily access it and use
	/// @notice it to scan for InternalTransfer and NewRedistributedSupply events
	uint256 public immutable creationBlock;

	/// @notice This determines whether the 3% is deducted from transactions.
	bool public deductTaxes = true;

	/// @notice The original supply of P4C.
	uint256 public constant originalSupply = 4_000_000_000_000e18;

	/// @notice The current supply of internal P4C. This goes down when funds are burnt, as well as when supply is
	/// @notice redistributed.
	uint256 public totalInternalSupply = originalSupply;

	/// @notice This is the internal supply held in non-excluded addresses.
	uint256 public internalSupplyInNonExcludedAddresses;

	// @notice This 1e18 times a factor that adjusts internal balances to external balances. For example, if an account
	// @notice has an internal balance of 1e18 and this factor is 1.5e18, the external balance of that account will be
	// @notice 1.5e18.
	uint256 public adjustmentFactor = 1e18;

	// @notice The owner of the contract, set to the address that instantiated the contract. Only `contractOwner` may
	// @notice add or remove excluded addresses.
	address public immutable contractOwner;

	// @notice This is a list of excluded addresses. Transfers involving these addresses don't have the 3% tax taken out
	// @notice of them, and they don't receive token redistribution (ie. their balances are adjusted downwards every
	// @notice time `adjustmentFactor` is increased.
	address[] public excludedAddresses;
	// @notice A map where addresses in `excludedAddresses` map to `true`.
	mapping (address => bool) excludedAddressesMap;

	// @notice This is a mapping of addresses to the number of *internal* tokens they hold. This is *different* from the
	// @notice values that are used in contract calls, as those are adjusted by `adjustmentFactor`.
	mapping (address => uint256) public internalBalances;

	// @notice This event is emitted when tokens are transferred from `_from` to `_to`. `_internalSentValue` is the
	// @notice number of internal tokens transferred *before* any fees are deducted (ie. the recipient will actually get
	// @notice 3% less unless `_from` or `_to` is an excluded address).
	event InternalTransfer(address _from, address _to, uint256 _internalSentValue);
	// @notice This event is fired when an excluded address is added.
	event AddedExcludedAddress(address _addr);
	// @notice This event is fired when an address is removed from the excluded address list.
	event RemovedExcludedAddress(address _addr);
	// @notice Called when deduct taxes setting is changed.
	event SetDeductTaxes(bool _enabled);

	// Token authorisations. `_authorisee` can withdraw up to `allowed[_authoriser][_authroisee]` from `_authoriser`'s
	// account. Multiple transfers can be made so long as they do not cumulatively exceed the given amount. This is in
	// *EXTERNAL* tokens.
	mapping (address => mapping (address => uint256)) allowed;

	constructor() {
		creationBlock = block.number;
		contractOwner = msg.sender;
		addExcludedAddress(msg.sender);
		internalBalances[contractOwner] = originalSupply;
	}

	/// @notice Derive an external amount from an internal amount. (This will return a different result every time it's
	/// @notice called, as the amount it's being adjusted by changes when transfers are made.)
	function internalToExternalAmount(uint256 _internalAmount) view internal returns (uint256) {
		return (_internalAmount * adjustmentFactor) / 1e18;
	}

	/// @notice Derive an internal amount from an external amount. (This will return a different result every time it's
	/// @notice called, as the amount it's being adjusted by changes when transfers are made.)
	function externalToInternalAmount(uint256 _externalAmount) view internal returns (uint256) {
		return (_externalAmount * 1e18) / adjustmentFactor;
	}

	/// @notice The total external supply of the contract.
	function totalSupply() public view returns (uint256) {
		return internalToExternalAmount(totalInternalSupply);
	}

	/// @notice Designate an address as excluded. Transactions to and from excluded addresses don't incur taxes, and
	/// @notice they don't receive token redistribution either (which in practice means that their balances are adjusted
	/// @notice downwards every time `adjustmentFactor` is increased). This may only be called by `contractOwner`.
	function addExcludedAddress(address _addr) public {
		require(msg.sender == contractOwner, "This function is callable only by the contract owner.");
		require(!excludedAddressesMap[_addr], "_addr is already an excluded address.");

		internalSupplyInNonExcludedAddresses -= internalBalances[_addr];
		excludedAddressesMap[_addr] = true;
		excludedAddresses.push(_addr);

		emit AddedExcludedAddress(_addr);
	}

	/// @notice Remove the designation of excluded address from `_addr`.  Transactions to and from excluded addresses
	/// @notice don't incur taxes, and they don't receive token redistribution either (which in practice means that
	/// @notice their balances are adjusted downwards every time `adjustmentFactor` is increased). This may only be
	/// @notice called by `contractOwner`.
	function removeExcludedAddress(address _addr) public {
		require(msg.sender == contractOwner, "This function is callable only by the contract owner.");
		require(_addr != contractOwner, "contractOwner must be an excluded address for correct contract behaviour.");
		require(!!excludedAddressesMap[_addr], "_addr is not an excluded address.");

		internalSupplyInNonExcludedAddresses += internalBalances[_addr];
		excludedAddressesMap[_addr] = false;
		for (uint i; i < excludedAddresses.length; i++) {
			if (excludedAddresses[i] == _addr) {
				if (i != excludedAddresses.length-1)
					excludedAddresses[i] = excludedAddresses[excludedAddresses.length-1];

				excludedAddresses.pop();
				break;
			}
		}

		emit RemovedExcludedAddress(_addr);
	}

	/// @notice Set whether or not we deduct 3% from every transaction. This may only be called by `contractOwner`.
	function setDeductTaxes(bool _deductTaxes) public {
		require(msg.sender == contractOwner, "This function is callable only by the contract owner.");
		require(_deductTaxes != deductTaxes, "deductTaxes is already that value");
		deductTaxes = _deductTaxes;
		emit SetDeductTaxes(_deductTaxes);
	}

	/// @notice Get the external balance of `_owner`.
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return internalToExternalAmount(internalBalances[_owner]);
	}

	/// @notice Approve `_spender` to remove up to `_value` in external tokens *at the time the withdraw happens* from
	/// @notice `msg.sender`'s account. Multiple withdraws may be made from a single `approve()` call so long as the
	/// @notice sum of the external values at the time of each individual call do not exceed `_value`.
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/// @notice This returns the number of external tokens `_spender` is allowed to transfer on behalf of `_owner`.
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/// @notice Transfer `_value` external tokens from `msg.sender`'s account to `_to`'s account. If neither
	/// @notice `msg.sender` nor `_to` are excluded addresses, `_to` will receive only 97% of `_value`. 1% will be
	/// @notice burned, 1% will be redistributed equally among non-excluded addresses, and 1% will be sent to
	/// @notice `contractOwner`.
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return transferCommon(msg.sender, _to, _value);
	}

	/// @notice Transfers `_value` from `_from` to `_to`, if `_from` has previously called `approve()` with the correct
	/// @notice arguments. Transfers work in the same way as `transfer()`.
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(allowed[_from][msg.sender] >= _value, "Sender has insufficient authorisation.");
		allowed[_from][msg.sender] -= _value;

		return transferCommon(_from, _to, _value);
	}

	/// @notice This transfers `_value` from `_from` to `_to`, WITHOUT CHECKING FOR AUTHORISATION.
	function transferCommon(address _from, address _to, uint256 _value) internal returns (bool success) {
		uint256 internalValue = externalToInternalAmount(_value);
		require(internalValue <= internalBalances[_from], "Transfer source has insufficient balance.");

		uint256 internalReceivedValue;
		if (!excludedAddressesMap[_from] && !excludedAddressesMap[_to] && deductTaxes) {
			uint256 onePercent = internalValue / 100;
			internalReceivedValue = internalValue - onePercent * 3;
			internalSupplyInNonExcludedAddresses -= onePercent * 3;

			// This is the adjustment resulting from just this transaction.
			uint256 readjustmentFactor =
				((internalSupplyInNonExcludedAddresses + onePercent) * 1e18) /
				internalSupplyInNonExcludedAddresses;
			adjustmentFactor = (adjustmentFactor * readjustmentFactor) / 1e18;

			internalBalances[contractOwner] += onePercent;

			uint256 removedFunds;
			for (uint i; i < excludedAddresses.length; i++) {
				// Because this is rounded down, excludedAddresses will slowly lose funds as more transactions are made.
				// However, due to the fact that transactions are expensive and we have such a high precision, this
				// doesn't make a difference in practice.
				uint256 oldBalance = internalBalances[excludedAddresses[i]];
				uint256 newBalance = ((oldBalance * 1e18) / readjustmentFactor);
				internalBalances[excludedAddresses[i]] = newBalance;
				removedFunds += oldBalance - newBalance;
			}

			// Decrement the total supply by 2% of the transfer amount plus the internal amount that's been taken from
			// excludedAddresses.
			totalInternalSupply -= removedFunds + onePercent*2;
		} else {
			if (excludedAddressesMap[_from] && !excludedAddressesMap[_to])
				internalSupplyInNonExcludedAddresses += internalValue;
			if (!excludedAddressesMap[_from] && excludedAddressesMap[_to])
				internalSupplyInNonExcludedAddresses -= internalValue;

			internalReceivedValue = internalValue;
		}

		internalBalances[_to] += internalReceivedValue;
		internalBalances[_from] -= internalValue;

		emit Transfer(_from, _to, _value);
		emit InternalTransfer(_from, _to, internalValue);

		return true;
	}
}