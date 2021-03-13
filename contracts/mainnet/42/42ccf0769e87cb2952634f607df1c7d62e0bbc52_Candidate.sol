// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "Ownable.sol";

import { IDAOCommittee } from "IDAOCommittee.sol";
import { IERC20 } from  "IERC20.sol";
import { SafeMath } from "SafeMath.sol";
import { ISeigManager } from "ISeigManager.sol";
import { ICandidate } from "ICandidate.sol";
import { ILayer2 } from "ILayer2.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ERC165 } from "ERC165.sol";

/// @title Managing a candidate
/// @notice Either a user or layer2 contract can be a candidate
contract Candidate is Ownable, ERC165, ICandidate, ILayer2 {
    using SafeMath for uint256;

    bool public override isLayer2Candidate;
    address public override candidate;
    string public override memo;

    IDAOCommittee public override committee;
    ISeigManager public override seigManager;

    modifier onlyCandidate() {
        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            require(layer2.operator() == msg.sender, "Candidate: sender is not the operator of this contract");
        } else {
            require(candidate == msg.sender, "Candidate: sender is not the candidate of this contract");
        }
        _;
    }

    constructor(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager
    ) 
    {
        require(
            _candidate != address(0)
            || _committee != address(0)
            || _seigManager != address(0),
            "Candidate: input is zero"
        );
        candidate = _candidate;
        isLayer2Candidate = _isLayer2Candidate;
        if (isLayer2Candidate) {
            require(
                ILayer2(candidate).isLayer2(),
                "Candidate: invalid layer2 contract"
            );
        }
        committee = IDAOCommittee(_committee);
        seigManager = ISeigManager(_seigManager);
        memo = _memo;

        _registerInterface(ICandidate(address(this)).isCandidateContract.selector);
    }
    
    /// @notice Set SeigManager contract address
    /// @param _seigManager New SeigManager contract address
    function setSeigManager(address _seigManager) external override onlyOwner {
        require(_seigManager != address(0), "Candidate: input is zero");
        seigManager = ISeigManager(_seigManager);
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external override onlyOwner {
        require(_committee != address(0), "Candidate: input is zero");
        committee = IDAOCommittee(_committee);
    }

    /// @notice Set memo
    /// @param _memo New memo on this candidate
    function setMemo(string calldata _memo) external override onlyOwner {
        memo = _memo;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @notice Call updateSeigniorage on SeigManager
    /// @return Whether or not the execution succeeded
    function updateSeigniorage() external override returns (bool) {
        require(address(seigManager) != address(0), "Candidate: SeigManager is zero");
        require(
            !isLayer2Candidate,
            "Candidate: you should update seigniorage from layer2 contract"
        );

        return seigManager.updateSeigniorage();
    }

    /// @notice Try to be a member
    /// @param _memberIndex The index of changing member slot
    /// @return Whether or not the execution succeeded
    function changeMember(uint256 _memberIndex)
        external
        override
        onlyCandidate
        returns (bool)
    {
        return committee.changeMember(_memberIndex);
    }

    /// @notice Retire a member
    /// @return Whether or not the execution succeeded
    function retireMember() external override onlyCandidate returns (bool) {
        return committee.retireMember();
    }
    
    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    )
        external
        override
        onlyCandidate
    {
        committee.castVote(_agendaID, _vote, _comment);
    }

    function claimActivityReward()
        external
        override
        onlyCandidate
    {
        address receiver;

        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            receiver = layer2.operator();
        } else {
            receiver = candidate;
        }
        committee.claimActivityReward(receiver);
    }

    /// @notice Checks whether this contract is a candidate contract
    /// @return Whether or not this contract is a candidate contract
    function isCandidateContract() external view override returns (bool) {
        return true;
    }

    function operator() external view override returns (address) { return candidate; }
    function isLayer2() external view override returns (bool) { return true; }
    function currentFork() external view override returns (uint256) { return 1; }
    function lastEpoch(uint256 forkNumber) external view override returns (uint256) { return 1; }
    function changeOperator(address _operator) external override { }

    /// @notice Retrieves the total staked balance on this candidate
    /// @return totalsupply Total staked amount on this candidate
    function totalStaked()
        external
        view
        override
        returns (uint256 totalsupply)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.totalSupply();
    }

    /// @notice Retrieves the staked balance of the account on this candidate
    /// @param _account Address being retrieved
    /// @return amount The staked balance of the account on this candidate
    function stakedOf(
        address _account
    )
        external
        view
        override
        returns (uint256 amount)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.balanceOf(_account);
    }

    function _getCoinageToken() internal view returns (IERC20) {
        address c;
        if (isLayer2Candidate) {
            c = candidate;
        } else {
            c = address(this);
        }

        require(c != address(0), "Candidate: coinage is zero");

        return IERC20(seigManager.coinages(c));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { IStorageStateCommittee } from "IStorageStateCommittee.sol";

interface IDAOCommittee is IStorageStateCommittee {
    //--owner
    function setSeigManager(address _seigManager) external;
    function setCandidatesSeigManager(address[] calldata _candidateContracts, address _seigManager) external;
    function setCandidatesCommittee(address[] calldata _candidateContracts, address _committee) external;
    function setLayer2Registry(address _layer2Registry) external;
    function setAgendaManager(address _agendaManager) external;
    function setCandidateFactory(address _candidateFactory) external;
    function setTon(address _ton) external;
    function setActivityRewardPerSecond(uint256 _value) external;
    function setDaoVault(address _daoVault) external;

    function increaseMaxMember(uint256 _newMaxMember, uint256 _quorum) external;
    function decreaseMaxMember(uint256 _reducingMemberIndex, uint256 _quorum) external;
    function createCandidate(string calldata _memo) external;
    function registerLayer2Candidate(address _layer2, string memory _memo) external;
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo) external;
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function setMemoOnCandidate(address _candidate, string calldata _memo) external;
    function setMemoOnCandidateContract(address _candidate, string calldata _memo) external;

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    )
        external
        returns (bool);

    function setQuorum(uint256 _quorum) external;
    function setCreateAgendaFees(uint256 _fees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriod) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriod) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function castVote(uint256 _AgendaID, uint256 _vote, string calldata _comment) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function executeAgenda(uint256 _AgendaID) external;
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external;

    function updateSeigniorage(address _candidate) external returns (bool);
    function updateSeigniorages(address[] calldata _candidates) external returns (bool);
    function claimActivityReward(address _receiver) external;

    function isCandidate(address _candidate) external view returns (bool);
    function totalSupplyOnCandidate(address _candidate) external view returns (uint256);
    function balanceOfOnCandidate(address _candidate, address _account) external view returns (uint256);
    function totalSupplyOnCandidateContract(address _candidateContract) external view returns (uint256);
    function balanceOfOnCandidateContract(address _candidateContract, address _account) external view returns (uint256);
    function candidatesLength() external view returns (uint256);
    function isExistCandidate(address _candidate) external view returns (bool);
    function getClaimableActivityReward(address _candidate) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISeigManager {
    function registry() external view returns (address);
    function depositManager() external view returns (address);
    function ton() external view returns (address);
    function wton() external view returns (address);
    function powerton() external view returns (address);
    function tot() external view returns (address);
    function coinages(address layer2) external view returns (address);
    function commissionRates(address layer2) external view returns (uint256);

    function lastCommitBlock(address layer2) external view returns (uint256);
    function seigPerBlock() external view returns (uint256);
    function lastSeigBlock() external view returns (uint256);
    function pausedBlock() external view returns (uint256);
    function unpausedBlock() external view returns (uint256);
    function DEFAULT_FACTOR() external view returns (uint256);

    function deployCoinage(address layer2) external returns (bool);
    function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);

    function uncomittedStakeOf(address layer2, address account) external view returns (uint256);
    function stakeOf(address layer2, address account) external view returns (uint256);
    function additionalTotBurnAmount(address layer2, address account, uint256 amount) external view returns (uint256 totAmount);

    function onTransfer(address sender, address recipient, uint256 amount) external returns (bool);
    function updateSeigniorage() external returns (bool);
    function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IDAOCommittee } from "IDAOCommittee.sol";
