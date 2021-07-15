// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './IBEP20.sol';
import './utils/Ownable.sol';
import "./utils/AdminRole.sol";


contract Crowdsale is AdminRole {
    address private _tokenContract;
    
    uint private _salesIndex;
    mapping(uint => Sale) private _sales;
    
    event NewSale(uint salesIndex, uint startDate, uint endDate, uint quantity, uint price);
    event Buy(address buyer, uint quantity, uint price);

    struct Sale {
        uint startDate;
        uint endDate;
        uint quantity;
        uint price;
    }

    constructor(address tokenContract_) {
        _tokenContract = tokenContract_;
        _salesIndex = 0;
    }

    function changeTokenContract(
        address tokenContract_
    )
        public
        onlyAdmin
        returns (bool)
    {
        require(_sales[_salesIndex].endDate < block.timestamp);
        _tokenContract = tokenContract_;
        return true;
    }

    function getTokenContract()
        public
        view
        returns (address)
    {
        return _tokenContract;
    }

    function createSale(
        uint startDate_,
        uint endDate_,
        uint quantity_,
        uint price_
    )
        public
        onlyAdmin
        returns (bool)
    {
        require(startDate_ > block.timestamp, "CRW: start date is in the past");
        require(endDate_ > startDate_, "CRW: end date is in the past");
        require(block.timestamp > _sales[_salesIndex].endDate, "CRW: previous sale is not closed yet");

        require(IBEP20(_tokenContract).balanceOf(_msgSender()) >= quantity_, "CRW: balance of sender is not enough");
        require(IBEP20(_tokenContract).allowance(_msgSender(), address(this)) >= quantity_, "CRW: allowance of contract is not enough");
        require(IBEP20(_tokenContract).transferFrom(_msgSender(), address(this), quantity_), "CRW: error during transfer from");

        _salesIndex == _salesIndex++;

        Sale memory c;
        c.startDate = startDate_;
        c.endDate = endDate_;
        c.quantity = quantity_;
        c.price = price_;

        _sales[_salesIndex] = c;

        emit NewSale(_salesIndex, c.startDate, c.endDate, c.quantity, c.price);

        return true;
    }

    function buy(
        uint amount_
    )
        public
        payable
        returns (bool)
    {
        Sale storage c = _sales[_salesIndex];

        require(msg.value == (amount_ * c.price) / 10 ** 18, "CRW: Price doesn't match quantity");
        require(block.timestamp > c.startDate, "CRW: Sale didn't start yet.");
        require(block.timestamp < c.endDate, "CRW: Sale is already closed.");
        require(amount_ < c.quantity, "CRW: Amount over the limit");

        IBEP20(_tokenContract).transfer(msg.sender, amount_);
        c.quantity = c.quantity - amount_;

        emit Buy(msg.sender, amount_, c.price);
        return true;
    }

    function forceClose()
        public
        onlyAdmin
        returns (bool)
    {
        Sale storage c = _sales[_salesIndex];

        require(c.endDate > block.timestamp, "CRW: sale is not open");
        c.endDate = block.timestamp;

        if ( c.quantity > 0 ) {
            require(IBEP20(_tokenContract).transfer(_msgSender(), _sales[_salesIndex].quantity));
            c.quantity = 0;
        }

        return true;
    }

    function getBalance()
        public
        view 
        returns(uint)
    {
        return address(this).balance;
    }

    function withdrawToken(uint salesIndex_)
        public
        onlyAdmin
        returns (bool)
    {
        Sale storage c = _sales[salesIndex_];

        require(c.endDate < block.timestamp, "CRW: sale is not closed yet");
        require(c.quantity > 0, "CRW: no tokens to withdraw");

        IBEP20(_tokenContract).transfer(_msgSender(), c.quantity);
        c.quantity = 0;

        return true;
    }

    function withdrawBNB() 
        public
        onlyAdmin
        returns (bool)
    {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
        return true;
    }


    function getInfoSale(uint salesIndex_)
        public
        view
        returns(Sale memory)
    {
        return _sales[salesIndex_];
    }

    function getLastSaleIndex()
        public
        view
        returns(uint)
    {
        return _salesIndex;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBEP20 {

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);


    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "./Ownable.sol";
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
abstract contract AdminRole is Ownable {

    mapping(address => bool) _adminAddress;
    modifier onlyAdmin() {
        require(_adminAddress[_msgSender()] == true , "COCM: caller is not a admin");
        _;
    }
    event AdminSet(address indexed from, address indexed newAdmin, bool action);

    /**
     * @dev Initializes the contract setting the deployer as a admin.
     */
    constructor () {
        _adminAddress[_msgSender()] = true;
    }

    /**
   * @dev Add to list of admin `newAdmin_` address
   *
   * Emits an {AddedAdmin} event
   *
   * Requirements:
   * - Caller **MUST** is an admin
   * - `newAdmin_` address **MUST** is not an admin
   */
    function addAdmin(address newAdmin_) public onlyAdmin returns (bool){
        require(_adminAddress[newAdmin_] == false, "COCM: Address is already admin");
        _adminAddress[newAdmin_] = true;

        emit AdminSet(_msgSender(), newAdmin_, true);
        return true;
    }

    /**
    * @dev Remove to list of admin `newAdmin_` address
    *
    * Emits an {AddedAdmin} event
    *
    * Requirements:
    * - Caller **MUST** is an admin
    * - newAdmin_ address **MUST** is an admin
    */
    function removeAdmin(address newAdmin_) public onlyAdmin returns (bool){
        require(_adminAddress[_msgSender()] == true, "COCM: Address is not a admin");
        _adminAddress[newAdmin_] = false;

        emit AdminSet(_msgSender(), newAdmin_, false);
        return true;
    }

    /**
    * @dev Return if `adminAddress_` is admin
    */
    function checkIfAdmin(address adminAddress_) public view returns(bool) {
        return _adminAddress[adminAddress_];
    }
}

// SPDX-License-Identifier: UNLICENSED

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