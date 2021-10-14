// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Resolver} from "./resolvers/Resolver.sol";
import {AddressResolver} from "./resolvers/AddressResolver.sol";
import {NameResolver} from "./resolvers/NameResolver.sol";

contract ENSResolver is
    Ownable,
    AddressResolver,
    NameResolver
{
    constructor() {}

    function setAddr(
        bytes32 node,
        address _addr
    )
        external
        onlyOwner
    {
        _setAddr(node, _addr);
    }

    function setName(
        bytes32 node,
        string calldata _name
    )
        external
        onlyOwner
    {
        _setName(node, _name);
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

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IENSResolver} from "../interfaces/IENSResolver.sol";

abstract contract Resolver is IENSResolver {
    mapping(bytes4 => bool) internal _supportedInterfaces;

    constructor() {
        registerSupportedInterface(type(IERC165).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    function registerSupportedInterface(bytes4 interfaceID)
        internal
    {
        _supportedInterfaces[interfaceID] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Resolver} from "./Resolver.sol";
import {IAddressResolver} from "../interfaces/IAddressResolver.sol";

abstract contract AddressResolver is IAddressResolver, Resolver {
    bytes4 private constant _interfaceId = 0x3b3b57de;

    mapping(bytes32 => address) internal _addresses;

    constructor() {
        registerSupportedInterface(_interfaceId);
    }

    function addr(bytes32 node)
        external
        view
        returns (address)
    {
        return _addresses[node];
    }

    function _setAddr(
        bytes32 node,
        address _addr
    )
        internal
    {
        require(
            node.length != 0,
            "node cannot be empty"
        );

        require(
            _addr != address(0),
            "address cannot be zero address"
        );

        _addresses[node] = _addr;

        emit AddrChanged(node, _addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Resolver} from "./Resolver.sol";
import {INameResolver} from "../interfaces/INameResolver.sol";

abstract contract NameResolver is INameResolver, Resolver {
    bytes4 private constant _interfaceId = 0x691f3431;

    mapping(bytes32 => string) internal _names;

    constructor() {
        registerSupportedInterface(_interfaceId);
    }

    function name(bytes32 node)
        external
        view
        returns (string memory)
    {
        return _names[node];
    }

    function _setName(
        bytes32 node,
        string calldata _name
    )
        internal
    {
        require(
            node.length != 0,
            "node cannot be empty"
        );

        require(
            bytes(_name).length != 0,
            "name cannot be empty"
        );

        _names[node] = _name;

        emit NameChanged(node, _name);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IENSResolver is IERC165 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    event AddrChanged(bytes32 indexed node, address a);

    function addr(bytes32) external view returns (address);

    function setAddr(bytes32, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    function name(bytes32) external view returns (string memory);

    function setName(bytes32, string calldata) external;
}