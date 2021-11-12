//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Quest} from "./Quest.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DevInRes is Proxy, Ownable {
    function registerQuest(bytes4 sig, address questContract) public onlyOwner {
        Quest.Store storage store = Quest.store();
        require(store.questContracts[sig] == address(0), "Already registered");
        store.questContracts[sig] = questContract;
    }

    function score() public {
        Quest.solve(DevInRes(payable(address(0))).score.selector, msg.sender);
    }

    function hasSolved(bytes4 sig, address solver) public view returns (bool) {
        Quest.Store storage store = Quest.store();
        return store.solved[sig][solver];
    }

    function getQuestContract(bytes4 sig) public view returns (address) {
        Quest.Store storage store = Quest.store();
        return store.questContracts[sig];
    }

    function getScore(address solver) public view returns (uint256) {
        Quest.Store storage store = Quest.store();
        return store.leaderBoard[solver];
    }

    function _implementation() internal view override returns (address) {
        Quest.Store storage store = Quest.store();
        address questContract = store.questContracts[msg.sig];
        require(questContract != address(0), "Not a registered quest");
        return questContract;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Quest {
    event SolvedQuest(bytes4 indexed questSig, address devInRes);

    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("dev-in-res")) - 1);

    struct Store {
        address admin;
        mapping(address => uint256) leaderBoard;
        mapping(bytes4 => mapping(address => bool)) solved;
        mapping(bytes4 => address) questContracts;
    }

    function store() internal pure returns (Store storage r) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            r.slot := slot
        }
    }

    function solve(bytes4 questSig, address solver) internal {
        Store storage strg = store();
        mapping(address => bool) storage quest = strg.solved[questSig];
        require(!quest[msg.sender], "Already solved");
        quest[solver] = true;
        strg.leaderBoard[msg.sender] += 1;
        emit SolvedQuest(questSig, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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