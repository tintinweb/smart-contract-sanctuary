pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../interfaces/IRaritySocietyDAO.sol';
import './RaritySocietyDAOStorage.sol';

contract RaritySocietyDAOImpl is RaritySocietyDAOStorageV1, IRaritySocietyDAO, ERC165 {

    string public constant name = 'Rarity Society DAO';

	uint256 public constant MIN_PROPOSAL_THRESHOLD = 1;

	uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 10%

	uint public constant MIN_VOTING_PERIOD = 6400; // 1 day

	uint public constant MAX_VOTING_PERIOD = 134000; // 3 Weeks

	uint256 public constant MIN_VOTING_DELAY = 1; 

	uint256 public constant MAX_VOTING_DELAY = 45000; // 1 Week

	uint256 public constant MIN_QUORUM_VOTES_BPS = 200; // 2%

	uint256 public constant MAX_QUORUM_VOTES_BPS = 2_000; // 20%

	uint256 public constant PROPOSAL_MAX_OPERATIONS = 10;

	bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;
    uint256 private _CACHED_CHAIN_ID;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;


	modifier onlyAdmin() {
		require(msg.sender == admin, "admin only");
		_;
	}

	modifier onlyPendingAdmin() {
		require(msg.sender == pendingAdmin, "pending admin only");
		_;
	}

	function initialize(
		address timelock_,
		address token_,
		address vetoer_,
		uint256 votingPeriod_,
		uint256 votingDelay_,
		uint256 proposalThreshold_,
		uint256 quorumVotesBPS_
	) public onlyAdmin {
		require(address(timelock) == address(0), 'initializable only once');
        require(token_ != address(0), 'invalid governance token address');
        require(timelock_ != address(0), 'invalid timelock address');
        require(
            votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD,
            'invalid voting period'
        );
        require(
            votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY,
            'invalid voting delay'
        );
        require(
            quorumVotesBPS_ >= MIN_QUORUM_VOTES_BPS && quorumVotesBPS_ <= MAX_QUORUM_VOTES_BPS,
            'invalid quorum votes threshold'
        );

        emit VotingPeriodSet(votingPeriod, votingPeriod_);
        emit VotingDelaySet(votingDelay, votingDelay_);
        emit ProposalThresholdSet(proposalThreshold, proposalThreshold_);
        emit QuorumVotesBPSSet(quorumVotesBPS, quorumVotesBPS_);

        token = IRaritySocietyDAOToken(token_);
		timelock = ITimelock(timelock_);
		vetoer = vetoer_;
		votingPeriod = votingPeriod_;
		votingDelay = votingDelay_;
		proposalThreshold = proposalThreshold_;
		quorumVotesBPS = quorumVotesBPS_;

        bytes32 hashedName = keccak256(bytes("Rarity Society DAO"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;

        require(
            proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD && proposalThreshold_ <= maxProposalThreshold(),
            'invalid proposal threshold'
        );

	}

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            token.getPriorVotes(msg.sender, block.number - 1) >= proposalThreshold,
            'proposer votes below proposal threshold'
        );
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            'proposal function arity mismatch'
        );
        require(targets.length != 0, 'actions not provided');
        require(targets.length <= PROPOSAL_MAX_OPERATIONS, 'too many actions');

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState latestProposalState = state(latestProposalId);
            require(latestProposalState != ProposalState.Pending, "One proposal per proposer - pending proposal already found");
            require(latestProposalState != ProposalState.Active, "One proposal per proposer - active proposal already found");
        }

        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.quorumVotes = max(1, bps2Uint(quorumVotesBPS, token.totalSupply()));
        proposal.eta = 0;
        proposal.targets = targets;
        proposal.values = values;
        proposal.signatures = signatures;
        proposal.calldatas = calldatas;
        proposal.startBlock = startBlock;
        proposal.endBlock = endBlock;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.abstainVotes = 0;
        proposal.canceled = false;
        proposal.executed = false;
        proposal.vetoed = false;
        latestProposalIds[proposal.proposer] = proposal.id;

        emit ProposalCreated(
            proposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            proposal.quorumVotes,
            description
        );

        return proposal.id;
    }

    function queue(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded,
            'proposal queueable only if succeeded'
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i],
            proposal.values[i],
            proposal.signatures[i],
            proposal.calldatas[i],
            eta
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            'identical proposal already queued at eta'
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Queued,
            'proposal can only be executed if queued'
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external {
        require(state(proposalId) != ProposalState.Executed, 'proposal already executed');
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer ||
            token.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold,
            'only proposer can cancel unless their votes drop below proposal threshold'
        );
        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalCanceled(proposalId);
    }

    function veto(uint256 proposalId) external {
        require(vetoer != address(0), 'veto power burned');
        require(msg.sender == vetoer, 'only vetoer can veto');
        require(state(proposalId) != ProposalState.Executed, 'cannot veto executed proposal');
        Proposal storage proposal = proposals[proposalId];

        proposal.vetoed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalVetoed(proposalId);
    }

    function getActions(uint256 proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

	function state(uint256 proposalId) public view override returns (ProposalState) {
		require(proposalCount >= proposalId, "Invalid proposal ID");
		Proposal storage proposal = proposals[proposalId];
		if (proposal.vetoed) {
			return ProposalState.Vetoed;
		} else if (proposal.canceled) {
			return ProposalState.Canceled;
		} else if (block.number <= proposal.startBlock) {
			return ProposalState.Pending;
		} else if (block.number <= proposal.endBlock) {
			return ProposalState.Active;
		} else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
			return ProposalState.Defeated;
		} else if (proposal.eta == 0) {
			return ProposalState.Succeeded;
		} else if (proposal.executed) {
			return ProposalState.Executed;
		} else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
			return ProposalState.Expired;
		} else {
			return ProposalState.Queued;
		}
	}

	function castVote(uint256 proposalId, uint8 support) external override {
		emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
	}

	function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external override {
		emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
	}

	function castVoteBySig(
		uint256 proposalId,
		uint8 support,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override {
		address signatory = ECDSA.recover(
			_hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
			v,
			r,
			s
		);
		emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
	}

	function castVoteInternal(
		address voter,
		uint256 proposalId,
		uint8 support
	) internal returns (uint32) {
		require(state(proposalId) == ProposalState.Active, 'voting is closed');
		require(support <= 2, 'invalid vote type');
		Proposal storage proposal = proposals[proposalId];
		Receipt storage receipt = proposal.receipts[voter];
		require(!receipt.hasVoted, "voter already voted!");

		uint32 votes = token.getPriorVotes(voter, proposal.startBlock - votingDelay);
		if (support == 0) {
			proposal.againstVotes = proposal.againstVotes + votes;
		} else if (support == 1) {
			proposal.forVotes = proposal.forVotes + votes;
		} else if (support == 2) {
			proposal.abstainVotes = proposal.abstainVotes + votes;
		}

		receipt.hasVoted = true;
		receipt.support = support;
		receipt.votes = votes;
		return votes;
	}

	function setVotingDelay(uint256 newVotingDelay) external override onlyAdmin {
		require(
			newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY,
			'invalid voting delay'
		);
		uint256 oldVotingDelay = votingDelay;
		votingDelay = newVotingDelay;

		emit VotingDelaySet(oldVotingDelay, votingDelay);
	}

	function setQuorumVotesBPS(uint256 newQuorumVotesBPS) external override onlyAdmin {
		require(
			newQuorumVotesBPS >= MIN_QUORUM_VOTES_BPS && newQuorumVotesBPS <= MAX_QUORUM_VOTES_BPS,
			'invalid quorum votes threshold set'
		);
		uint256 oldQuorumVotesBPS = quorumVotesBPS;
		quorumVotesBPS = newQuorumVotesBPS;
		emit QuorumVotesBPSSet(oldQuorumVotesBPS, quorumVotesBPS);
	}


	function setVotingPeriod(uint256 newVotingPeriod) external override onlyAdmin {
		require(
			newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD,
			"invalid voting period"
		);
		uint256 oldVotingPeriod = votingPeriod;
		votingPeriod = newVotingPeriod;

		emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
	}

	function setProposalThreshold(uint256 newProposalThreshold) external override onlyAdmin {
		require(newProposalThreshold >= MIN_PROPOSAL_THRESHOLD &&
			newProposalThreshold <= maxProposalThreshold(),
			'invalid proposal threshold'
		);
		uint256 oldProposalThreshold = proposalThreshold;
		proposalThreshold = newProposalThreshold;

		emit ProposalThresholdSet(oldProposalThreshold, newProposalThreshold);
	}

	function setPendingAdmin(address _pendingAdmin) external override onlyAdmin {
		address oldPendingAdmin = pendingAdmin;
		pendingAdmin = _pendingAdmin;

		emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
	}

    function setVetoer(address _vetoer) public {
        require(msg.sender == vetoer, 'vetoer only');
        emit NewVetoer(vetoer, _vetoer);
        vetoer = _vetoer;
    }

    function revokeVetoPower() external {
        require(msg.sender == vetoer, 'vetoer only');
        setVetoer(address(0));
    }

	function acceptAdmin() external override onlyPendingAdmin {
		require(pendingAdmin != address(0), 'pending admin not yet set!');

		address oldAdmin = admin;
		address oldPendingAdmin = pendingAdmin;

		admin = pendingAdmin;
		pendingAdmin = address(0);

		emit NewAdmin(oldAdmin, admin);
		emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
	}

	function maxProposalThreshold() public view returns (uint256) {
		return max(MIN_PROPOSAL_THRESHOLD, bps2Uint(MAX_PROPOSAL_THRESHOLD_BPS, token.totalSupply()));
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
		return interfaceId == type(IRaritySocietyDAO).interfaceId || super.supportsInterface(interfaceId);
	}

	function bps2Uint(uint256 bps, uint number) internal pure returns (uint256) {
		return (number * bps) / 10000;
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

pragma solidity ^0.8.9;

interface IRaritySocietyDAO {

    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 quorumVotes,
        string description
    );

    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    event ProposalCanceled(uint256 id);

    event ProposalQueued(uint id, uint eta);

    event ProposalExecuted(uint id);

    event ProposalVetoed(uint256 id);

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    event NewVetoer(address oldVetoer, address newVetoer);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;

    function cancel(uint256 proposalId) external;

    function veto(uint256 proposalId) external;

    function castVote(uint256 proposalId, uint8 support) external;

    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getActions(uint256 proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    );

    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);


    function state(uint256 proposalId) external view returns (ProposalState);

    function setVotingDelay(uint256 newVotingDelay) external;

    function setVotingPeriod(uint256 newVotingPeriod) external;

    function setProposalThreshold(uint256 newProposalThreshol) external;

    function setQuorumVotesBPS(uint256 newQuorumVotesBPS) external;

    function setVetoer(address newVetoer) external;

    function revokeVetoPower() external;

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

	function maxProposalThreshold() external view returns (uint256);

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 quorumVotes;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool vetoed;
        bool canceled;
        bool executed;
        mapping(address => Receipt) receipts;
    }


    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint32 votes;
    }



}

