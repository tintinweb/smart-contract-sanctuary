// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import '../repricers/IRepricer.sol';
import '../libs/complifi/registries/AddressRegistryParent.sol';

contract RepricerRegistry is AddressRegistryParent {
    function generateKey(address _value) public view override returns (bytes32 _key) {
        require(IRepricer(_value).isRepricer(), 'Should be repricer');
        return keccak256(abi.encodePacked(IRepricer(_value).symbol()));
    }
}

// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import '../libs/complifi/IVaultMinimal.sol';

interface IRepricer {
    function isRepricer() external pure returns (bool);

    function symbol() external pure returns (string memory);

    function reprice(
        IVaultMinimal _vault,
        uint256 _pMin,
        int256 _repricerParam1,
        int256 _repricerParam2
    )
        external
        view
        returns (
            int256 estPricePrimary,
            int256 estPriceComplement,
            uint256 estPrice,
            uint256 upperBoundary
        );

    function sqrtWrapped(int256 x) external pure returns (int256);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAddressRegistry.sol";

abstract contract AddressRegistryParent is Ownable, IAddressRegistry {
    mapping(bytes32 => address) internal _registry;

    event AddressAdded(bytes32 _key, address _value);

    function generateKey(address _value)
        public
        view
        virtual
        returns (bytes32 _key)
    {
        return keccak256(abi.encodePacked(_value));
    }

    function set(address _value) external override onlyOwner() {
        bytes32 key = generateKey(_value);
        _check(key, _value);
        emit AddressAdded(key, _value);
        _registry[key] = _value;
    }

    function get(bytes32 _key) external view override returns (address) {
        return _registry[_key];
    }

    function _check(bytes32 _key, address _value) internal virtual {
        require(_value != address(0), "Nullable address");
        require(_registry[_key] == address(0), "Key already exists");
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "./IDerivativeSpecificationMinimal.sol";

interface IVaultMinimal {

    function settleTime() external view returns (uint256);

    function derivativeSpecification()
    external
    view
    returns (IDerivativeSpecificationMinimal);

    function collateralToken() external view returns (address);

    function primaryToken() external view returns (address);

    function complementToken() external view returns (address);

    function underlyingStarts(uint256 index) external view returns (int256);

    function oracles(uint256 index) external view returns (address);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IDerivativeSpecificationMinimal {

    function primaryNominalValue() external view returns (uint256);

    function complementNominalValue() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
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

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IAddressRegistry {
    function get(bytes32 _key) external view returns (address);

    function set(address _value) external;
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

