// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CoinXPadInvestmentsInfo
/// @notice CoinXPadInvestmentsInfo gives infromation regarding  IDO contract which is launch by ASVAFACTORY contract.
/// Ref: https://testnet.bscscan.com/address/0x3109bf9e73f50209Cf92D2459B5Da0E38D8890C1#code
contract CoinXPadInvestmentsInfo is Ownable {
    address[] private presaleAddresses;

    mapping(address => bool) public alreadyAdded;
    mapping(uint256 => address) public presaleAddressByProjectID;

    /**
     * @dev To add presale address
     *
     * Requirements:
     * - presale address cannot be address zero.
     * - presale should not be already added
     */
    function addPresaleAddress(address _presale, uint256 _presaleProjectID) external returns (uint256) {
        require(_presale != address(0), "Address cannot be a zero address");
        require(!alreadyAdded[_presale], "Address already added");

        presaleAddresses.push(_presale);
        alreadyAdded[_presale] = true;
        presaleAddressByProjectID[_presaleProjectID] = _presale;
        return presaleAddresses.length - 1;
    }

    /**
     * @dev To return presale counts
     */
    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    /**
     * @dev To get presale contract address by DB id
     */
    function getPresaleAddressByDbId(uint256 asvaDbId) external view returns (address) {
        return presaleAddressByProjectID[asvaDbId];
    }

    /**
     * @dev To get presale contract address by asvaId
     *
     * Requirements:
     * - asvaId must be a valid id
     */
    function getPresaleAddress(uint256 asvaId) external view returns (address) {
        require(validAsvaId(asvaId), "Not a valid Id");
        return presaleAddresses[asvaId];
    }

    /**
     * @dev To get valid asva Id's
     */
    function validAsvaId(uint256 asvaId) public view returns (bool) {
        if (asvaId >= 0 && asvaId <= presaleAddresses.length - 1) return true;
    }
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