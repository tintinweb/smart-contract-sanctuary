// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IENSResolver.sol";


contract Pass3Resolver is  ERC165, Ownable, IENSResolver    {

    // ============ Interfaces ============
    bytes4 constant private ADDRESS_INTERFACE_ID = bytes4(keccak256("addr(bytes32)"));
    bytes4 constant private NAME_INTERFACE_ID = bytes4(keccak256("name(bytes32)"));
    
    // ============ Structs ============
    struct Record {
        address addr;
        string name;
    }

    // ============ Mappings ============

    // mapping between namehash and resolved records
    mapping(bytes32 => Record) records;

    
    // ============ Public Functions ============

    /**
     * @notice Lets the manager set the address associated with an ENS node.
     * @param _node The node to update.
     * @param _addr The address to set.
     */
    function setAddr(bytes32 _node, address _addr) public override onlyOwner {
        records[_node].addr = _addr;
        emit AddrChanged(_node, _addr);
    }

    /**
     * @notice Lets the manager set the name associated with an ENS node.
     * @param _node The node to update.
     * @param _name The name to set.
     */
    function setName(bytes32 _node, string memory _name)
        public
        override
        onlyOwner
    {
        records[_node].name = _name;
        emit NameChanged(_node, _name);
    }

    /**
     * @notice Gets the address associated to an ENS node.
     * @param _node The target node.
     * @return the address of the target node.
     */
    function addr(bytes32 _node) public view override returns (address) {
        return records[_node].addr;
    }

    /**
     * @notice Gets the name associated to an ENS node.
     * @param _node The target ENS node.
     * @return the name of the target ENS node.
     */
    function name(bytes32 _node) public view override returns (string memory) {
        return records[_node].name;
    }
    
    function supportsInterface(bytes4 _interfaceId) override public view returns (bool) {
        return _interfaceId == ADDRESS_INTERFACE_ID ||
                _interfaceId == NAME_INTERFACE_ID ||
                super.supportsInterface(_interfaceId);
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IENSResolver {
    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

    function addr(bytes32 _node) external view returns (address);

    function setAddr(bytes32 _node, address _addr) external;

    function name(bytes32 _node) external view returns (string memory);

    function setName(bytes32 _node, string calldata _name) external;

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

