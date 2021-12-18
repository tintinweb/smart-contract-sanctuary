pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWorkEvaluator.sol";
import "./interfaces/IBonder.sol";
import "./interfaces/IJobsRegistry.sol";
import "./interfaces/IMaster.sol";

error ZeroAddressJobsRegistry();
error ZeroAddressBonder();
error ZeroAddressWorkEvaluator();
error NonExistingJob();
error NotAWorker();
error RequirementsNotMet();
error Forbidden();
error InvalidWorker();
error NotEnoughCredit();

/**
 * @title Master
 * @dev Master contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract Master is IMaster, Ownable {
    uint256 private gasCheckpoint;
    address public bonder;
    address public jobsRegistry;
    address public workEvaluator;
    address public nativeToken;

    constructor(
        address _bonder,
        address _jobsRegistry,
        address _workEvaluator,
        address _nativeToken
    ) {
        if (_bonder == address(0)) revert ZeroAddressBonder();
        if (_jobsRegistry == address(0)) revert ZeroAddressJobsRegistry();
        if (_workEvaluator == address(0)) revert ZeroAddressWorkEvaluator();
        bonder = _bonder;
        jobsRegistry = _jobsRegistry;
        workEvaluator = _workEvaluator;
        nativeToken = _nativeToken;
    }

    function setBonder(address _bonder) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_bonder == address(0)) revert ZeroAddressBonder();
        bonder = _bonder;
        emit SetBonder(_bonder);
    }

    function setJobsRegistry(address _jobsRegistry) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_jobsRegistry == address(0)) revert ZeroAddressJobsRegistry();
        jobsRegistry = _jobsRegistry;
        emit SetJobsRegistry(_jobsRegistry);
    }

    function setWorkEvaluator(address _workEvaluator) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_workEvaluator == address(0)) revert ZeroAddressWorkEvaluator();
        workEvaluator = _workEvaluator;
        emit SetWorkEvaluator(_workEvaluator);
    }

    function worker(address _address) external view returns (bool) {
        return IBonder(bonder).bonded(_address) > 0;
    }

    function initializeWork(address _worker) external {
        if (!IJobsRegistry(jobsRegistry).exists(msg.sender)) revert Forbidden();
        if (IBonder(bonder).bonded(_worker) == 0) revert NotAWorker();
        gasCheckpoint = gasleft();
    }

    function initializeWorkWithRequirements(
        address _worker,
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) external override {
        if (!IJobsRegistry(jobsRegistry).exists(msg.sender)) revert Forbidden();
        uint256 _bonded = IBonder(bonder).bonded(_worker);
        if (_bonded == 0) revert NotAWorker();
        if (_minimumBonded > 0 && _bonded < _minimumBonded)
            revert RequirementsNotMet();
        if (
            _minimumEarned > 0 &&
            IBonder(bonder).earned(_worker) < _minimumEarned
        ) revert RequirementsNotMet();
        if (
            _minimumAge > 0 &&
            block.timestamp - IBonder(bonder).activationTimestamp(_worker) <
            _minimumAge
        ) revert RequirementsNotMet();
        gasCheckpoint = gasleft();
    }

    function finalizeWork(address _worker) external override {
        if (!IJobsRegistry(jobsRegistry).exists(msg.sender)) revert Forbidden();
        if (IBonder(bonder).bonded(_worker) == 0) revert InvalidWorker();
        uint256 _gasUsed = gasCheckpoint - gasleft();
        uint256 _workCost = IWorkEvaluator(workEvaluator).evaluateCost(
            _worker,
            _gasUsed
        );
        IJobsRegistry(jobsRegistry).registerWork(
            msg.sender,
            nativeToken,
            _worker,
            _workCost,
            _gasUsed
        );
    }

    function finalizeWork(
        address _worker,
        address _rewardToken,
        uint256 _amount
    ) external override {
        if (!IJobsRegistry(jobsRegistry).exists(msg.sender)) revert Forbidden();
        if (IBonder(bonder).bonded(_worker) == 0) revert InvalidWorker();
        IJobsRegistry(jobsRegistry).registerWork(
            msg.sender,
            _rewardToken,
            _worker,
            _amount,
            gasCheckpoint - gasleft()
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.8.10;

/**
 * @title IWorkEvaluator
 * @dev IWorkEvaluator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IWorkEvaluator {
    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        returns (uint256);
}

pragma solidity ^0.8.10;

/**
 * @title IBonder
 * @dev IBonder contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IBonder {
    struct Worker {
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingTimestamp;
        uint256 unbonding;
        uint256 unbondingTimestamp;
        uint256 activationTimestamp;
    }

    event SetBondingTime(uint32 bondingTime);
    event SetUnbondingTime(uint32 unbondingTime);
    event SetNativeToken(address nativeToken);
    event Bond(uint256 amount);
    event ConsolidateBond(uint256 amount);
    event CancelBonding(uint256 refundedAmount);
    event AccrueReward(address worker, address token, uint256 amount);
    event Unbond(uint256 amount);
    event ConsolidateUnbonding(uint256 amount);
    event Slash(address worker, uint256 amount);
    event Disallow(address worker);

    function totalBonded() external view returns (uint256);

    function bondingTime() external view returns (uint32);

    function unbondingTime() external view returns (uint32);

    function nativeToken() external view returns (address);

    function jobsRegistry() external view returns (address);

    function setBondingTime(uint32 _bondingTime) external;

    function setUnbondingTime(uint32 _unbondingTime) external;

    function setNativeToken(address _nativeToken) external;

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function accrueReward(
        address _address,
        address _token,
        uint256 _amount
    ) external;

    function unbond(uint256 _amount) external;

    function consolidateUnbonding() external;

    function slash(address _worker, uint256 _amount) external;

    function disallow(address _worker) external;

    function bonded(address _address) external view returns (uint256);

    function earned(address _address) external view returns (uint256);

    function disallowed(address _address) external view returns (bool);

    function activationTimestamp(address _address)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.10;

/**
 * @title IJobsRegistry
 * @dev IJobsRegistry contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJobsRegistry {
    struct Job {
        bool exists;
        mapping(address => uint256) credit;
    }

    event AllowLiquidity(address liquidity, address weightCalculator);
    event DisallowLiquidity(address liquidity);
    event AllowJobsCreator(address creator);
    event DisallowJobsCreator(address creator);
    event AddJob(address job);
    event RemoveJob(address job);
    event AddCredit(address job, uint256 amount);
    event AddLiquidityCredit(address job, address liquidity, uint256 amount);
    event RegisterWork(
        address job,
        address worker,
        address token,
        uint256 reward,
        uint256 usedGas
    );
    event SetFee(uint16 fee);
    event SetNativeToken(address nativeToken);
    event SetMaster(address master);
    event SetBonder(address bonder);
    event SetFeeReceiver(address feeReceiver);

    function liquidityWeightCalculator(address _liquidityToken)
        external
        returns (address);

    function jobsCreator(address _jobsCreator) external returns (bool);

    function fee() external returns (uint32);

    function nativeToken() external returns (address);

    function master() external returns (address);

    function bonder() external returns (address);

    function feeReceiver() external returns (address);

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external;

    function disallowLiquidity(address _liquidity) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(address _job) external;

    function removeJob(address _job) external;

    function addCredit(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    function addCreditWithPermit(
        address _job,
        address _token,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function addLiquidityCredit(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function registerWork(
        address _job,
        address _token,
        address _worker,
        uint256 _usedCredit,
        uint256 _usedGas
    ) external;

    function exists(address _job) external view returns (bool);

    function credit(address _job, address _token)
        external
        view
        returns (uint256);

    function setFee(uint16 _fee) external;

    function setNativeToken(address _nativeToken) external;

    function setMaster(address _master) external;

    function setBonder(address _bonder) external;

    function setFeeReceiver(address _feeReceiver) external;
}

pragma solidity >=0.8.10;

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IMaster {
    event SetBonder(address bonder);
    event SetJobsRegistry(address jobsRegistry);
    event SetWorkEvaluator(address workEvaluator);

    function setBonder(address _bonder) external;

    function setJobsRegistry(address _jobsRegistry) external;

    function setWorkEvaluator(address _workEvaluator) external;

    function bonder() external returns (address);

    function jobsRegistry() external returns (address);

    function workEvaluator() external returns (address);

    function initializeWork(address _worker) external;

    function initializeWorkWithRequirements(
        address _worker,
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) external;

    function finalizeWork(address _worker) external;

    function finalizeWork(
        address _worker,
        address _rewardToken,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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