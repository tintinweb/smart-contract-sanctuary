/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// : MIT

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


// File @openzeppelin/contracts/access/[email protected]

// : MIT

pragma solidity ^0.8.0;

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


// File src/PriceOracle.sol

// : BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title PriceOracle contract
 * @author The Swarm Authors
 * @dev The price oracle contract keeps track of the current prices for settlement in swap accounting.
 */
contract PriceOracle is Ownable {
    /**
     * @dev Emitted when the price is updated.
     */
    event PriceUpdate(uint256 price);
    /**
     * @dev Emitted when the cheque value deduction amount is updated.
     */
    /*
    delete for Deduction
    */
    //event ChequeValueDeductionUpdate(uint256 chequeValueDeduction);

    // current price in PLUR per accounting unit
    uint256 public price;
    
    /*
    delete for Deduction
    */
    // value deducted from first received cheque from a peer in PLUR
    //uint256 public chequeValueDeduction;
    /*
    delete for Deduction
    */
    /*
    constructor(uint256 _price, uint256 _chequeValueDeduction) {
        price = _price;
        chequeValueDeduction = _chequeValueDeduction;
    }
    */
    constructor(uint256 _price) {
        price = _price;
    }

    /**
     * @notice Returns the current price in PLUR per accounting unit and the current cheque value deduction amount.
     */
     /*
    delete for Deduction
    */
    /*
    function getPrice() external view returns (uint256, uint256) {
        return (price, chequeValueDeduction);
    }
    */
    function getPrice() external view returns (uint256) {
        return price;
    }

    /**
     * @notice Update the price. Can only be called by the owner.
     * @param newPrice the new price
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdate(price);
    }
    
    
     /*
    delete for Deduction
    */
    /**
     * @notice Update the cheque value deduction amount. Can only be called by the owner.
     * @param newChequeValueDeduction the new cheque value deduction amount
     */
    /*
    function updateChequeValueDeduction(uint256 newChequeValueDeduction)
        external
        onlyOwner
    {
        chequeValueDeduction = newChequeValueDeduction;
        emit ChequeValueDeductionUpdate(chequeValueDeduction);
    }
    */
}