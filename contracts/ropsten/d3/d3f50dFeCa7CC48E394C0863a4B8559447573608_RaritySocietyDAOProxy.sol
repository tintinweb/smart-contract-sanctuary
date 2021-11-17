pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Address.sol';
import './RaritySocietyDAOStorage.sol';

contract RaritySocietyDAOProxy is RaritySocietyDAOProxyStorage {

     event NewImpl(address oldImplementation, address newImplementation);

	constructor(
		address timelock_,
		address token_,
		address vetoer_,
		address admin_,
		address impl_,
		uint256 votingPeriod_,
		uint256 votingDelay_,
		uint256 proposalThreshold_,
		uint256 quorumVotesBPS_
	){
		admin = msg.sender;

		delegateTo(impl_, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,uint256,uint256)",
			timelock_,
			token_,
			vetoer_,
			votingPeriod_,
			votingDelay_,
			proposalThreshold_,
			quorumVotesBPS_
		));
		
		setImpl(impl_);

		admin = admin_;
	}

	function setImpl(address impl_) public {
		require(msg.sender == admin, "setImpl may only be called by admin");
		require(impl_ != address(0), "implementation is not a contract");

		address oldImpl = impl;
		impl = impl_;

		emit NewImpl(oldImpl, impl);
	}

	function delegateTo(address callee, bytes memory data) internal {
		(bool success, bytes memory returnData) = callee.delegatecall(data);
		assembly {
			if eq(success, 0) {
				revert(add(returnData, 0x20), returndatasize())
			}
		}
	}

	function _fallback() internal {
		(bool success, ) = impl.delegatecall(msg.data);
		assembly {
			let m := mload(0x40)
			returndatacopy(m, 0, returndatasize())

			switch success
			case 0 { revert(m, returndatasize()) }
			default { return(m, returndatasize()) }
		}
	}

	fallback() external payable {
		_fallback();
	}

	receive() external payable {
		_fallback();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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