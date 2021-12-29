// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
import "./OwnableV2.sol";

contract ClearAccessControl is OwnableV2 {
    address public DAO;

    mapping(address => mapping(bytes4 => bool)) public methods;

    event CallExecuted(address target, uint256 value, bytes data);
    event AddDAOMethod(address _target, bytes4 _method);
    event UpdateDAO(address _DAO);

    constructor(address _owner, address _DAO) public {
        setOwner(_owner);
        DAO = _DAO;
    }

    function setDao(address _DAO) external onlyOwner {
        require(DAO == address(0), "DAO not null");
        DAO = _DAO;
        emit UpdateDAO(_DAO);
    }

    function addDaoMethod(address _target, bytes4 _method) external onlyOwner {
        require(!methods[_target][_method], "repeat operation");
        methods[_target][_method] = true;
        emit AddDAOMethod(_target, _method);
    }

    modifier checkRole(address _target, bytes memory _data) {
        bytes4 _method;
        assembly {
            _method := mload(add(_data, 32))
        }
        if (_msgSender() == owner()) {
            require(!methods[_target][_method], "owner error");
        } else if (_msgSender() == DAO) {
            require(methods[_target][_method], "owner error");
        } else {
            revert();
        }
        _;
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes memory data
    ) public payable checkRole(target, data) {
        _call(target, value, data);
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        address target,
        uint256 value,
        bytes memory data
    ) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = target.call{value: value}(data);
        require(success, "transaction reverted");
        emit CallExecuted(target, value, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract OwnableV2 is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setOwner(address newOwner) internal {
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