import { ISeigManager } from "ISeigManager.sol";

interface ICandidate {
    function setSeigManager(address _seigMan) external;
    function setCommittee(address _committee) external;
    function updateSeigniorage() external returns (bool);
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function castVote(uint256 _agendaID, uint256 _vote, string calldata _comment) external;
    function isCandidateContract() external view returns (bool);
    function totalStaked() external view returns (uint256 totalsupply);
    function stakedOf(address _account) external view returns (uint256 amount);
    function setMemo(string calldata _memo) external;
    function claimActivityReward() external;

    // getter
    function candidate() external view returns (address);
    function isLayer2Candidate() external view returns (bool);
    function memo() external view returns (string memory);
    function committee() external view returns (IDAOCommittee);
    function seigManager() external view returns (ISeigManager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2 {
  function operator() external view returns (address);
  function isLayer2() external view returns (bool);
  function currentFork() external view returns (uint256);
  function lastEpoch(uint256 forkNumber) external view returns (uint256);
  function changeOperator(address _operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2Registry {
    function layer2s(address layer2) external view returns (bool);

    function register(address layer2) external returns (bool);
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);

    function deployCoinage(address layer2, address seigManager) external returns (bool);
    function registerAndDeployCoinage(address layer2, address seigManager) external returns (bool);
    function unregister(address layer2) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { ICandidateFactory } from "ICandidateFactory.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ISeigManager } from "ISeigManager.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOVault } from "IDAOVault.sol";

interface IStorageStateCommittee {
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    function ton() external returns (address);
    function daoVault() external returns (IDAOVault);
    function agendaManager() external returns (IDAOAgendaManager);
    function candidateFactory() external returns (ICandidateFactory);
    function layer2Registry() external returns (ILayer2Registry);
    function seigManager() external returns (ISeigManager);
    function candidates(uint256 _index) external returns (address);
    function members(uint256 _index) external returns (address);
    function maxMember() external returns (uint256);
    function candidateInfos(address _candidate) external returns (CandidateInfo memory);
    function quorum() external returns (uint256);
    function activityRewardPerSecond() external returns (uint256);

    function isMember(address _candidate) external returns (bool);
    function candidateContract(address _candidate) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity ^0.7.6;

interface ICandidateFactory {
    function deploy(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { LibAgenda } from "LibAgenda.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";

interface IDAOAgendaManager  {
    struct Ratio {
        uint256 numerator;
        uint256 denominator;
    }

    function setCommittee(address _committee) external;
    function setCreateAgendaFees(uint256 _createAgendaFees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function newAgenda(
        address[] memory _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        returns (uint256 agendaID);
    function castVote(uint256 _agendaID, address voter, uint256 _vote) external returns (bool);
    function setExecutedAgenda(uint256 _agendaID) external;
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result) external;
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function setExecutedCount(uint256 _agendaID, uint256 _count) external;
     
    // -- view functions
    function isVoter(uint256 _agendaID, address _user) external view returns (bool);
    function hasVoted(uint256 _agendaID, address _user) external view returns (bool);
    function getVoteStatus(uint256 _agendaID, address _user) external view returns (bool, uint256);
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view returns (uint256) ;

    function canExecuteAgenda(uint256 _agendaID) external view returns (bool);
    function getAgendaStatus(uint256 _agendaID) external view returns (uint256 status);
    function totalAgendas() external view returns (uint256);
    function getAgendaResult(uint256 _agendaID) external view returns (uint256 result, bool executed);
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        );
    function isVotableStatus(uint256 _agendaID) external view returns (bool);
    function getVotingCount(uint256 _agendaID)
        external
        view
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        );
    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        );
    function numAgendas() external view returns (uint256);
    function getVoters(uint256 _agendaID) external view returns (address[] memory);

    function getStatus(uint256 _createAgendaFees) external pure returns (LibAgenda.AgendaStatus);

    // getter
    function committee() external view returns (IDAOCommittee);
    function createAgendaFees() external view returns (uint256);
    function minimumNoticePeriodSeconds() external view returns (uint256);
    function minimumVotingPeriodSeconds() external view returns (uint256);
    function executingPeriodSeconds() external view returns (uint256);
    function agendas(uint256 _index) external view returns (LibAgenda.Agenda memory);
    function voterInfos(uint256 _index1, address _index2) external view returns (LibAgenda.Voter memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IDAOVault {
    function setTON(address _ton) external;
    function setWTON(address _wton) external;
    function approveTON(address _to, uint256 _amount) external;
    function approveWTON(address _to, uint256 _amount) external;
    function approveERC20(address _token, address _to, uint256 _amount) external;
    function claimTON(address _to, uint256 _amount) external;
    function claimWTON(address _to, uint256 _amount) external;
    function claimERC20(address _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

library LibAgenda {
    //using LibAgenda for Agenda;

    enum AgendaStatus { NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED }
    enum AgendaResult { PENDING, ACCEPT, REJECT, DISMISS }

    //votor : based operator 
    struct Voter {
        bool isVoter;
        bool hasVoted;
        uint256 vote;
    }

    // counting abstainVotes yesVotes noVotes
    struct Agenda {
        uint256 createdTimestamp;
        uint256 noticeEndTimestamp;
        uint256 votingPeriodInSeconds;
        uint256 votingStartedTimestamp;
        uint256 votingEndTimestamp;
        uint256 executableLimitTimestamp;
        uint256 executedTimestamp;
        uint256 countingYes;
        uint256 countingNo;
        uint256 countingAbstain;
        AgendaStatus status;
        AgendaResult result;
        address[] voters;
        bool executed;
    }

    struct AgendaExecutionInfo {
        address[] targets;
        bytes[] functionBytecodes;
        bool atomicExecute;
        uint256 executeStartFrom;
    }

    /*function getAgenda(Agenda[] storage agendas, uint256 index) public view returns (Agenda storage agenda) {
        return agendas[index];
    }*/
}