/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/interfaces/IPreSale.sol

interface IPreSale {
    event PresaleStatusChange(bool isActive);
    event PresaleSpotsSold(uint256 remainingSlots);

    function whitelist(address wallet) external view returns (uint256);
    function mintedIndex() external view returns (uint256);

    function withdraw() external;
    function togglePresale() external;
    function getPresaleSpot(uint256 numberOfTokens) external payable;
    function availiableForPresale() external view returns (uint);
    function removeBuyer(address buyer) external;
}


// File contracts/PreSale.sol

contract PreSale is Ownable, IPreSale{
  
    uint256 public constant WIZARD_PRICE = 50000000000000000; //0.05 ETH
    mapping(address => uint256) public override whitelist;
    uint256 public constant MAX_SALE = 10;
    uint256 public constant TOTAL_PRESALE = 1000;
    bool public preSaleIsActive = false;
    uint public override mintedIndex = 0;

    function withdraw() public override onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public override onlyOwner {
        preSaleIsActive = !preSaleIsActive;
        emit PresaleStatusChange(preSaleIsActive);
    }

    function getPresaleSpot(uint256 numberOfTokens) public override payable {
        require(preSaleIsActive, "Presale has not started.");
        require(whitelist[msg.sender] + numberOfTokens <= MAX_SALE, "Max allowance exceeded.");
        require(mintedIndex + numberOfTokens < TOTAL_PRESALE, "Can not mint this much.");
        require((WIZARD_PRICE * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        mintedIndex += numberOfTokens;
        whitelist[msg.sender] += numberOfTokens;
        emit PresaleSpotsSold(availiableForPresale());
    }

    function availiableForPresale() public view override returns (uint256) {
        return TOTAL_PRESALE - mintedIndex;
    }

    function removeBuyer(address buyer) public override onlyOwner {
        require(whitelist[buyer] > 0, "User has no pre-sale spots.");
        whitelist[buyer] = 0;
    }
}