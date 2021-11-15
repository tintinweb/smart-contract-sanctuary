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

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity ^0.8.0;

interface IToucanContractRegistry {
    function carbonOffsetBatchesAddress() external view returns (address);

    function carbonProjectsAddress() external view returns (address);

    function carbonProjectVintagesAddress() external view returns (address);

    function projectERC20FactoryAddress() external view returns (address);

    function carbonOffsetBadgesAddress() external view returns (address);

    function checkERC20(address _address) external view returns (bool);

    function addERC20(address _address) external;
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IToucanContractRegistry.sol';

// the ToucanContractRegistry can be utilized by other contracts to query the whitelisted contracts
contract ToucanContractRegistry is Ownable, IToucanContractRegistry {
    address private _carbonOffsetBatchesAddress;
    address private _carbonProjectsAddress;
    address private _carbonProjectVintagesAddress;
    address private _toucanCarbonOffsetsFactoryAddress;
    address private _carbonOffsetBadgesAddress;

    mapping(address => bool) public projectVintageERC20Registry;

    modifier onlyBy(address _factory, address _owner) {
        require(
            _factory == _msgSender() || _owner == _msgSender(),
            'Caller is not the factory'
        );
        _;
    }

    // --- Setters ---

    function setCarbonOffsetBatchesAddress(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), 'Error: zero address provided');
        _carbonOffsetBatchesAddress = _address;
    }

    function setCarbonProjectsAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Error: zero address provided');
        _carbonProjectsAddress = _address;
    }

    function setCarbonProjectVintagesAddress(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), 'Error: zero address provided');
        _carbonProjectVintagesAddress = _address;
    }

    function setToucanCarbonOffsetsFactoryAddress(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), 'Error: zero address provided');
        _toucanCarbonOffsetsFactoryAddress = _address;
    }

    function setCarbonOffsetBadgesAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Error: zero address provided');
        _carbonOffsetBadgesAddress = _address;
    }

    // Security: function should only be called by owner or tokenFactory
    function addERC20(address _address)
        external
        override
        onlyBy(_toucanCarbonOffsetsFactoryAddress, owner())
    {
        projectVintageERC20Registry[_address] = true;
    }

    // --- Getters ---

    function carbonOffsetBatchesAddress()
        external
        view
        override
        returns (address)
    {
        return _carbonOffsetBatchesAddress;
    }

    function carbonProjectsAddress() external view override returns (address) {
        return _carbonProjectsAddress;
    }

    function carbonProjectVintagesAddress()
        external
        view
        override
        returns (address)
    {
        return _carbonProjectVintagesAddress;
    }

    function projectERC20FactoryAddress()
        external
        view
        override
        returns (address)
    {
        return _toucanCarbonOffsetsFactoryAddress;
    }

    function carbonOffsetBadgesAddress()
        external
        view
        override
        returns (address)
    {
        return _carbonOffsetBadgesAddress;
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

