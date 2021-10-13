// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDynamicAttribute.sol";
import "../utils/AttributeClass.sol";
import "../utils/Operatable.sol";
import "../utils/Arrays.sol";

contract DynamicAttribute is
    IDynamicAttribute,
    Context,
    Ownable,
    Operatable,
    AttributeClass
{
    using Arrays for uint256[];

    struct DynamicSettings {
        string name;
        string description;
        string value;
    }

    // attribute ID => settings
    mapping(uint256 => DynamicSettings) public attrs;

    // nft ID => attributes
    mapping(uint256 => uint256[]) public nftAttrs;

    // attribute ID => nft ID => bool
    mapping(uint256 => mapping(uint256 => bool)) private _states;

    constructor() AttributeClass(2) {}

    function name(uint256 _attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return attrs[_attrId].name;
    }

    function description(uint256 _attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return attrs[_attrId].description;
    }

    function getNFTAttrs(uint256 _nftId)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return nftAttrs[_nftId];
    }

    function getValue(uint256 _attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return attrs[_attrId].value;
    }

    function create(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _value
    ) public virtual override onlyOwner {
        require(
            !_exists(_id),
            "DynamicAttribute: attribute _id already exists"
        );
        DynamicSettings memory settings = DynamicSettings({
            name: _name,
            description: _description,
            value: _value
        });
        attrs[_id] = settings;

        emit DynamicAttributeCreated(_name, _id);
    }

    function link(uint256 _nftId, uint256 _attrId)
        public
        virtual
        override
        onlyOperator
    {
        require(_exists(_attrId), "DynamicAttribute: attribute _id not exists");
        require(
            !_hasAttr(_nftId, _attrId),
            "UpgradableAttribute: nft has linked the attribute"
        );

        _states[_attrId][_nftId] = true;
        nftAttrs[_nftId].push(_attrId);

        emit DynamicAttributeLinked(_nftId, _attrId);
    }

    function change(uint256 _attrId, string memory _newValue)
        public
        virtual
        override
        onlyOperator
    {
        require(_exists(_attrId), "DynamicAttribute: attribute _id not exists");

        attrs[_attrId].value = _newValue;

        emit DynamicAttributeChanged(_attrId, _newValue);
    }

    function remove(uint256 _nftId, uint256 _attrId)
        public
        virtual
        override
        onlyOperator
    {
        require(_exists(_attrId), "DynamicAttribute: attribute _id not exists");
        require(
            _hasAttr(_nftId, _attrId),
            "UpgradableAttribute: nft has not linked the attribute"
        );

        delete _states[_attrId][_nftId];

        nftAttrs[_nftId].removeByValue(_attrId);

        emit DynamicAttributeRemoved(_nftId, _attrId);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        if (bytes(attrs[_id].name).length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function _hasAttr(uint256 _nftId, uint256 _attrId)
        internal
        view
        returns (bool)
    {
        return _states[_attrId][_nftId];
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

interface IDynamicAttribute {
    function name(uint256 _attrId) external view returns (string memory);

    function description(uint256 _attrId) external view returns (string memory);

    function getNFTAttrs(uint256 _nftId)
        external
        view
        returns (uint256[] memory);

    function getValue(uint256 _attrId) external view returns (string memory);

    function create(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _value
    ) external;

    function link(uint256 _nftId, uint256 _attrId) external;

    function remove(uint256 _nftId, uint256 _attrId) external;

    function change(uint256 _attrId, string memory newDescription) external;

    event DynamicAttributeCreated(string name, uint256 id);
    event DynamicAttributeLinked(uint256 nftId, uint256 attrId);
    event DynamicAttributeRemoved(uint256 nftId, uint256 attrId);
    event DynamicAttributeChanged(uint256 attrId, string newValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AttributeClass {
    // 1 => Upgradable,
    // 2 => Static,
    // more expand...
    uint16 private _class;

    constructor(uint16 class_) {
        _class = class_;
    }

    /**
     * @dev Returns the class of the attribute.
     */
    function getClass() public view virtual returns (uint16) {
        return _class;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Operatable is Context {
    address private _operator;

    event OperatorChanged(
        address indexed previousOperator,
        address indexed newOperator
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor() {
        address msgSender = _msgSender();
        _operator = msgSender;
        emit OperatorChanged(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(
            operator() == _msgSender(),
            "Operatable: caller is not the operator"
        );
        _;
    }

    /**
     * @dev Change operator of the contract.
     * Can only be called by the current operator.
     */
    function changeOperator(address newOperator) public virtual onlyOperator {
        require(
            newOperator != address(0),
            "Operatable: new operator is the zero address"
        );
        _operator = newOperator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    function find(uint256[] storage values, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 i = 0;
        while (values[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint256[] storage values, uint256 value) internal {
        uint256 i = find(values, value);
        delete values[i];
    }
}