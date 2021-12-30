// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interface/IManager.sol";

/**
   @title Archive contract
   @dev This contract archives the `saleID` that was canceled
*/
contract Archive is Ownable {
    struct OnSale {
        uint256 amount;
        bool locked;
    }

    //  Address of Manager contract
    IManager public manager;

    //  A mapping list of current on sale amount of one NFT1155 item
    mapping(uint256 => OnSale) public currentOnSale;

    //  A list of previous SaleIds
    mapping(uint256 => bool) public prevSaleIds;

    modifier onlyAuthorize() {
        require(
            _msgSender() == manager.vendor(), "Unauthorized "
        );
        _;
    }

    constructor(address _manager) Ownable() {
        manager = IManager(_manager);
    }

    /**
        @notice Change a new Manager contract
        @dev Caller must be Owner
        @param _newManager       Address of new Manager contract
    */
    function updateManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Set zero address");
        manager = IManager(_newManager);
    }

    /**
        @notice Query an amount of item that is current 'on sale'
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getCurrentOnSale(uint256 _saleId) external view returns (uint256 _currentAmt) {
        _currentAmt = currentOnSale[_saleId].amount;
    }

    /**
        @notice Update new amount of item that is 'on sale'
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
        @param _newAmt          New amount is 'on sale'  
    */
    function setCurrentOnSale(uint256 _saleId, uint256 _newAmt) external onlyAuthorize {
        currentOnSale[_saleId].amount = _newAmt;
    }

    /**
        @notice Query locking state of one `saleId`
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getLocked(uint256 _saleId) external view returns (bool _locked) {
        _locked = currentOnSale[_saleId].locked;
    }

    /**
        @notice Set locking state of one `saleId`
            Note: Once locking state of one `saleId` is set, it cannot be reset
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function setLocked(uint256 _saleId) external onlyAuthorize {
        currentOnSale[_saleId].locked = true;
    }

    /**
        @notice Archive `saleId`
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function archive(uint256 _saleId) external onlyAuthorize {
        prevSaleIds[_saleId] = true;
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
    constructor () {
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
pragma solidity ^0.8.0;

interface IManager {
    function treasury() external view returns (address);
    function verifier() external view returns (address);
    function vendor() external view returns (address);
    function acceptedPayments(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}