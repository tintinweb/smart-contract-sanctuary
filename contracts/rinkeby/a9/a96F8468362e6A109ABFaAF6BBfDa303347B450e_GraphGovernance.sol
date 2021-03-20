// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../upgrades/GraphUpgradeable.sol";

import "./GraphGovernanceStorage.sol";

/**
 * @title Graph Governance Contract
 * @notice Governance contract used to inscribe Graph Council and community votes.
 */
contract GraphGovernance is GraphGovernanceV1Storage, GraphUpgradeable, IGraphGovernance {
    // -- Events --

    event ProposalCreated(
        bytes32 proposalId,
        bytes32 votes,
        bytes32 metadata,
        ProposalResolution resolution
    );
    event ProposalUpdated(
        bytes32 proposalId,
        bytes32 votes,
        bytes32 metadata,
        ProposalResolution resolution
    );

    /**
     * @notice Initialize this contract.
     */
    function initialize(address _governor) public onlyImpl {
        Governed._initialize(_governor);
    }

    // -- Proposals --

    /**
     * @notice Return whether the proposal is created.
     * @param _proposalId Proposal identifier
     * @return True if the proposal is already created
     */
    function isProposalCreated(bytes32 _proposalId) public view override returns (bool) {
        return proposals[_proposalId].votes != 0;
    }

    /**
     * @notice Submit a new proposal.
     * @param _proposalId Proposal identifier. This is an IPFS hash to the content of the proposal
     * @param _votes An IPFS hash of the collection of signatures for each vote
     * @param _metadata A bytes32 field to attach metadata to the proposal if needed
     * @param _resolution Resolution choice, either Accepted or Rejected
     */
    function createProposal(
        bytes32 _proposalId,
        bytes32 _votes,
        bytes32 _metadata,
        ProposalResolution _resolution
    ) external override onlyGovernor {
        require(_proposalId != 0x0, "!proposalId");
        require(_votes != 0x0, "!votes");
        require(_resolution != ProposalResolution.Null, "!resolved");
        require(!isProposalCreated(_proposalId), "proposed");

        proposals[_proposalId] = Proposal({ votes: _votes, metadata: _metadata, resolution: _resolution });
        emit ProposalCreated(_proposalId, _votes, _metadata, _resolution);
    }

    /**
     * @notice Updates an existing proposal.
     * @param _proposalId Proposal identifier. This is an IPFS hash to the content of the proposal
     * @param _votes An IPFS hash of the collection of signatures for each vote
     * @param _metadata A bytes32 field to attach metadata to the proposal if needed
     * @param _resolution Resolution choice, either Accepted or Rejected
     */
    function updateProposal(
        bytes32 _proposalId,
        bytes32 _votes,
        bytes32 _metadata,
        ProposalResolution _resolution
    ) external override onlyGovernor {
        require(_proposalId != 0x0, "!proposalId");
        require(_votes != 0x0, "!votes");
        require(_resolution != ProposalResolution.Null, "!resolved");
        require(isProposalCreated(_proposalId), "!proposed");

        proposals[_proposalId] = Proposal({ votes: _votes, metadata: _metadata, resolution: _resolution });
        emit ProposalUpdated(_proposalId, _votes, _metadata, _resolution);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl {
        require(msg.sender == _implementation(), "Caller must be the implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Accept to be an implementation of proxy.
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @dev Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Governed.sol";
import "./IGraphGovernance.sol";

contract GraphGovernanceV1Storage is Governed {
    struct Proposal {
        bytes32 votes;      // IPFS hash of signed votes
        bytes32 metadata;   // Additional info that can be linked
        IGraphGovernance.ProposalResolution resolution;
    }

    // -- State --

    // Proposals are identified by a IPFS Hash used as proposalId
    // The `proposalId` must link to the content of the proposal
    mapping(bytes32 => Proposal) public proposals;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Graph Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
    // -- State --

    address public governor;
    address public pendingGovernor;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IGraphGovernance {
    enum ProposalResolution { Null, Accepted, Rejected }

    // -- Proposals --

    function isProposalCreated(bytes32 _proposalId) external view returns (bool);

    function createProposal(
        bytes32 _proposalId,
        bytes32 _votes,
        bytes32 _metadata,
        ProposalResolution _resolution
    ) external;

    function updateProposal(
        bytes32 _proposalId,
        bytes32 _votes,
        bytes32 _metadata,
        ProposalResolution _resolution
    ) external;
}