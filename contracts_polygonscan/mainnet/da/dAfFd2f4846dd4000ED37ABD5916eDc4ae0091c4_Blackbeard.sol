// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable not-rely-on-time, avoid-low-level-calls, reason-string */

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { GovernableTimelock } from "../libraries/GovernableTimelock.sol";
import { IBlackbeard } from "../interfaces/IBlackbeard.sol";
import { IJollyRoger } from "../interfaces/IJollyRoger.sol";

/**
 * @title Blackbeard
 * @author 0xBlackbeard
 * @notice Powerful and versatile timelock governing the JollyRoger token supply and metadata
 * 		   through a time-locked proposal/acceptance scheme
 * @dev All of the contract functions are behind a time-locked proposal->acceptance pattern
  		with a minimal proposal length hard-coded in for additional safety and guarantees.
 *
 * Note that:
 * - while this is the initial manager contract for the 🏴‍☠ token, it can be replaced in the future
 * - while all of the contract most sensitive functions are behind RBAC, governance still manages roles, ownership and
 *	 both (supply & metadata) managers (always through the built-in time-lock)
 * - while the contract has a satisfactory minimum time-lock (3 days), this or any other future managers will still be
 *	 bounded by JollyRoger hard-limits
 */
contract Blackbeard is AccessControlEnumerable, GovernableTimelock, IBlackbeard {
	bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER_ROLE");
	bytes32 public constant SUPPLY_MANAGER_ROLE = keccak256("SUPPLY_MANAGER_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	/// @notice The minimum time between proposal and acceptance
	uint32 public immutable proposalLengthMinimum = 12 hours;

	/// @notice The current time between proposal and acceptance
	uint32 public proposalLength = 2 days;

	/// @notice 🏴‍☠ token
	IJollyRoger public jollyRoger;

	/// @notice Current pending admin proposal
	GovernanceProposal public govProposal;

	/// @notice Current RBAC update proposal
	RBACUpdateProposal public rbacUpdateProposal;

	/// @notice Current pending supply manager proposal
	SupplyManagerProposal public supplyManagerProposal;

	/// @notice Current pending mint cap proposal
	MaxSupplyProposal public maxSupplyProposal;

	/// @notice Current pending waiting period proposal
	SupplyFreezeProposal public freezeProposal;

	/// @notice Current pending proposal length proposal
	ProposalLengthProposal public proposalLengthProposal;

	/// @notice Current pending supply manager proposal
	MetadataManagerProposal public metadataManagerProposal;

	/// @notice Current pending supply manager proposal
	MetadataUpdateProposal public metadataUpdateProposal;

	/**
	 * @notice Construct a new Blackbeard manager
	 * @param _token The address of the token to govern
	 * @param _gov The governance address for this contract
	 * @param _metadataManagers The initial metadata managers list
	 * @param _supplyManagers The initial supply managers list
	 * @param _minters The initial minters list
	 */
	constructor(
		address _token,
		address _gov,
		address[] memory _metadataManagers,
		address[] memory _supplyManagers,
		address[] memory _minters
	) GovernableTimelock(_gov) {
		require(_metadataManagers.length <= 2, "Blackbeard::constructor: too many metadata managers at deployment");
		require(_supplyManagers.length <= 2, "Blackbeard::constructor: too many supply managers at deployment");
		require(_minters.length <= 2, "Blackbeard::constructor: too many minters at deployment");

		jollyRoger = IJollyRoger(_token);

		_setRoleAdmin(METADATA_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
		_setRoleAdmin(SUPPLY_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
		_setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
		_setupRole(DEFAULT_ADMIN_ROLE, address(this));

		for (uint256 i = 0; i < _metadataManagers.length; i++) {
			_setupRole(METADATA_MANAGER_ROLE, _metadataManagers[i]);
		}

		for (uint256 i = 0; i < _supplyManagers.length; i++) {
			_setupRole(SUPPLY_MANAGER_ROLE, _supplyManagers[i]);
		}

		for (uint256 i = 0; i < _minters.length; i++) {
			_setupRole(MINTER_ROLE, _minters[i]);
		}
	}

	/**
	 * @notice Proposes a new governance
	 * @param newGov The new governance address
	 */
	function proposeGovernanceProposal(address newGov, bool emergency)
		external
		override
		onlyGovernance
		returns (uint256)
	{
		require(govProposal.eta == 0, "Blackbeard::proposeGovernanceProposal: cancel pending proposal");

		// In this scenario, hard-coded minimum ETA allows for quicker response times (emergency-only)
		uint256 eta = block.timestamp + (emergency ? proposalLengthMinimum : proposalLength);
		govProposal = GovernanceProposal(eta, newGov);
		emit GovernanceProposed(governance(), newGov, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed governance change
	 */
	function cancelGovernanceProposal() external override onlyGovernance {
		require(govProposal.eta != 0, "Blackbeard::cancelGovernanceProposal: no active proposal");

		emit GovernanceCanceled(govProposal.gov);
		govProposal = GovernanceProposal(0, address(0));
	}

	/**
	 * @notice Accepts the proposed governance change
	 */
	function acceptGovernanceProposal() external override onlyGovernance {
		require(govProposal.eta != 0, "Blackbeard::acceptGovernanceProposal: no active proposal");
		require(block.timestamp >= govProposal.eta, "Blackbeard::acceptGovernanceProposal: proposal eta not elapsed yet");

		address _oldGov = governance();
		address _newGov = govProposal.gov;
		(bool success, ) = address(this).call(abi.encodeWithSignature("changeGovernance(address)", _newGov));
		require(success, "Blackbeard::acceptGovernanceProposal: tx execution reverted");
		emit GovernanceAccepted(_oldGov, _newGov);
		govProposal = GovernanceProposal(0, address(0));
	}

	/**
	 * @notice Proposes a new RBAC update
	 * @param _role The role subject of the access control update
	 * @param _authorized The list of accounts to authorize
	 * @param _revocation Boolean flag indicating whether to revoke the roles, and perform sanity checks for revocations
	 */
	function proposeRBACUpdateProposal(
		bytes32 _role,
		address[] memory _authorized,
		bool _revocation
	) external override onlyGovernance returns (uint256) {
		require(
			_role == SUPPLY_MANAGER_ROLE || _role == METADATA_MANAGER_ROLE || _role == MINTER_ROLE,
			"Blackbeard::proposeRBACUpdateProposal: unknown role"
		);
		require(
			_authorized.length > 0 && _authorized.length < 10,
			"Blackbeard::proposeRBACUpdateProposal: invalid authorized list"
		);
		require(rbacUpdateProposal.eta == 0, "Blackbeard::proposeRBACUpdateProposal: cancel pending proposal");

		if (_revocation) {
			for (uint8 i = 0; i < _authorized.length; i++) {
				_checkRole(_role, _authorized[i]);
			}
		}

		uint256 eta = block.timestamp + proposalLength;
		rbacUpdateProposal = RBACUpdateProposal(eta, _role, _authorized, _revocation);
		emit RBACUpdateProposed(_role, _authorized, _revocation, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed RBAC update
	 */
	function cancelRBACUpdateProposal() external override onlyGovernance {
		require(rbacUpdateProposal.eta != 0, "Blackbeard::cancelRBACUpdateProposal: no active proposal");

		address[] memory _unathorized;
		emit RBACUpdateCanceled(rbacUpdateProposal.role, rbacUpdateProposal.authorized, rbacUpdateProposal.revocation);
		rbacUpdateProposal = RBACUpdateProposal(0, "", _unathorized, false);
	}

	/**
	 * @notice Accepts the proposed RBAC update
	 */
	function acceptRBACUpdateProposal() external override onlyGovernance {
		require(rbacUpdateProposal.eta != 0, "Blackbeard::acceptRBACUpdateProposal: no active proposal");
		require(
			block.timestamp >= rbacUpdateProposal.eta,
			"Blackbeard::acceptRBACUpdateProposal: proposal eta not elapsed yet"
		);

		bytes32 _role = rbacUpdateProposal.role;
		address[] memory _authorized = rbacUpdateProposal.authorized;
		address[] memory _unathorized;
		bool _revocation = rbacUpdateProposal.revocation;
		rbacUpdateProposal = RBACUpdateProposal(0, "", _unathorized, false);

		for (uint256 i = 0; i < _authorized.length; ++i) {
			if (_revocation) {
				(bool success, ) = address(this).call(
					abi.encodeWithSignature("revokeRole(bytes32,address)", _role, _authorized[i])
				);
				require(success, "Blackbeard::acceptRBACUpdateProposal: tx execution reverted");
			} else {
				(bool success, ) = address(this).call(
					abi.encodeWithSignature("grantRole(bytes32,address)", _role, _authorized[i])
				);
				require(success, "Blackbeard::acceptRBACUpdateProposal: tx execution reverted");
			}
		}

		emit RBACUpdateAccepted(_role, _authorized, _revocation);
	}

	/**
	 * @notice Proposes change to the proposal length
	 * @param newLength The new proposal length (lock period)
	 */
	function proposeProposalLengthProposal(uint32 newLength) external override onlyGovernance returns (uint256) {
		require(proposalLengthProposal.eta == 0, "Blackbeard::proposeProposalLengthProposal: cancel pending proposal");
		require(
			newLength >= proposalLengthMinimum,
			"Blackbeard::proposeProposalLengthProposal: length must be >= minimum"
		);
		require(newLength != proposalLength, "Blackbeard::proposeProposalLengthProposal: new length must differ");

		uint256 eta = block.timestamp + proposalLength;
		proposalLengthProposal = ProposalLengthProposal(eta, newLength);
		emit ProposalLengthProposed(proposalLength, newLength, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed update to proposals' length
	 */
	function cancelProposalLengthProposal() external override onlyGovernance {
		require(proposalLengthProposal.eta != 0, "Blackbeard::cancelProposalLengthProposal: no active proposal");

		emit ProposalLengthCanceled(proposalLengthProposal.length);
		proposalLengthProposal = ProposalLengthProposal(0, 0);
	}

	/**
	 * @notice Accepts the proposed change to proposals' length
	 */
	function acceptProposalLengthProposal() external override onlyGovernance {
		require(proposalLengthProposal.eta != 0, "Blackbeard::acceptProposalLengthProposal: no active proposal");
		require(
			block.timestamp >= proposalLengthProposal.eta,
			"Blackbeard::acceptProposalLengthProposal: proposal eta not elapsed yet"
		);

		uint32 oldLength = proposalLength;
		uint32 newLength = proposalLengthProposal.length;
		proposalLengthProposal = ProposalLengthProposal(0, 0);
		proposalLength = newLength;
		emit ProposalLengthAccepted(oldLength, newLength);
	}

	/**
	 * @notice Proposes a new metadata manager for the JollyRoger token
	 * @param newMetadataManager The new metadata manager address
	 */
	function proposeMetadataManagerProposal(address newMetadataManager)
		external
		override
		onlyGovernance
		returns (uint256)
	{
		require(metadataManagerProposal.eta == 0, "Blackbeard::proposeMetadataManagerProposal: cancel pending proposal");

		uint256 eta = block.timestamp + proposalLength;
		metadataManagerProposal = MetadataManagerProposal(eta, newMetadataManager);
		emit MetadataManagerProposed(jollyRoger.metadataManager(), newMetadataManager, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed metadata manager
	 */
	function cancelMetadataManagerProposal() external override onlyGovernance {
		require(metadataManagerProposal.eta != 0, "Blackbeard::cancelMetadataManagerProposal: no active proposal");

		emit MetadataManagerCanceled(metadataManagerProposal.manager);
		metadataManagerProposal = MetadataManagerProposal(0, address(0));
	}

	/**
	 * @notice Accepts the proposed metadata manager
	 */
	function acceptMetadataManagerProposal() external override onlyGovernance {
		require(metadataManagerProposal.eta != 0, "Blackbeard::acceptMetadataManagerProposal: no active proposal");
		require(
			block.timestamp >= metadataManagerProposal.eta,
			"Blackbeard::acceptMetadataManagerProposal: proposal eta not elapsed yet"
		);

		address oldManager = jollyRoger.metadataManager();
		address newManager = metadataManagerProposal.manager;
		metadataManagerProposal = MetadataManagerProposal(0, address(0));

		require(
			jollyRoger.setMetadataManager(newManager),
			unicode"Blackbeard::acceptMetadataManagerProposal: 🏴‍☠ op failed"
		);
		emit MetadataManagerAccepted(oldManager, newManager);
	}

	/**
	 * @notice Proposes a new supply manager for the JollyRoger token
	 * @dev WARNING: if accepted, this proposal would leave this contract (and all whitelisted addresses) unable to mint
	 * @param newSupplyManager The new supply manager address
	 */
	function proposeSupplyManagerProposal(address newSupplyManager) external override onlyGovernance returns (uint256) {
		require(supplyManagerProposal.eta == 0, "Blackbeard::proposeSupplyManagerProposal: cancel pending proposal");

		uint256 eta = block.timestamp + proposalLength;
		supplyManagerProposal = SupplyManagerProposal(eta, newSupplyManager);
		emit SupplyManagerProposed(jollyRoger.supplyManager(), newSupplyManager, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed supply manager
	 */
	function cancelSupplyManagerProposal() external override onlyGovernance {
		require(supplyManagerProposal.eta != 0, "Blackbeard::cancelSupplyManagerProposal: no active proposal");

		emit SupplyManagerCanceled(supplyManagerProposal.manager);
		supplyManagerProposal = SupplyManagerProposal(0, address(0));
	}

	/**
	 * @notice Accepts the new supply manager
	 */
	function acceptSupplyManagerProposal() external override onlyGovernance {
		require(supplyManagerProposal.eta != 0, "Blackbeard::acceptSupplyManagerProposal: no active proposal");
		require(
			block.timestamp >= supplyManagerProposal.eta,
			"Blackbeard::acceptSupplyManagerProposal: proposal eta not elapsed yet"
		);

		address oldManager = jollyRoger.supplyManager();
		address newManager = supplyManagerProposal.manager;
		supplyManagerProposal = SupplyManagerProposal(0, address(0));

		require(
			jollyRoger.setSupplyManager(newManager),
			unicode"Blackbeard::acceptSupplyManagerProposal: 🏴‍☠ op failed"
		);
		emit SupplyManagerAccepted(oldManager, newManager);
	}

	/**
	 * @notice Proposes a new metadata update (token and/or symbol)
	 * @param newName The new token name
	 * @param newSymbol The new token symbol
	 */
	function proposeMetadataUpdateProposal(string memory newName, string memory newSymbol)
		external
		override
		onlyRole(METADATA_MANAGER_ROLE)
		returns (uint256)
	{
		require(metadataUpdateProposal.eta == 0, "Blackbeard::proposeMetadataUpdateProposal: cancel pending proposal");

		uint256 eta = block.timestamp + proposalLength;
		metadataUpdateProposal = MetadataUpdateProposal(eta, newName, newSymbol);
		emit MetadataUpdateProposed(newName, newSymbol, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed metadata update
	 */
	function cancelMetadataUpdateProposal() external override onlyRole(METADATA_MANAGER_ROLE) {
		require(metadataUpdateProposal.eta != 0, "Blackbeard::cancelMetadataUpdateProposal: no active proposal");

		emit MetadataUpdateCanceled(metadataUpdateProposal.name, metadataUpdateProposal.symbol);
		metadataUpdateProposal = MetadataUpdateProposal(0, "", "");
	}

	/**
	 * @notice Accepts the proposed metadata manager
	 */
	function acceptMetadataUpdateProposal() external override onlyRole(METADATA_MANAGER_ROLE) {
		require(metadataUpdateProposal.eta != 0, "Blackbeard::acceptMetadataUpdateProposal: no active proposal");
		require(
			block.timestamp >= metadataUpdateProposal.eta,
			"Blackbeard::acceptMetadataUpdateProposal: proposal eta not elapsed yet"
		);

		string memory oldName = jollyRoger.name();
		string memory oldSymbol = jollyRoger.symbol();
		string memory newName = metadataUpdateProposal.name;
		string memory newSymbol = metadataUpdateProposal.symbol;
		metadataUpdateProposal = MetadataUpdateProposal(0, "", "");

		require(
			jollyRoger.updateTokenMetadata(newName, newSymbol),
			unicode"Blackbeard::acceptMetadataUpdateProposal: 🏴‍☠ op failed"
		);
		emit MetadataUpdateAccepted(oldName, oldSymbol, newName, newSymbol);
	}

	/**
	 * @notice Proposes a change to the maximum amount of tokens that can exist in circulation
	 * @param newMaxSupply The new maximum supply
	 */
	function proposeMaxSupplyProposal(uint256 newMaxSupply)
		external
		override
		onlyRole(SUPPLY_MANAGER_ROLE)
		returns (uint256)
	{
		require(maxSupplyProposal.eta == 0, "Blackbeard::proposeMaxSupplyProposal: cancel pending proposal");

		uint256 eta = block.timestamp + proposalLength;
		maxSupplyProposal = MaxSupplyProposal(eta, newMaxSupply);
		emit MaxSupplyProposed(jollyRoger.maximumSupply(), newMaxSupply, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed maximum supply change
	 */
	function cancelMaxSupplyProposal() external override onlyRole(SUPPLY_MANAGER_ROLE) {
		require(maxSupplyProposal.eta != 0, "Blackbeard::cancelMaxSupplyProposal: no active proposal");

		emit MaxSupplyCanceled(maxSupplyProposal.supply);
		maxSupplyProposal = MaxSupplyProposal(0, 0);
	}

	/**
	 * @notice Accepts the proposed maximum supply change
	 */
	function acceptMaxSupplyProposal() external override onlyRole(SUPPLY_MANAGER_ROLE) {
		require(maxSupplyProposal.eta != 0, "Blackbeard::acceptMaxSupplyProposal: no active proposals");
		require(
			block.timestamp >= maxSupplyProposal.eta,
			"Blackbeard::acceptMaxSupplyProposal: proposal eta not elapsed yet"
		);

		uint256 oldMaxSupply = jollyRoger.maximumSupply();
		uint256 newMaxSupply = maxSupplyProposal.supply;
		maxSupplyProposal = MaxSupplyProposal(0, 0);

		require(jollyRoger.setMaximumSupply(newMaxSupply), unicode"Blackbeard::acceptMaxSupplyProposal: 🏴‍☠ op failed");
		emit MaxSupplyAccepted(oldMaxSupply, newMaxSupply);
	}

	/**
	 * @notice Proposes a new supply change freeze period
	 * @param newFreeze The new supply freeze period
	 */
	function proposeSupplyFreezeProposal(uint32 newFreeze)
		external
		override
		onlyRole(SUPPLY_MANAGER_ROLE)
		returns (uint256)
	{
		require(freezeProposal.eta == 0, "Blackbeard::proposeSupplyFreezeProposal: cancel pending proposal");

		uint256 eta = block.timestamp + proposalLength;
		freezeProposal = SupplyFreezeProposal(eta, newFreeze);
		emit SupplyFreezeProposed(jollyRoger.supplyFreeze(), newFreeze, eta);

		return eta;
	}

	/**
	 * @notice Cancels the proposed supply chance freeze period
	 */
	function cancelSupplyFreezeProposal() external override onlyRole(SUPPLY_MANAGER_ROLE) {
		require(freezeProposal.eta != 0, "Blackbeard::cancelSupplyFreezeProposal: no active proposal");

		emit SupplyFreezeCanceled(freezeProposal.freeze);
		freezeProposal = SupplyFreezeProposal(0, 0);
	}

	/**
	 * @notice Accepts the proposed change to the supply change freeze period
	 */
	function acceptSupplyFreezeProposal() external override onlyRole(SUPPLY_MANAGER_ROLE) {
		require(freezeProposal.eta != 0, "Blackbeard::acceptSupplyFreezeProposal: no active proposals");
		require(
			block.timestamp >= freezeProposal.eta,
			"Blackbeard::acceptSupplyFreezeProposal: proposal eta not elapsed yet"
		);

		uint32 _oldPeriod = jollyRoger.supplyFreeze();
		uint32 _newFreeze = freezeProposal.freeze;
		freezeProposal = SupplyFreezeProposal(0, 0);
		require(jollyRoger.setSupplyFreeze(_newFreeze), unicode"Blackbeard::acceptSupplyFreezeProposal: 🏴‍☠ op failed");

		emit SupplyFreezeAccepted(_oldPeriod, _newFreeze);
	}

	/**
	 * @notice Mints more units of the 🏴‍☠ token to the specified beneficiary
	 * @dev All sanity checks are delegated to its counterpart method in the JollyRoger contract (`mint`)
	 * @param dst The destination address where the newly minted tokens are credited
	 * @param amount The amount of new tokens
	 */
	function sew(address dst, uint256 amount) external override onlyRole(MINTER_ROLE) {
		require(jollyRoger.mint(dst, amount), unicode"Blackbeard::forgeTridents: 🏴‍☠ op failed");
		emit JollyRogerSewed(dst, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable reason-string */

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account (a governance)
 * that can be granted exclusive access to specific functions.
 *
 * By default, the governance account will be the one that deploys the contract.
 * This can later be changed with {changeGovernance}, however, this must happen through the timelock contract itself.
 *
 * This module is used through inheritance. It will make available the modifier `onlyGovernance`,
 * which can be applied to your functions to restrict their use to the governance.
 */
abstract contract GovernableTimelock is Context {
	bytes32 public constant CHANGE_GOVERNANCE_FUNC_SIG_HASH = keccak256(abi.encodePacked("changeGovernance(address)")); // 0x99572d6f3320ad75be931851bbe30d8fa95d91783f113c3a420a3c69c2b4f67e;
	bytes32 public constant ACCEPT_GOVERNANCE_FUNC_SIG_HASH = keccak256(abi.encodePacked("acceptGovernance()")); // 0x238efcbc0d680b1dbcd35db915f12f0eeb1c4c4f9b458afb60568b2eb9f30e3a;

	address private _governance;
	address private _pendingGovernance;

	event GovernanceChanged(address indexed formerGov, address indexed newGov);

	/**
	 * @dev Initializes the contract setting the deployer as the initial governance.
	 */
	constructor(address _gov) {
		_governance = _gov;
		emit GovernanceChanged(address(0), _governance);
	}

	/**
	 * @dev Throws if called by any account other than the governance.
	 */
	modifier onlyGovernance() {
		require(
			governance() == _msgSender(),
			string(
				abi.encodePacked(
					"GovernableTimelock::onlyGovernance: ",
					Strings.toHexString(uint160(_msgSender()), 20),
					" is not governance"
				)
			)
		);
		_;
	}

	/**
	 * @dev Returns the address of the current governance.
	 */
	function governance() public view virtual returns (address) {
		return _governance;
	}

	/**
	 * @dev Returns the address of the pending governance.
	 */
	function pendingGovernance() public view virtual returns (address) {
		return _pendingGovernance;
	}

	/**
	 * @dev Begins the governance transfer handshake with a new account (`newGov`).
	 *
	 * Requirements:
	 *   - can only be called by the current governance
	 */
	function changeGovernance(address _newGov) public virtual {
		require(_msgSender() == address(this), "GovernableTimelock::changeGovernance: gov change must be time-locked");
		require(_newGov != address(0), "GovernableTimelock::changeGovernance: new governance cannot be the zero address");
		_pendingGovernance = _newGov;
	}

	/**
	 * @dev Ends the governance transfer handshake that results in governance powers being handed to the caller
	 *
	 * Requirements:
	 *   - caller must be the pending governance address
	 */
	function acceptGovernance() external virtual {
		require(
			_msgSender() == _pendingGovernance,
			"GovernableTimelock::acceptGovernance: only pending governance can accept"
		);
		emit GovernanceChanged(_governance, _pendingGovernance);
		_governance = _pendingGovernance;
		_pendingGovernance = address(0);
	}

	/**
	 * @dev Leaves the contract without governance. It will not be possible to call
	 * `onlyGovernance` functions anymore. Can only be called by the current governance.
	 *
	 * NOTE: Renouncing governance will leave the contract without an governance,
	 * thereby removing any functionality that is only available to the governance.
	 */
	function removeGovernance() public virtual onlyGovernance {
		emit GovernanceChanged(_governance, address(0));
		_governance = address(0);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

interface IBlackbeard {
	/// @notice New governance proposal
	struct GovernanceProposal {
		uint256 eta;
		address gov;
	}

	/// @notice New RBAC update proposal
	struct RBACUpdateProposal {
		uint256 eta;
		bytes32 role;
		address[] authorized;
		bool revocation;
	}

	/// @notice New supply manager proposal
	struct SupplyManagerProposal {
		uint256 eta;
		address manager;
	}

	/// @notice New maximum supply proposal
	struct MaxSupplyProposal {
		uint256 eta;
		uint256 supply;
	}

	/// @notice New supply freeze period proposal
	struct SupplyFreezeProposal {
		uint256 eta;
		uint32 freeze;
	}

	/// @notice New proposal length proposal
	struct ProposalLengthProposal {
		uint256 eta;
		uint32 length;
	}

	/// @notice New metadata manager proposal
	struct MetadataManagerProposal {
		uint256 eta;
		address manager;
	}

	/// @notice New metadata manager proposal
	struct MetadataUpdateProposal {
		uint256 eta;
		string name;
		string symbol;
	}

	/// @notice Event emitted whenever a new governance is proposed
	event GovernanceProposed(address indexed oldGov, address indexed newGov, uint256 eta);

	/// @notice Event emitted whenever an admin proposal is canceled
	event GovernanceCanceled(address indexed proposedGov);

	/// @notice Event emitted whenever a new admin is accepted
	event GovernanceAccepted(address indexed oldGov, address indexed newGov);

	/// @notice Event emitted whenever a new RBAC update is proposed
	event RBACUpdateProposed(bytes32 indexed role, address[] indexed authorized, bool indexed revocation, uint256 eta);

	/// @notice Event emitted whenever a RBAC update is canceled
	event RBACUpdateCanceled(bytes32 indexed role, address[] indexed authorized, bool indexed revocation);

	/// @notice Event emitted whenever a RBAC update is accepted
	event RBACUpdateAccepted(bytes32 indexed role, address[] indexed authorized, bool indexed revocation);

	/// @notice Event emitted whenever a new mint cap is proposed
	event MaxSupplyProposed(uint256 indexed oldCap, uint256 indexed newCap, uint256 eta);

	/// @notice Event emitted whenever a mint cap proposal is canceled
	event MaxSupplyCanceled(uint256 indexed proposedCap);

	/// @notice Event emitted whenever a new mint cap is accepted
	event MaxSupplyAccepted(uint256 indexed oldCap, uint256 indexed newCap);

	/// @notice Event emitted whenever a new waiting period is proposed
	event SupplyFreezeProposed(uint32 indexed oldFreeze, uint32 indexed newFreeze, uint256 eta);

	/// @notice Event emitted whenever a waiting period proposal is canceled
	event SupplyFreezeCanceled(uint32 indexed proposedFreeze);

	/// @notice Event emitted whenever a new waiting period is accepted
	event SupplyFreezeAccepted(uint32 indexed oldFreeze, uint32 indexed newFreeze);

	/// @notice Event emitted whenever a new supply manager is proposed
	event SupplyManagerProposed(address indexed oldManager, address indexed newManager, uint256 eta);

	/// @notice Event emitted whenever a supply manager proposal is canceled
	event SupplyManagerCanceled(address indexed proposedManager);

	/// @notice Event emitted whenever a new supply manager is accepted
	event SupplyManagerAccepted(address indexed oldManager, address indexed newManager);

	/// @notice Event emitted whenever a new metadata manager is proposed
	event MetadataManagerProposed(address indexed oldManager, address indexed newManager, uint256 eta);

	/// @notice Event emitted whenever a metadata manager proposal is canceled
	event MetadataManagerCanceled(address indexed proposedManager);

	/// @notice Event emitted whenever a new metadata manager is accepted
	event MetadataManagerAccepted(address indexed oldManager, address indexed newManager);

	/// @notice Event emitted whenever a new metadata update is proposed
	event MetadataUpdateProposed(string indexed newName, string indexed newSymbol, uint256 eta);

	/// @notice Event emitted whenever a metadata update proposal is canceled
	event MetadataUpdateCanceled(string indexed newName, string indexed newSymbol);

	/// @notice Event emitted whenever a new metadata update is accepted
	event MetadataUpdateAccepted(
		string oldName,
		string indexed oldSymbol,
		string indexed newName,
		string indexed newSymbol
	);

	/// @notice Event emitted whenever a new proposal length is proposed
	event ProposalLengthProposed(uint32 indexed oldProposalLength, uint32 indexed newProposalLength, uint256 eta);

	/// @notice Event emitted whenever a proposal length proposal is canceled
	event ProposalLengthCanceled(uint32 indexed proposedProposalLength);

	/// @notice Event emitted whenever a new proposal length is accepted
	event ProposalLengthAccepted(uint32 indexed oldProposalLength, uint32 indexed newProposalLength);

	/// @notice Event emitted whenever new 🔱 tokens are successfully minted
	event JollyRogerSewed(address destination, uint256 amount);

	function proposeRBACUpdateProposal(
		bytes32 role,
		address[] memory authorized,
		bool revocation
	) external returns (uint256);

	function cancelRBACUpdateProposal() external;

	function acceptRBACUpdateProposal() external;

	function proposeGovernanceProposal(address newGov, bool emergency) external returns (uint256);

	function cancelGovernanceProposal() external;

	function acceptGovernanceProposal() external;

	function proposeProposalLengthProposal(uint32 newLength) external returns (uint256);

	function cancelProposalLengthProposal() external;

	function acceptProposalLengthProposal() external;

	function proposeSupplyManagerProposal(address newManager) external returns (uint256);

	function cancelSupplyManagerProposal() external;

	function acceptSupplyManagerProposal() external;

	function proposeSupplyFreezeProposal(uint32 newFreeze) external returns (uint256);

	function cancelSupplyFreezeProposal() external;

	function acceptSupplyFreezeProposal() external;

	function proposeMaxSupplyProposal(uint256 newMaxSupply) external returns (uint256);

	function cancelMaxSupplyProposal() external;

	function acceptMaxSupplyProposal() external;

	function proposeMetadataUpdateProposal(string memory newName, string memory newSymbol) external returns (uint256);

	function cancelMetadataUpdateProposal() external;

	function acceptMetadataUpdateProposal() external;

	function proposeMetadataManagerProposal(address newManager) external returns (uint256);

	function cancelMetadataManagerProposal() external;

	function acceptMetadataManagerProposal() external;

	function sew(address dst, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IJollyRoger is IERC20, IERC20Metadata {
	/// @notice An event that's emitted when the token maximum supply cap is changed
	event MaxSupplyChanged(uint256 indexed oldMaxSupply, uint256 indexed newMaxSupply);

	/// @notice An event that's emitted when the token supply change freeze period is changed
	event SupplyFreezeChanged(uint32 oldFreeze, uint32 indexed newFreeze);

	/// @notice An event that's emitted when the token metadata is updated
	event TokenMetadataUpdated(string indexed newName, string indexed newSymbol);

	/// @notice An event that's emitted when the token metadata manager is changed
	event MetadataManagerChanged(address indexed oldMM, address indexed newMM);

	/// @notice An event that's emitted when the token supply manager is changed
	event SupplyManagerChanged(address indexed oldSM, address indexed newSM);

	function maximumSupply() external view returns (uint256);

	function mintable() external view returns (uint256);

	function mint(address dst, uint256 amount) external returns (bool);

	function burn(address src, uint256 amount) external returns (bool);

	function increaseAllowance(address spender, uint256 amount) external returns (bool);

	function decreaseAllowance(address spender, uint256 amount) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function metadataManager() external view returns (address);

	function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);

	function supplyManager() external view returns (address);

	function supplyFreezeEnds() external view returns (uint256);

	function supplyFreeze() external view returns (uint32);

	function supplyFreezeMinimum() external view returns (uint32);

	function supplyGrowthMaximum() external view returns (uint256);

	function setSupplyManager(address newSupplyManager) external returns (bool);

	function setMetadataManager(address newMetadataManager) external returns (bool);

	function setSupplyFreeze(uint32 period) external returns (bool);

	function setMaximumSupply(uint256 newMaxSupply) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}