pragma solidity ^0.8.9;

import '../interfaces/ITimelock.sol';
import '../interfaces/IRaritySocietyDAOToken.sol';
import '../interfaces/IRaritySocietyDAO.sol';

contract RaritySocietyDAOProxyStorage {

    address public admin;
    address public pendingAdmin;
    address public impl;
}

contract RaritySocietyDAOStorageV1 is RaritySocietyDAOProxyStorage {

    address public vetoer;

    uint256 public votingPeriod;

    uint256 public votingDelay;

    uint256 public proposalThreshold;

    uint256 public quorumVotesBPS;

    uint256 public proposalCount;

    ITimelock public timelock;

    IRaritySocietyDAOToken public token;

    mapping(uint256 => IRaritySocietyDAO.Proposal) public proposals;

    mapping(address => uint256) public latestProposalIds;

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

interface ITimelock {
    event NewAdmin(address oldAdmin, address newAdmin);

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewDelay(uint256 oldDelay, uint256 newDelay);

	event CancelTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event ExecuteTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event QueueTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    function setPendingAdmin(address pendingAdmin) external;

    function setDelay(uint256 delay) external;

    function delay() external view returns (uint256);

    function acceptAdmin() external;

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes memory);

    function queuedTransactions(bytes32 hash) external view returns (bool);
	function GRACE_PERIOD() external view returns (uint256);
}

pragma solidity ^0.8.9;

interface IRaritySocietyDAOToken {

    function getPriorVotes(address account, uint blockNumber) external view returns (uint32);

    function totalSupply() external view returns (uint32);

}