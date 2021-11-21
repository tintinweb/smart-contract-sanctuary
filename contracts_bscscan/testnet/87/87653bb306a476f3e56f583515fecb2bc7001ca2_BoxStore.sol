/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";

interface IMysterBox {

    function mintBatch(uint256[] memory tokenIds, address account) external;

}

contract BoxStore is Ownable  {

    event AdminWalletUpdated(address wallet);
    event BoxPriceUpdated(uint256 boxPrice);
    event BoxBought(address buyer, uint256[] tokenIds, uint256 price);

    IMysterBox public boxContract;

    address payable public adminWallet;

    uint256 public boxPrice;

    uint256 public counter;

    constructor(IMysterBox _boxContract, address payable _adminWallet, uint256 _boxPrice) {
        boxContract = _boxContract;
        adminWallet = _adminWallet;
        boxPrice = _boxPrice;
    }

    function setAdminWallet(address payable _adminWallet)
        public
        onlyOwner    
    {
        require(_adminWallet != address(0), "BoxStore: address must be not zero");

        adminWallet = _adminWallet;

        emit AdminWalletUpdated(_adminWallet);
    }

    function setBoxPrice(uint256 _boxPrice)
        public
        onlyOwner    
    {
        require(_boxPrice > 0, "BoxStore: price must be not zero");

        boxPrice = _boxPrice;

        emit BoxPriceUpdated(_boxPrice);
    }

    function buyBox(uint256 _quantity)
        public
        payable
    {
        require(_quantity > 0, "BoxStore: quantity must be not zero");

        uint256 amount = boxPrice * _quantity;

        require(amount == msg.value, "BoxStore: deposit amount is not enough");

        address msgSender = _msgSender();

        uint256[] memory tokenIds = new uint256[](_quantity);

        uint256 id = counter;

        for (uint256 i = 0; i < _quantity; i++) {
            tokenIds[i] = ++id;
        }

        counter = id;

        adminWallet.transfer(amount);

        boxContract.mintBatch(tokenIds, msgSender);

        emit BoxBought(msgSender, tokenIds, boxPrice);
    }

}