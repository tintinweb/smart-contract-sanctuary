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
import "../proxy/utils/Initializable.sol";

/*
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IEthSignSAModeratorContract.sol";

contract EthSignSAModeratorContract is
    OwnableUpgradeable,
    IEthSignSAModeratorContract
{
    mapping(address => uint256) private disputedBalanceMapping;
    mapping(address => IERC20) private disputedTokenContractMapping;

    function initialize() public initializer {
        __Ownable_init();
    }

    function receiveDisputedFunds(IERC20 tokenContract) external override {
        require(
            disputedBalanceMapping[_msgSender()] == 0 &&
                disputedTokenContractMapping[_msgSender()] == IERC20(address(0))
        );
        uint256 balance = tokenContract.balanceOf(_msgSender());
        require(
            tokenContract.transferFrom(_msgSender(), address(this), balance),
            "AM: Transfer failed"
        );
        disputedBalanceMapping[_msgSender()] = balance;
        disputedTokenContractMapping[_msgSender()] = tokenContract;
        emit EthSignSAModeratorReceivedDisputedFunds(
            address(tokenContract),
            _msgSender(),
            balance
        );
    }

    function resolveDisputedFunds(address triggerContract, address recipient)
        external
        override
        onlyOwner
    {
        IERC20 tokenContract = disputedTokenContractMapping[triggerContract];
        uint256 balance = disputedBalanceMapping[triggerContract];
        require(
            tokenContract.transfer(recipient, balance),
            "AM: Transfer failed"
        );
        emit EthSignSAModeratorResolvedDisputedFunds(
            address(tokenContract),
            triggerContract,
            recipient,
            balance
        );
    }

    function getDisputedFundsInfo(address triggerContract)
        external
        view
        override
        returns (IERC20 tokenContract, uint256 amount)
    {
        tokenContract = disputedTokenContractMapping[triggerContract];
        amount = disputedBalanceMapping[triggerContract];
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEthSignSAExecutorContract {
    function getInfo()
        external
        view
        returns (
            address sender,
            address beneficiary,
            bytes32 rewardsHash,
            uint256 currentIndex
        );

    function depositEscrow() external;

    function execute() external returns (bool);

    function refundEscrow(bytes calldata beneficiarySignature) external;

    function handleDispute() external;

    event EthSignSAExecutorEscrowDepositReceived(
        address tokenContract,
        address beneficiary,
        uint256 amount
    );

    event EthSignSAExecutorEscrowDepositRefunded(uint256 amount);

    event EthSignSAExecutorExecuted(address beneficiary, uint256 payoutAmount);

    event EthSignSAExecutorDisputeHandled();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEthSignSATriggerContract.sol";

interface IEthSignSAModeratorContract {
    function receiveDisputedFunds(IERC20 tokenContract) external;

    function resolveDisputedFunds(address triggerContract, address recipient)
        external;

    function getDisputedFundsInfo(address triggerContract)
        external
        view
        returns (IERC20 tokenContract, uint256 amount);

    event EthSignSAModeratorReceivedDisputedFunds(
        address tokenContract,
        address triggerContract,
        uint256 amount
    );

    event EthSignSAModeratorResolvedDisputedFunds(
        address tokenContract,
        address triggerContract,
        address recipient,
        uint256 amount
    );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IEthSignSATriggerContract.sol";
import "./IEthSignSAExecutorContract.sol";

interface IEthSignSARegistryContract {
    function registerTrigger(
        IEthSignSATriggerContract trigger,
        IEthSignSAExecutorContract executor
    ) external;

    function getTriggerRegisteredExecutor(IEthSignSATriggerContract trigger)
        external
        view
        returns (address);

    function getExecutorRegisteredTrigger(IEthSignSAExecutorContract executor)
        external
        view
        returns (address);

    event EthSignSAAddedTrustedFactory(address factory);
    event EthSignSARevokedTrustedFactory(address factory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IEthSignSAExecutorContract.sol";
import "./IEthSignSARegistryContract.sol";
import "./IEthSignSAModeratorContract.sol";

interface IEthSignSATriggerContract {
    function register(
        IEthSignSARegistryContract registry,
        IEthSignSAModeratorContract moderator,
        IEthSignSAExecutorContract executor
    ) external;

    function getInfo()
        external
        view
        returns (
            address sender,
            address beneficiary,
            bytes32 rewardsHash,
            uint256 currentIndex
        );

    event EthSignSAUpkeepPerformed();
    event EthSignSAResultReceived(bytes32 expected, bytes32 actual);
    event EthSignSAExecutionTriggered(string url);
    event EthSignSATriggerFundsReclaimed(uint256 link);
    event EthSignSAJobCompleted();
    event EthSignSAInconsistencyDetected();
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}