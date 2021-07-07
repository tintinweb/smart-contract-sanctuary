/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: None
/**
    BlockchainCommerce by SeiferXIII 07/01/2021
**/
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract BlockchainCommerce is Context, Ownable {

    /* Start BlockchainCommerce process */
    uint256 private orderCount;

    struct Order{
        uint256 _id;
        uint256 productNum;
        address buyerAddress;
        uint256 paidAmount;
        address merchantAddress;
    }

    mapping(uint256 => Order) public orders;

    event OrderCreated(
        uint256 id,
        uint256 productNum,
        address buyerAddress,
        uint256 paidAmount,
        address merchantAddress
    );

    function getOrderCount() external view returns (uint256) {
        return orderCount;
    }

    function getOrderData(uint256 _orderId) external view returns (uint256, uint256, address, uint256, address){
        require(_orderId >= 0, "Invalid order id");
        require(_orderId <= orderCount,"Invalid order id");
        return (orders[_orderId]._id, orders[_orderId].productNum, orders[_orderId].buyerAddress, orders[_orderId].paidAmount, orders[_orderId].merchantAddress);
    }

    function orderCreate(uint256 _productNum, address _buyerAddress, uint256 _paidAmount, address _merchantAddress) onlyOwner external returns(uint256)  {
        orderCount++;
        orders[orderCount] = Order(orderCount,_productNum,_buyerAddress,_paidAmount,_merchantAddress);
        emit OrderCreated(orderCount,_productNum,_buyerAddress,_paidAmount,_merchantAddress);
        return orderCount;
    }
    /* End BlockchainCommerce process */
}