// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQBridgeHandler.sol";
import "../library/PausableUpgradeable.sol";
import "../library/AccessControlIndexUpgradeable.sol";
import "../library/SafeToken.sol";


contract QBridge is PausableUpgradeable, AccessControlIndexUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    uint public constant MAX_RELAYERS = 200;

    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}

    struct Proposal {
        ProposalStatus _status;
        uint200 _yesVotes;      // bitmap, 200 maximum votes
        uint8 _yesVotesTotal;
        uint40 _proposedBlock; // 1099511627775 maximum block
    }

    /* ========== STATE VARIABLES ========== */

    uint8 public domainID;
    uint8 public relayerThreshold;
    uint128 public fee;
    uint40 public expiry;

    mapping(uint8 => uint64) public _depositCounts; // destinationDomainID => number of deposits
    mapping(bytes32 => address) public resourceIDToHandlerAddress; // resourceID => handler address
    mapping(uint72 => mapping(bytes32 => Proposal)) private _proposals; // destinationDomainID + depositNonce => dataHash => Proposal

    /* ========== EVENTS ========== */

    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(uint8 destinationDomainID, bytes32 resourceID, uint64 depositNonce, address indexed user, bytes data);
    event ProposalEvent(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes32 dataHash);
    event ProposalVote(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes32 dataHash);
    event FailedHandlerExecution(bytes lowLevelData);

    /* ========== INITIALIZER ========== */

    function initialize(uint8 _domainID, uint8 _relayerThreshold, uint128 _fee, uint40 _expiry) external initializer {
        __PausableUpgradeable_init();
        __AccessControl_init();

        domainID = _domainID;
        relayerThreshold = _relayerThreshold;
        fee = _fee;
        expiry = _expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRelayers() {
        require(hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the relayer");
        _;
    }

    modifier onlyOwnerOrRelayers() {
        require(owner() == msg.sender || hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the owner or relayer");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRelayerThreshold(uint8 newThreshold) external onlyOwner {
        relayerThreshold = newThreshold;
        emit RelayerThresholdChanged(newThreshold);
    }

    function addRelayer(address relayer) external onlyOwner {
        require(!hasRole(RELAYER_ROLE, relayer), "QBridge: duplicated relayer");
        require(totalRelayers() < MAX_RELAYERS, "QBridge: relayers limit reached");
        grantRole(RELAYER_ROLE, relayer);
        emit RelayerAdded(relayer);
    }

    function removeRelayer(address relayer) external onlyOwner {
        require(hasRole(RELAYER_ROLE, relayer), "QBridge: invalid relayer");
        revokeRole(RELAYER_ROLE, relayer);
        emit RelayerRemoved(relayer);
    }

    function setResource(address handlerAddress, bytes32 resourceID, address tokenAddress) external onlyOwner {
        resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IQBridgeHandler(handlerAddress).setResource(resourceID, tokenAddress);
    }

    function setBurnable(address handlerAddress, address tokenAddress) external onlyOwner {
        IQBridgeHandler(handlerAddress).setBurnable(tokenAddress);
    }

    function setDepositNonce(uint8 _domainID, uint64 nonce) external onlyOwner {
        require(nonce > _depositCounts[_domainID], "QBridge: decrements not allowed");
        _depositCounts[_domainID] = nonce;
    }

    function setFee(uint128 newFee) external onlyOwner {
        fee = newFee;
    }

    function manualRelease(address handlerAddress, address tokenAddress, address recipient, uint amount) external onlyOwner {
        IQBridgeHandler(handlerAddress).withdraw(tokenAddress, recipient, amount);
    }

    function sweep() external onlyOwner {
        SafeToken.safeTransferETH(msg.sender, address(this).balance);
    }

    /* ========== VIEWS ========== */

    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    function totalRelayers() public view returns (uint) {
        return AccessControlIndexUpgradeable.getRoleMemberCount(RELAYER_ROLE);
    }

    /**
        @notice Returns a proposalID.
        @param _domainID Chain ID.
        @param nonce ID of proposal generated by proposal's origin Bridge contract.
     */
    function combinedProposalId(uint8 _domainID, uint64 nonce) public pure returns (uint72 proposalID) {
        proposalID = (uint72(nonce) << 8) | uint72(_domainID);
    }

    /**
        @notice Returns a proposal.
        @param originDomainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(uint8 originDomainID, uint64 depositNonce, bytes32 dataHash, address relayer) external view returns (Proposal memory proposal, bool hasVoted) {
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        proposal = _proposals[proposalID][dataHash];
        hasVoted = _hasVoted(proposal, relayer);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param data Additional data to be passed to specified handler.
        @notice Emits {Deposit} event with all necessary parameters
     */
    function deposit(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external payable notPaused {
        require(msg.value == fee, "QBridge: invalid fee");

        address handler = resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "QBridge: invalid resourceID");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IQBridgeHandler(handler).deposit(resourceID, msg.sender, data);
        emit Deposit(destinationDomainID, resourceID, depositNonce, msg.sender, data);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data) external onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        require(handlerAddress != address(0), "QBridge: invalid handler");

        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal memory proposal = _proposals[proposalID][dataHash];

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, true);
            return;
        }

        require(uint(proposal._status) <= 1, "QBridge: proposal already executed/cancelled");
        require(!_hasVoted(proposal, msg.sender), "QBridge: relayer already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status : ProposalStatus.Active, _yesVotes : 0, _yesVotesTotal : 0, _proposedBlock : uint40(block.number)});
            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Active, dataHash);
        } else if (uint40(block.number.sub(proposal._proposedBlock)) > expiry) {
            proposal._status = ProposalStatus.Cancelled;
            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, dataHash);
        }

        if (proposal._status != ProposalStatus.Cancelled) {
            proposal._yesVotes = _bitmap(proposal._yesVotes, _relayerBit(msg.sender));
            proposal._yesVotesTotal++;
            emit ProposalVote(originDomainID, depositNonce, proposal._status, dataHash);

            if (proposal._yesVotesTotal >= relayerThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Passed, dataHash);
            }
        }
        _proposals[proposalID][dataHash] = proposal;

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, false);
        }
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Data originally provided when deposit was made.
        @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
        @notice Emits {FailedExecution} event with the failed reason.
     */
    function executeProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data, bool revertOnFail) public onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal storage proposal = _proposals[proposalID][dataHash];

        require(proposal._status == ProposalStatus.Passed, "QBridge: Proposal must have Passed status");

        proposal._status = ProposalStatus.Executed;
        IQBridgeHandler handler = IQBridgeHandler(handlerAddress);

        if (revertOnFail) {
            handler.executeProposal(resourceID, data);
        } else {
            try handler.executeProposal(resourceID, data) {
            } catch (bytes memory lowLevelData) {
                proposal._status = ProposalStatus.Passed;
                emit FailedHandlerExecution(lowLevelData);
                return;
            }
        }
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Executed, dataHash);
    }

    /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(uint8 originDomainID, uint64 depositNonce, bytes32 dataHash) public onlyOwnerOrRelayers {
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        Proposal memory proposal = _proposals[proposalID][dataHash];
        ProposalStatus currentStatus = proposal._status;

        require(currentStatus == ProposalStatus.Active || currentStatus == ProposalStatus.Passed, "QBridge: cannot be cancelled");
        require(uint40(block.number.sub(proposal._proposedBlock)) > expiry, "QBridge: not at expiry threshold");

        proposal._status = ProposalStatus.Cancelled;
        _proposals[proposalID][dataHash] = proposal;
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, dataHash);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _relayerBit(address relayer) private view returns (uint) {
        if (relayer == address(0)) return 0;
        return uint(1) << AccessControlIndexUpgradeable.getRoleMemberIndex(RELAYER_ROLE, relayer).sub(1);
    }

    function _hasVoted(Proposal memory proposal, address relayer) private view returns (bool) {
        return (_relayerBit(relayer) & uint(proposal._yesVotes)) > 0;
    }

    function _bitmap(uint200 source, uint bit) internal pure returns (uint200) {
        uint value = source | bit;
        require(value < 2 ** 200, "QBridge: value does not fit in 200 bits");
        return uint200(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


interface IQBridgeHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;

    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;

    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(bytes32 resourceID, address depositer, bytes calldata data) external;

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external;

    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amount the amount of ERC20 tokens to release.
     */
    function withdraw(address tokenAddress, address recipient, uint amount) external;
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "PausableUpgradeable: cannot be performed while the contract is paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "PausableUpgradeable: owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlIndexUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the index of the account that have `role`.
     */
    function getRoleMemberIndex(bytes32 role, address account) public view returns (uint256) {
        return _roles[role].members._inner._indexes[bytes32(uint256(account))];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPresaleLocker.sol";
import "../interfaces/IQubitPresale.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/SafeToken.sol";

contract QubitPresaleTester is IQubitPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant BUNNY_WBNB_LP = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address public constant QBT_WBNB_LP = 0x67EFeF66A55c4562144B9AcfCFbc62F9E4269b3e;

    address public constant DEPLOYER = 0xbeE397129374D0b4db7bf1654936951e5bdfe5a6;

    IPancakeRouter02 private constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    uint public startTime;
    uint public endTime;
    uint public presaleAmountUSD;
    uint public totalBunnyBnbLp;
    uint public qbtAmount;
    uint public override qbtBnbLpAmount;
    uint public override lpPriceAtArchive;
    uint private _distributionCursor;

    mapping(address => uint) public bunnyBnbLpOf;
    mapping(address => bool) public claimedOf;
    address[] public accountList;
    bool public archived;

    IPresaleLocker public qbtBnbLocker;

    mapping(address => uint) public refundLpOf;
    address public QBT;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint amount);
    event Distributed(uint length, uint remain);

    /* ========== INITIALIZER ========== */

    function initialize(
        uint _startTime,
        uint _endTime,
        uint _presaleAmountUSD,
        uint _qbtAmount,
        address _qbtAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        startTime = _startTime;
        endTime = _endTime;
        presaleAmountUSD = _presaleAmountUSD;
        qbtAmount = _qbtAmount;
        QBT = _qbtAddress;

        BUNNY_WBNB_LP.safeApprove(address(router), uint(~0));
        QBT.safeApprove(address(router), uint(~0));
        BUNNY.safeApprove(address(router), uint(~0));
        WBNB.safeApprove(address(router), uint(~0));
    }

    /* ========== VIEWS ========== */

    function allocationOf(address _user) public view override returns (uint) {
        return totalBunnyBnbLp == 0 ? 0 : bunnyBnbLpOf[_user].mul(1e18).div(totalBunnyBnbLp);
    }

    function refundOf(address _user) public view override returns (uint) {
        uint lpPriceNow = lpPriceAtArchive;
        if (lpPriceAtArchive == 0) {
            (, lpPriceNow) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        }

        if (totalBunnyBnbLp.mul(lpPriceNow).div(1e18) <= presaleAmountUSD) {
            return 0;
        }

        uint lpAmountToPay = presaleAmountUSD.mul(allocationOf(_user)).div(lpPriceNow);
        return bunnyBnbLpOf[_user].sub(lpAmountToPay);
    }

    function accountListLength() external view override returns (uint) {
        return accountList.length;
    }

    function presaleDataOf(address account) public view returns (PresaleData memory) {
        PresaleData memory presaleData;
        presaleData.startTime = startTime;
        presaleData.endTime = endTime;
        presaleData.userLpAmount = bunnyBnbLpOf[account];
        presaleData.totalLpAmount = totalBunnyBnbLp;
        presaleData.claimedOf = claimedOf[account];
        presaleData.refundLpAmount = refundLpOf[account];
        presaleData.qbtBnbLpAmount = qbtBnbLpAmount;

        return presaleData;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setQubitBnbLocker(address _qubitBnbLocker) public override onlyOwner {
        require(_qubitBnbLocker != address(0), "QubitPresale: invalid address");

        qbtBnbLocker = IPresaleLocker(_qubitBnbLocker);
        qbtBnbLocker.setPresaleEndTime(endTime);
        QBT_WBNB_LP.safeApprove(address(qbtBnbLocker), uint(~0));
    }

    function setPresaleAmountUSD(uint _presaleAmountUSD) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        presaleAmountUSD = _presaleAmountUSD;
    }

    function setPeriod(uint _start, uint _end) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");
        require(block.timestamp < _start && _start < _end, "QubitPresale: invalid time values");
        require(address(qbtBnbLocker) != address(0), "QubitPresale: QbtBnbLocker must be set");

        startTime = _start;
        endTime = _end;

        qbtBnbLocker.setPresaleEndTime(endTime);
    }

    function setQbtAmount(uint _qbtAmount) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        qbtAmount = _qbtAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        require(block.timestamp > startTime && block.timestamp < endTime, "QubitPresale: not in presale");
        require(_amount > 0, "QubitPresale: invalid amount");

        if (bunnyBnbLpOf[msg.sender] == 0) {
            accountList.push(msg.sender);
        }
        bunnyBnbLpOf[msg.sender] = bunnyBnbLpOf[msg.sender].add(_amount);
        totalBunnyBnbLp = totalBunnyBnbLp.add(_amount);

        BUNNY_WBNB_LP.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function archive() public override onlyOwner returns (uint bunnyAmount, uint wbnbAmount) {
        require(!archived && qbtBnbLpAmount == 0, "QubitPresale: already archived");
        require(IBEP20(QBT).balanceOf(address(this)) == qbtAmount, "QubitPresale: lack of QBT");
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        (, lpPriceAtArchive) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        require(lpPriceAtArchive > 0, "QubitPresale: invalid lp price");
        uint presaleAmount = presaleAmountUSD.div(lpPriceAtArchive).mul(1e18);

        // burn manually transferred LP token
        if (IPancakePair(BUNNY_WBNB_LP).balanceOf(BUNNY_WBNB_LP) > 0) {
            IPancakePair(BUNNY_WBNB_LP).burn(DEPLOYER);
        }

        uint amount = Math.min(totalBunnyBnbLp, presaleAmount);
        (bunnyAmount, wbnbAmount) = router.removeLiquidity(BUNNY, WBNB, amount, 0, 0, address(this), block.timestamp);
        BUNNY.safeTransfer(DEAD, bunnyAmount);

        uint qbtAmountFixed = presaleAmount < totalBunnyBnbLp
            ? qbtAmount
            : qbtAmount.mul(totalBunnyBnbLp).div(presaleAmount);
        (, , qbtBnbLpAmount) = router.addLiquidity(
            QBT,
            WBNB,
            qbtAmountFixed,
            wbnbAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        archived = true;
    }

    function distribute(uint distributeThreshold) external override onlyOwner {
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        require(archived, "QubitPresale: not yet archived");
        uint start = _distributionCursor;
        uint totalUserCount = accountList.length;
        uint remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        uint length = Math.min(remain, distributeThreshold);
        for (uint i = start; i < start + length; i++) {
            address account = accountList[i];
            if (!claimedOf[account]) {
                claimedOf[account] = true;

                uint refundingLpAmount = refundOf(account);
                if (refundingLpAmount > 0 && refundLpOf[account] == 0) {
                    refundLpOf[account] = refundingLpAmount;
                    BUNNY_WBNB_LP.safeTransfer(account, refundingLpAmount);
                }

                uint depositLpAmount = qbtBnbLpAmount.mul(allocationOf(account)).div(1e18);
                if (depositLpAmount > 0) {
                    delete bunnyBnbLpOf[account];
                    // block qbtBnbLocker for test
                    // qbtBnbLocker.depositBehalf(account, depositLpAmount);
                }
            }
            _distributionCursor++;
        }
        remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        emit Distributed(length, remain);
    }

    function sweep(uint _lpAmount, uint _offerAmount) public override onlyOwner {
        require(_lpAmount <= IBEP20(BUNNY_WBNB_LP).balanceOf(address(this)), "QubitPresale: not enough token 0");
        require(_offerAmount <= IBEP20(QBT).balanceOf(address(this)), "QubitPresale: not enough token 1");
        BUNNY_WBNB_LP.safeTransfer(msg.sender, _lpAmount);
        QBT.safeTransfer(msg.sender, _offerAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IPresaleLocker {
    function setPresale(address _presaleContract) external;

    function setPresaleEndTime(uint endTime) external;

    function balanceOf(address account) external view returns (uint);

    function withdrawableBalanceOf(address account) external view returns (uint);

    function depositBehalf(address account, uint balance) external;

    function withdraw(uint amount) external;

    function withdrawAll() external;

    function recoverToken(address tokenAddress, uint tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQubitPresale {
    struct PresaleData {
        uint startTime;
        uint endTime;
        uint userLpAmount;
        uint totalLpAmount;
        bool claimedOf;
        uint refundLpAmount;
        uint qbtBnbLpAmount;
    }

    function lpPriceAtArchive() external view returns (uint);

    function qbtBnbLpAmount() external view returns (uint);

    function allocationOf(address _user) external view returns (uint);

    function refundOf(address _user) external view returns (uint);

    function accountListLength() external view returns (uint);

    function setQubitBnbLocker(address _qubitBnbLocker) external;

    function setPresaleAmountUSD(uint _limitAmount) external;

    function setPeriod(uint _start, uint _end) external;

    function setQbtAmount(uint _qbtAmount) external;

    function deposit(uint _amount) external;

    function archive() external returns (uint bunnyAmount, uint wbnbAmount);

    function distribute(uint distributeThreshold) external;

    function sweep(uint _lpAmount, uint _offerAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function priceOf(address asset) external view returns (uint);
    function pricesOf(address[] memory assets) external view returns (uint[] memory);

    function getUnderlyingPrice(address qToken) external view returns (uint);
    function getUnderlyingPrices(address[] memory qTokens) external view returns (uint[] memory);

    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
    function unsafeValueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

contract QValidatorTester is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IPriceCalculator oracle;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function getAccountLiquidity(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        collateralInUSD = 0;
        borrowInUSD = 0;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralFactor = qore.marketInfoOf(payable(assets[i])).collateralFactor;
            uint collateralValuePerShareInUSD = snapshot.exchangeRate.mul(prices[i]).mul(collateralFactor).div(1e36);

            collateralInUSD = collateralInUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            supplyInUSD = supplyInUSD.add(snapshot.qTokenBalance.mul(snapshot.exchangeRate).mul(prices[i]).div(1e36));
            borrowInUSD = borrowInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QValidator: invalid oracle address");
        oracle = IPriceCalculator(_oracle);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }

        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }

    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");

        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");

        // seizeQTokenAmount = amount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getAccountLiquidityTester(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = getUnderlyingPricesTester(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getUnderlyingPricesTester(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BUNNY) {
                returnValue[i] = 25e18;
            } else if (addr == CAKE) {
                returnValue[i] = 20e18;
            } else if (addr == BUSD) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = 400e18;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQValidator {
    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external returns (bool);

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external returns (bool);

    function liquidateAllowed(
        address qTokenBorrowed,
        address borrower,
        uint repayAmount,
        uint closeFactor
    ) external returns (bool);

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint actualRepayAmount
    ) external returns (uint qTokenAmount);

    function getAccountLiquidity(address account) external view returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/QConstant.sol";

interface IQToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint);

    function accountSnapshot(address account) external view returns (QConstant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint);

    function borrowBalanceOf(address account) external view returns (uint);

    function borrowRatePerSec() external view returns (uint);

    function supplyRatePerSec() external view returns (uint);

    function totalBorrow() external view returns (uint);

    function totalReserve() external view returns (uint);

    function reserveFactor() external view returns (uint);

    function exchangeRate() external view returns (uint);

    function getCash() external view returns (uint);

    function getAccInterestIndex() external view returns (uint);

    function accruedAccountSnapshot(address account) external returns (QConstant.AccountSnapshot memory);

    function accruedUnderlyingBalanceOf(address account) external returns (uint);

    function accruedBorrowBalanceOf(address account) external returns (uint);

    function accruedTotalBorrow() external returns (uint);

    function accruedExchangeRate() external returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function supply(address account, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address account, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address account, uint underlyingAmount) external returns (uint);

    function borrow(address account, uint amount) external returns (uint);

    function repayBorrow(address account, uint amount) external payable returns (uint);

    function repayBorrowBehalf(address payer, address borrower, uint amount) external payable returns (uint);

    function liquidateBorrow(address qTokenCollateral, address liquidator, address borrower, uint amount) external payable returns (uint qAmountToSeize);

    function seize(address liquidator, address borrower, uint qTokenAmount) external;

    function transferTokensInternal(address spender, address src, address dst, uint amount) external;

    function supplyBehalf(address sender, address supplier, uint uAmount) external payable returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


import "../library/QConstant.sol";

interface IQore {
    function qValidator() external view returns (address);

    function allMarkets() external view returns (address[] memory);
    function marketListOf(address account) external view returns (address[] memory);
    function marketInfoOf(address qToken) external view returns (QConstant.MarketInfo memory);
    function checkMembership(address account, address qToken) external view returns (bool);
    function accountLiquidityOf(address account) external view returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD);

    function distributionInfoOf(address market) external view returns (QConstant.DistributionInfo memory);
    function accountDistributionInfoOf(address market, address account) external view returns (QConstant.DistributionAccountInfo memory);
    function apyDistributionOf(address market, address account) external view returns (QConstant.DistributionAPY memory);
    function distributionSpeedOf(address qToken) external view returns (uint supplySpeed, uint borrowSpeed);
    function boostedRatioOf(address market, address account) external view returns (uint boostedSupplyRatio, uint boostedBorrowRatio);

    function closeFactor() external view returns (uint);
    function liquidationIncentive() external view returns (uint);

    function accruedQubit(address account) external view returns (uint);
    function accruedQubit(address market, address account) external view returns (uint);

    function enterMarkets(address[] memory qTokens) external;
    function exitMarket(address qToken) external;

    function supply(address qToken, uint underlyingAmount) external payable returns (uint);
    function redeemToken(address qToken, uint qTokenAmount) external returns (uint redeemed);
    function redeemUnderlying(address qToken, uint underlyingAmount) external returns (uint redeemed);
    function borrow(address qToken, uint amount) external;
    function repayBorrow(address qToken, uint amount) external payable;
    function repayBorrowBehalf(address qToken, address borrower, uint amount) external payable;
    function liquidateBorrow(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) external payable;

    function claimQubit() external;
    function claimQubit(address market) external;

    function transferTokens(address spender, address src, address dst, uint amount) external;

    function supplyAndBorrowBehalf(address account, address supplyToken, uint supplyAmount, address borrowToken, uint borrowAmount) external payable returns (uint);
    function supplyAndBorrowBNB(address account, address supplyToken, uint supplyAmount, uint borrowAmount) external payable returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

library QConstant {
    uint public constant CLOSE_FACTOR_MIN = 5e16;
    uint public constant CLOSE_FACTOR_MAX = 9e17;
    uint public constant COLLATERAL_FACTOR_MAX = 9e17;

    struct MarketInfo {
        bool isListed;
        uint borrowCap;
        uint collateralFactor;
    }

    struct BorrowInfo {
        uint borrow;
        uint interestIndex;
    }

    struct AccountSnapshot {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
    }

    struct AccrueSnapshot {
        uint totalBorrow;
        uint totalReserve;
        uint accInterestIndex;
    }

    struct DistributionInfo {
        uint supplySpeed;
        uint borrowSpeed;
        uint totalBoostedSupply;
        uint totalBoostedBorrow;
        uint accPerShareSupply;
        uint accPerShareBorrow;
        uint accruedAt;
    }

    struct DistributionAccountInfo {
        uint accruedQubit;
        uint boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint accPerShareSupply; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint accPerShareBorrow; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint apySupplyQBT;
        uint apyBorrowQBT;
        uint apyAccountSupplyQBT;
        uint apyAccountBorrowQBT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../library/QConstant.sol";
pragma experimental ABIEncoderV2;

contract SimpleQTokenTester {
    address public underlying;
    uint public qTokenBalance;
    uint public borrowBalance;
    uint public exchangeRate;
    uint public exchangeRateStored;
    uint public totalBorrow;

    constructor(address _underlying) public {
        underlying = _underlying;
        exchangeRateStored = 50000000000000000;
    }

    function getAccountSnapshot(address)
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (qTokenBalance, borrowBalance, exchangeRate);
    }

    function setAccountSnapshot(
        uint _qTokenBalance,
        uint _borrowBalance,
        uint _exchangeRate
    ) public {
        qTokenBalance = _qTokenBalance;
        borrowBalance = _borrowBalance;
        exchangeRate = _exchangeRate;
        totalBorrow = _borrowBalance;
    }

    function borrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedAccountSnapshot(address) external view returns (QConstant.AccountSnapshot memory) {
        QConstant.AccountSnapshot memory snapshot;
        snapshot.qTokenBalance = qTokenBalance;
        snapshot.borrowBalance = borrowBalance;
        snapshot.exchangeRate = exchangeRate;
        return snapshot;
    }

    function accruedTotalBorrow() public view returns (uint) {
        return totalBorrow;
    }

    function accruedBorrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedExchangeRate() public view returns (uint) {
        return exchangeRate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQDistributor.sol";
import "../interfaces/IWETH.sol";
import "../library/QConstant.sol";
import "../library/SafeToken.sol";
import "../markets/QMarket.sol";

contract QTokenTester is QMarket {
    using SafeMath for uint;
    using SafeToken for address;

    // for test
    function setQDistributor(address _qDistributor) external onlyOwner {
        require(_qDistributor != address(0), "QTokenTester: invalid qDistributor address");
        qDistributor = IQDistributor(_qDistributor);
    }

    /* ========== CONSTANT ========== */

    IQDistributor public qDistributor;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint mintAmount);
    event Redeem(address account, uint underlyingAmount, uint qTokenAmount);

    event Borrow(address account, uint ammount, uint accountBorrow);
    event RepayBorrow(address payer, address borrower, uint amount, uint accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint amount,
        address qTokenCollateral,
        uint seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __QMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    function allowance(address account, address spender) external view override returns (uint) {
        return _transferAllowances[account][spender];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint amount) external override accrue nonReentrant returns (bool) {
        qore.transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external override accrue nonReentrant returns (bool) {
        qore.transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function supply(address account, uint uAmount)
        external
        payable
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);

        totalSupply = totalSupply.add(qAmount);
        accountBalances[account] = accountBalances[account].add(qAmount);

        emit Mint(account, qAmount);
        emit Transfer(address(this), account, qAmount);
        return qAmount;
    }

    function redeemToken(address redeemer, uint qAmount) external override accrue onlyQore nonReentrant returns (uint) {
        return _redeem(redeemer, qAmount, 0);
    }

    function redeemUnderlying(address redeemer, uint uAmount)
        external
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        return _redeem(redeemer, 0, uAmount);
    }

    function borrow(address account, uint amount) external override accrue onlyQore nonReentrant returns (uint) {
        require(getCash() >= amount, "QToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    function repayBorrow(address account, uint amount)
        external
        payable
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(WBNB) ? msg.value : amount);
    }

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore nonReentrant returns (uint) {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(borrower);
        }
        return _repay(payer, borrower, underlying == address(WBNB) ? msg.value : amount);
    }

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore nonReentrant returns (uint qAmountToSeize) {
        require(borrower != liquidator, "QToken: cannot liquidate yourself");

        amount = underlying == address(WBNB) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint(-1), "QToken: invalid repay amount");

        qAmountToSeize = IQValidator(qore.qValidator()).qTokenAmountToSeize(address(this), qTokenCollateral, amount);
        require(
            IQToken(payable(qTokenCollateral)).balanceOf(borrower) >= qAmountToSeize,
            "QToken: too much seize amount"
        );
        emit LiquidateBorrow(liquidator, borrower, amount, qTokenCollateral, qAmountToSeize);
    }

    function seize(
        address liquidator,
        address borrower,
        uint qAmount
    ) external override accrue onlyQore nonReentrant {
        accountBalances[borrower] = accountBalances[borrower].sub(qAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(qAmount);

        emit Transfer(borrower, liquidator, qAmount);
    }

    function transferTokensInternal(
        address spender,
        address src,
        address dst,
        uint amount
    ) external override onlyQore {
        require(
            src != dst && IQValidator(qore.qValidator()).redeemAllowed(address(this), src, amount),
            "QToken: cannot transfer"
        );
        require(amount != 0, "QToken: zero amount");

        uint _allowance = spender == src ? uint(-1) : _transferAllowances[src][spender];
        uint _allowanceNew = _allowance.sub(amount, "QToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        qDistributor.notifyTransferred(address(this), src, dst);

        if (_allowance != uint(-1)) {
            _transferAllowances[src][msg.sender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    function supplyBehalf(address sender, address supplier, uint uAmount) external payable override accrue onlyQore returns (uint) {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(sender, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);
        updateSupplyInfo(supplier, qAmount, 0);

        emit Mint(supplier, qAmount);
        emit Transfer(address(0), supplier, qAmount);
        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (underlying == address(WBNB)) {
            require(msg.value >= amount, "QToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            return IBEP20(underlying).balanceOf(address(this)).sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (underlying == address(WBNB)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    function _redeem(
        address account,
        uint qAmountIn,
        uint uAmountIn
    ) private returns (uint) {
        require(qAmountIn == 0 || uAmountIn == 0, "QToken: one of qAmountIn or uAmountIn must be zero");
        require(totalSupply >= qAmountIn, "QToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "QToken: not enough underlying");
        require(
            getCash() >= qAmountIn.mul(exchangeRate()).div(1e18) || qAmountIn == 0,
            "QToken: not enough underlying"
        );

        uint qAmountToRedeem = qAmountIn > 0 ? qAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint uAmountToRedeem = qAmountIn > 0 ? qAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(
            IQValidator(qore.qValidator()).redeemAllowed(address(this), account, qAmountToRedeem),
            "QToken: cannot redeem"
        );

        totalSupply = totalSupply.sub(qAmountToRedeem);
        accountBalances[account] = accountBalances[account].sub(qAmountToRedeem);
        _doTransferOut(account, uAmountToRedeem);

        emit Transfer(account, address(this), qAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, qAmountToRedeem);
        return uAmountToRedeem;
    }

    function _repay(
        address payer,
        address borrower,
        uint amount
    ) private returns (uint) {
        uint borrowBalance = borrowBalanceOf(borrower);
        uint repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(WBNB)) {
            uint refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/QConstant.sol";

interface IQDistributor {
    function accruedQubit(address[] calldata markets, address account) external view returns (uint);
    function distributionInfoOf(address market) external view returns (QConstant.DistributionInfo memory);
    function accountDistributionInfoOf(address market, address account) external view returns (QConstant.DistributionAccountInfo memory);
    function apyDistributionOf(address market, address account) external view returns (QConstant.DistributionAPY memory);
    function boostedRatioOf(address market, address account) external view returns (uint boostedSupplyRatio, uint boostedBorrowRatio);

    function notifySupplyUpdated(address market, address user) external;
    function notifyBorrowUpdated(address market, address user) external;
    function notifyTransferred(address qToken, address sender, address receiver) external;

    function claimQubit(address[] calldata markets, address account) external;
    function kick(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWETH {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

import "../interfaces/IQValidator.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

abstract contract QMarket is IQToken, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    uint internal constant RESERVE_FACTOR_MAX = 1e18;
    uint internal constant DUST = 1000;

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IRateModel public rateModel;
    address public override underlying;

    uint public override totalSupply;
    uint public override totalReserve;
    uint private _totalBorrow;

    mapping(address => uint) internal accountBalances;
    mapping(address => QConstant.BorrowInfo) internal accountBorrows;

    uint public override reserveFactor;
    uint private lastAccruedTime;
    uint private accInterestIndex;

    /* ========== Event ========== */

    event RateModelUpdated(address newRateModel);
    event ReserveFactorUpdated(uint newReserveFactor);

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function __QMarket_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    modifier accrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            uint borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QToken: only Qore Contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) public onlyOwner {
        require(_qore != address(0), "QMarket: invalid qore address");
        require(address(qore) == address(0), "QMarket: qore already set");
        qore = IQore(_qore);
    }

    function setUnderlying(address _underlying) public onlyOwner {
        require(_underlying != address(0), "QMarket: invalid underlying address");
        require(underlying == address(0), "QMarket: set underlying already");
        underlying = _underlying;
    }

    function setRateModel(address _rateModel) public accrue onlyOwner {
        require(_rateModel != address(0), "QMarket: invalid rate model address");
        rateModel = IRateModel(_rateModel);
        emit RateModelUpdated(_rateModel);
    }

    function setReserveFactor(uint _reserveFactor) public accrue onlyOwner {
        require(_reserveFactor <= RESERVE_FACTOR_MAX, "QMarket: invalid reserve factor");
        reserveFactor = _reserveFactor;
        emit ReserveFactorUpdated(_reserveFactor);
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view override returns (uint) {
        return accountBalances[account];
    }

    function accountSnapshot(address account) external view override returns (QConstant.AccountSnapshot memory) {
        QConstant.AccountSnapshot memory snapshot;
        snapshot.qTokenBalance = accountBalances[account];
        snapshot.borrowBalance = borrowBalanceOf(account);
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    function underlyingBalanceOf(address account) external view override returns (uint) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    function borrowBalanceOf(address account) public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        QConstant.BorrowInfo storage info = accountBorrows[account];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    function borrowRatePerSec() external view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return rateModel.getBorrowRate(getCashPrior(), snapshot.totalBorrow, snapshot.totalReserve);
    }

    function supplyRatePerSec() external view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return rateModel.getSupplyRate(getCashPrior(), snapshot.totalBorrow, snapshot.totalReserve, reserveFactor);
    }

    function totalBorrow() public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    function exchangeRate() public view override returns (uint) {
        if (totalSupply == 0) return 1e18;
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return getCashPrior().add(snapshot.totalBorrow).sub(snapshot.totalReserve).mul(1e18).div(totalSupply);
    }

    function getCash() public view override returns (uint) {
        return getCashPrior();
    }

    function getAccInterestIndex() public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function accruedAccountSnapshot(address account)
        external
        override
        accrue
        returns (QConstant.AccountSnapshot memory)
    {
        QConstant.AccountSnapshot memory snapshot;
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }

        snapshot.qTokenBalance = accountBalances[account];
        snapshot.borrowBalance = info.borrow;
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    function accruedUnderlyingBalanceOf(address account) external override accrue returns (uint) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    function accruedBorrowBalanceOf(address account) external override accrue returns (uint) {
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }
        return info.borrow;
    }

    function accruedTotalBorrow() external override accrue returns (uint) {
        return _totalBorrow;
    }

    function accruedExchangeRate() external override accrue returns (uint) {
        return exchangeRate();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function updateBorrowInfo(
        address account,
        uint addAmount,
        uint subAmount
    ) internal {
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex == 0) {
            info.interestIndex = accInterestIndex;
        }

        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(addAmount).sub(subAmount);
        info.interestIndex = accInterestIndex;
        _totalBorrow = _totalBorrow.add(addAmount).sub(subAmount);

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;
    }

    function updateSupplyInfo(
        address account,
        uint addAmount,
        uint subAmount
    ) internal {
        accountBalances[account] = accountBalances[account].add(addAmount).sub(subAmount);
        totalSupply = totalSupply.add(addAmount).sub(subAmount);

        totalSupply = (totalSupply < DUST) ? 0 : totalSupply;
    }

    function getCashPrior() internal view returns (uint) {
        return
            underlying == address(WBNB)
                ? address(this).balance.sub(msg.value)
                : IBEP20(underlying).balanceOf(address(this));
    }

    function pendingAccrueSnapshot() internal view returns (QConstant.AccrueSnapshot memory) {
        QConstant.AccrueSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.totalReserve = totalReserve;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IRateModel {
    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) external view returns (uint);

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IWETH.sol";
import "../library/SafeToken.sol";
import "./QMarket.sol";

contract QToken is QMarket {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint mintAmount);
    event Redeem(address account, uint underlyingAmount, uint qTokenAmount);

    event Borrow(address account, uint ammount, uint accountBorrow);
    event RepayBorrow(address payer, address borrower, uint amount, uint accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint amount,
        address qTokenCollateral,
        uint seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __QMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    function allowance(address account, address spender) external view override returns (uint) {
        return _transferAllowances[account][spender];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint amount) external override accrue nonReentrant returns (bool) {
        qore.transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external override accrue nonReentrant returns (bool) {
        qore.transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function supply(address account, uint uAmount) external payable override accrue onlyQore returns (uint) {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);
        updateSupplyInfo(account, qAmount, 0);

        emit Mint(account, qAmount);
        emit Transfer(address(0), account, qAmount);
        return qAmount;
    }

    function redeemToken(address redeemer, uint qAmount) external override accrue onlyQore returns (uint) {
        return _redeem(redeemer, qAmount, 0);
    }

    function redeemUnderlying(address redeemer, uint uAmount) external override accrue onlyQore returns (uint) {
        return _redeem(redeemer, 0, uAmount);
    }

    function borrow(address account, uint amount) external override accrue onlyQore returns (uint) {
        require(getCash() >= amount, "QToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    function repayBorrow(address account, uint amount) external payable override accrue onlyQore returns (uint) {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(WBNB) ? msg.value : amount);
    }

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore returns (uint) {
        return _repay(payer, borrower, underlying == address(WBNB) ? msg.value : amount);
    }

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore returns (uint qAmountToSeize) {
        require(borrower != liquidator, "QToken: cannot liquidate yourself");

        amount = underlying == address(WBNB) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint(-1), "QToken: invalid repay amount");

        qAmountToSeize = IQValidator(qore.qValidator()).qTokenAmountToSeize(address(this), qTokenCollateral, amount);
        require(
            IQToken(payable(qTokenCollateral)).balanceOf(borrower) >= qAmountToSeize,
            "QToken: too much seize amount"
        );
        emit LiquidateBorrow(liquidator, borrower, amount, qTokenCollateral, qAmountToSeize);
    }

    function seize(
        address liquidator,
        address borrower,
        uint qAmount
    ) external override accrue onlyQore nonReentrant {
        accountBalances[borrower] = accountBalances[borrower].sub(qAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(qAmount);

        emit Transfer(borrower, liquidator, qAmount);
    }

    function transferTokensInternal(
        address spender,
        address src,
        address dst,
        uint amount
    ) external override onlyQore {
        require(
            src != dst && IQValidator(qore.qValidator()).redeemAllowed(address(this), src, amount),
            "QToken: cannot transfer"
        );
        require(amount != 0, "QToken: zero amount");

        uint _allowance = spender == src ? uint(-1) : _transferAllowances[src][spender];
        uint _allowanceNew = _allowance.sub(amount, "QToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        if (_allowance != uint(-1)) {
            _transferAllowances[src][spender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    function supplyBehalf(address sender, address supplier, uint uAmount) external payable override accrue onlyQore returns (uint) {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(sender, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);
        updateSupplyInfo(supplier, qAmount, 0);

        emit Mint(supplier, qAmount);
        emit Transfer(address(0), supplier, qAmount);
        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (underlying == address(WBNB)) {
            require(msg.value >= amount, "QToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            uint balanceAfter = IBEP20(underlying).balanceOf(address(this));
            require(balanceAfter.sub(balanceBefore) <= amount);
            return balanceAfter.sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (underlying == address(WBNB)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    function _redeem(
        address account,
        uint qAmountIn,
        uint uAmountIn
    ) private returns (uint) {
        require(qAmountIn == 0 || uAmountIn == 0, "QToken: one of qAmountIn or uAmountIn must be zero");
        require(totalSupply >= qAmountIn, "QToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "QToken: not enough underlying");
        require(
            getCash() >= qAmountIn.mul(exchangeRate()).div(1e18) || qAmountIn == 0,
            "QToken: not enough underlying"
        );

        uint qAmountToRedeem = qAmountIn > 0 ? qAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint uAmountToRedeem = qAmountIn > 0 ? qAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(
            IQValidator(qore.qValidator()).redeemAllowed(address(this), account, qAmountToRedeem),
            "QToken: cannot redeem"
        );

        updateSupplyInfo(account, 0, qAmountToRedeem);
        _doTransferOut(account, uAmountToRedeem);

        emit Transfer(account, address(0), qAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, qAmountToRedeem);
        return uAmountToRedeem;
    }

    function _repay(
        address payer,
        address borrower,
        uint amount
    ) private returns (uint) {
        uint borrowBalance = borrowBalanceOf(borrower);
        uint repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(WBNB)) {
            uint refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IQDistributor.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQubitLocker.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/WhitelistUpgradeable.sol";
import "../markets/QToken.sol";



contract QDistributorTester is IQDistributor, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ======= TEST FUNCTIONS ====== */
    function setEffectiveSupply(
        address market,
        address user,
        uint effectiveSupply
    ) public {
        accountDistributions[market][user].boostedSupply = effectiveSupply;
    }

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant BOOST_PORTION = 150;
    uint public constant BOOST_MAX = 250;

    address private constant QORE = 0x21824518e7E443812586c96aB5B05E9F91831E06;
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);
    /* ========== STATE VARIABLES ========== */

    mapping(address => QConstant.DistributionInfo) distributions;
    mapping(address => mapping(address => QConstant.DistributionAccountInfo)) accountDistributions;

    IQubitLocker public qubitLocker;
    IQore public qore;

    /* ========== MODIFIERS ========== */

    modifier updateDistributionOf(address market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }

            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QDistributor: caller is not Qore");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
            }
        }
        require(fromMarket == true, "QDistributor: caller should be market");
        _;
    }

    /* ========== EVENTS ========== */

    event QubitDistributionSpeedUpdated(address indexed qToken, uint supplySpeed, uint borrowSpeed);
    event QubitClaimed(address indexed user, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
        qore = IQore(QORE);
    }

    /* ========== VIEWS ========== */

    function accruedQubit(address[] calldata markets, address account) external view override returns (uint) {
        uint amount = 0;
        for (uint i = 0; i < markets.length; i++) {
            amount = amount.add(_accruedQubit(markets[i], account));
        }
        return amount;
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return distributions[market];
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return accountDistributions[market][account];
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        (uint apySupplyQBT, uint apyBorrowQBT) = _calculateMarketDistributionAPY(market);
        (uint apyAccountSupplyQBT, uint apyAccountBorrowQBT) = _calculateAccountDistributionAPY(market, account);
        return QConstant.DistributionAPY(apySupplyQBT, apyBorrowQBT, apyAccountSupplyQBT, apyAccountBorrowQBT);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        uint accountSupply = IQToken(market).balanceOf(account);
        uint accountBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());

        boostedSupplyRatio = accountSupply > 0 ? accountDistributions[market][account].boostedSupply.mul(1e18).div(accountSupply).mul(250).div(100) : 0;
        boostedBorrowRatio = accountBorrow > 0 ? accountDistributions[market][account].boostedBorrow.mul(1e18).div(accountBorrow).mul(250).div(100) : 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQubitLocker(address _locker) external onlyOwner {
        require(address(_locker) != address(0), "QDistributor: invalid locker");
        qubitLocker = IQubitLocker(_locker);
    }

    function setQore(address _qore) external onlyOwner {
        require(address(_qore) != address(0), "QDistributor: invalid qore");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    function setQubitDistributionSpeed(
        address qToken,
        uint supplySpeed,
        uint borrowSpeed
    ) external onlyOwner updateDistributionOf(qToken) {
        QConstant.DistributionInfo storage dist = distributions[qToken];
        dist.supplySpeed = supplySpeed;
        dist.borrowSpeed = borrowSpeed;
        emit QubitDistributionSpeedUpdated(qToken, supplySpeed, borrowSpeed);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function notifySupplyUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function notifyBorrowUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function notifyTransferred(
        address qToken,
        address sender,
        address receiver
    ) external override nonReentrant onlyMarket updateDistributionOf(qToken) {
        QConstant.DistributionInfo storage dist = distributions[qToken];
        QConstant.DistributionAccountInfo storage senderInfo = accountDistributions[qToken][sender];
        QConstant.DistributionAccountInfo storage receiverInfo = accountDistributions[qToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedQubit = senderInfo.accruedQubit.add(
                accQubitPerShare.mul(senderInfo.boostedSupply).div(1e18)
            );
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedQubit = receiverInfo.accruedQubit.add(
                accQubitPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSenderSupply = _calculateBoostedSupply(qToken, sender);
        uint boostedReceiverSupply = _calculateBoostedSupply(qToken, receiver);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    function claimQubit(address[] calldata markets, address account) external override onlyQore {
        uint amount = 0;
        for (uint i = 0; i < markets.length; i++) {
            amount = amount.add(_claimQubit(markets[i], account));
        }

        amount = Math.min(amount, IBEP20(QBT).balanceOf(address(this)));
        QBT.safeTransfer(account, amount);
        emit QubitClaimed(account, amount);
    }

    function kick(address user) external override nonReentrant {
        require(qubitLocker.scoreOf(user) == 0, "QDistributor: kick not allowed");

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            _updateSupplyOf(market, user);
            _updateBorrowOf(market, user);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _accruedQubit(address market, address user) private view returns (uint) {
        QConstant.DistributionInfo memory dist = distributions[market];
        QConstant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];

        uint amount = userInfo.accruedQubit;
        uint accPerShareSupply = dist.accPerShareSupply;
        uint accPerShareBorrow = dist.accPerShareBorrow;

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (
            timeElapsed > 0 ||
            (accPerShareSupply != userInfo.accPerShareSupply) ||
            (accPerShareBorrow != userInfo.accPerShareBorrow)
        ) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint pendingQubit = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                amount = amount.add(pendingQubit);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint pendingQubit = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                amount = amount.add(pendingQubit);
            }
        }
        return amount;
    }

    function _claimQubit(address market, address user) private returns (uint amount) {
        bool hasBoostedSupply = accountDistributions[market][user].boostedSupply > 0;
        bool hasBoostedBorrow = accountDistributions[market][user].boostedBorrow > 0;
        if (hasBoostedSupply) _updateSupplyOf(market, user);
        if (hasBoostedBorrow) _updateBorrowOf(market, user);

        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];
        amount = amount.add(userInfo.accruedQubit);
        userInfo.accruedQubit = 0;

        return amount;
    }

    function _calculateMarketDistributionAPY(address market) private view returns (uint apySupplyQBT, uint apyBorrowQBT) {
        // base supply QBT APY == average supply QBT APY * (Total balance / total Boosted balance)
        // base supply QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base supply QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset)
        uint numerSupply = distributions[market].supplySpeed.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomSupply = distributions[market].totalBoostedSupply.mul(IQToken(market).exchangeRate()).mul(priceCalculator.getUnderlyingPrice(market)).div(1e36);
        apySupplyQBT = denomSupply > 0 ? numerSupply.div(denomSupply) : 0;

        // base borrow QBT APY == average borrow QBT APY * (Total balance / total Boosted balance)
        // base borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset)
        uint numerBorrow = distributions[market].borrowSpeed.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomBorrow = distributions[market].totalBoostedBorrow.mul(IQToken(market).getAccInterestIndex()).mul(priceCalculator.getUnderlyingPrice(market)).div(1e36);
        apyBorrowQBT = denomBorrow > 0 ? numerBorrow.div(denomBorrow) : 0;
    }

    function _calculateAccountDistributionAPY(address market, address account) private view returns (uint apyAccountSupplyQBT, uint apyAccountBorrowQBT) {
        if (account == address(0)) return (0, 0);
        (uint apySupplyQBT, uint apyBorrowQBT) = _calculateMarketDistributionAPY(market);

        // user supply QBT APY == ((qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        uint accountSupply = IQToken(market).balanceOf(account);
        apyAccountSupplyQBT = accountSupply > 0 ? apySupplyQBT.mul(accountDistributions[market][account].boostedSupply).div(accountSupply) : 0;

        // user borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * interestIndex * price of asset) * my boosted balance  / my balance
        uint accountBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());
        apyAccountBorrowQBT = accountBorrow > 0 ? apyBorrowQBT.mul(accountDistributions[market][account].boostedBorrow).div(accountBorrow) : 0;
    }


    function _calculateBoostedSupply(address market, address user) private view returns (uint) {
        uint defaultSupply = IQToken(market).balanceOf(user);
        uint boostedSupply = defaultSupply;

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint scoreBoosted = IQToken(market).totalSupply().mul(userScore).div(totalScore).mul(BOOST_PORTION).div(
                100
            );
            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply.mul(BOOST_MAX).div(100));
    }

    function _calculateBoostedBorrow(address market, address user) private view returns (uint) {
        uint accInterestIndex = IQToken(market).getAccInterestIndex();
        uint defaultBorrow = IQToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);
        uint boostedBorrow = defaultBorrow;

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint totalBorrow = IQToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint scoreBoosted = totalBorrow.mul(userScore).div(totalScore).mul(BOOST_PORTION).div(100);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow.mul(BOOST_MAX).div(100));
    }

    function _updateSupplyOf(address market, address user) private updateDistributionOf(market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(address market, address user) private updateDistributionOf(market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQubitLocker {
    struct CheckPoint {
        uint totalWeightedBalance;
        uint slope;
        uint ts;
    }

    function totalBalance() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function expiryOf(address account) external view returns (uint);

    function availableOf(address account) external view returns (uint);

    function totalScore() external view returns (uint score, uint slope);

    function scoreOf(address account) external view returns (uint);

    function deposit(uint amount, uint unlockTime) external;

    function extendLock(uint expiryTime) external;

    function withdraw() external;

    function depositBehalf(address account, uint amount, uint unlockTime) external;

    function withdrawBehalf(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";

contract QubitReservoir is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    /* ========== STATE VARIABLES ========== */

    address public receiver;

    uint public startAt;
    uint public ratePerSec;
    uint public ratePerSec2;
    uint public ratePerSec3;
    uint public dripped;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _receiver,
        uint _ratePerSec,
        uint _ratePerSec2,
        uint _ratePerSec3,
        uint _startAt
    ) external initializer {
        __WhitelistUpgradeable_init();

        require(_receiver != address(0), "QubitReservoir: invalid receiver");
        require(_ratePerSec > 0, "QubitReservoir: invalid rate");

        receiver = _receiver;
        ratePerSec = _ratePerSec;
        ratePerSec2 = _ratePerSec2;
        ratePerSec3 = _ratePerSec3;
        startAt = _startAt;
    }

    /* ========== VIEWS ========== */

    function getDripInfo()
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        if (block.timestamp < startAt || block.timestamp.sub(startAt) <= 30 days) {
            return (startAt, ratePerSec, dripped);
        } else if (30 days < block.timestamp.sub(startAt) && block.timestamp.sub(startAt) <= 60 days) {
            return (startAt, ratePerSec2, dripped);
        } else {
            return (startAt, ratePerSec3, dripped);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function drip() public onlyOwner returns (uint) {
        require(block.timestamp >= startAt, "QubitReservoir: not started");

        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip;
        if (block.timestamp.sub(startAt) <= 30 days) {
            totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        } else if (block.timestamp.sub(startAt) <= 60 days) {
            totalDrip = ratePerSec.mul(30 days);
            totalDrip = totalDrip.add(ratePerSec2.mul(block.timestamp.sub(startAt + 30 days)));
        } else {
            totalDrip = ratePerSec.mul(30 days);
            totalDrip = totalDrip.add(ratePerSec2.mul(30 days));
            totalDrip = totalDrip.add(ratePerSec3.mul(block.timestamp.sub(startAt + 60 days)));
        }

        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);
        QBT.safeTransfer(receiver, amountToDrip);
        return amountToDrip;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract QTokenBulkTransfer {
    function bulkSend(
        address qToken,
        uint amount,
        address[] memory accounts
    ) external {
        require(IBEP20(qToken).balanceOf(address(this)) > 0, "no balance");

        for (uint i = 0; i < accounts.length; i++) {
            IBEP20(qToken).transfer(accounts[i], amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";
import "../interfaces/IQubitPool.sol";
import "../interfaces/IQore.sol";

contract QubitDevWallet is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    IQubitPool public constant QubitPool = IQubitPool(0x33F93897e914a7482A262Ef10A94319840EB8D05);
    IQore public constant Qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    address internal constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        IBEP20(QBT).approve(address(QubitPool), uint(- 1));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public {
        QBT.safeTransferFrom(msg.sender, address(this), _amount);

        QubitPool.deposit(_amount);
    }

    function harvest() public onlyOwner {
        uint _before = QBT.balanceOf(address(this));
        QubitPool.getReward();
        uint amountQBT = QBT.balanceOf(address(this)).sub(_before);

        QubitPool.deposit(amountQBT);
    }

    function withdrawBQBT(uint _amount) public onlyOwner {
        QubitPool.withdraw(_amount);
        address(QubitPool).safeTransfer(msg.sender, _amount);
    }

    function approveQBTMarket() public onlyOwner {
        IBEP20(QBT).approve(qQBT, uint(- 1));
    }

    function supply(uint _amount) public {
        QBT.safeTransferFrom(msg.sender, address(this), _amount);

        Qore.supply(qQBT, _amount);
    }

    function redeemToken(uint _qAmount) public onlyOwner {
        uint uAmountToRedeem = Qore.redeemToken(qQBT, _qAmount);
        QBT.safeTransfer(msg.sender, uAmountToRedeem);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "./IVaultController.sol";

interface IQubitPool is IVaultController {

    /* ========== Dashboard ========== */
    function balance() external view returns (uint);
    function principalOf(address account) external view returns (uint);
    function withdrawableBalanceOf(address account) external view returns (uint);
    function earned(address account) external view returns (uint);
    function priceShare() external view returns (uint);
    function depositedAt(address account) external view returns (uint);
    function rewardsToken() external view returns (address);

    /* ========== Interface ========== */
    function deposit(uint _amount) external;
    function getReward() external;
    function stake(uint _amount) external;
    function notifyRewardAmount(uint reward) external;
    function withdraw(uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IVaultController {
    function minter() external view returns (address);
    function bunnyChef() external view returns (address);
    function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";


contract ReentrancyTesterForRedeem {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    //    receive() external payable {

    //        receiveCalled = true;
    //        IQore(qore).redeemToken(qBNB, uint(1).mul(1e18));

    //    }
    receive() external payable {

        receiveCalled = true;
        IQore(qore).redeemUnderlying(qBNB, uint(1).mul(1e18));

    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";


contract ReentrancyTesterForLiquidateBorrow {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    address public liquidation_borrower;

    /* ========== INITIALIZER ========== */

    constructor(address _borrower) public {
        liquidation_borrower = _borrower;
    }

    receive() external payable {

        receiveCalled = true;
        IQore(qore).liquidateBorrow(qBNB, qBNB, liquidation_borrower, uint(1).mul(1e18));

    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";


contract ReentrancyTesterForBorrow {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {

        receiveCalled = true;
        IQore(qore).borrow(qBNB, uint(1).mul(1e18));

    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";


contract ReentrancyTester2 {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {

        receiveCalled = true;
        IQore(qore).borrow(qBNB, uint(1).mul(1e18));
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function deposit() external payable {}

    function callLiquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).liquidateBorrow{ value: msg.value }(qTokenBorrowed, qTokenCollateral, borrower, amount);
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callBorrow(address qToken, uint amount) external {
        IQore(qore).borrow(qToken, amount);
    }

    function callRepayBorrow(address qToken, uint amount) external payable {
        IQore(qore).repayBorrow{ value: msg.value }(qToken, amount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";


contract ReentrancyTester {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {

        receiveCalled = true;
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function deposit() external payable {}

    function callLiquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).liquidateBorrow{ value: msg.value }(qTokenBorrowed, qTokenCollateral, borrower, amount);
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callBorrow(address qToken, uint amount) external {
        IQore(qore).borrow(qToken, amount);
    }

    function callRepayBorrow(address qToken, uint amount) external payable {
        IQore(qore).repayBorrow{ value: msg.value }(qToken, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IFlashLoanReceiver.sol";

import "../QoreAdmin.sol";

contract QoreTester is QoreAdmin {
    using SafeMath for uint;

    function notifySupplyUpdated(address market, address user) external {
        qDistributor.notifySupplyUpdated(market, user);
    }

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public constant FLASHLOAN_FEE = 5e14;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "Qore: caller should be market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function accountLiquidityOf(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        return IQValidator(qValidator).getAccountLiquidity(account);
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return IQDistributor(qDistributor).distributionInfoOf(market);
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return IQDistributor(qDistributor).accountDistributionInfoOf(market, account);
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        return IQDistributor(qDistributor).apyDistributionOf(market, account);
    }

    function distributionSpeedOf(address qToken) external view override returns (uint supplySpeed, uint borrowSpeed) {
        QConstant.DistributionInfo memory distribution = IQDistributor(qDistributor).distributionInfoOf(qToken);
        return (distribution.supplySpeed, distribution.borrowSpeed);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        return IQDistributor(qDistributor).boostedRatioOf(market, account);
    }

    function accruedQubit(address account) external view override returns (uint) {
        return IQDistributor(qDistributor).accruedQubit(markets, account);
    }

    function accruedQubit(address market, address account) external view override returns (uint) {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        return IQDistributor(qDistributor).accruedQubit(_markets, account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        delete usersOfMarket[qToken][msg.sender];
        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount) external payable override onlyListedMarket(qToken) returns (uint) {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override nonReentrant {
        amount = IQToken(qTokenBorrowed).underlying() == address(WBNB) ? msg.value : amount;
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(usersOfMarket[qTokenCollateral][borrower], "Qore: not a collateral");
        require(marketInfos[qTokenCollateral].collateralFactor > 0, "Qore: not a collateral");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifyTransferred(qTokenCollateral, borrower, msg.sender);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    function claimQubit() external override nonReentrant {
        qDistributor.claimQubit(markets, msg.sender);
    }

    function claimQubit(address market) external override nonReentrant {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        qDistributor.claimQubit(_markets, msg.sender);
    }

    function transferTokens(address spender, address src, address dst, uint amount) external override nonReentrant onlyMarket {
        IQToken(msg.sender).transferTokensInternal(spender, src, dst, amount);
        qDistributor.notifyTransferred(msg.sender, src, dst);
    }


    /* ========== RESTRICTED FUNCTION FOR WHITELIST ========== */

    function supplyAndBorrowBehalf(address account, address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount)
    external
    payable
    override
    onlyListedMarket(supplyMarket)
    onlyListedMarket(borrowMarket)
    onlyWhitelisted
    nonReentrant
    returns (uint)
    {
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;

        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, borrowMarket, borrowAmount), "Qore: cannot borrow");
        IQToken(borrowMarket).borrow(account, borrowAmount);

        qDistributor.notifySupplyUpdated(supplyMarket, account);
        qDistributor.notifyBorrowUpdated(borrowMarket, account);
        return qAmount;
    }

    function supplyAndBorrowBNB(address account, address supplyMarket, uint supplyAmount, uint borrowAmount)
    external
    payable
    override
    onlyListedMarket(supplyMarket)
    onlyWhitelisted
    nonReentrant
    returns (uint)
    {
        require(borrowAmount <= 5e16, "exceed maximum amount");
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;
        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        address qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
        _enterMarket(qBNB, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, qBNB, borrowAmount), "Qore: cannot borrow");
        IQToken(qBNB).borrow(account, borrowAmount); // borrow 0.05 BNB
        // no reward update to reduce gasfee
        // qDistributor.notifySupplyUpdated(supplyMarket, account);
        // qDistributor.notifyBorrowUpdated(0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351, account);

        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");

        address[] memory updatedMarkets = new address[](marketListOfUsers[_account].length - 1);
        uint counter = 0;
        for (uint i = 0; i < marketListOfUsers[_account].length; i++) {
            if (marketListOfUsers[_account][i] != qTokenToExit) {
                updatedMarkets[counter++] = marketListOfUsers[_account][i];
            }
        }
        marketListOfUsers[_account] = updatedMarkets;
    }

    function _borrowAllowed(address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount) internal view returns (bool){
        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = marketInfos[borrowMarket].borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(borrowMarket)).totalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Qore: market borrow cap reached");
        }

        address[] memory markets = new address[](2);
        markets[0] = supplyMarket;
        markets[1] = borrowMarket;
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        uint collateralValueInUSD = prices[0].mul(supplyAmount).mul(marketInfos[supplyMarket].collateralFactor).div(1e36);
        uint borrowValueInUSD = prices[1].mul(borrowAmount).div(1e18);

        return collateralValueInUSD >= borrowValueInUSD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata markets,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address initiator,
        bytes calldata params
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IQore.sol";
import "./interfaces/IQDistributor.sol";
import "./interfaces/IPriceCalculator.sol";
import "./library/WhitelistUpgradeable.sol";
import { QConstant } from "./library/QConstant.sol";
import "./interfaces/IQToken.sol";

abstract contract QoreAdmin is IQore, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    address public override qValidator;
    IQDistributor public qDistributor;

    address[] public markets; // qTokenAddress[]
    mapping(address => QConstant.MarketInfo) public marketInfos; // (qTokenAddress => MarketInfo)

    uint public override closeFactor;
    uint public override liquidationIncentive;

    /* ========== Event ========== */

    event MarketListed(address qToken);
    event MarketEntered(address qToken, address account);
    event MarketExited(address qToken, address account);

    event CloseFactorUpdated(uint newCloseFactor);
    event CollateralFactorUpdated(address qToken, uint newCollateralFactor);
    event LiquidationIncentiveUpdated(uint newLiquidationIncentive);
    event BorrowCapUpdated(address indexed qToken, uint newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event QValidatorUpdated(address newQValidator);
    event QDistributorUpdated(address newQDistributor);
    event FlashLoan(address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium);

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Qore: caller is not the owner or keeper");
        _;
    }

    modifier onlyListedMarket(address qToken) {
        require(marketInfos[qToken].isListed, "Qore: invalid market");
        _;
    }

    /* ========== INITIALIZER ========== */

    function __Qore_init() internal initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        closeFactor = 5e17;
        liquidationIncentive = 11e17;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "Qore: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function setQValidator(address _qValidator) external onlyKeeper {
        require(_qValidator != address(0), "Qore: invalid qValidator address");
        qValidator = _qValidator;
        emit QValidatorUpdated(_qValidator);
    }

    function setQDistributor(address _qDistributor) external onlyKeeper {
        require(_qDistributor != address(0), "Qore: invalid qDistributor address");
        qDistributor = IQDistributor(_qDistributor);
        emit QDistributorUpdated(_qDistributor);
    }

    function setCloseFactor(uint newCloseFactor) external onlyKeeper {
        require(
            newCloseFactor >= QConstant.CLOSE_FACTOR_MIN && newCloseFactor <= QConstant.CLOSE_FACTOR_MAX,
            "Qore: invalid close factor"
        );
        closeFactor = newCloseFactor;
        emit CloseFactorUpdated(newCloseFactor);
    }

    function setCollateralFactor(address qToken, uint newCollateralFactor)
        external
        onlyKeeper
        onlyListedMarket(qToken)
    {
        require(newCollateralFactor <= QConstant.COLLATERAL_FACTOR_MAX, "Qore: invalid collateral factor");
        if (newCollateralFactor != 0 && priceCalculator.getUnderlyingPrice(qToken) == 0) {
            revert("Qore: invalid underlying price");
        }

        marketInfos[qToken].collateralFactor = newCollateralFactor;
        emit CollateralFactorUpdated(qToken, newCollateralFactor);
    }

    function setLiquidationIncentive(uint newLiquidationIncentive) external onlyKeeper {
        liquidationIncentive = newLiquidationIncentive;
        emit LiquidationIncentiveUpdated(newLiquidationIncentive);
    }

    function setMarketBorrowCaps(address[] calldata qTokens, uint[] calldata newBorrowCaps) external onlyKeeper {
        require(qTokens.length != 0 && qTokens.length == newBorrowCaps.length, "Qore: invalid data");

        for (uint i = 0; i < qTokens.length; i++) {
            marketInfos[qTokens[i]].borrowCap = newBorrowCaps[i];
            emit BorrowCapUpdated(qTokens[i], newBorrowCaps[i]);
        }
    }

    function listMarket(
        address payable qToken,
        uint borrowCap,
        uint collateralFactor
    ) external onlyKeeper {
        require(!marketInfos[qToken].isListed, "Qore: already listed market");
        for (uint i = 0; i < markets.length; i++) {
            require(markets[i] != qToken, "Qore: already listed market");
        }

        marketInfos[qToken] = QConstant.MarketInfo({
            isListed: true,
            borrowCap: borrowCap,
            collateralFactor: collateralFactor
        });
        markets.push(qToken);
        emit MarketListed(qToken);
    }

    function removeMarket(address payable qToken) external onlyKeeper {
        require(marketInfos[qToken].isListed, "Qore: unlisted market");
        require(IQToken(qToken).totalSupply() == 0 && IQToken(qToken).totalBorrow() == 0, "Qore: cannot remove market");

        uint length = markets.length;
        for (uint i = 0; i < length; i++) {
            if (markets[i] == qToken) {
                markets[i] = markets[length - 1];
                markets.pop();
                delete marketInfos[qToken];
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../interfaces/IQToken.sol";



contract SimplePriceCalculatorTester {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address public constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;

    uint public priceBunny;
    uint public priceCake;
    uint public priceBNB;
    uint public priceETH;
    uint public priceBTC;
    uint public priceMDX;

    constructor() public {
        priceBunny = 20e18;
        priceCake = 15e18;
        priceBNB = 400e18;
        priceETH = 3000e18;
        priceBTC = 40000e18;
        priceMDX = 142e16;
    }

    function setUnderlyingPrice(address qTokenAddress, uint price) public {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            priceBunny = price;
        } else if (addr == CAKE) {
            priceCake = price;
        } else if (addr == BNB || addr == WBNB) {
            priceBNB = price;
        } else if (addr == ETH) {
            priceETH = price;
        } else if (addr == BTC) {
            priceBTC = price;
        } else if (addr == MDX) {
            priceMDX = price;
        }
    }

    function getUnderlyingPrice(address qTokenAddress) public view returns (uint) {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            return priceBunny;
        } else if (addr == CAKE) {
            return priceCake;
        } else if (addr == BUSD) {
            return 1e18;
        } else if (addr == USDT || addr == USDC || addr == DAI) {
            return 1e18;
        } else if (addr == ETH) {
            return priceETH;
        } else if (addr == BTC) {
            return priceBTC;
        } else if (addr == MDX) {
            return priceMDX;
        } else if (addr == BNB || addr == WBNB) {
            return priceBNB;
        } else {
            return 0;
        }
    }

    function getUnderlyingPrices(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == BUNNY) {
                returnValue[i] = priceBunny;
            } else if (addr == CAKE) {
                returnValue[i] = priceCake;
            } else if (addr == BUSD || addr == USDC || addr == DAI) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = priceBNB;
            } else if (addr == ETH) {
                returnValue[i] = priceETH;
            } else if (addr == BTC) {
                returnValue[i] = priceBTC;
            } else if (addr == MDX) {
                returnValue[i] = priceMDX;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IQToken.sol";
import "../interfaces/IBEP20.sol";


contract QTokenTransferTester {
    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;

    /* ========== STATE VARIABLES ========== */

    /* ========== INITIALIZER ========== */

    constructor() public {}

    function transfer(
        address qToken,
        address sender,
        address receiver,
        uint amount
    ) external {
        IQToken(qToken).transferFrom(sender, receiver, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../library/SafeToken.sol";


contract FlashLoanReceiver is IFlashLoanReceiver {
    using SafeMath for uint;

    address private constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
    address private constant qBTC = 0xd055D32E50C57B413F7c2a4A052faF6933eA7927;
    address private constant qETH = 0xb4b77834C73E9f66de57e6584796b034D41Ce39A;
    address private constant qUSDC = 0x1dd6E079CF9a82c91DaF3D8497B27430259d32C2;
    address private constant qUSDT = 0x99309d2e7265528dC7C3067004cC4A90d37b7CC3;
    address private constant qDAI = 0x474010701715658fC8004f51860c90eEF4584D2B;
    address private constant qBUSD = 0xa3A155E76175920A40d2c8c765cbCB1148aeB9D1;
    address private constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    address private constant qMDX = 0xFF858dB0d6aA9D3fCA13F6341a1693BE4416A550;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;  // BUSD pair
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // BUSD pair
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address private constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;

    address private constant Qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;

    constructor() public {
        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            IBEP20(underlying).approve(Qore, uint(- 1));
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
        }
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[10] memory) {
        return [WBNB, BTC, ETH, DAI, USDC, BUSD, USDT, CAKE, QBT, MDX];
    }

    function qTokens() public pure returns (address[10] memory) {
        return [qBNB, qBTC, qETH, qDAI, qUSDC, qBUSD, qUSDT, qCAKE, qQBT, qMDX];
    }

    receive() external payable {

    }

    /* ========== Qubit Flashloan Callback FUNCTION ========== */

    function executeOperation(
        address[] calldata markets,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address,
        bytes calldata
    ) external override returns (bool) {

        for (uint i = 0; i < markets.length; i++) {
            uint amountIncludingFee = amounts[i].add(fees[i]);
            address underlying = IQToken(markets[i]).underlying();
            if (underlying == address(WBNB)) {
                IWETH(underlying).deposit{value:amountIncludingFee}();
//                SafeToken.safeTransferETH(markets[0], amountIncludingFee);
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IFlashLoanReceiver.sol";


contract QLiquidationV2Testnet is WhitelistUpgradeable, ReentrancyGuardUpgradeable, IFlashLoanReceiver {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0x995cCA2cD0C269fdEe7d057A8A7aaA1586ecEf51);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    address private constant qBNB = 0x14fA6A83A08B763B8A430e1fAeafe009D266F280;
    address private constant qETH = 0xAf9A0488D21A3cec2012f3E6Fe632B65Aa6Ea61D;
    address private constant qUSDT = 0x93848E23F0a70891A67a98a6CEBb47Fa55A51508;
    address private constant qDAI = 0xfc743504c7FF5526e3Ba97617F6e6Bf8fD8cfdF0;
    address private constant qBUSD = 0x5B8BA405976b3A798F47DAE502e1982502aF64c5;
    address private constant qQBT = 0x2D076EC4FE501927c5bea2A5bA8902e5e7A9B727;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    address private constant ETH = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    address private constant DAI = 0x8a9424745056Eb399FD19a0EC26A14316684e274;  // BUSD pair
    address private constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private constant USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;


    address private constant QBT = 0xF523e4478d909968090a232eB380E2dd6f802518;



    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying != QBT) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            }
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
            IBEP20(underlying).approve(address(Qore), uint(- 1));
        }

    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[6] memory) {
        return [WBNB, ETH, DAI, BUSD, USDT, QBT];
    }

    function qTokens() public pure returns (address[6] memory) {
        return [qBNB, qETH, qDAI, qBUSD, qUSDT, qQBT];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidation: invalid route address");
        _routePairAddresses[token] = route;
    }

    /* ========== Flashloan Callback FUNCTION ========== */

    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata fees,
        address,
        bytes calldata params
    ) external override returns (bool) {
        require(fees.length == 1, "QLiquidationV2 : invalid request");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) = abi.decode(params, (address, address, address, uint));

        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, amount);

        if (qTokenBorrowed != qTokenCollateral) {
            _swapToRepayFlashloan(qTokenCollateral, qTokenBorrowed, amount.add(fees[0]));
        }
        else if (qTokenBorrowed == qBNB) {
            IWETH(WBNB).deposit{value:amount.add(fees[0])}();
        }

        return true;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));
        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _flashloanQubit(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address[] memory _markets = new address[](1);
        _markets[0] = _qTokenBorrowed;

        uint[] memory _amounts = new uint[](1);
        _amounts[0] = amount;
//        Qore.flashLoan(address(this), _markets, _amounts,
//            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, amount)
//        );
    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _swapToRepayFlashloan(address _qTokenCollateral, address _qTokenBorrowed, uint repayAmount) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();
        address borrowedToken = IQToken(_qTokenBorrowed).underlying();

        if (collateralToken == WBNB) {
            if (_routePairAddresses[borrowedToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = WBNB;
                path[1] = _routePairAddresses[borrowedToken];
                path[2] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
            else {
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
        } else if (borrowedToken == WBNB) {
            if (_routePairAddresses[collateralToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = collateralToken;
                path[1] = _routePairAddresses[collateralToken];
                path[2] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            }
        }
        else {
            if ( (borrowedToken == DAI && collateralToken == BUSD) || (collateralToken == DAI && borrowedToken == BUSD) ||
                (borrowedToken == BUSD && (collateralToken == USDT)) ||
                (collateralToken == BUSD && (borrowedToken == USDT)) ||
                (borrowedToken == USDT && (collateralToken == BUSD)) ||
                (collateralToken == USDT && (borrowedToken == BUSD)) ) {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = borrowedToken;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                // first swap to WBNB,
                uint WBNBamount;
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                }

                if (_routePairAddresses[collateralToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = collateralToken;
                    path[1] = _routePairAddresses[collateralToken];
                    path[2] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = collateralToken;
                    path[1] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                }

                // then swap WBNB to borrowedToken
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IQToken.sol";
import "./interfaces/IQValidator.sol";
import "./interfaces/IFlashLoanReceiver.sol";
import "./library/SafeToken.sol";

import "./QoreAdmin.sol";

contract Qore is QoreAdmin {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public constant FLASHLOAN_FEE = 5e14; // 0.05%

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))
    address[] public totalUserList; // do not use

    mapping(address => uint) public supplyCap;

    /* ========== Event ========== */

    event SupplyCapUpdated(address indexed qToken, uint newSupplyCap);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "Qore: caller should be market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function accountLiquidityOf(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        return IQValidator(qValidator).getAccountLiquidity(account);
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return qDistributor.distributionInfoOf(market);
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return qDistributor.accountDistributionInfoOf(market, account);
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        return qDistributor.apyDistributionOf(market, account);
    }

    function distributionSpeedOf(address qToken) external view override returns (uint supplySpeed, uint borrowSpeed) {
        QConstant.DistributionInfo memory distribution = qDistributor.distributionInfoOf(qToken);
        return (distribution.supplySpeed, distribution.borrowSpeed);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        return qDistributor.boostedRatioOf(market, account);
    }

    function accruedQubit(address account) external view override returns (uint) {
        return qDistributor.accruedQubit(markets, account);
    }

    function accruedQubit(address market, address account) external view override returns (uint) {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        return qDistributor.accruedQubit(_markets, account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount)
        external
        payable
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        if (supplyCap[qToken] != 0) {
            require(IQToken(qToken).totalSupply().mul(IQToken(qToken).exchangeRate())
            .div(1e18).add(uAmount) <= supplyCap[qToken], "Qore: market supply cap reached");
        }
        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) nonReentrant {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override nonReentrant {
        amount = IQToken(qTokenBorrowed).underlying() == address(WBNB) ? msg.value : amount;
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(usersOfMarket[qTokenCollateral][borrower], "Qore: not a collateral");
        require(marketInfos[qTokenCollateral].collateralFactor > 0, "Qore: not a collateral");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifyTransferred(qTokenCollateral, borrower, msg.sender);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    function claimQubit() external override nonReentrant {
        qDistributor.claimQubit(markets, msg.sender);
    }

    function claimQubit(address market) external override nonReentrant {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        qDistributor.claimQubit(_markets, msg.sender);
    }

    function transferTokens(address spender, address src, address dst, uint amount) external override nonReentrant onlyMarket {
        IQToken(msg.sender).transferTokensInternal(spender, src, dst, amount);
        qDistributor.notifyTransferred(msg.sender, src, dst);
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setSupplyCap(address qToken, uint newSupplyCap) external onlyKeeper {
        supplyCap[qToken] = newSupplyCap;
        emit SupplyCapUpdated(qToken, newSupplyCap);
    }

    /* ========== RESTRICTED FUNCTION FOR WHITELIST ========== */

    function supplyAndBorrowBehalf(address account, address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount)
        external
        payable
        override
        onlyListedMarket(supplyMarket)
        onlyListedMarket(borrowMarket)
        onlyWhitelisted
        nonReentrant
        returns (uint)
    {
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;

        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, borrowMarket, borrowAmount), "Qore: cannot borrow");
        IQToken(borrowMarket).borrow(account, borrowAmount);

        qDistributor.notifySupplyUpdated(supplyMarket, account);
        qDistributor.notifyBorrowUpdated(borrowMarket, account);
        return qAmount;
    }

    function supplyAndBorrowBNB(address account, address supplyMarket, uint supplyAmount, uint borrowAmount)
        external
        payable
        override
        onlyListedMarket(supplyMarket)
        onlyWhitelisted
        nonReentrant
        returns (uint)
    {
        require(borrowAmount <= 5e16, "exceed maximum amount");
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;
        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        address qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
        _enterMarket(qBNB, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, qBNB, borrowAmount), "Qore: cannot borrow");
        IQToken(qBNB).borrow(account, borrowAmount);
        // no reward update to reduce gasfee
        // qDistributor.notifySupplyUpdated(supplyMarket, account);
        // qDistributor.notifyBorrowUpdated(0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351, account);

        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");
        delete usersOfMarket[qTokenToExit][_account];

        uint length = marketListOfUsers[_account].length;
        for (uint i = 0; i < length; i++) {
            if (marketListOfUsers[_account][i] == qTokenToExit) {
                marketListOfUsers[_account][i] = marketListOfUsers[_account][length - 1];
                marketListOfUsers[_account].pop();
                break;
            }
        }
    }

    function _borrowAllowed(address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount) internal view returns (bool){
        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = marketInfos[borrowMarket].borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(borrowMarket)).totalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Qore: market borrow cap reached");
        }

        address[] memory markets = new address[](2);
        markets[0] = supplyMarket;
        markets[1] = borrowMarket;
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        uint collateralValueInUSD = prices[0].mul(supplyAmount).mul(marketInfos[supplyMarket].collateralFactor).div(1e36);
        uint borrowValueInUSD = prices[1].mul(borrowAmount).div(1e18);

        return collateralValueInUSD >= borrowValueInUSD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

contract QValidator is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public constant oracle = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    uint private constant qbtPriceCollateralCap = 15e16;
    address private constant qBunny = 0xceB82D224a531525C838BF0ACdc33B2C8d550c47;
    uint private constant bunnyPriceCollateralCap = 5e18;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function getAccountLiquidity(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        collateralInUSD = 0;
        supplyInUSD = 0;
        borrowInUSD = 0;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);
            
            uint priceCollateral;
            if (assets[i] == qQBT && prices[i] > qbtPriceCollateralCap) {
                priceCollateral = qbtPriceCollateralCap;
            } else if (assets[i] == qBunny && prices[i] > bunnyPriceCollateralCap) {
                priceCollateral = bunnyPriceCollateralCap;
            } else {
                priceCollateral = prices[i];
            }

            uint collateralFactor = qore.marketInfoOf(payable(assets[i])).collateralFactor;
            uint collateralValuePerShareInUSD = snapshot.exchangeRate.mul(priceCollateral).mul(collateralFactor).div(1e36);

            collateralInUSD = collateralInUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            supplyInUSD = supplyInUSD.add(snapshot.qTokenBalance.mul(snapshot.exchangeRate).mul(prices[i]).div(1e36));
            borrowInUSD = borrowInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }

        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }

    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");

        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");

        // seizeQTokenAmount = amount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD;
            if (assets[i] == qQBT && prices[i] > qbtPriceCollateralCap) {
                collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(qbtPriceCollateralCap)
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            }
            else if (assets[i] == qBunny && prices[i] > bunnyPriceCollateralCap) {
                collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(bunnyPriceCollateralCap)
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            }
            else {
                collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            }

            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
        ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
        : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
        ? 0
        : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPresaleLocker.sol";
import "../interfaces/IQubitPresale.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/SafeToken.sol";

contract QubitPresale is IQubitPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant BUNNY_WBNB_LP = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address public constant QBT_WBNB_LP = 0x67EFeF66A55c4562144B9AcfCFbc62F9E4269b3e;

    address public constant DEPLOYER = 0xbeE397129374D0b4db7bf1654936951e5bdfe5a6;

    IPancakeRouter02 private constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    uint public startTime;
    uint public endTime;
    uint public presaleAmountUSD;
    uint public totalBunnyBnbLp;
    uint public qbtAmount;
    uint public override qbtBnbLpAmount;
    uint public override lpPriceAtArchive;
    uint private _distributionCursor;

    mapping(address => uint) public bunnyBnbLpOf;
    mapping(address => bool) public claimedOf;
    address[] public accountList;
    bool public archived;

    IPresaleLocker public qbtBnbLocker;

    mapping(address => uint) public refundLpOf;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint amount);
    event Distributed(uint length, uint remain);

    /* ========== INITIALIZER ========== */

    function initialize(
        uint _startTime,
        uint _endTime,
        uint _presaleAmountUSD,
        uint _qbtAmount
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        startTime = _startTime;
        endTime = _endTime;
        presaleAmountUSD = _presaleAmountUSD;
        qbtAmount = _qbtAmount;

        BUNNY_WBNB_LP.safeApprove(address(router), uint(~0));
        QBT.safeApprove(address(router), uint(~0));
        BUNNY.safeApprove(address(router), uint(~0));
        WBNB.safeApprove(address(router), uint(~0));
    }

    /* ========== VIEWS ========== */

    function allocationOf(address _user) public view override returns (uint) {
        return totalBunnyBnbLp == 0 ? 0 : bunnyBnbLpOf[_user].mul(1e18).div(totalBunnyBnbLp);
    }

    function refundOf(address _user) public view override returns (uint) {
        uint lpPriceNow = lpPriceAtArchive;
        if (lpPriceAtArchive == 0) {
            (, lpPriceNow) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        }

        if (totalBunnyBnbLp.mul(lpPriceNow).div(1e18) <= presaleAmountUSD) {
            return 0;
        }

        uint lpAmountToPay = presaleAmountUSD.mul(allocationOf(_user)).div(lpPriceNow);
        return bunnyBnbLpOf[_user].sub(lpAmountToPay);
    }

    function accountListLength() external view override returns (uint) {
        return accountList.length;
    }

    function presaleDataOf(address account) public view returns (PresaleData memory) {
        PresaleData memory presaleData;
        presaleData.startTime = startTime;
        presaleData.endTime = endTime;
        presaleData.userLpAmount = bunnyBnbLpOf[account];
        presaleData.totalLpAmount = totalBunnyBnbLp;
        presaleData.claimedOf = claimedOf[account];
        presaleData.refundLpAmount = refundLpOf[account];
        presaleData.qbtBnbLpAmount = qbtBnbLpAmount;

        return presaleData;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setQubitBnbLocker(address _qubitBnbLocker) public override onlyOwner {
        require(_qubitBnbLocker != address(0), "QubitPresale: invalid address");

        qbtBnbLocker = IPresaleLocker(_qubitBnbLocker);
        qbtBnbLocker.setPresaleEndTime(endTime);
        QBT_WBNB_LP.safeApprove(address(qbtBnbLocker), uint(~0));
    }

    function setPresaleAmountUSD(uint _presaleAmountUSD) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        presaleAmountUSD = _presaleAmountUSD;
    }

    function setPeriod(uint _start, uint _end) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");
        require(block.timestamp < _start && _start < _end, "QubitPresale: invalid time values");
        require(address(qbtBnbLocker) != address(0), "QubitPresale: QbtBnbLocker must be set");

        startTime = _start;
        endTime = _end;

        qbtBnbLocker.setPresaleEndTime(endTime);
    }

    function setQbtAmount(uint _qbtAmount) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        qbtAmount = _qbtAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        require(block.timestamp > startTime && block.timestamp < endTime, "QubitPresale: not in presale");
        require(_amount > 0, "QubitPresale: invalid amount");

        if (bunnyBnbLpOf[msg.sender] == 0) {
            accountList.push(msg.sender);
        }
        bunnyBnbLpOf[msg.sender] = bunnyBnbLpOf[msg.sender].add(_amount);
        totalBunnyBnbLp = totalBunnyBnbLp.add(_amount);

        BUNNY_WBNB_LP.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function archive() public override onlyOwner returns (uint bunnyAmount, uint wbnbAmount) {
        require(!archived && qbtBnbLpAmount == 0, "QubitPresale: already archived");
        require(IBEP20(QBT).balanceOf(address(this)) == qbtAmount, "QubitPresale: lack of QBT");
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        (, lpPriceAtArchive) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        require(lpPriceAtArchive > 0, "QubitPresale: invalid lp price");
        uint presaleAmount = presaleAmountUSD.div(lpPriceAtArchive).mul(1e18);

        // burn manually transferred LP token
        if (IPancakePair(BUNNY_WBNB_LP).balanceOf(BUNNY_WBNB_LP) > 0) {
            IPancakePair(BUNNY_WBNB_LP).burn(DEPLOYER);
        }

        uint amount = Math.min(totalBunnyBnbLp, presaleAmount);
        (bunnyAmount, wbnbAmount) = router.removeLiquidity(BUNNY, WBNB, amount, 0, 0, address(this), block.timestamp);
        BUNNY.safeTransfer(DEAD, bunnyAmount);

        uint qbtAmountFixed = presaleAmount < totalBunnyBnbLp
            ? qbtAmount
            : qbtAmount.mul(totalBunnyBnbLp).div(presaleAmount);
        (, , qbtBnbLpAmount) = router.addLiquidity(
            QBT,
            WBNB,
            qbtAmountFixed,
            wbnbAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        archived = true;
    }

    function distribute(uint distributeThreshold) external override onlyOwner {
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        require(archived, "QubitPresale: not yet archived");
        uint start = _distributionCursor;
        uint totalUserCount = accountList.length;
        uint remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        uint length = Math.min(remain, distributeThreshold);
        for (uint i = start; i < start + length; i++) {
            address account = accountList[i];
            if (!claimedOf[account]) {
                claimedOf[account] = true;

                uint refundingLpAmount = refundOf(account);
                if (refundingLpAmount > 0 && refundLpOf[account] == 0) {
                    refundLpOf[account] = refundingLpAmount;
                    BUNNY_WBNB_LP.safeTransfer(account, refundingLpAmount);
                }

                uint depositLpAmount = qbtBnbLpAmount.mul(allocationOf(account)).div(1e18);
                if (depositLpAmount > 0) {
                    delete bunnyBnbLpOf[account];
                    qbtBnbLocker.depositBehalf(account, depositLpAmount);
                }
            }
            _distributionCursor++;
        }
        remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        emit Distributed(length, remain);
    }

    function sweep(uint _lpAmount, uint _offerAmount) public override onlyOwner {
        require(_lpAmount <= IBEP20(BUNNY_WBNB_LP).balanceOf(address(this)), "QubitPresale: not enough token 0");
        require(_offerAmount <= IBEP20(QBT).balanceOf(address(this)), "QubitPresale: not enough token 1");
        BUNNY_WBNB_LP.safeTransfer(msg.sender, _lpAmount);
        QBT.safeTransfer(msg.sender, _offerAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IFlashLoanReceiver.sol";


contract QLiquidationV2 is WhitelistUpgradeable, ReentrancyGuardUpgradeable, IFlashLoanReceiver {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeRouter02 private constant ROUTER_MDEX = IPancakeRouter02(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8);

    address private constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
    address private constant qBTC = 0xd055D32E50C57B413F7c2a4A052faF6933eA7927;
    address private constant qETH = 0xb4b77834C73E9f66de57e6584796b034D41Ce39A;
    address private constant qUSDC = 0x1dd6E079CF9a82c91DaF3D8497B27430259d32C2;
    address private constant qUSDT = 0x99309d2e7265528dC7C3067004cC4A90d37b7CC3;
    address private constant qDAI = 0x474010701715658fC8004f51860c90eEF4584D2B;
    address private constant qBUSD = 0xa3A155E76175920A40d2c8c765cbCB1148aeB9D1;
    address private constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    address private constant qMDX = 0xFF858dB0d6aA9D3fCA13F6341a1693BE4416A550;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;  // BUSD pair
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // BUSD pair
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address private constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;


    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying != MDX && underlying != QBT) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            }
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
            IBEP20(underlying).approve(address(Qore), uint(- 1));
        }

        IBEP20(WBNB).approve(address(ROUTER_MDEX), uint(- 1));
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[10] memory) {
        return [WBNB, BTC, ETH, DAI, USDC, BUSD, USDT, CAKE, QBT, MDX];
    }

    function qTokens() public pure returns (address[10] memory) {
        return [qBNB, qBTC, qETH, qDAI, qUSDC, qBUSD, qUSDT, qCAKE, qQBT, qMDX];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidation: invalid route address");
        _routePairAddresses[token] = route;
    }

    /* ========== Flashloan Callback FUNCTION ========== */

    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata fees,
        address,
        bytes calldata params
    ) external override returns (bool) {
        require(fees.length == 1, "QLiquidationV2 : invalid request");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) = abi.decode(params, (address, address, address, uint));

        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, amount);

        if (qTokenBorrowed != qTokenCollateral) {
            if (qTokenBorrowed == qMDX) {
                _swapToMDX(qTokenCollateral, amount.add(fees[0]));
            }
            else {
                _swapToRepayFlashloan(qTokenCollateral, qTokenBorrowed, amount.add(fees[0]));
            }
        }
        else if (qTokenBorrowed == qBNB) {
            IWETH(WBNB).deposit{value:amount.add(fees[0])}();
        }

        return true;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));
        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _flashloanQubit(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address[] memory _markets = new address[](1);
        _markets[0] = _qTokenBorrowed;

        uint[] memory _amounts = new uint[](1);
        _amounts[0] = amount;
//        Qore.flashLoan(address(this), _markets, _amounts,
//            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, amount)
//        );
    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _swapToMDX(address _qTokenCollateral, uint repayAmount) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();
        if (collateralToken == WBNB) {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = MDX;
            ROUTER_MDEX.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
        } else {
            uint WBNBamount;
            {
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = MDX;
                WBNBamount = ROUTER_MDEX.getAmountsIn(repayAmount, path)[0];
            }

            if (_routePairAddresses[collateralToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = collateralToken;
                path[1] = _routePairAddresses[collateralToken];
                path[2] = WBNB;

                ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp)[2];
            } else {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = WBNB;

                ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp)[1];
            }

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = MDX;

            ROUTER_MDEX.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
        }
    }

    function _swapToRepayFlashloan(address _qTokenCollateral, address _qTokenBorrowed, uint repayAmount) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();
        address borrowedToken = IQToken(_qTokenBorrowed).underlying();

        if (collateralToken == WBNB) {
            if (_routePairAddresses[borrowedToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = WBNB;
                path[1] = _routePairAddresses[borrowedToken];
                path[2] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
            else {
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
        } else if (borrowedToken == WBNB) {
            if (_routePairAddresses[collateralToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = collateralToken;
                path[1] = _routePairAddresses[collateralToken];
                path[2] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            }
        }
        else {
            if ( (borrowedToken == ETH && (collateralToken == USDC || collateralToken == BTC)) ||
                (collateralToken == ETH && (borrowedToken == USDC || borrowedToken == BTC)) ||
                (borrowedToken == BTC && (collateralToken == ETH || collateralToken == BUSD)) ||
                (collateralToken == BTC && (borrowedToken == ETH || borrowedToken == BUSD)) ||
                (borrowedToken == DAI && collateralToken == BUSD) || (collateralToken == DAI && borrowedToken == BUSD) ||
                (borrowedToken == BUSD && (collateralToken == CAKE || collateralToken == BTC || collateralToken == USDT || collateralToken == USDC)) ||
                (collateralToken == BUSD && (borrowedToken == CAKE || borrowedToken == BTC || borrowedToken == USDT || borrowedToken == USDC)) ||
                (borrowedToken == USDT && (collateralToken == BUSD || collateralToken == CAKE || collateralToken == USDC)) ||
                (collateralToken == USDT && (borrowedToken == BUSD || borrowedToken == CAKE || borrowedToken == USDC)) ||
                (borrowedToken == USDC && (collateralToken == ETH || collateralToken == BUSD || collateralToken == USDT)) ||
                (collateralToken == USDC && (borrowedToken == ETH || borrowedToken == BUSD || borrowedToken == USDT)) ) {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = borrowedToken;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                // first swap to WBNB,
                uint WBNBamount;
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                }

                if (_routePairAddresses[collateralToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = collateralToken;
                    path[1] = _routePairAddresses[collateralToken];
                    path[2] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = collateralToken;
                    path[1] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                }

                // then swap WBNB to borrowedToken
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/ISwapCallee.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceCalculator.sol";


contract QLiquidationTestnet is ISwapCallee, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0x995cCA2cD0C269fdEe7d057A8A7aaA1586ecEf51);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    address private constant qBNB = 0x14fA6A83A08B763B8A430e1fAeafe009D266F280;
//    address private constant qETH = 0xAf9A0488D21A3cec2012f3E6Fe632B65Aa6Ea61D;
    address private constant qUSDT = 0x93848E23F0a70891A67a98a6CEBb47Fa55A51508;
//    address private constant qDAI = 0xfc743504c7FF5526e3Ba97617F6e6Bf8fD8cfdF0;
    address private constant qBUSD = 0x5B8BA405976b3A798F47DAE502e1982502aF64c5;
    address private constant qQBT = 0x2D076EC4FE501927c5bea2A5bA8902e5e7A9B727;

//    address private constant BUNNY_BNB = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address private constant WBNB_BUSD = 0xe0e92035077c39594793e61802a350347c320cf2;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

//    address private constant ETH = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
//    address private constant DAI = 0x8a9424745056Eb399FD19a0EC26A14316684e274;  // BUSD pair
    address private constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private constant USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    address private constant QBT = 0xF523e4478d909968090a232eB380E2dd6f802518;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
        }
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[4] memory) {
        return [WBNB, BUSD, USDT, QBT];
    }

    function qTokens() public pure returns (address[4] memory) {
        return [qBNB, qBUSD, qUSDT, qQBT];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidationTestnet: invalid route address");
        _routePairAddresses[token] = route;
    }

    function approveTokenForRouter(address token) external onlyOwner {
        IBEP20(token).approve(address(ROUTER), uint(- 1));
    }

    /* ========== Pancake Callback FUNCTION ========== */

    function pancakeCall(address, uint, uint, bytes calldata data) external override {
        require(msg.sender == WBNB_BUSD, "QLiquidation: only used for WBNB_BUSD");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint loanBalance, uint amount) = abi.decode(data, (address, address, address, uint, uint));

        uint liquidateBalance = Math.min(_swapWBNBtoBorrowToken(qTokenBorrowed, loanBalance), amount);
        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, liquidateBalance);

        _repayToSwap(
            qTokenCollateral,
            loanBalance.mul(10000).div(9975).add(1),
            msg.sender
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloan(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloan(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));

        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            IWETH(WBNB).withdraw(amount);
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _swapWBNBtoBorrowToken(address _qTokenBorrowed, uint loanBalance) private returns (uint liquidateBalance) {
        address underlying = IQToken(_qTokenBorrowed).underlying();
        liquidateBalance = 0;
        if (underlying == WBNB) {
            liquidateBalance = loanBalance;
        } else {
            uint before = IBEP20(underlying).balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = underlying;

            ROUTER.swapExactTokensForTokens(loanBalance, 0, path, address(this), block.timestamp);
            liquidateBalance = IBEP20(underlying).balanceOf(address(this)).sub(before);
        }
    }

    function _flashloan(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address _underlying = IQToken(_qTokenBorrowed).underlying();

        uint borrowBalance;
        if (_underlying == WBNB) {
            borrowBalance = amount;
        } else {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = _underlying;

            borrowBalance = ROUTER.getAmountsIn(amount, path)[0];
        }

        IPancakePair(WBNB_BUSD).swap(
            0, borrowBalance, address(this),
            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, borrowBalance, amount)
        );

    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        if (address(collateralToken) == WBNB) {
            IWETH(WBNB).deposit{value : address(this).balance}();
        }

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _repayToSwap(address _qTokenCollateral, uint repayAmount, address to) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();

        if (collateralToken != WBNB) {
            address[] memory path = new address[](2);
            path[0] = collateralToken;
            path[1] = WBNB;

            ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
        }

        require(IBEP20(WBNB).balanceOf(address(this)) >= repayAmount, "QLiquidation: can't repay to pancake");
        WBNB.safeTransfer(to, repayAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISwapCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/ISwapCallee.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceCalculator.sol";


contract QLiquidation is ISwapCallee, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeRouter02 private constant ROUTER_MDEX = IPancakeRouter02(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8);

    address private constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
    address private constant qBTC = 0xd055D32E50C57B413F7c2a4A052faF6933eA7927;
    address private constant qETH = 0xb4b77834C73E9f66de57e6584796b034D41Ce39A;
    address private constant qUSDC = 0x1dd6E079CF9a82c91DaF3D8497B27430259d32C2;
    address private constant qUSDT = 0x99309d2e7265528dC7C3067004cC4A90d37b7CC3;
    address private constant qDAI = 0x474010701715658fC8004f51860c90eEF4584D2B;
    address private constant qBUSD = 0xa3A155E76175920A40d2c8c765cbCB1148aeB9D1;
    address private constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    address private constant qMDX = 0xFF858dB0d6aA9D3fCA13F6341a1693BE4416A550;
    address private constant qBUNNY = 0xceB82D224a531525C838BF0ACdc33B2C8d550c47;

    address private constant BUNNY_BNB = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address private constant CAKE_BNB = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;  // BUSD pair
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // BUSD pair
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address private constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;
    address private constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;


    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying != MDX && underlying != QBT) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            }
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
        }

        IBEP20(WBNB).approve(address(ROUTER_MDEX), uint(- 1));
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[11] memory) {
        return [WBNB, BTC, ETH, DAI, USDC, BUSD, USDT, CAKE, QBT, MDX, BUNNY];
    }

    function qTokens() public pure returns (address[11] memory) {
        return [qBNB, qBTC, qETH, qDAI, qUSDC, qBUSD, qUSDT, qCAKE, qQBT, qMDX, qBUNNY];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidation: invalid route address");
        _routePairAddresses[token] = route;
    }

    function approveTokenForRouter(address token) external onlyOwner {
        IBEP20(token).approve(address(ROUTER), uint(- 1));
    }

    function approveToken(address token) external onlyOwner {
        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying == token) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
                IBEP20(underlying).approve(qTokens()[i], uint(- 1));
            }
        }
    }

    /* ========== Pancake Callback FUNCTION ========== */

    function pancakeCall(address, uint, uint, bytes calldata data) external override {
        require(msg.sender == BUNNY_BNB || msg.sender == CAKE_BNB, "QLiquidation: only used for BUNNY_BNB or CAKE_BNB");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint loanBalance, uint amount) = abi.decode(data, (address, address, address, uint, uint));

        uint liquidateBalance = Math.min(_swapWBNBtoBorrowToken(qTokenBorrowed, loanBalance), amount);
        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, liquidateBalance);

        _repayToSwap(
            qTokenCollateral,
            loanBalance.mul(10000).div(9975).add(1),
            msg.sender
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloan(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloan(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));
        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            IWETH(WBNB).withdraw(amount);
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _swapWBNBtoBorrowToken(address _qTokenBorrowed, uint loanBalance) private returns (uint liquidateBalance) {
        address underlying = IQToken(_qTokenBorrowed).underlying();
        liquidateBalance = 0;
        if (underlying == WBNB) {
            liquidateBalance = loanBalance;
        } else if (underlying == MDX) {
            uint before = IBEP20(underlying).balanceOf(address(this));

            address[] memory path = new address[](3);
            path[0] = WBNB;
            path[1] = BUSD;
            path[2] = underlying;

            ROUTER_MDEX.swapExactTokensForTokens(loanBalance, 0, path, address(this), block.timestamp);
            liquidateBalance = IBEP20(underlying).balanceOf(address(this)).sub(before);
        } else {
            uint before = IBEP20(underlying).balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = underlying;

            ROUTER.swapExactTokensForTokens(loanBalance, 0, path, address(this), block.timestamp);
            liquidateBalance = IBEP20(underlying).balanceOf(address(this)).sub(before);
        }
    }

    function _flashloan(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address _underlying = IQToken(_qTokenBorrowed).underlying();

        uint borrowBalance;
        if (_underlying == WBNB) {
            borrowBalance = amount;
        } else if (_underlying == MDX) {
            address[] memory path = new address[](3);
            path[0] = WBNB;
            path[1] = BUSD;
            path[2] = _underlying;

            borrowBalance = ROUTER_MDEX.getAmountsIn(amount, path)[0];
        } else if (_routePairAddresses[_underlying] != address(0)) {
            address[] memory path = new address[](3);
            path[0] = WBNB;
            path[1] = _routePairAddresses[_underlying];
            path[2] = _underlying;

            borrowBalance = ROUTER.getAmountsIn(amount, path)[0];
        } else {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = _underlying;

            borrowBalance = ROUTER.getAmountsIn(amount, path)[0];
        }

        address flashLoanPool = _qTokenBorrowed == qCAKE || _qTokenCollateral == qCAKE ? BUNNY_BNB : CAKE_BNB;

        IPancakePair(flashLoanPool).swap(
            borrowBalance, 0, address(this),
            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, borrowBalance, amount)
        );

    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        if (address(collateralToken) == WBNB) {
            IWETH(WBNB).deposit{value : address(this).balance}();
        }

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _repayToSwap(address _qTokenCollateral, uint repayAmount, address to) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();

        if (collateralToken != WBNB && _routePairAddresses[collateralToken] != address(0)) {
            address[] memory path = new address[](3);
            path[0] = collateralToken;
            path[1] = _routePairAddresses[collateralToken];
            path[2] = WBNB;

            ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
        } else if (collateralToken != WBNB) {
            address[] memory path = new address[](2);
            path[0] = collateralToken;
            path[1] = WBNB;

            ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
        }

        require(IBEP20(WBNB).balanceOf(address(this)) >= repayAmount, "QLiquidation: can't repay to pancake");
        WBNB.safeTransfer(to, repayAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IQubitLocker.sol";
import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";

contract QubitLocker is IQubitLocker, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant LOCK_UNIT_BASE = 7 days;
    uint public constant LOCK_UNIT_MAX = 2 * 365 days;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint) public balances;
    mapping(address => uint) public expires;

    uint public override totalBalance;

    uint private _lastTotalScore;
    uint private _lastSlope;
    uint private _lastTimestamp;
    mapping(uint => uint) private _slopeChanges;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
        _lastTimestamp = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    function expiryOf(address account) external view override returns (uint) {
        return expires[account];
    }

    function availableOf(address account) external view override returns (uint) {
        return expires[account] < block.timestamp ? balances[account] : 0;
    }

    function totalScore() public view override returns (uint score, uint slope) {
        score = _lastTotalScore;
        slope = _lastSlope;

        uint prevTimestamp = _lastTimestamp;
        uint nextTimestamp = truncateExpiry(_lastTimestamp).add(LOCK_UNIT_BASE);
        while (nextTimestamp < block.timestamp) {
            uint deltaScore = nextTimestamp.sub(prevTimestamp).mul(slope);
            score = score < deltaScore ? 0 : score.sub(deltaScore);
            slope = slope.sub(_slopeChanges[nextTimestamp]);

            prevTimestamp = nextTimestamp;
            nextTimestamp = nextTimestamp.add(LOCK_UNIT_BASE);
        }

        uint deltaScore = block.timestamp > prevTimestamp ? block.timestamp.sub(prevTimestamp).mul(slope) : 0;
        score = score > deltaScore ? score.sub(deltaScore) : 0;
    }

    /**
     * @notice Calculate time-weighted balance of account
     * @param account Account of which the balance will be calculated
     */
    function scoreOf(address account) external view override returns (uint) {
        if (expires[account] < block.timestamp) return 0;
        return expires[account].sub(block.timestamp).mul(balances[account].div(LOCK_UNIT_MAX));
    }

    function truncateExpiry(uint time) public pure returns (uint) {
        return time.div(LOCK_UNIT_BASE).mul(LOCK_UNIT_BASE);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount, uint expiry) external override nonReentrant {
        require(amount > 0, "QubitLocker: invalid amount");

        expiry = balances[msg.sender] == 0 ? truncateExpiry(expiry) : expires[msg.sender];
        require(block.timestamp < expiry && expiry <= block.timestamp + LOCK_UNIT_MAX, "QubitLocker: invalid expiry");

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        QBT.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[msg.sender] = balances[msg.sender].add(amount);
        expires[msg.sender] = expiry;
    }

    function extendLock(uint nextExpiry) external override nonReentrant {
        uint amount = balances[msg.sender];
        require(amount > 0, "QubitLocker: zero balance");

        uint prevExpiry = expires[msg.sender];
        nextExpiry = truncateExpiry(nextExpiry);
        require(block.timestamp < prevExpiry, "QubitLocker: expired lock");
        require(
            Math.max(prevExpiry, block.timestamp) < nextExpiry && nextExpiry <= block.timestamp + LOCK_UNIT_MAX,
            "QubitLocker: invalid expiry time"
        );

        uint slopeChange = (_slopeChanges[prevExpiry] < amount.div(LOCK_UNIT_MAX))
            ? _slopeChanges[prevExpiry]
            : amount.div(LOCK_UNIT_MAX);
        _slopeChanges[prevExpiry] = _slopeChanges[prevExpiry].sub(slopeChange);
        _slopeChanges[nextExpiry] = _slopeChanges[nextExpiry].add(slopeChange);
        _updateTotalScoreExtendingLock(amount, prevExpiry, nextExpiry);
        expires[msg.sender] = nextExpiry;
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        require(balances[msg.sender] > 0 && block.timestamp >= expires[msg.sender], "QubitLocker: invalid state");
        _updateTotalScore(0, 0);

        uint amount = balances[msg.sender];
        totalBalance = totalBalance.sub(amount);
        delete balances[msg.sender];
        delete expires[msg.sender];
        QBT.safeTransfer(msg.sender, amount);
    }

    function depositBehalf(address account, uint amount, uint expiry) external override onlyWhitelisted nonReentrant {
        require(amount > 0, "QubitLocker: invalid amount");

        expiry = balances[account] == 0 ? truncateExpiry(expiry) : expires[account];
        require(block.timestamp < expiry && expiry <= block.timestamp + LOCK_UNIT_MAX, "QubitLocker: invalid expiry");

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        QBT.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[account] = balances[account].add(amount);
        expires[account] = expiry;
    }

    function withdrawBehalf(address account) external override onlyWhitelisted nonReentrant {
        require(balances[account] > 0 && block.timestamp >= expires[account], "QubitLocker: invalid state");
        _updateTotalScore(0, 0);

        uint amount = balances[account];
        totalBalance = totalBalance.sub(amount);
        delete balances[account];
        delete expires[account];
        QBT.safeTransfer(account, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _updateTotalScore(uint newAmount, uint nextExpiry) private {
        (uint score, uint slope) = totalScore();

        if (newAmount > 0) {
            uint slopeChange = newAmount.div(LOCK_UNIT_MAX);
            uint newAmountDeltaScore = nextExpiry.sub(block.timestamp).mul(slopeChange);

            slope = slope.add(slopeChange);
            score = score.add(newAmountDeltaScore);
        }

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;
    }

    function _updateTotalScoreExtendingLock(uint amount, uint prevExpiry, uint nextExpiry) private {
        (uint score, uint slope) = totalScore();

        uint deltaScore = nextExpiry.sub(prevExpiry).mul(amount.div(LOCK_UNIT_MAX));
        score = score.add(deltaScore);

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";
import "../interfaces/IQubitLocker.sol";

contract QubitDevReservoir is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    /* ========== STATE VARIABLES ========== */

    address public receiver;
    IQubitLocker public qubitLocker;

    uint public startAt;
    uint public ratePerSec;
    uint public dripped;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _receiver,
        uint _ratePerSec,
        uint _startAt
    ) external initializer {
        __WhitelistUpgradeable_init();

        require(_receiver != address(0), "QubitDevReservoir: invalid receiver");
        require(_ratePerSec > 0, "QubitDevReservoir: invalid rate");

        receiver = _receiver;
        ratePerSec = _ratePerSec;
        startAt = _startAt;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setLocker(address _qubitLocker) external onlyOwner {
        require(_qubitLocker != address(0), "QubitDevReservoir: invalid locker address");
        qubitLocker = IQubitLocker(_qubitLocker);
        IBEP20(QBT).approve(_qubitLocker, uint(-1));
    }

    /* ========== VIEWS ========== */

    function getDripInfo()
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (startAt, ratePerSec, dripped);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function drip() public onlyOwner returns (uint) {
        require(block.timestamp >= startAt, "QubitDevReservoir: not started");

        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);
        QBT.safeTransfer(receiver, amountToDrip);
        return amountToDrip;
    }

    function dripToLocker() public onlyOwner returns (uint) {
        require(address(qubitLocker) != address(0), "QubitDevReservoir: no locker assigned");
        require(block.timestamp >= startAt, "QubitDevReservoir: not started");
        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);

        if (qubitLocker.expiryOf(receiver) > block.timestamp) {
            qubitLocker.depositBehalf(receiver, amountToDrip, 0);
            return amountToDrip;
        } else {
            qubitLocker.depositBehalf(receiver, amountToDrip, block.timestamp + 365 days * 2);
            return amountToDrip;
        }
    }

    function setStartAt(uint _startAt) public onlyOwner {
        require(startAt <= _startAt, "QubitDevReservoir: invalid startAt");
        startAt = _startAt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";
import "../interfaces/IBEP20.sol";

contract QPromise is WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== STATE VARIABLES ========== */

    struct TokenData {
        address asset;
        uint amount;
    }

    mapping(address => TokenData) private _swaps;
    mapping(address => TokenData) private _repays;
    mapping(address => bool) public completes;

    /* ========== EVENTS ========== */

    event RepaymentClaimed(address indexed user, address asset, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setData(address[] memory accounts, TokenData[] memory receives, TokenData[] memory repays) external onlyOwner {
        require(accounts.length != 0 && accounts.length == receives.length && accounts.length == repays.length, "QRepayment: invalid data");
        for (uint i = 0; i < accounts.length; i++) {
            _swaps[accounts[i]] = receives[i];
            _repays[accounts[i]] = repays[i];
        }
    }

    function sweep(address asset) external onlyOwner {
        uint balance = IBEP20(asset).balanceOf(address(this));
        if (balance > 0) {
            asset.safeTransfer(msg.sender, balance);
        }
    }

    /* ========== VIEWS ========== */

    function infoOf(address account) external view returns (bool didClaim, address swapAsset, uint swapAmount, address repayAsset, uint repayAmount) {
        return (completes[account], _swaps[account].asset, _swaps[account].amount, _repays[account].asset, _repays[account].amount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external nonReentrant {
        require(!completes[msg.sender], "QRepayment: already claimed");
        completes[msg.sender] = true;

        address swapToken = _swaps[msg.sender].asset;
        uint swapAmount = _swaps[msg.sender].amount;
        delete _swaps[msg.sender];

        address repayToken = _repays[msg.sender].asset;
        uint repayAmount = _repays[msg.sender].amount;
        delete _repays[msg.sender];

        swapToken.safeTransferFrom(msg.sender, address(this), swapAmount);
        repayToken.safeTransfer(msg.sender, repayAmount);

        emit RepaymentClaimed(msg.sender, repayToken, repayAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IQDistributor.sol";
import "../interfaces/IQubitLocker.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IPriceCalculator.sol";

contract QDistributor is IQDistributor, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant BOOST_PORTION = 150;
    uint public constant BOOST_MAX = 250;
    uint private constant LAUNCH_TIMESTAMP = 1629784800;

    IQore public constant qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    IQubitLocker public constant qubitLocker = IQubitLocker(0xB8243be1D145a528687479723B394485cE3cE773);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    mapping(address => QConstant.DistributionInfo) public distributions;
    mapping(address => mapping(address => QConstant.DistributionAccountInfo)) public accountDistributions;

    /* ========== MODIFIERS ========== */

    modifier updateDistributionOf(address market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }

            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QDistributor: caller is not Qore");
        _;
    }

    /* ========== EVENTS ========== */

    event QubitDistributionSpeedUpdated(address indexed qToken, uint supplySpeed, uint borrowSpeed);
    event QubitClaimed(address indexed user, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQubitDistributionSpeed(address qToken, uint supplySpeed, uint borrowSpeed) external onlyOwner updateDistributionOf(qToken) {
        QConstant.DistributionInfo storage dist = distributions[qToken];
        dist.supplySpeed = supplySpeed;
        dist.borrowSpeed = borrowSpeed;
        emit QubitDistributionSpeedUpdated(qToken, supplySpeed, borrowSpeed);
    }

    // For reward distribution to different network (such as Klaytn)
    function withdrawReward(address receiver, uint amount) external onlyOwner {
        QBT.safeTransfer(receiver, amount);
    }

    /* ========== VIEWS ========== */

    function accruedQubit(address[] calldata markets, address account) external view override returns (uint) {
        uint amount = 0;
        for (uint i = 0; i < markets.length; i++) {
            amount = amount.add(_accruedQubit(markets[i], account));
        }
        return amount;
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return distributions[market];
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return accountDistributions[market][account];
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        (uint apySupplyQBT, uint apyBorrowQBT) = _calculateMarketDistributionAPY(market);
        (uint apyAccountSupplyQBT, uint apyAccountBorrowQBT) = _calculateAccountDistributionAPY(market, account);
        return QConstant.DistributionAPY(apySupplyQBT, apyBorrowQBT, apyAccountSupplyQBT, apyAccountBorrowQBT);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        uint accountSupply = IQToken(market).balanceOf(account);
        uint accountBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());

        boostedSupplyRatio = accountSupply > 0 ? accountDistributions[market][account].boostedSupply.mul(1e18).div(accountSupply) : 0;
        boostedBorrowRatio = accountBorrow > 0 ? accountDistributions[market][account].boostedBorrow.mul(1e18).div(accountBorrow) : 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function notifySupplyUpdated(address market, address user) external override nonReentrant onlyQore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP)
            return;

        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function notifyBorrowUpdated(address market, address user) external override nonReentrant onlyQore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP)
            return;

        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function notifyTransferred(address qToken, address sender, address receiver) external override nonReentrant onlyQore updateDistributionOf(qToken) {
        if (block.timestamp < LAUNCH_TIMESTAMP)
            return;

        require(sender != receiver, "QDistributor: invalid transfer");
        QConstant.DistributionInfo storage dist = distributions[qToken];
        QConstant.DistributionAccountInfo storage senderInfo = accountDistributions[qToken][sender];
        QConstant.DistributionAccountInfo storage receiverInfo = accountDistributions[qToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedQubit = senderInfo.accruedQubit.add(
                accQubitPerShare.mul(senderInfo.boostedSupply).div(1e18)
            );
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedQubit = receiverInfo.accruedQubit.add(
                accQubitPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSenderSupply = _calculateBoostedSupply(qToken, sender);
        uint boostedReceiverSupply = _calculateBoostedSupply(qToken, receiver);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    function claimQubit(address[] calldata markets, address account) external override onlyQore {
        uint amount = 0;
        uint userScore = qubitLocker.scoreOf(account);
        (uint totalScore, ) = qubitLocker.totalScore();

        for (uint i = 0; i < markets.length; i++) {
            amount = amount.add(_claimQubit(markets[i], account, userScore, totalScore));
        }

        amount = Math.min(amount, IBEP20(QBT).balanceOf(address(this)));
        QBT.safeTransfer(account, amount);
        emit QubitClaimed(account, amount);
    }

    function kick(address user) external override nonReentrant {
        if (block.timestamp < LAUNCH_TIMESTAMP)
            return;

        uint userScore = qubitLocker.scoreOf(user);
        require(userScore == 0, "QDistributor: kick not allowed");
        (uint totalScore, ) = qubitLocker.totalScore();

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            QConstant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];
            if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
            if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _accruedQubit(address market, address user) private view returns (uint) {
        QConstant.DistributionInfo memory dist = distributions[market];
        QConstant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];

        uint amount = userInfo.accruedQubit;
        uint accPerShareSupply = dist.accPerShareSupply;
        uint accPerShareBorrow = dist.accPerShareBorrow;

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (
            timeElapsed > 0 ||
            (accPerShareSupply != userInfo.accPerShareSupply) ||
            (accPerShareBorrow != userInfo.accPerShareBorrow)
        ) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint pendingQubit = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                amount = amount.add(pendingQubit);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint pendingQubit = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                amount = amount.add(pendingQubit);
            }
        }
        return amount;
    }

    function _claimQubit(address market, address user, uint userScore, uint totalScore) private returns (uint amount) {
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
        if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);

        amount = amount.add(userInfo.accruedQubit);
        userInfo.accruedQubit = 0;

        return amount;
    }

    function _calculateMarketDistributionAPY(address market) private view returns (uint apySupplyQBT, uint apyBorrowQBT) {
        // base supply QBT APY == average supply QBT APY * (Total balance / total Boosted balance)
        // base supply QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base supply QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset)
        uint numerSupply = distributions[market].supplySpeed.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomSupply = distributions[market].totalBoostedSupply.mul(IQToken(market).exchangeRate()).mul(priceCalculator.getUnderlyingPrice(market)).div(1e36);
        apySupplyQBT = denomSupply > 0 ? numerSupply.div(denomSupply) : 0;

        // base borrow QBT APY == average borrow QBT APY * (Total balance / total Boosted balance)
        // base borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset)
        uint numerBorrow = distributions[market].borrowSpeed.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomBorrow = distributions[market].totalBoostedBorrow.mul(IQToken(market).getAccInterestIndex()).mul(priceCalculator.getUnderlyingPrice(market)).div(1e36);
        apyBorrowQBT = denomBorrow > 0 ? numerBorrow.div(denomBorrow) : 0;
    }

    function _calculateAccountDistributionAPY(address market, address account) private view returns (uint apyAccountSupplyQBT, uint apyAccountBorrowQBT) {
        if (account == address(0)) return (0, 0);
        (uint apySupplyQBT, uint apyBorrowQBT) = _calculateMarketDistributionAPY(market);

        // user supply QBT APY == ((qubitRate * 365 days * price Of Qubit) / (Total boosted balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        uint accountSupply = IQToken(market).balanceOf(account);
        apyAccountSupplyQBT = accountSupply > 0 ? apySupplyQBT.mul(accountDistributions[market][account].boostedSupply).div(accountSupply) : 0;

        // user borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total boosted balance * interestIndex * price of asset) * my boosted balance  / my balance
        uint accountBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());
        apyAccountBorrowQBT = accountBorrow > 0 ? apyBorrowQBT.mul(accountDistributions[market][account].boostedBorrow).div(accountBorrow) : 0;
    }

    function _calculateBoostedSupply(address market, address user) private view returns (uint) {
        uint defaultSupply = IQToken(market).balanceOf(user);
        uint boostedSupply = defaultSupply;

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint scoreBoosted = IQToken(market).totalSupply().mul(userScore).div(totalScore).mul(BOOST_PORTION).div(
                100
            );
            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply.mul(BOOST_MAX).div(100));
    }

    function _calculateBoostedBorrow(address market, address user) private view returns (uint) {
        uint accInterestIndex = IQToken(market).getAccInterestIndex();
        uint defaultBorrow = IQToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);
        uint boostedBorrow = defaultBorrow;

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint totalBorrow = IQToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint scoreBoosted = totalBorrow.mul(userScore).div(totalScore).mul(BOOST_PORTION).div(100);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow.mul(BOOST_MAX).div(100));
    }

    function _calculateBoostedSupply(address market, address user, uint userScore, uint totalScore) private view returns (uint) {
        uint defaultSupply = IQToken(market).balanceOf(user);
        uint boostedSupply = defaultSupply;

        if (userScore > 0 && totalScore > 0) {
            uint scoreBoosted = IQToken(market).totalSupply().mul(userScore).div(totalScore).mul(BOOST_PORTION).div(
                100
            );
            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply.mul(BOOST_MAX).div(100));
    }

    function _calculateBoostedBorrow(address market, address user, uint userScore, uint totalScore) private view returns (uint) {
        uint accInterestIndex = IQToken(market).getAccInterestIndex();
        uint defaultBorrow = IQToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);
        uint boostedBorrow = defaultBorrow;

        if (userScore > 0 && totalScore > 0) {
            uint totalBorrow = IQToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint scoreBoosted = totalBorrow.mul(userScore).div(totalScore).mul(BOOST_PORTION).div(100);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow.mul(BOOST_MAX).div(100));
    }

    function _updateSupplyOf(address market, address user, uint userScore, uint totalScore) private updateDistributionOf(market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user, userScore, totalScore);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(address market, address user, uint userScore, uint totalScore) private updateDistributionOf(market) {
        QConstant.DistributionInfo storage dist = distributions[market];
        QConstant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user, userScore, totalScore);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";

contract RateModelSlope is IRateModel, OwnableUpgradeable {
    using SafeMath for uint;

    uint private baseRatePerYear;
    uint private slopePerYearFirst;
    uint private slopePerYearSecond;
    uint private optimal;

    function initialize(
        uint _baseRatePerYear,
        uint _slopePerYearFirst,
        uint _slopePerYearSecond,
        uint _optimal
    ) external initializer {
        __Ownable_init();

        baseRatePerYear = _baseRatePerYear;
        slopePerYearFirst = _slopePerYearFirst;
        slopePerYearSecond = _slopePerYearSecond;
        optimal = _optimal;
    }

    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }

    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public view override returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        if (optimal > 0 && utilization < optimal) {
            return baseRatePerYear.add(utilization.mul(slopePerYearFirst).div(optimal)).div(365 days);
        } else {
            uint ratio = utilization.sub(optimal).mul(1e18).div(uint(1e18).sub(optimal));
            return baseRatePerYear.add(slopePerYearFirst).add(ratio.mul(slopePerYearSecond).div(1e18)).div(365 days);
        }
    }

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) public view override returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRateModel.sol";

contract InterestRateModelHarness is IRateModel {
    uint public constant opaqueBorrowFailureCode = 20;
    bool public failBorrowRate;
    uint public borrowRate;

    constructor(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function setFailBorrowRate(bool failBorrowRate_) public {
        failBorrowRate = failBorrowRate_;
    }

    function setBorrowRate(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function getBorrowRate(
        uint _cash,
        uint _borrows,
        uint _reserves
    ) public view override returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        require(!failBorrowRate, "INTEREST_RATE_MODEL_ERROR");
        return borrowRate;
    }

    function getSupplyRate(
        uint _cash,
        uint _borrows,
        uint _reserves,
        uint _reserveFactor
    ) external view override returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        return borrowRate * (1 - _reserveFactor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";

contract RateModelLinear is IRateModel, OwnableUpgradeable {
    using SafeMath for uint;

    uint private baseRatePerYear;
    uint private multiplierPerYear;

    function initialize(uint _baseRatePerYear, uint _multiplierPerYear) external initializer {
        __Ownable_init();
        baseRatePerYear = _baseRatePerYear;
        multiplierPerYear = _multiplierPerYear;
    }

    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }

    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public view override returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        return (utilization.mul(multiplierPerYear).div(1e18).add(baseRatePerYear)).div(365 days);
    }

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) public view override returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/IQubitLocker.sol";
import "../interfaces/IBEP20.sol";


contract DashboardBSC is IDashboard, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IQubitLocker public qubitLocker;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "DashboardBSC: invalid qore address");
        require(address(qore) == address(0), "DashboardBSC: qore already set");
        qore = IQore(_qore);
    }

    function setLocker(address _qubitLocker) external onlyOwner {
        require(_qubitLocker != address(0), "DashboardBSC: invalid locker address");
        qubitLocker = IQubitLocker(_qubitLocker);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function qubitDataOf(address[] memory markets, address account) public view override returns (QubitData memory) {
        QubitData memory qubit;
        qubit.marketList = new MarketData[](markets.length);
        qubit.membershipList = new MembershipData[](markets.length);

        if (account != address(0)) {
            qubit.accountAcc = accountAccDataOf(account);
            qubit.locker = lockerDataOf(account);
        }

        for (uint i = 0; i < markets.length; i++) {
            qubit.marketList[i] = marketDataOf(markets[i]);

            if (account != address(0)) {
                qubit.membershipList[i] = membershipDataOf(markets[i], account);
            }
        }

        qubit.marketAverageBoostedRatio = _calculateAccMarketAverageBoostedRatio(markets);
        return qubit;
    }

    function marketDataOf(address market) public view override returns (MarketData memory) {
        MarketData memory marketData;
        QConstant.DistributionAPY memory apyDistribution = qore.apyDistributionOf(market, address(0));
        QConstant.DistributionInfo memory distributionInfo = qore.distributionInfoOf(market);
        IQToken qToken = IQToken(market);
        marketData.qToken = market;

        marketData.apySupply = qToken.supplyRatePerSec().mul(365 days);
        marketData.apyBorrow = qToken.borrowRatePerSec().mul(365 days);
        marketData.apySupplyQBT = apyDistribution.apySupplyQBT;
        marketData.apyBorrowQBT = apyDistribution.apyBorrowQBT;

        marketData.totalSupply = qToken.totalSupply().mul(qToken.exchangeRate()).div(1e18);
        marketData.totalBorrows = qToken.totalBorrow();
        marketData.totalBoostedSupply = distributionInfo.totalBoostedSupply;
        marketData.totalBoostedBorrow = distributionInfo.totalBoostedBorrow;

        marketData.cash = qToken.getCash();
        marketData.reserve = qToken.totalReserve();
        marketData.reserveFactor = qToken.reserveFactor();
        marketData.collateralFactor = qore.marketInfoOf(market).collateralFactor;
        marketData.exchangeRate = qToken.exchangeRate();
        marketData.borrowCap = qore.marketInfoOf(market).borrowCap;
        marketData.accInterestIndex = qToken.getAccInterestIndex();
        return marketData;
    }

    function membershipDataOf(address market, address account) public view override returns (MembershipData memory) {
        MembershipData memory membershipData;
        QConstant.DistributionAPY memory apyDistribution = qore.apyDistributionOf(market, account);
        QConstant.DistributionAccountInfo memory accountDistributionInfo = qore.accountDistributionInfoOf(market, account);

        membershipData.qToken = market;
        membershipData.membership = qore.checkMembership(account, market);
        membershipData.supply = IQToken(market).underlyingBalanceOf(account);
        membershipData.borrow = IQToken(market).borrowBalanceOf(account);
        membershipData.boostedSupply = accountDistributionInfo.boostedSupply;
        membershipData.boostedBorrow = accountDistributionInfo.boostedBorrow;
        membershipData.apyAccountSupplyQBT = apyDistribution.apyAccountSupplyQBT;
        membershipData.apyAccountBorrowQBT = apyDistribution.apyAccountBorrowQBT;
        return membershipData;
    }

    function accountAccDataOf(address account) public view override returns (AccountAccData memory) {
        AccountAccData memory accData;
        accData.accruedQubit = qore.accruedQubit(account);
        (accData.collateralInUSD,, accData.borrowInUSD) = qore.accountLiquidityOf(account);

        address[] memory markets = qore.allMarkets();
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        for (uint i = 0; i < markets.length; i++) {
            accData.supplyInUSD = accData.supplyInUSD.add(IQToken(markets[i]).underlyingBalanceOf(account).mul(prices[i]).div(1e18));
        }
        uint totalValueInUSD = accData.supplyInUSD.add(accData.borrowInUSD);
        (accData.accApySupply, accData.accApySupplyQBT) = _calculateAccAccountSupplyAPYOf(account, markets, prices, totalValueInUSD);
        (accData.accApyBorrow, accData.accApyBorrowQBT) = _calculateAccAccountBorrowAPYOf(account, markets, prices, totalValueInUSD);
        accData.averageBoostedRatio = _calculateAccAccountAverageBoostedRatio(account, markets);
        return accData;
    }

    function lockerDataOf(address account) public view override returns (LockerData memory) {
        LockerData memory lockerInfo;

        lockerInfo.totalLocked = qubitLocker.totalBalance();
        lockerInfo.locked = qubitLocker.balanceOf(account);

        (uint totalScore, ) = qubitLocker.totalScore();
        lockerInfo.totalScore = totalScore;
        lockerInfo.score = qubitLocker.scoreOf(account);

        lockerInfo.available = qubitLocker.availableOf(account);
        lockerInfo.expiry = qubitLocker.expiryOf(account);
        return lockerInfo;
    }

    function totalValueLockedOf(address[] memory markets) public view returns (uint totalSupplyInUSD) {
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        for (uint i = 0; i < markets.length; i++) {
            uint supplyInUSD = IQToken(markets[i]).getCash().mul(IQToken(markets[i]).exchangeRate()).div(1e18);
            totalSupplyInUSD = totalSupplyInUSD.add(supplyInUSD.mul(prices[i]).div(1e18));
        }
        return totalSupplyInUSD;
    }

    function totalCirculating() public view returns (uint) {
        return IBEP20(QBT).totalSupply()
                .sub(IBEP20(QBT).balanceOf(0xa7bc9a205A46017F47949F5Ee453cEBFcf42121b))      // reward Lock
                .sub(IBEP20(QBT).balanceOf(0xB224eD67C2F89Ae97758a9DB12163A6f30830EB2))      // developer's Supply Lock
                .sub(IBEP20(QBT).balanceOf(0x4c97c901B5147F8C1C7Ce3c5cF3eB83B44F244fE))      // MND Vault Lock
                .sub(IBEP20(QBT).balanceOf(0xB56290bEfc4216dc2A526a9022A76A1e4FDf122b))      // marketing Treasury
                .sub(IBEP20(QBT).balanceOf(0xAAf5d0dB947F835287b9432F677A51e9a1a01a35))      // security Treasury
                .sub(IBEP20(QBT).balanceOf(0xc7939B1Fa2E7662592b4d11dbE3C331bEE18FC85))      // Dev Treasury
//                .sub(qubitLocker.balanceOf(0x12C62464D8CF4a9Ca6f2EEAd1d7954A9fC21d053))      // QubitPool (lock forever)
                .sub(qubitLocker.totalBalance())                                             // QubitLocker
                .sub(IBEP20(QBT).balanceOf(0x67B806ab830801348ce719E0705cC2f2718117a1))      // reward Distributor (QDistributor)
                .sub(IBEP20(QBT).balanceOf(0xD1ad1943b70340783eD9814ffEdcAaAe459B6c39))      // PCB QBT-BNB pool reward lock
                .sub(IBEP20(QBT).balanceOf(0x89c527764f03BCb7dC469707B23b79C1D7Beb780));     // Orbit Bridge lock (displayed in Klaytn instead)
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _calculateAccAccountSupplyAPYOf(address account, address[] memory markets, uint[] memory prices, uint totalValueInUSD) private view returns (uint accApySupply, uint accApySupplyQBT) {
        for (uint i = 0; i < markets.length; i++) {
            QConstant.DistributionAPY memory apyDistribution = qore.apyDistributionOf(markets[i], account);

            uint supplyInUSD = IQToken(markets[i]).underlyingBalanceOf(account).mul(prices[i]).div(1e18);
            accApySupply = accApySupply.add(supplyInUSD.mul(IQToken(markets[i]).supplyRatePerSec().mul(365 days)).div(1e18));
            accApySupplyQBT = accApySupplyQBT.add(supplyInUSD.mul(apyDistribution.apyAccountSupplyQBT).div(1e18));
        }

        accApySupply = totalValueInUSD > 0 ? accApySupply.mul(1e18).div(totalValueInUSD) : 0;
        accApySupplyQBT = totalValueInUSD > 0 ? accApySupplyQBT.mul(1e18).div(totalValueInUSD) : 0;
    }

    function _calculateAccAccountBorrowAPYOf(address account, address[] memory markets, uint[] memory prices, uint totalValueInUSD) private view returns (uint accApyBorrow, uint accApyBorrowQBT) {
        for (uint i = 0; i < markets.length; i++) {
            QConstant.DistributionAPY memory apyDistribution = qore.apyDistributionOf(markets[i], account);

            uint borrowInUSD = IQToken(markets[i]).borrowBalanceOf(account).mul(prices[i]).div(1e18);
            accApyBorrow = accApyBorrow.add(borrowInUSD.mul(IQToken(markets[i]).borrowRatePerSec().mul(365 days)).div(1e18));
            accApyBorrowQBT = accApyBorrowQBT.add(borrowInUSD.mul(apyDistribution.apyAccountBorrowQBT).div(1e18));
        }

        accApyBorrow = totalValueInUSD > 0 ? accApyBorrow.mul(1e18).div(totalValueInUSD) : 0;
        accApyBorrowQBT = totalValueInUSD > 0 ? accApyBorrowQBT.mul(1e18).div(totalValueInUSD) : 0;
    }

    function _calculateAccAccountAverageBoostedRatio(address account, address[] memory markets) public view returns (uint averageBoostedRatio) {
        uint accBoostedCount = 0;
        for (uint i = 0; i < markets.length; i++) {
            (uint boostedSupplyRatio, uint boostedBorrowRatio) = qore.boostedRatioOf(markets[i], account);

            if (boostedSupplyRatio > 0) {
                averageBoostedRatio = averageBoostedRatio.add(boostedSupplyRatio);
                accBoostedCount++;
            }

            if (boostedBorrowRatio > 0) {
                averageBoostedRatio = averageBoostedRatio.add(boostedBorrowRatio);
                accBoostedCount++;
            }
        }
        return accBoostedCount > 0 ? averageBoostedRatio.div(accBoostedCount) : 0;
    }

    function _calculateAccMarketAverageBoostedRatio(address[] memory markets) public view returns (uint averageBoostedRatio) {
        uint accValueInUSD = 0;
        uint accBoostedValueInUSD = 0;

        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        for (uint i = 0; i < markets.length; i++) {
            QConstant.DistributionInfo memory distributionInfo = qore.distributionInfoOf(markets[i]);

            accBoostedValueInUSD = accBoostedValueInUSD.add(distributionInfo.totalBoostedSupply.mul(IQToken(markets[i]).exchangeRate()).mul(prices[i]).div(1e36));
            accBoostedValueInUSD = accBoostedValueInUSD.add(distributionInfo.totalBoostedBorrow.mul(IQToken(markets[i]).getAccInterestIndex()).mul(prices[i]).div(1e36));

            accValueInUSD = accValueInUSD.add(IQToken(markets[i]).totalSupply().mul(IQToken(markets[i]).exchangeRate()).mul(prices[i]).div(1e36));
            accValueInUSD = accValueInUSD.add(IQToken(markets[i]).totalBorrow().mul(prices[i]).div(1e18));
        }
        return accValueInUSD > 0 ? accBoostedValueInUSD.mul(1e18).div(accValueInUSD) : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/QConstant.sol";

interface IDashboard {
    struct QubitData {
        MarketData[] marketList;
        MembershipData[] membershipList;
        AccountAccData accountAcc;
        LockerData locker;
        uint marketAverageBoostedRatio;
    }

    struct MarketData {
        address qToken;

        uint apySupply;
        uint apyBorrow;
        uint apySupplyQBT;
        uint apyBorrowQBT;

        uint totalSupply;
        uint totalBorrows;
        uint totalBoostedSupply;
        uint totalBoostedBorrow;

        uint cash;
        uint reserve;
        uint reserveFactor;
        uint collateralFactor;
        uint exchangeRate;
        uint borrowCap;
        uint accInterestIndex;
    }

    struct MembershipData {
        address qToken;
        bool membership;
        uint supply;
        uint borrow;
        uint boostedSupply;
        uint boostedBorrow;
        uint apyAccountSupplyQBT;
        uint apyAccountBorrowQBT;
    }

    struct AccountAccData {
        uint accruedQubit;
        uint collateralInUSD;
        uint supplyInUSD;
        uint borrowInUSD;
        uint accApySupply;
        uint accApyBorrow;
        uint accApySupplyQBT;
        uint accApyBorrowQBT;
        uint averageBoostedRatio;
    }

    struct LockerData {
        uint totalLocked;
        uint locked;
        uint totalScore;
        uint score;
        uint available;
        uint expiry;
    }

    function qubitDataOf(address[] memory markets, address account) external view returns (QubitData memory);

    function marketDataOf(address market) external view returns (MarketData memory);
    function membershipDataOf(address market, address account) external view returns (MembershipData memory);
    function accountAccDataOf(address account) external view returns (AccountAccData memory);
    function lockerDataOf(address account) external view returns (LockerData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../library/HomoraMath.sol";

contract PriceCalculatorBSC is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;
    using HomoraMath for uint;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPancakeFactory private constant mdexFactory = IPancakeFactory(0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8);

    uint private constant THRESHOLD = 5 minutes;

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    mapping(address => ReferenceData) public references;
    mapping(address => address) private tokenFeeds;

    /* ========== Event ========== */

    event MarketListed(address qToken);
    event MarketEntered(address qToken, address account);
    event MarketExited(address qToken, address account);

    event CloseFactorUpdated(uint newCloseFactor);
    event CollateralFactorUpdated(address qToken, uint newCollateralFactor);
    event LiquidationIncentiveUpdated(uint newLiquidationIncentive);
    event BorrowCapUpdated(address indexed qToken, uint newBorrowCap);

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Qore: caller is not the owner or keeper");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "PriceCalculatorBSC: invalid keeper address");
        keeper = _keeper;
    }

    function setTokenFeed(address asset, address feed) external onlyKeeper {
        tokenFeeds[asset] = feed;
    }

    function setPrices(address[] memory assets, uint[] memory prices, uint timestamp) external onlyKeeper {
        require(timestamp <= block.timestamp && block.timestamp.sub(timestamp) <= THRESHOLD, "PriceCalculator: invalid timestamp");

        for (uint i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({lastData : prices[i], lastUpdated : block.timestamp});
        }
    }

    /* ========== VIEWS ========== */

    function priceOf(address asset) public view override returns (uint priceInUSD) {
        if (asset == address(0)) {
            return priceOfBNB();
        }
        uint decimals = uint(IBEP20(asset).decimals());
        uint unitAmount = 10 ** decimals;
        return _oracleValueInUSDOf(asset, unitAmount, decimals);
    }

    function pricesOf(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            prices[i] = priceOf(assets[i]);
        }
        return prices;
    }

    function getUnderlyingPrice(address qToken) public view override returns (uint) {
        return priceOf(IQToken(qToken).underlying());
    }

    function getUnderlyingPrices(address[] memory qTokens) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](qTokens.length);
        for (uint i = 0; i < qTokens.length; i++) {
            prices[i] = priceOf(IQToken(qTokens[i]).underlying());
        }
        return prices;
    }

    function priceOfBNB() public view returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(tokenFeeds[WBNB]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInBNB, uint valueInUSD) {
        if (asset == address(0) || asset == WBNB) {
            return _oracleValueOf(asset, amount);
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("Cake-LP")) {
            return _getPairPrice(asset, amount);
        } else {
            return _oracleValueOf(asset, amount);
        }
    }

    function unsafeValueOfAsset(address asset, uint amount) public view override returns (uint valueInBNB, uint valueInUSD) {
        valueInBNB = 0;
        valueInUSD = 0;

        if (asset == address(0) || asset == WBNB) {
            valueInBNB = amount;
            valueInUSD = amount.mul(priceOfBNB()).div(1e18);
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("Cake-LP")) {
            if (IPancakePair(asset).totalSupply() == 0) return (0, 0);

            (uint reserve0, uint reserve1,) = IPancakePair(asset).getReserves();
            if (IPancakePair(asset).token0() == WBNB) {
                valueInBNB = amount.mul(reserve0).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            } else if (IPancakePair(asset).token1() == WBNB) {
                valueInBNB = amount.mul(reserve1).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            } else {
                (uint tokenPriceInBNB,) = valueOfAsset(IPancakePair(asset).token0(), 10 ** uint(IBEP20(IPancakePair(asset).token0()).decimals()));
                if (tokenPriceInBNB == 0) {
                    (tokenPriceInBNB,) = valueOfAsset(IPancakePair(asset).token1(), 10 ** uint(IBEP20(IPancakePair(asset).token1()).decimals()));
                    if (IBEP20(IPancakePair(asset).token1()).decimals() < uint8(18)) {
                        reserve1 = reserve1.mul(10 ** uint(uint8(18) - IBEP20(IPancakePair(asset).token1()).decimals()));
                    }
                    valueInBNB = amount.mul(reserve1).mul(2).mul(tokenPriceInBNB).div(1e18).div(IPancakePair(asset).totalSupply());
                } else {
                    if (IBEP20(IPancakePair(asset).token0()).decimals() < uint8(18)) {
                        reserve0 = reserve0.mul(10 ** uint(uint8(18) - IBEP20(IPancakePair(asset).token0()).decimals()));
                    }
                    valueInBNB = amount.mul(reserve0).mul(2).mul(tokenPriceInBNB).div(1e18).div(IPancakePair(asset).totalSupply());
                }
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            }
        } else if (asset == MDX) {
            address pair = mdexFactory.getPair(MDX, BUSD);
            if (IBEP20(MDX).balanceOf(pair) == 0) return (0, 0);
            (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();

            (,uint priceOfBUSD) = _oracleValueOf(BUSD, 1e18);
            if (IPancakePair(pair).token0() == BUSD) {
                valueInUSD = reserve0.mul(amount).div(reserve1).mul(priceOfBUSD).div(1e18);
            } else if (IPancakePair(pair).token1() == BUSD) {
                valueInUSD = reserve1.mul(amount).div(reserve0).mul(priceOfBUSD).div(1e18);
            } else {
                return (0, 0);
            }
            valueInBNB = valueInUSD.mul(1e18).div(priceOfBNB());
        } else {
            address pair = factory.getPair(asset, WBNB);
            if (IBEP20(asset).balanceOf(pair) == 0) return (0, 0);
            (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();

            if (IPancakePair(pair).token0() == WBNB) {
                valueInBNB = reserve0.mul(amount).div(reserve1);
            } else if (IPancakePair(pair).token1() == WBNB) {
                valueInBNB = reserve1.mul(amount).div(reserve0);
            } else {
                return (0, 0);
            }
            valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getPairPrice(address pair, uint amount) private view returns (uint valueInBNB, uint valueInUSD) {
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint totalSupply = IPancakePair(pair).totalSupply();
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();

        if (IBEP20(token0).decimals() < uint8(18)) {
            reserve0 = reserve0.mul(10 ** uint(uint8(18) - IBEP20(token0).decimals()));
        }

        if (IBEP20(token1).decimals() < uint8(18)) {
            reserve1 = reserve1.mul(10 ** uint(uint8(18) - IBEP20(token1).decimals()));
        }

        uint sqrtK = HomoraMath.sqrt(reserve0.mul(reserve1)).fdiv(totalSupply);
        (uint px0,) = _oracleValueOf(token0, 10 ** uint(IBEP20(token0).decimals()));
        (uint px1,) = _oracleValueOf(token1, 10 ** uint(IBEP20(token1).decimals()));
        uint fairPriceInBNB = sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2 ** 56).mul(HomoraMath.sqrt(px1)).div(2 ** 56);

        valueInBNB = fairPriceInBNB.mul(amount).div(1e18);
        valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
    }

    function _oracleValueOf(address asset, uint amount) private view returns (uint valueInBNB, uint valueInUSD) {
        valueInUSD = 0;
        uint assetDecimals = asset == address(0) ? 1e18 : 10 ** uint(IBEP20(asset).decimals());
        if (tokenFeeds[asset] != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint(price).mul(1e10).mul(amount).div(assetDecimals);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(assetDecimals);
        }
        valueInBNB = valueInUSD.mul(1e18).div(priceOfBNB());
    }

    function _oracleValueInUSDOf(address asset, uint amount, uint decimals) private view returns (uint valueInUSD) {
        valueInUSD = 0;
        uint assetDecimals = asset == address(0) ? 1e18 : 10 ** decimals;
        if (tokenFeeds[asset] != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint(price).mul(1e10).mul(amount).div(assetDecimals);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(assetDecimals);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint;

    function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(rhs) / (2**112);
    }

    function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(2**112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQBridgeHandler.sol";
import "../interfaces/IQBridgeDelegator.sol";
import "../library/SafeToken.sol";
import "./QBridgeToken.sol";


contract QBridgeHandler is IQBridgeHandler, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint public constant OPTION_QUBIT_BNB_NONE = 100;
    uint public constant OPTION_QUBIT_BNB_0100 = 110;
    uint public constant OPTION_QUBIT_BNB_0050 = 105;
    uint public constant OPTION_BUNNY_XLP_0150 = 215;

    /* ========== STATE VARIABLES ========== */

    address public _bridgeAddress;

    mapping(bytes32 => address) public resourceIDToTokenContractAddress; // resourceID => token contract address
    mapping(address => bytes32) public tokenContractAddressToResourceID; // token contract address => resourceID

    mapping(address => bool) public burnList; // token contract address => is burnable
    mapping(address => bool) public contractWhitelist; // token contract address => is whitelisted
    mapping(uint => address) public delegators; // option => delegator contract address
    mapping(bytes32 => uint) public withdrawalFees; // resourceID => withdraw fee
    mapping(bytes32 => mapping(uint => uint)) public minAmounts; // [resourceID][option] => minDepositAmount

    /* ========== INITIALIZER ========== */

    function initialize(address bridgeAddress) external initializer {
        __Ownable_init();
        _bridgeAddress = bridgeAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBridge() {
        require(msg.sender == _bridgeAddress, "QBridgeHandler: caller is not the bridge contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setResource(bytes32 resourceID, address contractAddress) external override onlyBridge {
        resourceIDToTokenContractAddress[resourceID] = contractAddress;
        tokenContractAddressToResourceID[contractAddress] = resourceID;
        contractWhitelist[contractAddress] = true;
    }

    function setBurnable(address contractAddress) external override onlyBridge {
        require(contractWhitelist[contractAddress], "QBridgeHandler: contract address is not whitelisted");
        burnList[contractAddress] = true;
    }

    function setDelegator(uint option, address newDelegator) external onlyOwner {
        delegators[option] = newDelegator;
    }

    function setWithdrawalFee(bytes32 resourceID, uint withdrawalFee) external onlyOwner {
        withdrawalFees[resourceID] = withdrawalFee;
    }

    function setMinDepositAmount(bytes32 resourceID, uint option, uint minAmount) external onlyOwner {
        minAmounts[resourceID][option] = minAmount;
    }

    /**
        @notice A deposit is initiated by making a deposit in the Bridge contract.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data passed into the function should be constructed as follows:
        option                                 uint256     bytes  0 - 32
        amount                                 uint256     bytes  32 - 64
     */
    function deposit(bytes32 resourceID, address depositer, bytes calldata data) external override onlyBridge {
        uint option;
        uint amount;
        (option, amount) = abi.decode(data, (uint, uint));

        address tokenAddress = resourceIDToTokenContractAddress[resourceID];
        require(contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        if (burnList[tokenAddress]) {
            require(amount >= withdrawalFees[resourceID], "less than withdrawal fee");
            QBridgeToken(tokenAddress).burnFrom(depositer, amount);
        } else {
            require(amount >= minAmounts[resourceID][option], "less than minimum amount");
            tokenAddress.safeTransferFrom(depositer, address(this), amount);
        }
    }

    /**
        @notice Proposal execution should be initiated by a relayer on the deposit's destination chain.
        @param data passed into the function should be constructed as follows:
        option                                 uint256
        amount                                 uint256
        destinationRecipientAddress            address
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external override onlyBridge {
        uint option;
        uint amount;
        address recipientAddress;
        (option, amount, recipientAddress) = abi.decode(data, (uint, uint, address));

        address tokenAddress = resourceIDToTokenContractAddress[resourceID];

        require(contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        if (burnList[tokenAddress]) {
            address delegatorAddress = delegators[option];
            if (delegatorAddress == address(0)) {
                QBridgeToken(tokenAddress).mint(recipientAddress, amount);
            } else {
                QBridgeToken(tokenAddress).mint(delegatorAddress, amount);
                IQBridgeDelegator(delegatorAddress).delegate(tokenAddress, recipientAddress, option, amount);
            }
        } else {
            tokenAddress.safeTransfer(recipientAddress, amount.sub(withdrawalFees[resourceID]));
        }
    }

    function withdraw(address tokenAddress, address recipient, uint amount) external override onlyBridge {
        tokenAddress.safeTransfer(recipient, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


interface IQBridgeDelegator {

    function delegate(address xToken, address account, uint option, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/BEP20Upgradeable.sol";


contract QBridgeToken is BEP20Upgradeable {

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter() {
        require(isMinter(msg.sender), "QBridgeToken: caller is not the minter");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(string memory name, string memory symbol, uint8 decimals) external initializer {
        __BEP20__init(name, symbol, decimals);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    function burnFrom(address account, uint amount) public onlyMinter {
        uint decreasedAllowance = allowance(account, msg.sender).sub(amount, "BEP20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
    using SafeMath for uint;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint[50] private __gap;

    /**
     * @dev sets initials supply and the owner
     */
    function __BEP20__init(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal initializer {
        __Ownable_init();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
     */
    function burn(uint amount) public returns (bool) {
        _burn(_msgSender(), amount);
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
        uint amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
        uint amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "../library/BEP20Upgradeable.sol";

contract TestXToken is BEP20Upgradeable {
    // STATE VARIABLES
    mapping(address => bool) private _minters;
    uint public ownerInt;

    // MODIFIERS
    modifier onlyMinter() {
        require(isMinter(msg.sender), "TestToken: caller is not the minter");
        _;
    }

    // INITIALIZER
    function initialize() external initializer {
        __BEP20__init("TestXToken Token", "xTST", 18);
        _minters[owner()] = true;
        ownerInt = 0;
    }

    // RESTRICTED FUNCTIONS
    function setOwnerInt(uint _ownerInt) external onlyOwner {
        ownerInt = _ownerInt;
    }

    function multiplyOwnerInt(uint multiplier, uint plus) external onlyOwner {
        ownerInt = ownerInt.mul(multiplier).add(plus);
    }

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        _mint(_to, _amount);
    }


    // VIEWS
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "../library/BEP20Upgradeable.sol";

contract TestToken is BEP20Upgradeable {
    // STATE VARIABLES
    mapping(address => bool) private _minters;
    uint public ownerInt;

    // MODIFIERS
    modifier onlyMinter() {
        require(isMinter(msg.sender), "TestToken: caller is not the minter");
        _;
    }

    // INITIALIZER
    function initialize() external initializer {
        __BEP20__init("TestToken Token", "TST", 18);
        _minters[owner()] = true;
        ownerInt = 0;
    }

    // RESTRICTED FUNCTIONS
    function setOwnerInt(uint _ownerInt) external onlyOwner {
        ownerInt = _ownerInt;
    }

    function multiplyOwnerInt(uint multiplier, uint plus) external onlyOwner {
        ownerInt = ownerInt.mul(multiplier).add(plus);
    }

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }


    // VIEWS
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/BEP20Upgradeable.sol";

contract QubitTokenTester is BEP20Upgradeable {
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __BEP20__init("Qubit Token", "QBT", 18);
        _minters[owner()] = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "./library/BEP20Upgradeable.sol";

contract QubitToken is BEP20Upgradeable {
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter() {
        require(isMinter(msg.sender), "QBT: caller is not the minter");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __BEP20__init("Qubit Token", "QBT", 18);
        _minters[owner()] = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQBridgeHandler.sol";
import "../interfaces/IQBridgeDelegator.sol";
import "../interfaces/IQore.sol";
import "../library/SafeToken.sol";
import "./QBridgeToken.sol";


contract QBridgeDelegator is IQBridgeDelegator, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint public constant OPTION_QUBIT_BNB_NONE = 100;
    uint public constant OPTION_QUBIT_BNB_0100 = 110;
    uint public constant OPTION_QUBIT_BNB_0050 = 105;
    uint public constant OPTION_BUNNY_XLP_0150 = 215;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) public handlerWhitelist; // handler address => is whitelisted
    mapping(address => address) public marketAddress; // xToken address => market address
    IQore public qore;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBridgeHandler() {
        require(handlerWhitelist[msg.sender], "QBridgeDelegator: caller is not the whitelisted handler contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QBridgeDelegator: invalid qore address");
        require(address(qore) == address(0), "QBridgeDelegator: qore already set");
        qore = IQore(_qore);
    }

    function setHandlerWhitelist(address _handler, bool option) external onlyOwner {
        handlerWhitelist[_handler] = option;
    }

    function setMarket(address xToken, address market) external onlyOwner {
        require(xToken != address(0), "QBridgeDelegator: invalid xToken address");
        require(market != address(0), "QBridgeDelegator: invalid market address");
        marketAddress[xToken] = market;
    }

    function approveTokenForMarket(address token, address market) external onlyOwner {
        require(token != address(0), "QBridgeDelegator: invalid xToken address");
        require(market != address(0), "QBridgeDelegator: invalid market address");
        QBridgeToken(token).approve(market, uint(- 1));
    }

    /* ========== MUTATIVE  ========== */

    function delegate(address xToken, address recipientAddress, uint option, uint amount) external override onlyBridgeHandler {
        if (option == OPTION_QUBIT_BNB_NONE) {
            qore.supplyAndBorrowBNB(recipientAddress, marketAddress[xToken], amount, 0);
        }
        else if (option == OPTION_QUBIT_BNB_0050) {
            qore.supplyAndBorrowBNB(recipientAddress, marketAddress[xToken], amount, 5e16);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IBEP20.sol";

interface IWBNB is IBEP20 {
    function deposit() external payable;
}