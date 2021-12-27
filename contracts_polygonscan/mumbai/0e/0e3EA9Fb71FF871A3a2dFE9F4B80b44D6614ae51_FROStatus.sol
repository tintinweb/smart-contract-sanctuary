// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../address/FROAddressesProxy.sol";
import "../interfaces/IStatus.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FROStatus is IStatus, Ownable, FROAddressesProxy {
    constructor(address registry_) FROAddressesProxy(registry_) {}

    // mapping(tokenId => Status)
    mapping(uint => IStatus.Status) private status;
    // mapping(tokenId => color)
    mapping(uint => uint8) public override color;
    // mapping(tokenId => weapon)
    mapping(uint => uint8) public override weapon;

    function getStatus(uint tokenId)
        external
        view
        override
        returns (IStatus.Status memory)
    {
        return status[tokenId];
    }

    function setStatusByOwner(uint[] calldata _tokenIds, IStatus.Status[] calldata _status, uint8[] calldata _weapons, uint8[] calldata _colors)
        external
        override
        onlyOwner
    {
        require(
            _tokenIds.length == _status.length && _tokenIds.length == _weapons.length && _tokenIds.length == _colors.length,
            "input length must be same"
        );
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _setStatus(_tokenIds[i], _status[i]);
            _setWeapon(_tokenIds[i], _weapons[i]);
            _setColor(_tokenIds[i], _colors[i]);
        }
    }

    //TODO from check
    // function setStatus(uint tokenId, IStatus.Status calldata status_)
    //     external
    //     override
    // {
    //     
    //     _setStatus(tokenId, status_);
    // }

    function _setStatus(uint tokenId, IStatus.Status calldata status_)
        internal
    {
        status[tokenId] = status_;
    }

    function _setColor(uint _tokenId, uint8 _color)
        internal
    {
        color[_tokenId] = _color;
    }

    function _setWeapon(uint _tokenId, uint8 _weapon)
        internal
    {
        weapon[_tokenId] = _weapon;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../interfaces/IAddresses.sol";

contract FROAddressesProxy {
    IAddresses public registry;

    constructor(address registry_){
        registry = IAddresses(registry_);
    }

    modifier onlyAddress(string memory _key) {
        registry.checkRegistory(_key, msg.sender);
        _;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStatus {
    struct Status {
        uint256 hp;
        uint256 at;
        uint256 df;
        uint256 it;
        uint256 sp;
    }

    function getStatus(uint256 tokenId)
        external
        view
        returns (IStatus.Status memory);

    // function setStatus(uint256 tokenId, IStatus.Status calldata status_) external;
    function setStatusByOwner(uint[] calldata _tokenIds, IStatus.Status[] calldata _status, uint8[] calldata _weapons, uint8[] calldata _colors) external;
    function color(uint256 _tokenId) external view returns(uint8);
    function weapon(uint256 _tokenId) external view returns(uint8);
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

interface IAddresses {
    function setRegistry(string memory _key, address _addr) external;
    function getRegistry(string memory _key) external view returns (address);
    function checkRegistory(string memory _key, address _sender) external view;
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