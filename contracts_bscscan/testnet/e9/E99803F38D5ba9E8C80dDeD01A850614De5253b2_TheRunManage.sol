//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Manageable.sol";

interface BEP20Token {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TheRunManage is Ownable, Manageable {
    event TheRunManageEvent(string indexed eventType, address indexed eventAddress, bytes32 indexed inEventId, uint256 eventAmount);

    address private _BEP20Address;
    address payable private _bufferAddress;
    BEP20Token private _BEP20;

    constructor(address BEP20Address, address bufferAddress, address managerAddress) Manageable(managerAddress) {
        _BEP20Address = BEP20Address;
        _bufferAddress = payable(bufferAddress);
        _BEP20 = BEP20Token(_BEP20Address);
    }

    function acceptBNB(bytes32 personalToken) public payable {
        require(msg.value > 0, 'Value must be more than 0');
        _bufferAddress.transfer(msg.value);
        emit TheRunManageEvent('AcceptBNB', msg.sender, personalToken, msg.value);
    }

    function acceptTokens(bytes32 personalToken, uint256 amount) public {
        require(amount > 0, 'Amount must be more than 0');
        require(_BEP20.transferFrom(msg.sender, _bufferAddress, amount));
        emit TheRunManageEvent('AcceptTokens', msg.sender, personalToken, amount);
    }

    function sendTokens(bytes32 requestId, address to, uint256 amount) public onlyManager {
        require(amount > 0);
        require(_BEP20.transferFrom(_bufferAddress, to, amount));
        emit TheRunManageEvent('SendTokens', to, requestId, amount);
    }

    function changeBEP20Address(address newBEP20Address) public onlyOwner {
        _BEP20Address = newBEP20Address;
        _BEP20 = BEP20Token(newBEP20Address);
    }

    function changeBufferAddress(address newBufferAddress) public onlyOwner {
        _bufferAddress = payable(newBufferAddress);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounceOwnership");
    }
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

//import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a manager) that can be granted exclusive access to
 * specific contract manage functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the initial manager.
     */
    constructor(address initialManager) {
        _setManager(initialManager);
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == _msgSender(), "Manageable: caller is not the manager");
        _;
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the owner of contract.
     */
    function transferManagership(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "Manageable: new manager is the zero address");
        _setManager(newManager);
    }

    function _setManager(address newManager) private {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagershipTransferred(oldManager, newManager);
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