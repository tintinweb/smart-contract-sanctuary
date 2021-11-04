/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu*]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu*]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity >=0.7;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {Waiting, Appealable, Solved}

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7;

import {IArbitrable} from "@kleros/erc-792/contracts/IArbitrable.sol";
import {IEvidence} from "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";

interface IHomeArbitrationProxy {
    /**
     * @notice To be emitted when the arbitration request acknowledgement is sent to the Foreign Chain.
     * @param _projectID The ID of the question.
     */
    event RequestAcknowledged(uint256 indexed _projectID);

    /**
     * @notice To be emitted when the arbitration request is canceled.
     * @param _projectID The ID of the question.
     */
    event RequestCanceled(uint256 indexed _projectID);

    /**
     * @notice To be emitted when the dispute could not be created on the Foreign Chain.
     * @dev This will happen if the arbitration fee increases in between the arbitration request and acknowledgement.
     * @param _projectID The ID of the question.
     */
    event ArbitrationFailed(uint256 indexed _projectID);

    /**
     * @notice To be emitted when receiving the answer from the arbitrator.
     * @param _projectID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    event ArbitratorAnswered(uint256 indexed _projectID, uint256 _answer);

    /**
     * @notice Requests arbitration for the given projectID.
     * @param _projectID The ID of the project.
     */
    function receiveCreateDisputeRequest(uint256 _projectID) external;

    /**
     * @notice Receives a failed attempt to request arbitration. TRUSTED.
     * @dev Currently this can happen only if the arbitration cost increased.
     * @param _projectID The ID of the question.
     */
    function receiveArbitrationFailure(uint256 _projectID) external;

    /**
     * @notice Receives the answer to a specified question. TRUSTED.
     * @param _projectID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    function receiveArbitrationAnswer(uint256 _projectID, uint256 _answer) external;
}

interface IForeignArbitrationProxy is IArbitrable, IEvidence {
    /**
     * @notice Should be emitted when the arbitration is requested.
     * @param _projectID The ID of the question with the request for arbitration.
     * @param _requester The address of the arbitration requester.
     */
    event ArbitrationRequested(uint256 indexed _projectID, address indexed _requester);

    /**
     * @notice Should be emitted when the dispute is created.
     * @param _projectID The ID of the question with the request for arbitration.
     * @param _disputeID The ID of the dispute.
     */
    event ArbitrationCreated(uint256 indexed _projectID, uint256 indexed _disputeID);

    /**
     * @notice Should be emitted when the dispute could not be created.
     * @dev This will happen if there is an increase in the arbitration fees
     * between the time the arbitration is made and the time it is acknowledged.
     * @param _projectID The ID of the question with the request for arbitration.
     */
    event ArbitrationFailed(uint256 indexed _projectID);

    /**
     * @notice Should be emitted when the arbitration is canceled by the Home Chain.
     * @param _projectID The ID of the question with the request for arbitration.
     */
    event ArbitrationCanceled(uint256 indexed _projectID);

    /**
     * @notice Requests arbitration for the given projectID.
     * @param _projectID The ID of the project.
     */
    function createDisputeForProjectRequest(uint256 _projectID) external payable;

    /**
     * @notice Receives the acknowledgement of the arbitration request for the given question. TRUSTED.
     * @param _projectID The ID of the question.
     */
    function receiveArbitrationAcknowledgement(uint256 _projectID) external;

    /**
     * @notice Receives the cancelation of the arbitration request for the given question. TRUSTED.
     * @param _projectID The ID of the question.
     */
    function receiveArbitrationCancelation(uint256 _projectID) external;

    /**
     * @notice Cancels the arbitration in case the dispute could not be created.
     * @param _projectID The ID of the question.
     */
    function handleFailedDisputeCreation(uint256 _projectID) external;

