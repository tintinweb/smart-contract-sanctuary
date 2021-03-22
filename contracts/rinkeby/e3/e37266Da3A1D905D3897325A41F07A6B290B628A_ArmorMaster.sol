// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.0;

import "../general/Ownable.sol";
import "../interfaces/IArmorMaster.sol";
import "../general/Keeper.sol";

/**
 * @dev ArmorMaster controls all jobs, address, and ownership in the Armor Core system.
 *      It is used when contracts call each other, when contracts restrict functions to
 *      each other, when onlyOwner functionality is needed, and when keeper functions must be run.
 * @author Armor.fi -- Taek Lee
**/
contract ArmorMaster is Ownable, IArmorMaster {
    mapping(bytes32 => address) internal _modules;

    // Keys for different jobs to be run. A job correlates to an address with a keep()
    // function, which is then called to run maintenance functions on the contract.
    bytes32[] internal _jobs;

    function initialize() external {
        Ownable.initializeOwnable();
        _modules[bytes32("MASTER")] = address(this);
    }

    /**
     * @dev Register a contract address with corresponding job key.
     * @param _key The key that will point a job to an address.
    **/
    function registerModule(bytes32 _key, address _module) external override onlyOwner {
        _modules[_key] = _module;
    }

    function getModule(bytes32 _key) external override view returns(address) {
        return _modules[_key];
    }

    /**
     * @dev Add a new job that correlates to a registered module.
     * @param _key Key of the job used to point to module.
    **/
    function addJob(bytes32 _key) external onlyOwner {
        require(_jobs.length < 3, "cannot have more than 3 jobs");
        require(_modules[_key] != address(0), "module is not listed");
        for(uint256 i = 0; i< _jobs.length; i++){
            require(_jobs[i] != _key, "already registered");
        }
        _jobs.push(_key);
    }

    function deleteJob(bytes32 _key) external onlyOwner {
        for(uint256 i = 0; i < _jobs.length; i++) {
            if(_jobs[i] == _key) {
                _jobs[i] = _jobs[_jobs.length - 1];
                _jobs.pop();
                return;
            }
        }
        revert("job not found");
    }

    /**
     * @dev Anyone can call keep to run jobs in this system that need to be periodically done.
     *      To begin with, these jobs including expiring plans and expiring NFTs.
    **/
    function keep() external override {
        for(uint256 i = 0; i < _jobs.length; i++) {
            IKeeperRecipient(_modules[_jobs[i]]).keep();
        }
    }

    function jobs() external view returns(bytes32[] memory) {
        return _jobs;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IKeeperRecipient {
    function keep() external;
}