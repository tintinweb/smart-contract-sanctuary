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
        return msg.data;
    }
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.co2ken.io
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IContractRegistry.sol';

// the ContractRegistry can be utilized by other contracts to query the whitelisted contracts
contract ContractRegistry is Ownable, IContractRegistry {
    address private _batchCollectionAddress;
    address private _carbonProjectsAddress;
    address private _ProjectERC20FactoryAddress;
    address private _RetirementBadgeCollectionAddress;

    mapping(address => bool) public projectVintageERC20Registry;

    // Currently not used, replaced by OnlyBy modifier
    modifier onlyFactory() {
        require(
            _ProjectERC20FactoryAddress != address(0),
            'ProjectERC20FactoryAddress not set'
        );
        require(
            _ProjectERC20FactoryAddress == _msgSender(),
            'Caller is not the factory'
        );
        _;
    }

    modifier OnlyBy(address _factory, address _owner) {
        require(
            _factory == _msgSender() || _owner == _msgSender(),
            'Caller is not the factory'
        );

        _;
    }

    // --- Setters ---

    function setCarbonProjectsAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Error: zero address provided');
        _carbonProjectsAddress = _address;
    }

    function setBatchCollectionAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Error: zero address provided');
        _batchCollectionAddress = _address;
    }

    function setProjectERC20FactoryAddress(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), 'Error: zero address provided');
        _ProjectERC20FactoryAddress = _address;
    }

    function setRetirementBadgeCollectionAddress(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), 'Error: zero address provided');
        _RetirementBadgeCollectionAddress = _address;
    }

    // Security: function should only be called by owner or tokenFactory
    function addERC20(address _address)
        external
        override
        OnlyBy(_ProjectERC20FactoryAddress, owner())
    {
        projectVintageERC20Registry[_address] = true;
    }

    // --- Getters ---

    function batchCollectionAddress() external view override returns (address) {
        return _batchCollectionAddress;
    }

    function carbonProjectsAddress() external view override returns (address) {
        return _carbonProjectsAddress;
    }

    function projectERC20FactoryAddress()
        external
        view
        override
        returns (address)
    {
        return _ProjectERC20FactoryAddress;
    }

    function retirementBadgeCollectionAddress()
        external
        view
        override
        returns (address)
    {
        return _RetirementBadgeCollectionAddress;
    }

    function checkERC20(address _address)
        external
        view
        override
        returns (bool)
    {
        return projectVintageERC20Registry[_address];
    }
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.co2ken.io
pragma solidity ^0.8.0;

interface IContractRegistry {
    function batchCollectionAddress() external view returns (address);

    function carbonProjectsAddress() external view returns (address);

    function projectERC20FactoryAddress() external view returns (address);

    function retirementBadgeCollectionAddress() external view returns (address);

    function checkERC20(address _address) external view returns (bool);

    function addERC20(address _address) external;
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
    "runs": 20000
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