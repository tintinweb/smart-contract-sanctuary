//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FeeManager.sol";
import "../storage/TaskStorage.sol";
import "../storage/StorageAccessor.sol";
import "../interfaces/IIterableFunctions.sol";

/**
* @dev - order of inheritance is relevant to storage layout
* Order should be something like:
* - interfaces
* - AccessLevel (because it has internal storage and should be always on the first slot
* - other stateless storages
* even though StorageAccessor actually uses storage, it can be considered stateless since it's using StorageSlot
*/
contract TaskManager is IIterableFunctions, StorageAccessor, FeeManager {

    struct TaskCreationParams {
        uint256 externalId;
        string taskDescriptionUri;
        string taskDescriptionHash;
        address tokenAddress;
        uint256 amount;
        bool isHyveCommission;
        uint256 deadline;
    }

    string constant ETH_INSUFFICIENT_REASON = "TM: ETH != declared";
    string constant NOT_CREATOR_REASON = "TM: not task creator";
    string constant NO_SOLUTION = "TM: no solution";
    string constant TYPE = "TASK";
    bytes32 private constant _STORAGE_SLOT = keccak256("hyve.works.storage.task");

    event TaskCreated(uint256 indexed externalId, uint256 indexed taskId);
    event TaskCanceled(uint256 indexed taskId);
    event TaskApplicationCreated(uint256 indexed taskId, uint256 indexed applicationId, address applicant);
    event TaskApplicationAccepted(uint256 indexed taskId, uint256 indexed applicationId);
    event TaskSolutionSubmitted(uint256 indexed taskId, uint256 indexed applicationId, uint256 solutionId, address applicant);
    event TaskSolutionAccepted(uint256 indexed taskId, uint256 solutionId);
    event TaskSolutionRejected(uint256 indexed taskId, uint256 solutionId);

    function __TaskManager_init(address owner, address taskStorage) initializer public {
        __AccessLevel_init(owner);
        setStorageAddress(taskStorage);
    }

    function getFunctions() override external pure returns (bytes4[] memory){
        bytes4[] memory functions = new bytes4[](10);
        //initializer
        functions[0] = this.__TaskManager_init.selector;
        //access level
        functions[1] = this.grantRole.selector;
        functions[2] = this.hasRole.selector;
        functions[3] = this.revokeRole.selector;
        //erc20Sender
        functions[4] = this.sendERC20.selector;
        //taskManagement
        functions[5] = this.createTask.selector;
        functions[6] = this.cancelTask.selector;
        functions[7] = this.submitTaskSolution.selector;
        functions[8] = this.acceptTaskSolution.selector;
        functions[9] = this.rejectTaskSolution.selector;
        return functions;
    }

    function getStorageSlot() override internal pure returns (bytes32){
        return _STORAGE_SLOT;
    }

    function getTaskStorage() private view returns (TaskStorage) {
        return TaskStorage(getStorageAddress());
    }

    function supportsInterface(bytes4 interfaceId) override virtual public view returns (bool) {
        return interfaceId == type(IIterableFunctions).interfaceId || super.supportsInterface(interfaceId);
    }

    function getConfigStorage() override virtual internal view returns (IConfigStorage) {
        return getTaskStorage().configStorage();
    }

    function createTask(
        TaskCreationParams calldata taskParams,
        address applicant
    ) external payable {
        require(taskParams.amount > 0, "TM: 0 amount");
        bool isEth = (taskParams.tokenAddress == address(0)) && msg.value > 0;
        //checks
        uint256 tax = calculateTax(taskParams.isHyveCommission, isEth, taskParams.amount, taskParams.tokenAddress);

        if (msg.value > 0) {
            require(taskParams.tokenAddress == address(0), "TM: Token address included");
            isEth = true;
            if (taskParams.isHyveCommission) {
                checkUserTokenBalance(_msgSender(), getConfigStorage().getHyveERC(), tax);
                require(msg.value == taskParams.amount, ETH_INSUFFICIENT_REASON);
            } else {
                require(msg.value == taskParams.amount + tax, ETH_INSUFFICIENT_REASON);
            }
        }
        else {
            require(
                taskParams.tokenAddress != getConfigStorage().getHyveERC() || taskParams.isHyveCommission,
                "TM: payment & commission not in HYVE");
            if (taskParams.isHyveCommission) {
                checkUserTokenBalance(_msgSender(), taskParams.tokenAddress, taskParams.amount);
                checkUserTokenBalance(_msgSender(), getConfigStorage().getHyveERC(), tax);
            } else {
                checkUserTokenBalance(_msgSender(), taskParams.tokenAddress, taskParams.amount + tax);
            }
        }
        require(taskParams.deadline > block.timestamp, "TM: Past deadline!");

        //effects
        uint256 taskId = getTaskStorage().getNewTaskId();
        getTaskStorage().addNewTask(
            taskId,
            TaskStorage.Task(
                taskParams.taskDescriptionUri,
                taskParams.taskDescriptionHash,
                taskParams.tokenAddress,
                taskParams.amount,
                _msgSender(),
                taskParams.deadline,
                false,
                0,
                0)
        );

        //interactions
        if (taskParams.isHyveCommission) {
            splitTax(_msgSender(), false, tax, IERC20Upgradeable(getConfigStorage().getHyveERC()));
        } else {
            splitTax(_msgSender(), isEth, tax, IERC20Upgradeable(taskParams.tokenAddress));
        }

        if (isEth) {
            IEscrow(getConfigStorage().getEscrow()).createDepositETH{value : taskParams.amount}(taskId, TYPE, _msgSender(), taskParams.amount);
        } else {
            IEscrow(getConfigStorage().getEscrow()).createDeposit(address(this), taskId, TYPE, _msgSender(), taskParams.tokenAddress, taskParams.amount);
        }

        emit TaskCreated(taskParams.externalId, taskId);
        uint256 applicationId = getTaskStorage().getNewApplicationId();
        getTaskStorage().addNewApplication(applicationId, UtilityStorage.Application(taskId, applicant));
        emit TaskApplicationCreated(taskId, applicationId, applicant);
        getTaskStorage().acceptApplication(applicationId);
        emit TaskApplicationAccepted(taskId, applicationId);
    }

    function cancelTask(uint256 taskId) external {
        TaskStorage.Task memory task = getTaskStorage().getTask(taskId);
        require(_msgSender() == task.creator, NOT_CREATOR_REASON);
        getTaskStorage().cancelTask(taskId);
        IEscrow(getConfigStorage().getEscrow()).redeemDeposit(taskId, TYPE);
        emit TaskCanceled(taskId);
    }

    function submitTaskSolution(uint256 applicationId, string memory solutionUri, string memory solutionHash) external {
        require(applicationId <= getTaskStorage().getLastApplicationId(), "TM: no application");
        UtilityStorage.Application memory application = getTaskStorage().getApplication(applicationId);
        require(_msgSender() == application.worker, "TM: not applicant");
        uint256 solutionId = getTaskStorage().getNewSolutionId();
        getTaskStorage().addNewSolution(solutionId, UtilityStorage.Solution(applicationId, solutionUri, solutionHash, ""));
        emit TaskSolutionSubmitted(application.listingId, applicationId, solutionId, _msgSender());
    }

    function acceptTaskSolution(uint256 solutionId) external {
        require(solutionId <= getTaskStorage().getLastSolutionId(), NO_SOLUTION);
        UtilityStorage.Application memory application = getTaskStorage().getApplication(getTaskStorage().getSolution(solutionId).applicationId);
        require(_msgSender() == getTaskStorage().getTask(application.listingId).creator, NOT_CREATOR_REASON);
        getTaskStorage().acceptSolution(solutionId);
        IEscrow(getConfigStorage().getEscrow()).setBeneficiary(application.listingId, TYPE, application.worker);
        IEscrow(getConfigStorage().getEscrow()).executePayment(application.listingId, TYPE);
        emit TaskSolutionAccepted(application.listingId, solutionId);
    }

    function rejectTaskSolution(uint256 solutionId, string memory reason) external {
        require(solutionId <= getTaskStorage().getLastSolutionId(), NO_SOLUTION);
        UtilityStorage.Application memory application = getTaskStorage().getApplication(getTaskStorage().getSolution(solutionId).applicationId);
        require(_msgSender() == getTaskStorage().getTask(application.listingId).creator, NOT_CREATOR_REASON);
        getTaskStorage().rejectSolution(solutionId, reason);
        emit TaskSolutionRejected(application.listingId, solutionId);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ERC20Sender.sol";

//@dev - keep these stateless
abstract contract ERC20Taker {
    //@dev call this when transferring erc20 from a different contract
    function takeERC20(ERC20Sender sender, address from, IERC20Upgradeable token, uint256 amount) virtual public {
        sender.sendERC20(from, address(this), token, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./AccessLevel.sol";

//@dev - keep these stateless
abstract contract ERC20Sender is AccessLevel {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function sendERC20(address from, address to, IERC20Upgradeable token, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        require(token.balanceOf(from) >= amount, "ERC20Giver: not enough balance");
        token.safeTransferFrom(from, to, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import "../interfaces/IIterableFunctions.sol";

abstract contract AccessLevel is AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function __AccessLevel_init(address owner) initializer public {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }
}

import "./ConfigStorage.sol";

abstract contract UtilityStorage is AccessLevel {
    ConfigStorage public configStorage;

    uint256 private _applicationId;
    mapping(uint256 => uint256[]) internal _listingApplications;
    mapping(uint256 => Application) internal _applications;

    uint256 internal _solutionId;
    mapping(uint256 => uint256[]) internal _applicationSolutions;
    mapping(uint256 => Solution) internal _solutions;

    struct Application {
        uint256 listingId;
        address worker;
    }

    struct Solution {
        uint256 applicationId;
        string solutionURI;
        string solutionHash;
        string rejectionReason;
    }

    function initialize(address owner, address _storageAddress) initializer public {
        __AccessLevel_init(owner);
        configStorage = ConfigStorage(_storageAddress);
    }

    function getNewApplicationId() external onlyRole(OPERATOR_ROLE) returns (uint256){
        _applicationId = _applicationId + 1;
        return _applicationId;
    }

    function getLastApplicationId() external view returns (uint256){
        return _applicationId;
    }

    function getApplications(uint256 listingId) external view returns (uint256[] memory) {
        return _listingApplications[listingId];
    }

    function getApplication(uint256 applicationId) external view returns (Application memory) {
        return _applications[applicationId];
    }

    function addNewApplication(uint256 applicationId, Application memory application) external onlyRole(OPERATOR_ROLE) {
        _applications[applicationId] = application;
        _listingApplications[application.listingId].push(applicationId);
    }

    function getNewSolutionId() external onlyRole(OPERATOR_ROLE) returns (uint256){
        _solutionId = _solutionId + 1;
        return _solutionId;
    }

    function getLastSolutionId() external view returns (uint256){
        return _solutionId;
    }

    function getJobSolutions(uint256 applicationId) external view returns (uint256[] memory) {
        return _applicationSolutions[applicationId];
    }

    function getSolution(uint256 solutionId) external view returns (Solution memory) {
        return _solutions[solutionId];
    }

    function addNewSolution(uint256 solutionId, Solution memory solution) external onlyRole(OPERATOR_ROLE) {
        _solutions[solutionId] = solution;
        _applicationSolutions[solution.applicationId].push(solutionId);
    }

    function rejectSolution(uint256 solutionId, string memory reason) external onlyRole(OPERATOR_ROLE) {
        _solutions[solutionId].rejectionReason = reason;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./UtilityStorage.sol";

// @dev - need Access level because logic abstract contracts also use AccessLevel so we make sure there's no clash
// of storage since inherited fields are stored in the first slots
contract TaskStorage is UtilityStorage {

    struct Task {
        string descriptionURI;
        string descriptionHash;
        address token;
        uint256 amount;
        address creator;
        uint256 deadline;
        bool canceled;
        uint256 applicationId;
        uint256 solutionId;
    }

    uint256 private _taskId;
    mapping(address => uint256[]) private _creatorTasks;
    mapping(uint256 => Task) private _tasks;

    function getNewTaskId() external onlyRole(OPERATOR_ROLE) returns (uint256){
        _taskId = _taskId + 1;
        return _taskId;
    }

    function getLastTaskId() external view returns (uint256){
        return _taskId;
    }

    function getTasksCreatedBy(address creator) external view returns (uint256[] memory){
        return _creatorTasks[creator];
    }

    function addNewTask(uint256 taskId, Task memory task) external onlyRole(OPERATOR_ROLE) {
        _creatorTasks[task.creator].push(taskId);
        _tasks[taskId] = task;
    }

    function getTask(uint256 taskId) external view returns (Task memory){
        return _tasks[taskId];
    }

    function cancelTask(uint256 taskId) external onlyRole(OPERATOR_ROLE) {
        TaskStorage.Task memory task = _tasks[taskId];
        require(task.deadline < block.timestamp, "TS: deadline not reached!");
        require(_applicationSolutions[task.applicationId].length == 0, "TS: task has solutions submitted!");
        _tasks[taskId].canceled = true;
    }

    function acceptApplication(uint applicationId) external onlyRole(OPERATOR_ROLE) {
        _tasks[_applications[applicationId].listingId].applicationId = applicationId;
    }

    function acceptSolution(uint256 solutionId) external onlyRole(OPERATOR_ROLE) {
        _tasks[_applications[_solutions[solutionId].applicationId].listingId].solutionId = solutionId;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import 'contracts4/utils/StorageSlot.sol';
import "../interfaces/IAddressManager.sol";
import "../utils/AccessLevel.sol";

abstract contract StorageAccessor is IAddressManager {

    function getStorageAddress() internal view returns (address) {
        return StorageSlot.getAddressSlot(getStorageSlot()).value;
    }

    function setStorageAddress(address newStorage) internal {
        require(newStorage != address(0), "StorageAccessor: new storage is the zero address");
        StorageSlot.getAddressSlot(getStorageSlot()).value = newStorage;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


import "../utils/AccessLevel.sol";
import "../interfaces/IConfigStorage.sol";

contract ConfigStorage is IConfigStorage, AccessLevel {
    address private _hyveERC;
    address private _vault;
    address private _staking;
    address private _escrow;
    mapping(address => bool) private _reducedTaxCoins;
    uint256 private _stakingPercent;

    function initialize(
        address owner,
        address hyveERC,
        address vault,
        address staking,
        address escrow,
        uint256 stakingPercent
    ) initializer public {
        __AccessLevel_init(owner);
        _hyveERC = hyveERC;
        _vault = vault;
        _staking = staking;
        _escrow = escrow;
        _stakingPercent = stakingPercent;
    }

    function setStaking(address staking) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _staking = staking;
    }

    function getStaking() override external view returns (address){
        return _staking;
    }

    function setVault(address vault) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _vault = vault;
    }

    function getVault() override external view returns (address){
        return _vault;
    }

    function setEscrow(address escrow) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _escrow = escrow;
    }

    function getEscrow() override external view returns (address) {
        return _escrow;
    }

    function setStakingPercent(uint256 stakingPercent) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _stakingPercent = stakingPercent;
    }

    function getStakingPercent() override  external view returns (uint256) {
        return _stakingPercent;
    }

    function setHyveERC(address hyveERC) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _hyveERC = hyveERC;
    }

    function getHyveERC() override external view returns (address) {
        return _hyveERC;
    }

    function isReducedTaxToken(address token) override external view returns (bool) {
        return _reducedTaxCoins[token];
    }

    function setReducedTaskTokens(address[] memory tokens) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            _reducedTaxCoins[tokens[i]] = true;
        }
    }

    function removeReducedTaxToken(address token) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        _reducedTaxCoins[token] = false;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "contracts4/utils/math/SafeMath.sol";
import "../interfaces/IAddressManager.sol";
import "../utils/ERC20Sender.sol";
import "../utils/ERC20Taker.sol";

//@dev - keep these stateless
//@notice - this smart contract is to be extended by TaskManager and other contracts where Fees are collected
abstract contract FeeManager is IAddressManager, ERC20Sender {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    uint256 constant private BIPS_DIVISOR = 10000;
    uint256 constant private T0_TAX = 0;
    uint256 constant private T1_TAX = 25;
    uint256 constant private T2_TAX = 50;
    uint256 constant private T3_TAX = 100;

    /**
    * @notice - calculates the required tax for the payment amount
    * formula:
    * - if task is paid in hyve - 0%
    * - if only the fee is paid in hyve - 0.25%
    * - if the fee is paid in stablecoins / ether - 0.50%
    * - if the fee is paid in unknown coins - 1%
    */
    function calculateTax(bool isHyveCommission, bool isEther, uint256 amount, address tokenAddress) internal view returns (uint256) {
        if (getConfigStorage().getHyveERC() == tokenAddress) {
            return T0_TAX;
        } else {
            if (isHyveCommission) {
                return amount * T1_TAX / BIPS_DIVISOR;
            } else {
                if (isEther || getConfigStorage().isReducedTaxToken(tokenAddress)) {
                    return amount * T2_TAX / BIPS_DIVISOR;
                } else {
                    return amount * T3_TAX / BIPS_DIVISOR;
                }
            }
        }
    }

    function splitTax(address customer, bool isEthTax, uint256 taxValue, IERC20Upgradeable token) internal {
        uint256 stakingValue = taxValue * getConfigStorage().getStakingPercent() / BIPS_DIVISOR;
        uint256 vaultValue = taxValue.sub(stakingValue);
        if (isEthTax) {
            payable(getConfigStorage().getStaking()).call{value : stakingValue}("");
            payable(getConfigStorage().getVault()).call{value : vaultValue}("");
        } else {
            ERC20Taker(getConfigStorage().getStaking()).takeERC20(ERC20Sender(this), customer, token, stakingValue);
            ERC20Taker(getConfigStorage().getVault()).takeERC20(ERC20Sender(this), customer, token, vaultValue);
        }
    }

    function checkUserTokenBalance(address user, address token, uint256 minimumBalance) internal view {
        require(
            IERC20Upgradeable(token).balanceOf(user) >= minimumBalance &&
            IERC20Upgradeable(token).allowance(user, address(this)) >= minimumBalance,
            "JM: Too few funds");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {

    function depositedTokens() external view returns (address[] memory);

    function withdrawERC20(address to, address tokenAddress, uint256 amount) external;

    function withdrawAllERC20(address to, address tokenAddress) external;

    function withdrawETH(address payable to, uint256 amount) external;

    function withdrawAllFunds(address payable to) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IStaking {
    struct StakingDataForInterval {
        uint256 periodEnd;
        mapping(address => uint256) tokenFees;
        uint256 ethFees;
        uint256 amountStaked;
    }

    // duration should be specified in months
    function stakeHYVETokens(address from, uint amount, uint durationInMonths) external;

    function claimRewards(address to, uint256 timePeriodEnd) external;

    function withdrawStakedAmount(address to, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IIterableFunctions {
    function getFunctions() external pure returns (bytes4[] memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IEscrow {
    struct EscrowDeposit {
        address from;
        address tokenAddress;
        uint256 initialDeposit;
        address beneficiary;
    }

    function createDeposit(address mediator, uint256 taskId, string memory listingType, address from, address tokenAddress, uint256 amount) external;

    function createDepositETH(uint256 taskId, string memory listingType, address from, uint256 amount) external payable;

    function setBeneficiary(uint256 taskId, string memory listingType, address beneficiary) external;

    function executePayment(uint256 taskId, string memory listingType) external;

    function getEscrowDeposit(uint256 taskId, string memory listingType) external view returns (EscrowDeposit memory);

    function redeemDeposit(uint256 taskId, string memory listingType) external;

    function splitDeposit(uint256 taskId, string memory listingType, uint256 paymentPercentage) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "../Staking.sol";
import "../Vault.sol";
import "../Escrow.sol";

interface IConfigStorage {
    function setStaking(address staking) external;

    function getStaking() external view returns (address);

    function setVault(address vault) external;

    function getVault() external view returns (address);

    function setEscrow(address staking) external;

    function getEscrow() external view returns (address);

    function setStakingPercent(uint256 stakingPercent) external;

    function getStakingPercent() external view returns (uint256);

    function setHyveERC(address hyveERC) external;

    function getHyveERC() external view returns (address);

    function isReducedTaxToken(address token) external view returns (bool);

    function setReducedTaskTokens(address[] memory tokens) external;

    function removeReducedTaxToken(address token) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConfigStorage.sol";

abstract contract IAddressManager {
    function getStorageSlot() virtual internal pure returns (bytes32);

    function getConfigStorage() virtual internal view returns (IConfigStorage);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./interfaces/IVault.sol";
import "./utils/AccessLevel.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./utils/ERC20Taker.sol";

contract Vault is IVault, AccessLevel, ERC20Taker {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private registeredTokenSet;

    function initialize(address owner) initializer public {
        __AccessLevel_init(owner);
    }

    //@dev - handle receiving native coin ETH/MATIC
    receive() external payable {}

    function takeERC20(ERC20Sender mediator, address from, IERC20Upgradeable token, uint256 amount) override public {
        require(address(token) != address(0), "Address should not be 0");
        super.takeERC20(mediator, from, token, amount);

        if (!registeredTokenSet.contains(address(token))) {
            registeredTokenSet.add(address(token));
        }
    }

    function depositedTokens() override external view returns (address[] memory) {
        return registeredTokenSet.values();
    }

    function withdrawERC20(address to, address tokenAddress, uint256 amount) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenAddress != address(0), "Address should not be 0");

        uint256 balance = IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        require(amount <= balance, "Amount is too large!");

        if (amount == balance) {
            registeredTokenSet.remove(tokenAddress);
        }

        IERC20Upgradeable(tokenAddress).safeTransfer(to, amount);
    }

    function withdrawAllERC20(address to, address tokenAddress) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenAddress != address(0), "Address should not be 0");

        uint256 balance = IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        registeredTokenSet.remove(tokenAddress);
        IERC20Upgradeable(tokenAddress).safeTransfer(to, balance);
    }

    function withdrawETH(address payable to, uint256 amount) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= address(this).balance, "Amount is too large!");
        to.call{value: amount}("");
    }

    function withdrawAllFunds(address payable to) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint index=0; index < registeredTokenSet.length(); index++) {
            IERC20Upgradeable tokenToTransfer = IERC20Upgradeable(registeredTokenSet.at(index));
            tokenToTransfer.safeTransfer(to, tokenToTransfer.balanceOf(address(this)));
        }
        while(registeredTokenSet.length() != 0) {
            registeredTokenSet.remove(registeredTokenSet.at(0));
        }

        to.call{value: address(this).balance}("");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./interfaces/IStaking.sol";
import "./utils/AccessLevel.sol";
import "./utils/ERC20Taker.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Staking is IStaking, AccessLevel, ERC20Taker {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    EnumerableSetUpgradeable.AddressSet private feeTokens;
    mapping(address => uint256) public tmpTokenFeesWithdraw;

    uint256 public secondsPerDay;
    uint private constant BIGNUMBER = 10 ** 18;
    uint8 public nrLockingDays;
    uint8 public nrEarningDays;
    uint256 public lockingDuration;
    uint256 public earningDuration;
    address public hyveTokenAddress;
    uint256 public lockingPeriodEnd;
    uint256 public lastCheckedTimestamp;
    uint256 public totalHyveStaked;

    // user => stakeExpire => amount
    mapping(address => mapping(uint256 => uint256)) public userToStakeAmountByPeriod;
    mapping(address => EnumerableSetUpgradeable.UintSet) private userToStakeEnds;

    mapping(address => uint256) public totalFeeAmounts;
    uint256 public totalEthFeeAmount;
    mapping(address => mapping(uint256 => uint256)) public userStakedAmountInInterval;
    mapping(uint256 => StakingDataForInterval) public dataForTimeIntervals;


    function initialize(
        address owner,
        address _hyveTokenAddress,
        uint8 _nrLockingDays,
        uint8 _nrEarningDays,
        uint256 _secondsPerDay) initializer public {

        __AccessLevel_init(owner);
        hyveTokenAddress = _hyveTokenAddress;
        nrLockingDays = _nrLockingDays;
        nrEarningDays = _nrEarningDays;
        secondsPerDay = _secondsPerDay;
        lockingDuration = secondsPerDay * nrLockingDays;
        earningDuration = secondsPerDay * nrEarningDays;
        lockingPeriodEnd = block.timestamp + nrLockingDays;
        lastCheckedTimestamp = block.timestamp;
    }

    receive() external payable {
        checkStakingPeriod();
        totalEthFeeAmount += msg.value;
        uint256 endOfCurrentPeriod = lockingPeriodEnd + earningDuration;
        dataForTimeIntervals[endOfCurrentPeriod].ethFees += msg.value;
    }

    function takeERC20(ERC20Sender mediator, address from, IERC20Upgradeable token, uint256 amount) override public {
        require(address(token) != address(0), "Staking: Token address should not be 0");
        checkStakingPeriod();

        if (!feeTokens.contains(address(token))) {
            feeTokens.add(address(token));
        }
        totalFeeAmounts[address(token)] += amount;
        uint256 endOfCurrentPeriod = lockingPeriodEnd + earningDuration;
        dataForTimeIntervals[endOfCurrentPeriod].tokenFees[address(token)] += amount;

        super.takeERC20(mediator, from, token, amount);
    }

    function stakeHYVETokens(address from, uint amount, uint durationInMonths) override external {
        require(amount > 0, "Staking: Staked amount should not be 0");
        require(durationInMonths > 0, "Staking: Duration in moths should not be 0");

        checkStakingPeriod();
        require(block.timestamp <= lockingPeriodEnd, "Staking: Stake possible only during locking period");

        totalHyveStaked += amount;
        uint256 secondsInMonth = lockingDuration + earningDuration;
        uint256 stakeExpiryTime = lockingPeriodEnd + earningDuration + ((durationInMonths - 1) * secondsInMonth);

        // add the staked amount for each month - rewards are computed for each month
        uint256 currentMonthEnd = lockingPeriodEnd + earningDuration;
        for(uint256 i = 0; i < durationInMonths; i++) {
            userStakedAmountInInterval[from][currentMonthEnd] += amount;
            currentMonthEnd += secondsInMonth;
        }

        userToStakeEnds[from].add(stakeExpiryTime);
        userToStakeAmountByPeriod[from][stakeExpiryTime] += amount;

        IERC20Upgradeable(hyveTokenAddress).safeTransferFrom(from, address(this), amount);
    }

    function claimRewards(address to, uint256 timePeriodEnd) override external {
        checkStakingPeriod();
        require(timePeriodEnd <= lockingPeriodEnd - lockingDuration, "Staking: Can't claim rewards from current month or future");
        require(userStakedAmountInInterval[to][timePeriodEnd] != 0, "Staking: No rewards to be claimed!");

        uint256 amount = userStakedAmountInInterval[to][timePeriodEnd];
        require(amount > 0, "Staking: Amount should not be 0");
        StakingDataForInterval storage intervalData = dataForTimeIntervals[timePeriodEnd];
        require(intervalData.periodEnd == timePeriodEnd, "Staking: The 2 time periods should match");

        uint256 rewardPercent = computeRewardPercent(amount, intervalData.amountStaked);

        // reset the amount of hyve staked for interval
        userStakedAmountInInterval[to][timePeriodEnd] = 0;

        address[] memory tokens = feeTokens.values();
        for(uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenAmountToClaim = (intervalData.tokenFees[tokens[i]] * rewardPercent) / BIGNUMBER;
            require(tokenAmountToClaim <= totalFeeAmounts[tokens[i]], "Staking: Insufficient token fees!");
            totalFeeAmounts[tokens[i]] -= tokenAmountToClaim;
            IERC20Upgradeable(tokens[i]).safeTransfer(to, tokenAmountToClaim);
        }
        uint256 ethToClaim = (intervalData.ethFees * rewardPercent) / BIGNUMBER;

        require(ethToClaim <= totalEthFeeAmount, "Staking: Insufficient eth fees!");
        totalEthFeeAmount -= ethToClaim;
        payable(to).call{value: ethToClaim}("");
    }

    function withdrawStakedAmount(address to, uint256 amount) override external {
        require(amount > 0, "Staking: Amount should not be 0");
        checkStakingPeriod();

        require(block.timestamp > lockingPeriodEnd - lockingDuration && block.timestamp <= lockingPeriodEnd, "Stake: Withdrawal possible only during lock period");

        uint256[] memory stakeEndTimes = userToStakeEnds[to].values();
        uint256 amountToCollect = amount;

        for (uint timeIndex = 0; timeIndex < stakeEndTimes.length && amountToCollect != 0; timeIndex++) {
            uint256 stakeEnd = stakeEndTimes[timeIndex];

            if(stakeEnd <= lockingPeriodEnd - lockingDuration) {
                if (userToStakeAmountByPeriod[to][stakeEnd] > amountToCollect) {
                    userToStakeAmountByPeriod[to][stakeEnd] -= amountToCollect;
                    amountToCollect = 0;
                } else {
                    amountToCollect -= userToStakeAmountByPeriod[to][stakeEnd];
                    delete userToStakeAmountByPeriod[to][stakeEnd];
                    userToStakeEnds[to].remove(stakeEnd);
                }
            }
        }

        require(amountToCollect == 0, "Staking: Not enough staked amount!");
        totalHyveStaked -= amount;
        IERC20Upgradeable(hyveTokenAddress).safeTransfer(to, amount);
    }

    function checkStakingPeriod() public {
        if (lockingPeriodEnd + earningDuration <= block.timestamp) {
            // got into a new locking period
            // modify state variables that indicate the current locking period
            storeCollectedAmountsForCurrentMonth();
            uint256 endOfLastMonth = lockingPeriodEnd + earningDuration;
            uint256 nrMonthsSinceLastCompute = (block.timestamp - endOfLastMonth) / (lockingDuration + earningDuration);

            lockingPeriodEnd = endOfLastMonth + (nrMonthsSinceLastCompute * (lockingDuration + earningDuration)) + lockingDuration;
        }
        lastCheckedTimestamp = block.timestamp;
    }

    function storeCollectedAmountsForCurrentMonth() private {
        uint256 endOfCurrentPeriod = lockingPeriodEnd + earningDuration;
        dataForTimeIntervals[endOfCurrentPeriod].periodEnd = endOfCurrentPeriod;
        dataForTimeIntervals[endOfCurrentPeriod].amountStaked = totalHyveStaked;
    }

    function computeRewardPercent(uint256 userStakedAmount, uint256 totalAmount) pure private returns (uint256){
        return ((userStakedAmount * BIGNUMBER) / totalAmount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/AccessLevel.sol";
import "./utils/ERC20Taker.sol";
import "./interfaces/IEscrow.sol";

contract Escrow is IEscrow, AccessLevel, ERC20Taker {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    mapping(uint256 => EscrowDeposit) private _deposits;

    event DepositCreated(uint256 listingId, string ltype, uint256 id, address from, address token, uint256 amount);
    event DepositWithdrawal(uint256 listingId, string ltype, uint256 id, address beneficiary, uint256 amount);

    function initialize(address owner) initializer public {
        __AccessLevel_init(owner);
    }

    function getDepositId(uint256 listingId, string calldata listingType) private pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(listingType, listingId)));
    }

    function createDeposit(address mediator, uint256 listingId, string calldata listingType, address from, address tokenAddress, uint256 amount) override external onlyRole(OPERATOR_ROLE) {
        require(tokenAddress != address(0), "Escrow: Token address is 0");
        uint256 depositId = getDepositId(listingId, listingType);
        require(!depositExistsWithId(depositId), "Escrow: A deposit has already been created");

        createNewDeposit(depositId, from, tokenAddress, amount);

        takeERC20(ERC20Sender(mediator), from, IERC20Upgradeable(tokenAddress), amount);
        emit DepositCreated(listingId, listingType, depositId, from, tokenAddress, amount);
    }

    function createDepositETH(uint256 listingId, string calldata listingType, address from, uint256 amount) override external payable {
        require(amount == msg.value, "Escrow: Sent amount not equal to amount as parameter");
        uint256 depositId = getDepositId(listingId, listingType);
        require(!depositExistsWithId(depositId), "Escrow: A deposit has already been created");
        createNewDeposit(depositId, from, address(0), msg.value);
        emit DepositCreated(listingId, listingType, depositId, from, address(0), amount);
    }

    function setBeneficiary(uint256 listingId, string calldata listingType, address beneficiary) override external onlyRole(OPERATOR_ROLE) {
        uint256 depositId = getDepositId(listingId, listingType);
        require(beneficiary != address(0), "Escrow: Beneficiary address should not be 0");
        require(depositExistsWithId(depositId), "Escrow: Deposit should already exist!");
        _deposits[depositId].beneficiary = beneficiary;
    }

    function depositExistsWithId(uint256 depositId) private view returns (bool) {
        return _deposits[depositId].initialDeposit != 0;
    }

    function createNewDeposit(
        uint256 depositId,
        address from,
        address token,
        uint256 amount
    ) private {
        require(from != address(0), "Escrow: Sender address should not be 0");
        require(depositId >= 0, "Escrow: Task id is not valid");
        require(amount > 0, "Escrow: Deposit amount should be more than 0");

        _deposits[depositId] = EscrowDeposit(from, token, amount, address(0));
    }

    function executePayment(uint256 listingId, string calldata listingType) override external onlyRole(OPERATOR_ROLE) {
        uint256 depositId = getDepositId(listingId, listingType);
        require(depositExistsWithId(depositId), "Escrow: No deposit has been created for given task id!");
        transferDeposit(depositId, _deposits[depositId].beneficiary, _deposits[depositId].initialDeposit);

        emit DepositWithdrawal(listingId, listingType, depositId, _deposits[depositId].beneficiary, _deposits[depositId].initialDeposit);
    }

    function getEscrowDeposit(uint256 listingId, string calldata listingType) override external view returns (EscrowDeposit memory) {
        uint256 depositId = getDepositId(listingId, listingType);
        require(depositId >= 0, "Escrow: Deposit id is not valid");
        return _deposits[depositId];
    }

    function splitDeposit(uint256 listingId, string calldata listingType, uint256 paymentPercentage) override external onlyRole(ARBITER_ROLE) {
        uint256 depositId = getDepositId(listingId, listingType);
        require(depositExistsWithId(depositId), "Escrow: No deposit has been created for given task id!");

        uint256 depositedAmount = _deposits[depositId].initialDeposit;
        uint256 amountForApplicant = depositedAmount * paymentPercentage / 100;
        uint256 amountForOwner = depositedAmount - amountForApplicant;

        transferDeposit(depositId, _deposits[depositId].beneficiary, amountForApplicant);
        emit DepositWithdrawal(listingId, listingType, depositId, _deposits[depositId].beneficiary, amountForApplicant);
        transferDeposit(depositId, _deposits[depositId].from, amountForOwner);
        emit DepositWithdrawal(listingId, listingType, depositId, _deposits[depositId].from, amountForOwner);
    }

    function redeemDeposit(uint256 listingId, string calldata listingType) override external onlyRole(OPERATOR_ROLE) {
        uint256 depositId = getDepositId(listingId, listingType);
        require(depositExistsWithId(depositId), "Escrow: No deposit has been created for given task id!");

        transferDeposit(depositId, _deposits[depositId].from, _deposits[depositId].initialDeposit);
        emit DepositWithdrawal(listingId, listingType, depositId, _deposits[depositId].from, _deposits[depositId].initialDeposit);
    }

    function transferDeposit(uint256 depositId, address beneficiary, uint256 amount) private {
        require(amount <= _deposits[depositId].initialDeposit, "Escrow: Amount too large");
        require(amount > 0, "Escrow not enough funds");

        if (_deposits[depositId].tokenAddress == address(0)) {
            //@dev - please make sure deposit amount is zeroed before transferring ETH to avoid re-entrancy attack
            delete _deposits[depositId];
            payable(beneficiary).call{value : amount}("");
        } else {
            address tokenAddress = _deposits[depositId].tokenAddress;
            delete _deposits[depositId];
            IERC20Upgradeable(tokenAddress).safeTransfer(beneficiary, amount);
        }
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

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}