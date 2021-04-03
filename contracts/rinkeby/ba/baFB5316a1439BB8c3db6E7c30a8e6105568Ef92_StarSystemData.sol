// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    struct SysData {
        bytes32 map;
        address owner;
    }

    uint public numSystems;
    mapping(uint => SysData) public sysData; // [sysId]
    mapping(address => bool) public dataEditors;

    event StarSystemMapSet(uint indexed _sysId, bytes32 _newMap);
    event StarSystemOwnerSet(uint indexed _sysId, address indexed _owner);
    event StarSystemDataCleared(uint indexed _sysId);

    modifier onlyDataEditor {
        require(dataEditors[msg.sender], "Unauthorised to change system data");
        _;
    }

    function ownerOf(uint _sysId) public view returns (address) { return sysData[_sysId].owner; }
    function mapOf(uint _sysId) external view returns (bytes32) { return sysData[_sysId].map; }

    function setDataEditor(address _editor, bool _added) external onlyOwner { 
        dataEditors[_editor] = _added; 
    }

    function setOwner(uint _sysId, address _owner) public onlyDataEditor {
        require(_owner != address(0), "_owner cannot be null");
        if(ownerOf(_sysId) == address(0)) {
            numSystems++;
        }
        sysData[_sysId].owner = _owner;
        emit StarSystemOwnerSet(_sysId, _owner);
    }

    function setMap(uint _sysId, bytes32 _sysMap) public onlyDataEditor {
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        sysData[_sysId].map = _sysMap;
        emit StarSystemMapSet(_sysId, _sysMap);
    }

    function setSystemData(uint _sysId, address _owner, bytes32 _sysMap) external onlyDataEditor {
        setOwner(_sysId, _owner);
        setMap(_sysId, _sysMap);
    }

    function clearSystemData(uint _sysId) external onlyDataEditor {
        require(ownerOf(_sysId) != address(0), "system data not set");
        numSystems--;
        delete sysData[_sysId];
        emit StarSystemDataCleared(_sysId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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