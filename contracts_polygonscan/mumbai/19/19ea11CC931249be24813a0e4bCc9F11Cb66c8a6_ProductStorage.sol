/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/ProductStorage.sol



pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
contract ProductStorage is Ownable {
    struct Product {
        uint256 price;
        bool inserted;
    }

    mapping(uint256 => Product) public products;

    // Events
    event NewInsertedProduct(uint256 id, uint256 price);
    event UpdatedProduct(uint256 id, uint256 price);
    event ErasedProduct(uint256 id);

    modifier onlyOwnerOrInternal() {
        require(
            (owner() == _msgSender()) || (address(this) == _msgSender()),
            "Ownable: caller is not the owner"
        );
        _;
    }

    // READ CONTRACT
    function getProduct(uint256 id) public view returns (Product memory) {
        return products[id];
    }

    // WRITE CONTRACT
    function insert(uint256 id, uint256 price) external onlyOwnerOrInternal {
        // function to insert a new product
        // first check the id is not taken
        // Then add the product
        if (!products[id].inserted) {
            Product memory inserting;
            inserting.price = price;
            inserting.inserted = true;
            products[id] = inserting;
            emit NewInsertedProduct(id, price);
        }
    }

    function update(uint256 id, uint256 price) external onlyOwnerOrInternal {
        // function to update a product
        // If the product doesn't exists, then it should insert it
        if (products[id].inserted) {
            products[id].price = price;
        } else {
            this.insert(id, price);
        }
        emit UpdatedProduct(id, price);
    }

    function erase(uint256 id) external onlyOwnerOrInternal {
        // Function to erase existing product
        // first check the id exists
        if (products[id].inserted) {
            delete (products[id]);
            emit ErasedProduct(id);
        }
    }

    function insertSeveral(uint256[] memory ids, uint256[] memory prices)
        external
        onlyOwner
    {
        // function to insert new products from an array of id's
        // and an array of their correspondent prices
        // require is more convinient than assert since it returns remaining gas
        require(
            ids.length == prices.length,
            "IDs and price arrays have different length"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            this.insert(ids[uint256(i)], prices[uint256(i)]);
        }
    }

    function updateSeveral(uint256[] memory ids, uint256[] memory prices)
        external
        onlyOwner
    {
        // function to update several products from an array of id's
        // and an array of their correspondent prices
        require(
            ids.length == prices.length,
            "IDs and price arrays have different length"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            this.update(ids[uint256(i)], prices[uint256(i)]);
        }
    }

    function eraseSeveral(uint256[] memory ids) external onlyOwner {
        // function to erase products given an array of products id's
        for (uint256 i = 0; i < ids.length; i++) {
            this.erase(ids[uint256(i)]);
        }
    }
}