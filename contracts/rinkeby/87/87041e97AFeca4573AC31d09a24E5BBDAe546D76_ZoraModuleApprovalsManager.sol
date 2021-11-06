// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

import {ZoraProposalManager} from "./ZoraProposalManager.sol";

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract allows users to explicitly allow modules access to the ZORA transfer helpers on their behalf
contract ZoraModuleApprovalsManager {
    /// @notice The address of the proposal manager, manages allowed modules
    ZoraProposalManager public proposalManager;

    /// @notice Mapping of specific approvals for (module, user) pairs in the ZORA registry
    mapping(address => mapping(address => bool)) public userApprovals;

    event ModuleApprovalSet(address indexed user, address indexed module, bool approved);
    event AllModulesApprovalSet(address indexed user, bool approved);

    /// @param _proposalManager The address of the ZORA proposal manager
    constructor(address _proposalManager) {
        proposalManager = ZoraProposalManager(_proposalManager);
    }

    /// @notice Returns true if the user has approved a given module, false otherwise
    /// @param _user The user to check approvals for
    /// @param _module The module to check approvals for
    /// @return True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module) external view returns (bool) {
        return userApprovals[_user][_module];
    }

    /// @notice Allows a user to set the approval for a given module
    /// @param _moduleAddress The module to approve
    /// @param _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _moduleAddress, bool _approved) public {
        require(proposalManager.isPassedProposal(_moduleAddress), "ZMAM::module must be approved");

        userApprovals[msg.sender][_moduleAddress] = _approved;

        emit ModuleApprovalSet(msg.sender, _moduleAddress, _approved);
    }

    /// @notice Sets approvals for multiple modules at once
    /// @param _moduleAddresses The list of module addresses to set approvals for
    /// @param _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(address[] memory _moduleAddresses, bool _approved) public {
        for (uint256 i = 0; i < _moduleAddresses.length; i++) {
            setApprovalForModule(_moduleAddresses[i], _approved);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract accepts proposals and registers new modules, granting them access to the ZORA Module Approval Manager
contract ZoraProposalManager {
    enum ProposalStatus {
        Nonexistent,
        Pending,
        Passed,
        Failed
    }
    /// @notice A Proposal object that tracks a proposal and its status
    /// @member proposer The address that created the proposal
    /// @member status The status of the proposal (see ProposalStatus)
    struct Proposal {
        address proposer;
        ProposalStatus status;
    }

    /// @notice The registrar address that can register, or cancel
    address public registrar;
    /// @notice A mapping of module addresses to proposals
    mapping(address => Proposal) public proposedModuleToProposal;

    event ModuleProposed(address indexed contractAddress, address indexed proposer);
    event ModuleRegistered(address indexed contractAddress);
    event ModuleCanceled(address indexed contractAddress);
    event RegistrarChanged(address indexed newRegistrar);

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "ZPM::onlyRegistrar must be registrar");
        _;
    }

    /// @param _registrarAddress The initial registrar for the manager
    constructor(address _registrarAddress) {
        require(_registrarAddress != address(0), "ZPM::must set registrar to non-zero address");

        registrar = _registrarAddress;
    }

    /// @notice Returns true if the module has been registered
    /// @param _proposalImpl The address of the proposed module
    /// @return True if the module has been registered, false otherwise
    function isPassedProposal(address _proposalImpl) public view returns (bool) {
        return proposedModuleToProposal[_proposalImpl].status == ProposalStatus.Passed;
    }

    /// @notice Creates a new proposal for a module
    /// @param _impl The address of the deployed module being proposed
    function proposeModule(address _impl) public {
        require(proposedModuleToProposal[_impl].proposer == address(0), "ZPM::proposeModule proposal already exists");
        require(_impl != address(0), "ZPM::proposeModule proposed contract cannot be zero address");

        Proposal memory proposal = Proposal({proposer: msg.sender, status: ProposalStatus.Pending});
        proposedModuleToProposal[_impl] = proposal;

        emit ModuleProposed(_impl, msg.sender);
    }

    /// @notice Registers a proposed module
    /// @param _proposalAddress The address of the proposed module
    function registerModule(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::registerModule can only register pending proposals");

        proposal.status = ProposalStatus.Passed;

        emit ModuleRegistered(_proposalAddress);
    }

    /// @notice Cancels a proposed module
    /// @param _proposalAddress The address of the proposed module
    function cancelProposal(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::cancelProposal can only cancel pending proposals");

        proposal.status = ProposalStatus.Failed;

        emit ModuleCanceled(_proposalAddress);
    }

    /// @notice Sets the registrar for this manager
    /// @param _registrarAddress the address of the new registrar
    function setRegistrar(address _registrarAddress) public onlyRegistrar {
        require(_registrarAddress != address(0), "ZPM::setRegistrar must set registrar to non-zero address");
        registrar = _registrarAddress;

        emit RegistrarChanged(_registrarAddress);
    }
}