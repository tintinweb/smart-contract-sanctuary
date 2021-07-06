/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


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


contract ProductFactory is Ownable{

    event NewProduct(uint productId, string name);
    event DelegateProduct(uint productId, address newOwner, uint8 status);
    event AcceptProduct(uint productId, string name, uint8 status);

    struct Product {
        string name;
        uint8 status;
        address owner;
        address newOwner;

    }

    Product[] public products;

    mapping (uint => address) public productToOwner;
    mapping (address => uint) ownerProductCount;

    function createProduct (string memory _name) public {
        require(ownerProductCount[msg.sender] <= 10);
        products.push(Product(_name, 0, msg.sender, address(0)));
        uint id = products.length - 1;
        productToOwner[id] = msg.sender;
        ownerProductCount[msg.sender]++;
        emit NewProduct(id, _name);
    }
    function delegateProduct(uint _productId, address _newOwner) public{
        require (productToOwner[_productId]== msg.sender);
        require (products[_productId].status == 0, "is already delegated");
        Product storage p = products[_productId];
        p.status = 1;
        p.newOwner = _newOwner;
        emit DelegateProduct(_productId, _newOwner, p.status);

    }

    function acceptProduct(uint _productId) public{
        require (products[_productId].status == 1);
        require (products[_productId].newOwner == msg.sender);
        Product storage p = products[_productId];
        p.status = 0;
        p.newOwner = address(0);
        p.owner = msg.sender;
        emit AcceptProduct(_productId, p.name, p.status);
    }


}