    /**
     * @notice Gets the fee to create a dispute.
     * @param _projectID the ID of the question.
     * @return The fee to create a dispute.
     */
    function getDisputeFee(uint256 _projectID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ~0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Types.sol";
import "./DAISOInterface.sol";

import {FxBaseChildTunnel} from "./dependencies/0.8.x/FxBaseChildTunnel.sol";
import {IForeignArbitrationProxy, IHomeArbitrationProxy} from "./ArbitrationProxyInterfaces.sol";

contract DAISO is IHomeArbitrationProxy, Ownable, ReentrancyGuard, DAISOInterface, FxBaseChildTunnel {
    using SafeMath for uint256;

    /*** Storage Properties ***/

    /**
     * @notice Counter for invest stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice Counter for project stream ids.
     */
    uint256 public nextProjectId;

    /**
     * @notice Counter for EvidenceGroup ids.
     */
    uint256 public nextEvidenceGroup;

    /**
     * @notice Calculation project balance.
     */
    mapping(uint256 => Types.CalProjectBalance) public calProjectBalances;

    /**
     * @notice The invest stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Stream) public streams;

    /**
     * @notice The project stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Project) public projects;

    /**
     * @notice State changed when the invest cancel streams, The Status identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.CancelProjectForInvest) public cancelProjectForInvests;

    /**
     * @notice The arbitration objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Arbitration) public arbitrations;

    /**
     * @notice The disputeID identifiable by their unsigned integer ids.
     */
    mapping(uint256 => uint256) public disputeIDtoArbitrationID;

    modifier onlyBridge() {
        require(msg.sender == address(this), "Can only be called via bridge");
        _;
    }

    /**
     * @dev Throws if the caller is not the sender of the invest stream.
     */
    modifier onlyInvest(uint256 streamId) {
        require(msg.sender == streams[streamId].sender, "NOT_INVEST_SENDER");
        _;
    }

    /**
     * @dev Throws if the caller is not the sender of the project stream.
     */
    modifier onlyProject(uint256 projectId) {
        require(msg.sender == projects[projectId].sender, "NOT_PROJECT_SENDER");
        _;
    }

    /**
     * @dev Throws if the stream id does not point to a valid stream.
     */
    modifier investExists(uint256 streamId) {
        require(streams[streamId].sender != address(0x0), "STREAM_NOT_EXIT");
        _;
    }

    /**
     * @dev Throws if the project id does not point to a valid stream.
     */
    modifier projectExists(uint256 projectId) {
        require(projects[projectId].sender != address(0x0), "PROJECT_NOT_EXIT");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor(address _fxChild, address _foreignProxy) FxBaseChildTunnel(_fxChild, _foreignProxy) {
        nextStreamId = 1;
        nextProjectId = 1;
        nextEvidenceGroup = 1;
    }

    /*** Project Functions ***/

    /**
     * @notice Creates a new project stream for sell xDAI to fund DAI.
     *  Throws if the projectSellTokenAddress is same the projectFundTokenAddress.
     *  Throws if the projectSellDeposit is 0.
     *  Throws if the projectFundDeposit is 0.
     *  Throws if the start time is before `block.timestamp`.
     *  Throws if the stop time is before the start time.
     *  Throws if the lockPeriod is 0.
     *  Throws if the duration calculation has a math error.
     *  Throws if the projectSellDeposit is not multiple of time delta.
     *  Throws if the projectFundDeposit is not multiple of time delta.
     *  Throws if the projectId calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param projectSellTokenAddress The address of project sell.
     * @param projectSellDeposit The amount of project sell.
     * @param projectFundTokenAddress The address of project fund.
     * @param projectFundDeposit The amount of project fund.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param lockPeriod The amount of lockPeriod and the uint is seconds.
     * @param hash The ipfs hash for project info and promise submitted by the Project Party.
     * @return The uint256 id of the project stream.
     */
    function createProject(
        address projectSellTokenAddress,
        uint256 projectSellDeposit,
        address projectFundTokenAddress,
        uint256 projectFundDeposit,
        uint256 startTime,
        uint256 stopTime,
        uint256 lockPeriod,
        string calldata hash
    ) external returns (uint256) {
        require(projectSellTokenAddress != projectFundTokenAddress, "SELLTOKEN_SAME_FUNDTOKEN");
        require(projectSellDeposit > 0, "PROJECTSELLDEPOSIT_IS_ZERO");
        require(projectFundDeposit > 0, "PEOJECTFUNDDEPOSIT_IS_ZERO");
        require(startTime >= block.timestamp, "STARTTIME_BEFORE_NOW");
        require(stopTime > startTime, "STOPTIME_BEFORE_STARTTIME");
        require(lockPeriod > 0, "LOCKPERIOD_IS_ZERO");

        uint256 projectId = nextProjectId;

        projects[projectId] = Types.Project({
            projectSellDeposit: projectSellDeposit,
            projectFundDeposit: projectFundDeposit,
            projectActualSellDeposit: 0,
            projectActualFundDeposit: 0,
            projectWithdrawalAmount: 0,
            sender: payable(msg.sender),
            startTime: startTime,
            stopTime: stopTime,
            projectSellTokenAddress: projectSellTokenAddress,
            projectFundTokenAddress: projectFundTokenAddress,
            streamId: new uint256[](0),
            lockPeriod: lockPeriod,
            hash: hash,
            refunded: 0
        });

        cancelProjectForInvests[projectId].exitStopTime = stopTime;
        nextProjectId = nextProjectId + 1;

        require(
            IERC20(projectSellTokenAddress).transferFrom(msg.sender, address(this), projectSellDeposit),
            "TOKEN_TREANSFER_FAILURE"
        );
        emit CreateProject(projectId, msg.sender, hash);
        return projectId;
    }

    /**
     * @notice Returns the sellToken balance and fundToken balance for project.
     * @dev Throws if the project id does not point to a valid project stream.
     * @param projectId The id of the project stream for which to query the balance.
     * @return projectSellBalance is stream balance for project SellToken.
     * @return projectFundBalance is stream balance for project FundToken.
     */
    function projectBalanceOf(uint256 projectId)
        external
        view
        projectExists(projectId)
        returns (uint256 projectSellBalance, uint256 projectFundBalance)
    {
        Types.Project storage project = projects[projectId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[projectId];
        Types.CalProjectBalance storage calProjectBalance = calProjectBalances[projectId];

        if (cancelProjectForInvest.proposalForCancelStatus == 1) {
            projectSellBalance = cancelProjectForInvest.exitProjectSellBalance;
            projectFundBalance = 0;
        } else {
            if (block.timestamp <= project.startTime) {
                projectSellBalance = project.projectActualSellDeposit;
                projectFundBalance = 0;
            } else if (block.timestamp < project.stopTime) {
                if (project.projectActualSellDeposit > 0) {
                    uint256 delta = block.timestamp.sub(project.startTime);
                    uint256 investFundBalance = delta.mul(calProjectBalance.sumOfRatePerSecondOfInvestFund);
                    investFundBalance = investFundBalance.sub(calProjectBalance.sumOfCalBalance);
                    investFundBalance = investFundBalance.add(calProjectBalance.sumOfCancelInvestor);

                    projectSellBalance = project.projectActualSellDeposit.sub(investFundBalance);

                    projectFundBalance = project.projectActualFundDeposit.mul(projectSellBalance);
                    projectFundBalance = projectFundBalance.div(project.projectActualSellDeposit);
                    projectFundBalance = project.projectActualFundDeposit.sub(projectFundBalance);
                    projectFundBalance = projectFundBalance.sub(project.projectWithdrawalAmount);
                } else {
                    projectSellBalance = 0;
                    projectFundBalance = 0;
                }
            } else {
                projectSellBalance = 0;
                projectFundBalance = project.projectActualFundDeposit;
                projectFundBalance = projectFundBalance.sub(project.projectWithdrawalAmount);
            }
        }
        return (projectSellBalance, projectFundBalance);
    }

    /**
     * @notice Project refund sellToken for Unsold and must exceed project stopTime + lock period!
     * @dev Throws if the project id does not point to a valid project stream.
     * Throws if the caller is not the sender of the project stream
     * Throws if now time smaller than project stopTime.
     * @param projectId The id of the project stream for refunds.
     * @return bool true=success, otherwise false.
     */
    function projectRefunds(uint256 projectId)
        external
        nonReentrant
        projectExists(projectId)
        onlyProject(projectId)
        returns (bool)
    {
        Types.Project storage project = projects[projectId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[projectId];

        require(block.timestamp >= project.stopTime.add(project.lockPeriod), "FAIL_REACH_UNLOCKPERIOD");
        require(project.refunded == 0, "ALREADY_REFUND");

        uint256 refunds = project.projectSellDeposit.sub(project.projectActualSellDeposit);
        uint256 projectSellBalance = refunds.add(cancelProjectForInvest.exitProjectSellBalance);

        projects[projectId].refunded = 1;

        if (projectSellBalance > 0)
            require(
                IERC20(project.projectSellTokenAddress).transfer(project.sender, projectSellBalance),
                "TOKEN_TREANSFER_FAILURE"
            );

        emit CancelProjectForProject(projectId, projectSellBalance);
        return true;
    }

    /**
     * @notice Withdraws from the contract to the Project's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if caller is not project.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param projectId The id of the project to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, otherwise false.
     */
    function withdrawFromProject(uint256 projectId, uint256 amount)
        external
        nonReentrant
        projectExists(projectId)
        onlyProject(projectId)
        returns (bool)
    {
        require(amount > 0, "AMOUNT_IS_ZERO");
        (, uint256 balance) = this.projectBalanceOf(projectId);
        require(balance >= amount, "BALANCE_SMALLER_AMOUNT");

        Types.Arbitration storage arbitration = arbitrations[projectId];
        Types.Project storage project = projects[projectId];

        require(arbitration.reclaimedAt == 0, "PROJECT_HAS_ARBITRATION");

        projects[projectId].projectWithdrawalAmount = project.projectWithdrawalAmount.add(amount);

        require(IERC20(project.projectFundTokenAddress).transfer(project.sender, amount), "TOKEN_TREANSFER_FAILURE");
        emit WithdrawFromProject(projectId, project.sender, block.timestamp, amount);

        return true;
    }

    /*** Investor Functions ***/

    struct CreateStreamLocalVars {
        uint256 time;
        uint256 calBalance;
        uint256 startTime;
        uint256 duration;
        uint256 ratePerSecondOfInvestSell;
        uint256 ratePerSecondOfInvestFund;
    }

    /**
     * @notice Creates a new stream for invest project by investors;.
     *  Throws if the caller is project.
     *  Throws if the investSellDeposit is 0.
     *  Throws if the now is before project start time.
     *  Throws if the investSellDeposit is not a multiple of the duration.
     *  Throws if the projectActualFundDeposit calculation has a math error.
     *  Throws if the projectActualSellDeposit calculation has a math error.
     *  Throws if the ratePerSecondOfProjectSell calculation has a math error.
     *  Throws if the ratePerSecondOfProjectFund calculation has a math error.
     *  Throws if the investFundDeposit calculation has a math error.
     *  Throws if the ratePerSecondOfInvestSell calculation has a math error.
     *  Throws if the ratePerSecondOfInvestFund calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     *  Throws if the projectFundDeposit is smaller than projectActualFundDeposit.
     * @param projectId The id of the project stream for investors create.
     * @param investSellDeposit The amount of money to be invested.
     * @return The uint256 id of the newly created invest stream.
     */
    function createStream(uint256 projectId, uint256 investSellDeposit) external returns (uint256) {
        Types.Project storage project = projects[projectId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[projectId];
        CreateStreamLocalVars memory vars;

        require(msg.sender != project.sender, "SENDER_SAME_PROJECT");
        require(investSellDeposit > 0, "INVESTSELLDEPOSIT_IS_ZERO");
        require(block.timestamp < cancelProjectForInvest.exitStopTime, "NOW_BIGGER_STOPTIME");

        projects[projectId].projectActualFundDeposit = project.projectActualFundDeposit.add(investSellDeposit);
        require(
            project.projectFundDeposit >= projects[projectId].projectActualFundDeposit,
            "EXCEED_PROJECTFUNDDEPOSIT"
        );

        uint256 projectActualSellDeposit = projects[projectId].projectActualFundDeposit.mul(project.projectSellDeposit);
        projects[projectId].projectActualSellDeposit = projectActualSellDeposit.div(project.projectFundDeposit);

        uint256 investFundDeposit = investSellDeposit.mul(project.projectSellDeposit);
        investFundDeposit = investFundDeposit.div(project.projectFundDeposit);

        if (block.timestamp <= project.startTime) {
            vars.startTime = project.startTime;
            vars.duration = project.stopTime.sub(vars.startTime);
            vars.ratePerSecondOfInvestSell = investSellDeposit.div(vars.duration);
            vars.ratePerSecondOfInvestFund = investFundDeposit.div(vars.duration);
        } else {
            vars.startTime = block.timestamp;
            vars.duration = project.stopTime.sub(vars.startTime);
            vars.ratePerSecondOfInvestSell = investSellDeposit.div(vars.duration);
            vars.ratePerSecondOfInvestFund = investFundDeposit.div(vars.duration);

            vars.time = vars.startTime.sub(project.startTime);
            vars.calBalance = vars.time.mul(vars.ratePerSecondOfInvestFund);
            calProjectBalances[projectId].sumOfCalBalance = calProjectBalances[projectId].sumOfCalBalance.add(
                vars.calBalance
            );
        }

        calProjectBalances[projectId].sumOfRatePerSecondOfInvestFund = calProjectBalances[projectId]
        .sumOfRatePerSecondOfInvestFund
        .add(vars.ratePerSecondOfInvestFund);
        cancelProjectForInvests[projectId].sumForExistInvest = cancelProjectForInvests[projectId].sumForExistInvest.add(
            investSellDeposit
        );

        uint256 streamId = nextStreamId;

        streams[streamId] = Types.Stream({
            projectId: projectId,
            investSellDeposit: investSellDeposit,
            investFundDeposit: investFundDeposit,
            ratePerSecondOfInvestSell: vars.ratePerSecondOfInvestSell,
            ratePerSecondOfInvestFund: vars.ratePerSecondOfInvestFund,
            startTime: vars.startTime,
            stopTime: project.stopTime,
            sender: msg.sender,
            investWithdrawalAmount: 0
        });

        nextStreamId = nextStreamId + 1;

        require(
            IERC20(project.projectFundTokenAddress).transferFrom(msg.sender, address(this), investSellDeposit),
            "TOKEN_TREANSFER_FAILURE"
        );
        emit CreateStream(streamId, msg.sender);
        return streamId;
    }

    /**
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `exitStopTime` and `startTime, whichever is smaller. If `block.timestamp` iis starts before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the delta.
     * @return delta is time delta in seconds.
     */
    function deltaOf(uint256 streamId) external view returns (uint256 delta) {
        Types.Stream storage stream = streams[streamId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[stream.projectId];

        if (cancelProjectForInvest.proposalForCancelStatus != 1) {
            if (block.timestamp <= stream.startTime) return 0;
            if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
            return stream.stopTime - stream.startTime;
        } else if (cancelProjectForInvest.proposalForCancelStatus == 1) {
            if (block.timestamp <= stream.startTime) return 0;
            if (block.timestamp < cancelProjectForInvest.exitStopTime) return block.timestamp - stream.startTime;
            return cancelProjectForInvest.exitStopTime - stream.startTime;
        }
    }

    /**
     * @notice Returns the sellToken balance and fundToken balance for invest.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the invest stream for balance.
     * @return investSellBalance is stream balance for invest SellToken.
     * @return investFundBalance is  stream balance for invest FundToken.
     */
    function investBalanceOf(uint256 streamId)
        external
        view
        investExists(streamId)
        returns (uint256 investSellBalance, uint256 investFundBalance)
    {
        Types.Stream storage stream = streams[streamId];
        Types.Project storage project = projects[stream.projectId];

        uint256 delta = this.deltaOf(streamId);
        investFundBalance = delta * stream.ratePerSecondOfInvestFund;

        if (block.timestamp >= project.stopTime) {
            investFundBalance = stream.investFundDeposit;
        }
        investFundBalance = investFundBalance.sub(stream.investWithdrawalAmount);

        investSellBalance = delta * stream.ratePerSecondOfInvestSell;

        if (block.timestamp >= project.stopTime) {
            investSellBalance = stream.investSellDeposit;
        }

        investSellBalance = stream.investSellDeposit.sub(investSellBalance);

        return (investSellBalance, investFundBalance);
    }

    /**
     * @notice Withdraws from the contract to the investor's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if caller is not invest.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, otherwise false.
     */
    function withdrawFromInvest(uint256 streamId, uint256 amount)
        external
        nonReentrant
        investExists(streamId)
        onlyInvest(streamId)
        returns (bool)
    {
        require(amount > 0, "AMOUNT_IS_ZERO");
        (, uint256 balance) = this.investBalanceOf(streamId);
        require(balance >= amount, "BALANCE_SMALLER_AMOUNT");

        Types.Stream storage stream = streams[streamId];
        Types.Project storage project = projects[stream.projectId];

        streams[streamId].investWithdrawalAmount = stream.investWithdrawalAmount.add(amount);

        require(IERC20(project.projectSellTokenAddress).transfer(stream.sender, amount), "TOKEN_TREANSFER_FAILURE");
        emit WithdrawFromInvest(streamId, stream.projectId, stream.sender, block.timestamp, amount);

        return true;
    }

    /**
     * @notice Cancels the invest stream and transfers the tokens back to invest.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if caller is not the sender of the invest stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the invest stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelInvest(uint256 streamId)
        external
        nonReentrant
        investExists(streamId)
        onlyInvest(streamId)
        returns (bool)
    {
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[
            streams[streamId].projectId
        ];

        if (cancelProjectForInvest.proposalForCancelStatus != 1) {
            /* cancel due invest reason*/
            cancelInvestInternal(streamId);
            return true;
        } else {
            /* cancel due project reason*/
            cancelProjectInternal(streamId);
            return true;
        }
    }

    /**
     * @notice investor cancels the stream and transfers the tokens back to invest.
     * Throws if the projectActualFundDeposit calculation has a math error.
     * Throws if the projectActualSellDeposit calculation has a math error.
     *  Throws if there is a projectFund token transfer failure.
     *  Throws if there is a projectSell token transfer failure.
     */
    function cancelInvestInternal(uint256 streamId) internal {
        Types.Stream storage stream = streams[streamId];
        Types.Project storage project = projects[stream.projectId];

        uint256 investSellBalance;
        uint256 investFundBalance;

        (investSellBalance, investFundBalance) = this.investBalanceOf(streamId);

        projects[stream.projectId].projectActualFundDeposit = project.projectActualFundDeposit.sub(investSellBalance);

        uint256 projectActualSellDeposit = projects[stream.projectId].projectActualFundDeposit.mul(
            project.projectSellDeposit
        );
        projects[stream.projectId].projectActualSellDeposit = projectActualSellDeposit.div(project.projectFundDeposit);

        cancelProjectForInvests[stream.projectId].sumForExistInvest = cancelProjectForInvests[stream.projectId]
        .sumForExistInvest
        .sub(stream.investSellDeposit);

        calProjectBalances[stream.projectId].sumOfRatePerSecondOfInvestFund = calProjectBalances[stream.projectId]
        .sumOfRatePerSecondOfInvestFund
        .sub(stream.ratePerSecondOfInvestFund);

        if (stream.startTime > project.startTime) {
            uint256 time = stream.startTime.sub(project.startTime);
            uint256 calBalance = time.mul(stream.ratePerSecondOfInvestFund);
            calProjectBalances[stream.projectId].sumOfCalBalance = calProjectBalances[stream.projectId]
            .sumOfCalBalance
            .sub(calBalance);
        }

        uint256 investFund = investFundBalance.add(stream.investWithdrawalAmount);
        calProjectBalances[stream.projectId].sumOfCancelInvestor = calProjectBalances[stream.projectId]
        .sumOfCancelInvestor
        .add(investFund);

        if (investSellBalance > 0)
            require(
                IERC20(project.projectFundTokenAddress).transfer(stream.sender, investSellBalance),
                "TOKEN_TREANSFER_FAILURE"
            );
        if (investFundBalance > 0)
            require(
                IERC20(project.projectSellTokenAddress).transfer(stream.sender, investFundBalance),
                "TOKEN_TREANSFER_FAILURE"
            );

        delete streams[streamId];

        emit CancelStream(
            stream.projectId,
            streamId,
            stream.sender,
            investSellBalance,
            investFundBalance,
            block.timestamp
        );
    }

    /**
     * @notice investor cancels the stream and transfers the tokens back to invest.
     * Just open when project loss Arbitration, project fundToken balance will refunds to investors according to percent for
     * (investSellDeposit / sumForInvestSellDeposit)
     * @dev Throws if the sumForInvestSellDeposit calculation has a math error.
     * Throws if the amount calculation has a math error.
     * Throws if the investSellBalance calculation has a math error.
     *  Throws if there is a projectFund token transfer failure.
     *  Throws if there is a projectSell token transfer failure.
     */
    function cancelProjectInternal(uint256 streamId) internal {
        Types.Stream storage stream = streams[streamId];
        Types.Project storage project = projects[stream.projectId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[stream.projectId];

        uint256 amount = cancelProjectForInvest.exitProjectFundBalance.mul(stream.investSellDeposit);
        amount = amount.div(cancelProjectForInvest.sumForExistInvest);

        (uint256 investSellBalance, uint256 investFundBalance) = this.investBalanceOf(streamId);

        investSellBalance = amount.add(investSellBalance);

        if (investSellBalance > 0)
            require(
                IERC20(project.projectFundTokenAddress).transfer(stream.sender, investSellBalance),
                "TOKEN_TREANSFER_FAILURE"
            );
        if (investFundBalance > 0)
            require(
                IERC20(project.projectSellTokenAddress).transfer(stream.sender, investFundBalance),
                "TOKEN_TREANSFER_FAILURE"
            );

        delete streams[streamId];

        emit CancelProject(
            stream.projectId,
            streamId,
            stream.sender,
            investSellBalance,
            investFundBalance,
            amount,
            block.timestamp
        );
    }

    /**
     * @notice Returns the project with all its properties.
     * @dev Throws if the project id does not point to a valid project stream.
     * @param projectId The id of the project stream for getProject info.
     */
    function getProject(uint256 projectId)
        external
        view
        projectExists(projectId)
        returns (
            uint256 projectSellDeposit,
            uint256 projectFundDeposit,
            uint256 projectActualSellDeposit,
            uint256 projectActualFundDeposit,
            uint256 projectWithdrawalAmount,
            address payable sender,
            uint256 startTime,
            uint256 stopTime,
            address projectSellTokenAddress,
            address projectFundTokenAddress,
            uint256 lockPeriod,
            string memory hash
        )
    {
        projectSellDeposit = projects[projectId].projectSellDeposit;
        projectFundDeposit = projects[projectId].projectFundDeposit;
        projectActualSellDeposit = projects[projectId].projectActualSellDeposit;
        projectActualFundDeposit = projects[projectId].projectActualFundDeposit;
        projectWithdrawalAmount = projects[projectId].projectWithdrawalAmount;
        sender = projects[projectId].sender;
        startTime = projects[projectId].startTime;
        stopTime = projects[projectId].stopTime;
        projectSellTokenAddress = projects[projectId].projectSellTokenAddress;
        projectFundTokenAddress = projects[projectId].projectFundTokenAddress;
        lockPeriod = projects[projectId].lockPeriod;
        hash = projects[projectId].hash;
    }

    /**
     * @notice Returns the stream with all its properties.
     * @dev Throws if the stream id does not point to a valid invest stream.
     * @param streamId The id of the invest stream for get stream info.
     */
    function getStream(uint256 streamId)
        external
        view
        investExists(streamId)
        returns (
            uint256 projectId,
            uint256 investSellDeposit,
            uint256 investFundDeposit,
            address sender,
            uint256 startTime,
            uint256 stopTime,
            uint256 investWithdrawalAmount,
            uint256 ratePerSecondOfInvestSell,
            uint256 ratePerSecondOfInvestFund
        )
    {
        projectId = streams[streamId].projectId;
        investSellDeposit = streams[streamId].investSellDeposit;
        investFundDeposit = streams[streamId].investFundDeposit;
        sender = streams[streamId].sender;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        investWithdrawalAmount = streams[streamId].investWithdrawalAmount;
        ratePerSecondOfInvestSell = streams[streamId].ratePerSecondOfInvestSell;
        ratePerSecondOfInvestFund = streams[streamId].ratePerSecondOfInvestFund;
    }

    /**
     * @notice Returns the project with all its properties.
     * @dev Throws if the project id does not point to a valid project stream.
     * @param projectId The id of the project stream for get CancelProjectForInvest info.
     */
    function getCancelProjectForInvest(uint256 projectId)
        external
        view
        projectExists(projectId)
        returns (
            uint256 exitProjectSellBalance,
            uint256 exitProjectFundBalance,
            uint256 exitStopTime,
            uint256 sumForExistInvest,
            uint256 proposalForCancelStatus
        )
    {
        exitProjectSellBalance = cancelProjectForInvests[projectId].exitProjectSellBalance;
        exitProjectFundBalance = cancelProjectForInvests[projectId].exitProjectFundBalance;
        exitStopTime = cancelProjectForInvests[projectId].exitStopTime;
        sumForExistInvest = cancelProjectForInvests[projectId].sumForExistInvest;
        proposalForCancelStatus = cancelProjectForInvests[projectId].proposalForCancelStatus;
    }

    function getCalProjectBalance(uint256 projectId)
        external
        view
        projectExists(projectId)
        returns (
            uint256 sumOfRatePerSecondOfInvestFund,
            uint256 sumOfCalBalance,
            uint256 sumOfCancelInvestor
        )
    {
        sumOfRatePerSecondOfInvestFund = calProjectBalances[projectId].sumOfRatePerSecondOfInvestFund;
        sumOfCalBalance = calProjectBalances[projectId].sumOfCalBalance;
        sumOfCancelInvestor = calProjectBalances[projectId].sumOfCancelInvestor;
    }

    function getArbitration(uint256 projectId)
        external
        view
        projectExists(projectId)
        returns (
            Types.Status status,
            uint256 disputeID,
            uint256 reclaimedAt
        )
    {
        status = arbitrations[projectId].status;
        reclaimedAt = arbitrations[projectId].reclaimedAt;
    }

    /**
     * @notice investor reclaim funds when project not pay arbitration fee.
     * @dev Throws if the arbitration id does not point to a valid project.
     *  Throws if the arbitrations[projectId].status is not Reclaimed.
     *  Throws if the caller is not arbitration.invest.
     *  Throws if the now not exceeds arbitration.reclaimedAt + 86400(reclaimed time).
     * @param projectId The id of the project arbitration for which to query the delta.
     */
    function reclaimFunds(uint256 projectId) external nonReentrant {
        Types.Arbitration storage arbitration = arbitrations[projectId];

        require(arbitration.status == Types.Status.Reclaimed, "STATUS_NOT_RECLAIMED");
        require(block.timestamp - arbitration.reclaimedAt > 86400, "NOT_ARRIVAL_RECLAIMEDPERIOD");

        (uint256 exitProjectSellBalance, uint256 exitProjectFundBalance) = this.projectBalanceOf(projectId);
        cancelProjectForInvests[projectId].exitProjectSellBalance = exitProjectSellBalance;
        cancelProjectForInvests[projectId].exitProjectFundBalance = exitProjectFundBalance;

        if (block.timestamp <= cancelProjectForInvests[projectId].exitStopTime) {
            cancelProjectForInvests[projectId].exitStopTime = block.timestamp;
        }
        cancelProjectForInvests[projectId].proposalForCancelStatus = 1;

        arbitrations[projectId].status = Types.Status.Resolved;
    }

    /**
     * @notice invest create arbitration with project.
     * @param projectId The id of the project to create arbitration.
     */
    function createArbitrationForInvestor(uint256 projectId) external projectExists(projectId) {
        Types.Project storage project = projects[projectId];
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[projectId];

        require(arbitrations[projectId].reclaimedAt == 0, "ALREADY_HAVE_ARBITRATION");
        require(block.timestamp >= project.startTime, "PROJECT_NOT_START");
        require(block.timestamp < cancelProjectForInvest.exitStopTime, "PROJECT_IS_FINISHED");
        require(block.timestamp >= cancelProjectForInvest.preReclaimedAt + 86400, "NOT_ARRIVE_24HOURS");

        arbitrations[projectId] = Types.Arbitration({
            invest: payable(msg.sender),
            project: project.sender,
            status: Types.Status.Reclaimed,
            reclaimedAt: block.timestamp
        });

        cancelProjectForInvests[projectId].preReclaimedAt = block.timestamp;

        emit Arbitration(projectId, project.sender, msg.sender, block.timestamp);
    }

    /**
     * @notice project pay arbitration fee.
     * @dev Throws if the arbitration id does not point to a valid project.
     *  Throws if the arbitration.status is not Reclaimed.
     *  Throws if the now exceeds arbitration.reclaimedAt + 86400(reclaimed time).
     * @param _projectId The id of the project arbitration for which to query the delta.
     */
    function receiveCreateDisputeRequest(uint256 _projectId) external onlyBridge {
        Types.Arbitration storage arbitration = arbitrations[_projectId];

        if (arbitration.status == Types.Status.Reclaimed && block.timestamp - arbitration.reclaimedAt <= 86400) {
            arbitrations[_projectId].status = Types.Status.Disputed;

            bytes4 selector = IForeignArbitrationProxy.receiveArbitrationAcknowledgement.selector;
            bytes memory data = abi.encodeWithSelector(selector, _projectId);
            _sendMessageToRoot(data);

            emit RequestAcknowledged(_projectId);
        } else {
            // Invalid Request
            bytes4 selector = IForeignArbitrationProxy.receiveArbitrationCancelation.selector;
            bytes memory data = abi.encodeWithSelector(selector, _projectId);
            _sendMessageToRoot(data);

            emit RequestCanceled(_projectId);
        }
    }

    /**
     * @notice Receives a failed attempt to request arbitration. TRUSTED.
     * @dev Currently this can happen only if the arbitration cost increased.
     * @param _projectId The ID of the question.
     */
    function receiveArbitrationFailure(uint256 _projectId) public override onlyBridge {
        Types.Arbitration storage arbitration = arbitrations[_projectId];

        require(arbitration.status == Types.Status.Disputed, "Invalid arbitration status");

        // At this point, only the arbitration.status is set,
        // simply reseting the status to Status.Reclaimed is enough.
        arbitration.status = Types.Status.Reclaimed;

        emit ArbitrationFailed(_projectId);
    }

    /**
     * @notice Receives the answer to a specified question. TRUSTED.
     * @param _projectId The ID of the project.
     * @param _answer The answer from the arbitrator.
     */
    function receiveArbitrationAnswer(uint256 _projectId, uint256 _answer) public override onlyBridge {
        Types.Arbitration storage arbitration = arbitrations[_projectId];
        require(arbitration.status == Types.Status.Disputed, "Invalid request status");

        arbitration.status = Types.Status.Resolved;

        _executeRuling(_projectId, _answer);
        emit ArbitratorAnswered(_projectId, _answer);
    }

    /**
     * @notice IArbitrator Execute ruling.
     * @param _projectId The ID of the project.
     * @param _ruling The result of Irabitrator.
     */
    function _executeRuling(uint256 _projectId, uint256 _ruling) internal {
        Types.CancelProjectForInvest storage cancelProjectForInvest = cancelProjectForInvests[_projectId];

        if (_ruling == 1) {
            (uint256 exitProjectSellBalance, uint256 exitProjectFundBalance) = this.projectBalanceOf(_projectId);
            cancelProjectForInvests[_projectId].exitProjectSellBalance = exitProjectSellBalance;
            cancelProjectForInvests[_projectId].exitProjectFundBalance = exitProjectFundBalance;

            cancelProjectForInvests[_projectId].proposalForCancelStatus = 1;

            if (block.timestamp <= cancelProjectForInvest.exitStopTime) {
                cancelProjectForInvests[_projectId].exitStopTime = block.timestamp;
            }
        } else if (_ruling == 2) {
            cancelProjectForInvests[_projectId].proposalForCancelStatus = 2;

            delete arbitrations[_projectId];
        } else if (_ruling == 0) {
            delete arbitrations[_projectId];
        }
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory _data
    ) internal override validateSender(sender) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(_data);
        require(success, "Failed to call contract");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

interface DAISOInterface {
    /* DAISO */
    event CreateProject(uint256 indexed projectId, address indexed sender, string hash);

    event CreateStream(uint256 indexed streamId, address indexed sender);

    event WithdrawFromProject(uint256 indexed projectId, address indexed sender, uint256 withdrawTime, uint256 amount);

    event CancelProject(
        uint256 indexed projectId,
        uint256 indexed streamId,
        address sender,
        uint256 investSellBalance,
        uint256 investFundBalance,
        uint256 refunds,
        uint256 cancelTime
    );

    event CancelProjectForProject(uint256 indexed projectId, uint256 projectSellBalance);

    /* DAISOForInvest */
    event WithdrawFromInvest(
        uint256 indexed streamId,
        uint256 indexed projectId,
        address indexed sender,
        uint256 withdrawTime,
        uint256 amount
    );

    event CancelStream(
        uint256 indexed projectId,
        uint256 indexed streamId,
        address indexed sender,
        uint256 investSellBalance,
        uint256 investFundBalance,
        uint256 cancelTime
    );

    event Arbitration(uint256 indexed projectId, address project, address indexed invest, uint256 reclaimedAt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Types {
    struct Project {
        uint256 projectSellDeposit;
        uint256 projectFundDeposit;
        uint256 projectActualSellDeposit;
        uint256 projectActualFundDeposit;
        uint256 projectWithdrawalAmount;
        address payable sender;
        uint256 startTime;
        uint256 stopTime;
        address projectSellTokenAddress;
        address projectFundTokenAddress;
        uint256 lockPeriod;
        uint256[] streamId;
        string hash;
        uint8 refunded;
    }

    struct Stream {
        uint256 projectId;
        uint256 investSellDeposit;
        uint256 investFundDeposit;
        uint256 ratePerSecondOfInvestSell;
        uint256 ratePerSecondOfInvestFund;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        uint256 investWithdrawalAmount;
    }

    struct CancelProjectForInvest {
        uint256 exitProjectSellBalance;
        uint256 exitProjectFundBalance;
        uint256 exitStopTime;
        uint256 sumForExistInvest;
        uint256 proposalForCancelStatus;
        uint256 preReclaimedAt;
    }

    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }

    struct Arbitration {
        address payable invest;
        address payable project;
        Status status;
        uint256 reclaimedAt;
    }

    enum RulingOptions {
        RefusedToArbitrate,
        InvestWins,
        ProjectWins
    }

    struct CalProjectBalance {
        uint256 sumOfRatePerSecondOfInvestFund;
        uint256 sumOfCalBalance;
        uint256 sumOfCancelInvestor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild, address _fxRootTunnel) {
        fxChild = _fxChild;
        fxRootTunnel = _fxRootTunnel;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}