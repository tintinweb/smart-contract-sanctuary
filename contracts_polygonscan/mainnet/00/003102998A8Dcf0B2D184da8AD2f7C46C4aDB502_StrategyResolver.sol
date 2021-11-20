// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.6.0;

import "Ownable.sol";

import "IStrategyFacade.sol";

/// @title Resolver contract for Gelato harvest bot
/// @author Tesseract Finance
contract StrategyResolver is Ownable {
    address public facade;

    event FacadeContractUpdated(address facade);

    constructor(address _facade) public {
        facade = _facade;
    }

    function setFacadeContract(address _facade) public onlyOwner {
        facade = _facade;

        emit FacadeContractUpdated(_facade);
    }

    function check(uint256 _callCost) external view returns (bool canExec, bytes memory execPayload) {
        (bool _canExec, address _strategy) = IStrategyFacade(facade).checkHarvest(_callCost);

        canExec = _canExec;

        execPayload = abi.encodeWithSelector(IStrategyFacade.harvest.selector, address(_strategy));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.6.0;

/// @title StrategyFacade Interface
/// @author Tesseract Finance
interface IStrategyFacade {
    /**
     * Checks if any of the strategies should be harvested
     * @dev :_callCost: must be priced in terms of wei (1e-18 ETH)
     *
     * @param _callCost - The Gelato bot's estimated gas cost to call harvest function (in wei)
     *
     * @return canExec - True if Gelato bot should harvest, false if it shouldn't
     * @return strategy - Address of the strategy contract that needs to be harvested
     */
    function checkHarvest(uint256 _callCost) external view returns (bool canExec, address strategy);

    /**
     * Call harvest function on a Strategy smart contract with the given address
     *
     * @param _strategy - Address of a Strategy smart contract which needs to be harvested
     *
     * No return, reverts on error
     */
    function harvest(address _strategy) external;
}