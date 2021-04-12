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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MARGIN_CALLER = 2;
uint256 constant BORROWER = 3;
uint256 constant MARGIN_TRADER = 4;
uint256 constant FEE_SOURCE = 5;
uint256 constant LIQUIDATOR = 6;
uint256 constant AUTHORIZED_FUND_TRADER = 7;
uint256 constant INCENTIVE_REPORTER = 8;
uint256 constant TOKEN_ACTIVATOR = 9;
uint256 constant STAKE_PENALIZER = 10;

uint256 constant FUND = 101;
uint256 constant LENDING = 102;
uint256 constant MARGIN_ROUTER = 103;
uint256 constant CROSS_MARGIN_TRADING = 104;
uint256 constant FEE_CONTROLLER = 105;
uint256 constant PRICE_CONTROLLER = 106;
uint256 constant ADMIN = 107;
uint256 constant INCENTIVE_DISTRIBUTION = 108;
uint256 constant TOKEN_ADMIN = 109;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][TOKEN_ACTIVATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = true;
    }

    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        mainCharacters[role] = actor;
    }

    function getRole(uint256 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }

    /// @dev current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 30000
  },
  "remappings": [],
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