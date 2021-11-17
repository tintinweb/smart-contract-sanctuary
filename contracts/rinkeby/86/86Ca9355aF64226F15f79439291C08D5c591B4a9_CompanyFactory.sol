// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Battambang
* CompanyFactory contract to instantiate Campaign contracts
/******************************************************************************/

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../contracts/Campaign.sol";

contract CompanyFactory is Initializable, OwnableUpgradeable {
    address[] public deployedCampaigns;
    string public companyName;

    /**
     * @dev Initializes the contract.
     */
    function initialize(string memory currentCompanyName) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        companyName = currentCompanyName;
    }

    /**
     * @dev creates campaign contracts.
     */
    function createTrustedCampaign(uint256 minimum) public {
        address newTrustedCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(newTrustedCampaign);
    }

    /**
     * @dev gets the address list of the deployed campaigns.
     */
    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Battambang
* Campaign contract to manage crowdfunding campaign.
/******************************************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/interfaces/IRequest.sol";

contract Campaign is Ownable, IRequest {
    mapping(uint256 => Request) public requests;
    uint256 private currentRequestIndex;
    address public manager;
    uint256 public minimumContribution;
    uint256 public creationTime;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    /**
     * @dev Initializes the contract.
     */
    constructor(uint256 minimum, address creator) {
        manager = creator;
        transferOwnership(manager);
        minimumContribution = minimum;
        creationTime = block.timestamp;
    }

    /**
     * @dev contributes by a contributor with a defined minimal contribution.
     */
    function contribute() external payable {
        require(
            msg.value > minimumContribution,
            "Insufficient minimum contribution"
        );
        approvers[msg.sender] = true;
        approversCount++;
    }

    /**
     * @dev creates a request in order to transfer an amount of fund.
     * Only the contract owner can call.
     */
    function createRequest(
        string memory description,
        uint256 value,
        address payable recipient
    ) external onlyOwner {
        Request storage newRequest = requests[currentRequestIndex];
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        currentRequestIndex++;
    }

    /**
     * @dev approves a request by an allowed contributor.
     * Only the contributors can execute.
     */
    function approveRequest(uint256 index) external {
        Request storage request = requests[index];
        require(approvers[msg.sender], "Permission denied : not contributor");
        require(
            !request.approvals[msg.sender],
            "Not allowed : already approved"
        );
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    /**
     * @dev finalizes a request if half of the approvers approve.
     * Fund transfer is executed.
     * Only the contract owner can call.
     */
    function finalizeRequest(uint256 index) external onlyOwner {
        Request storage request = requests[index];
        require(
            request.approvalCount > (approversCount / 2),
            "Not enough approvals"
        );
        require(!request.complete, "Request already finalized");
        request.recipient.transfer(request.value);
        request.complete = true;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Battambang
* Interface to manage request to make payment.
/******************************************************************************/

interface IRequest {
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    /**
     * @dev creates a request in order to transfer an amount of fund.
     */
    function createRequest(
        string memory description,
        uint256 value,
        address payable recipient
    ) external;

    /**
     * @dev approves a request by an allowed contributor.
     */
    function approveRequest(uint256 index) external;

    /**
     * @dev finalizes a request if half of the approvers approve.
     * Fund transfer is executed.
     * Only the contract owner can call.
     */
    function finalizeRequest(uint256 index) external;
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