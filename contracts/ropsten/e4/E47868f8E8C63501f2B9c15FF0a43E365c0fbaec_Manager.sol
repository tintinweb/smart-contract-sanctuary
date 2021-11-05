/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: ManagerInterface.sol


pragma solidity ^0.8.0;

interface ManagerInterface{

    function feeSilver() external view returns (uint256);

    function feeGold() external view returns (uint256);

    function feeDinamond() external view returns (uint256);

    function feeEvolve() external view returns (uint256);

    function feeAddress() external view returns (address);
}
// File: Manager.sol




contract Manager is ManagerInterface,Ownable{
    uint256 public fee_evolve = 500;
    uint256 public fee_silver = 2000;
    uint256 public fee_gold = 4000;
    uint256 public fee_dinamond = 16000;
    address public fee_address;

    function feeSilver() public override view returns (uint256) {
        return fee_silver;
    }
    
    function feeGold() public override view returns (uint256) {
        return fee_gold;
    }
    
    function feeDinamond() public override view returns (uint256) {
        return fee_dinamond;
    }

    function feeEvolve() public override view returns (uint256) {
        return fee_evolve;
    }

    function feeAddress() public override  view returns (address) {
        return fee_address;
    }
    
    function setFeeSilver(uint256 price) public onlyOwner{
        fee_silver = price;
    }
    
    function setFeeGold(uint256 price) public onlyOwner{
        fee_gold = price;
    }
    
    function setFeeDinamond(uint256 price) public onlyOwner{
        fee_dinamond = price;
    }
    
    function setFeeEvolve(uint256 price) public onlyOwner{
        fee_evolve = price;
    }
    function setFeeAddress(address _address) public onlyOwner{
        fee_address = _address;
    }
}