pragma solidity ^0.6.12;

import "./ControllerStorage.sol";

contract ControllerDelegator is ControllerAdminStorage {

    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address _WETH,
        address _implementation
    ) public {
        admin = msg.sender;
        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(address)",
                _WETH
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable{}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }
}

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ControllerAdminStorage is Ownable {
    address public admin;

    address public implementation;
}

contract ControllerStorage is ControllerAdminStorage {
    struct WithdrawSetting {
        address strategy;
        uint256[] tokenLimit;
    }
    struct WithdrawSettingInfo{
        WithdrawSetting[] withdrawSettings;
        address[] tokens;
    }
    address public WETH;
    address public strategist;
    mapping(address => mapping(address => bool)) public acceptedPools;
    //mapping(address => address[]) public poolStrategies; //pool在哪些策略中有资金
    mapping(address => mapping(address => bool)) public approvedStrategies; //pool ID => strategy合约地址 => 在poolStrategies中的index加一(0表示未使用该策略)
    //mapping(address => mapping(address => uint256)) public poolAmountInStrategy; //pool在策略中的资金数量
    mapping(address => WithdrawSettingInfo) internal withdrawSettingInfos;
    address[] public fixedPools;
    address[] public flexiblePools;
    mapping(address => bool) public acceptedStrategies;
    address[] public strategies; //策略数组
    mapping(address => uint256) public allocatedProfit;
    address public sVaultNetValue;
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

