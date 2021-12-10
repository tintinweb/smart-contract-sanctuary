// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../interfaces/IHp.sol";
import "../address/FROAddressesProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FROHp is IHp, FROAddressesProxy, Ownable {

    constructor(address registory_) FROAddressesProxy(registory_) {}

    // mapping(tokenId => hp)
    mapping(uint256 => IHp.Hp) private tokenHp;

    // これでバトル中のHPは取得不可能
    function getHp(uint256 _tokenId)
        external
        view
        override
        returns (IHp.Hp memory)
    {
        return tokenHp[_tokenId];
    }

    function setHp(uint256 _tokenId, uint256 _hp) external override {
        registry.checkRegistory("FROLogic", msg.sender);
        _setHp(_tokenId, _hp);
    }

    function setHpByMint(uint256 _tokenId, uint256 _hp) external override {
        registry.checkRegistory("FROMintLogic", msg.sender);
        _setHp(_tokenId, _hp);
    }

    function _setHp(uint256 _tokenId, uint256 _hp) internal virtual {
        tokenHp[_tokenId] = IHp.Hp(_hp, block.number);
    }

    function _reduceHp(uint256 _tokenId, uint256 _hpDiff, uint256 _blockNumber)
        internal
        returns (uint256)
    {
        // if character is dead, hp = 0
        uint256 _hp = 0;
        if (tokenHp[_tokenId].hp > _hpDiff) {
            _hp = tokenHp[_tokenId].hp - _hpDiff;
        }
        tokenHp[_tokenId] = IHp.Hp(_hp, _blockNumber);

        return _hp;        
    }

    function reduceHp(uint256 _tokenId, uint256 _hpDiff)
        external
        override
        returns (uint256)
    {
        registry.checkRegistory("FROLogic", msg.sender);
        return _reduceHp(_tokenId, _hpDiff, block.number);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHp {
    struct Hp {
        uint hp;
        uint blockNumber;
    }
    function getHp(uint256 _tokenId) external view returns(Hp memory);
    function setHp(uint256 _tokenId, uint _hp) external;
    function setHpByMint(uint256 _tokenId, uint _hp) external;
    function reduceHp(uint256 _tokenId, uint _hpDiff) external returns(uint);
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