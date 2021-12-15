// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface OpDefaultInterface {
    function enable(address user) external;

    function setAccountCenter(address _accountCenter) external;
}

contract AccountCenter is Ownable {

    // totally account count
    uint256 public accountCount;

    // Account Type ID count
    uint256 accountTypeCount;

    // Account Type ID -> accountProxyTemplateAddress
    mapping(uint256 => address) accountProxyTemplate;

    // EOA -> AccountType -> SmartAccount
    mapping(address => mapping(uint256 => address)) accountBook;

    // Account Type ID -> account count in this type
    mapping(uint256 => uint256) accountOfTypeCount;

    // SmartAccount -> EOA
    mapping(address => address) eoaBook;

    // SmartAccount -> TypeID
    mapping(address => uint256) SmartAccountType;

    event AddNewAccountType(uint256 accountTypeID, address acountProxyAddress);
    event UpdateAccountType(uint256 accountTypeID, address acountProxyAddress);
    event CreateAccount(address EOA, address account, uint256 accountTypeID);

    function addNewAccountType(address acountProxyAddress) external onlyOwner {
        require(
            acountProxyAddress != address(0),
            "CHFRY: acountProxyAddress should not be 0"
        );
        accountTypeCount = accountTypeCount + 1;
        accountProxyTemplate[accountTypeCount] = acountProxyAddress;
        emit AddNewAccountType(accountTypeCount, acountProxyAddress);
    }

    function updateAccountType(address acountProxyAddress, uint256 accountTypeID) external onlyOwner {
        require(
            acountProxyAddress != address(0),
            "CHFRY: acountProxyAddress should not be 0"
        );
        require(
            accountProxyTemplate[accountTypeID] != address(0),
            "CHFRY: account Type not exist"
        );
        accountProxyTemplate[accountTypeID] = acountProxyAddress;
        emit UpdateAccountType(accountTypeID, acountProxyAddress);
    }

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account)
    {
        require(
            accountBook[msg.sender][accountTypeID] == address(0),
            "CHFRY: account exist"
        );
        _account = cloneAccountProxy(accountTypeID);
        accountBook[msg.sender][accountTypeID] = _account;
        accountCount = accountCount + 1;
        accountOfTypeCount[accountTypeID] =
            accountOfTypeCount[accountTypeID] +
            1;
        eoaBook[_account] = msg.sender;
        SmartAccountType[_account] = accountTypeID;
        OpDefaultInterface(_account).setAccountCenter(address(this));
        OpDefaultInterface(_account).enable(msg.sender);
        emit CreateAccount(msg.sender, _account, accountTypeID);
    }

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account)
    {
        _account = accountBook[msg.sender][accountTypeID];
        require(
            accountBook[msg.sender][accountTypeID] != address(0),
            "account not exist"
        );
    }

    function getEOA(address account) external view returns (address  _eoa) {
        require(account != address(0),"CHFRY: address should not be 0");
        _eoa = eoaBook[account];
    }

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount)
    {
        require(_address != address(0),"CHFRY: address should not be 0");
        if (eoaBook[_address] == address(0)) {
            _isAccount = false;
        } else {
            _isAccount = true;
        }
    }

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount)
    {
        require(_address != address(0),"CHFRY: address should not be 0");
        if (SmartAccountType[_address] == accountTypeID) {
            _isAccount = true;
        } else {
            _isAccount = false;
        }
    }

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count)
    {
        count = accountOfTypeCount[accountTypeID];
    }

    function cloneAccountProxy(uint256 accountTypeID)
        internal
        returns (address accountAddress)
    {
        address accountProxyTemplateAddress = accountProxyTemplate[
            accountTypeID
        ];
        require(
            accountProxyTemplateAddress != address(0),
            "CHFRY: accountProxyTemplateAddress not found"
        );
        bytes20 targetBytes = bytes20(accountProxyTemplateAddress);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            accountAddress := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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