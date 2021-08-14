/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

/** 
 *  SourceUnit: \blg-smart-contracts\contracts\OrderManager.sol
*/
            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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




/** 
 *  SourceUnit: \blg-smart-contracts\contracts\OrderManager.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
        return msg.data;
    }
}




/** 
 *  SourceUnit: \blg-smart-contracts\contracts\OrderManager.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IRefundManager {
    function refund(uint action, address payable receiver) external;
}

interface IToken is IERC20 {
    function approveManager(address account, address manager) external;
    function transferToManager(address account, uint amount) external;
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}




/** 
 *  SourceUnit: \blg-smart-contracts\contracts\OrderManager.sol
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
 *  SourceUnit: \blg-smart-contracts\contracts\OrderManager.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "./Common.sol";


contract OrderManager is Context, Ownable {

    uint constant NEW = 0;
    uint constant APPROVED = 1;
    uint constant CONFIRMED = 2;
    uint constant REJECTED = 3;
    uint constant CANCELED = 4;

    struct Order {
        address owner;
        address provider;
        uint amount;
        uint fee;
        address approver;
        uint status; 
    }

    IRefundManager private _refund;
    IToken private _token;
    address private _feeHolder;
    mapping(address => bool) private _approvers;
    mapping(bytes32 => Order) private _orders;
    

    modifier refundable() {
        _;
        _refund.refund(0, payable(_msgSender()));
    }

    modifier onlyApprover() {
        require(_approvers[_msgSender()], "Only mint approver" );
        _;
    }

    modifier orderExists(bytes32 id) {
        Order storage order = _orders[id];
        require(order.provider != address(0), 'Order not found');
        _;
    }

    event OrderCreated(bytes32 id, address provider, uint amount, uint fee);
    event OrderUpdated(bytes32 id, uint status);
    event ApproverUpdated(address indexed account, bool enabled);
    event FeeHoldUpdated(address indexed account);

    constructor(IToken token, IRefundManager refund, address feeHolder) {
        _token = token;
        _refund = refund;
        _feeHolder = feeHolder;
    }

    function setRefundManager(IRefundManager refund) external onlyOwner {
        _refund = refund;
    }

    function setFeeHolder(address account) external onlyOwner {
        _feeHolder = account;
        emit FeeHoldUpdated(account);
    }

    function updateApprover(address account, bool enabled) external onlyOwner {
        _approvers[account] = enabled;
        emit ApproverUpdated(account, enabled);
    }

    function newOrder(bytes32 id, address provider, uint amount, uint fee) external payable refundable {

        Order storage order = _orders[id];
        require(order.provider == address(0), 'Order exists');
        require(fee < amount, 'Invalid fee');

        order.owner = _msgSender();
        order.provider = provider;
        order.amount = amount;
        order.fee = fee;

        _token.transferToManager(order.owner, amount);

        emit OrderCreated(id, provider, amount, fee);
    }

    function approveOrder(bytes32 id, uint newFee) external payable onlyApprover orderExists(id) refundable {
        Order storage order = _orders[id];
        require(order.status == NEW, 'Order processed');
        if (newFee > 0) {
            require(newFee < order.amount, 'Invalid fee');
            order.fee = newFee;
        }
        order.status = APPROVED;
        emit OrderUpdated(id, APPROVED);
    }

    function rejectOrder(bytes32 id) external payable onlyApprover orderExists(id) refundable {
        Order storage order = _orders[id];
        require(order.status == NEW, 'Order processed');
        order.status = REJECTED;
        _token.transfer(order.owner, order.amount);
        emit OrderUpdated(id, REJECTED);
    }

    function confirmOrder(bytes32 id) external payable onlyApprover orderExists(id) refundable {
        Order storage order = _orders[id];
        require(order.status == APPROVED, 'Order not approved');
        order.status = CONFIRMED;

        _token.transfer(order.provider, order.amount - order.fee);
        _token.transfer(_feeHolder, order.fee);

        emit OrderUpdated(id, CONFIRMED);
    }

    function cancelOrder(bytes32 id) external payable orderExists(id) refundable {
        Order storage order = _orders[id];
        require(order.status == NEW, 'Order processed');
        require(order.owner == _msgSender(), 'Order owner required');

        _cancelOrder(id);
    }

    function rejectApprovedOrder(bytes32 id) external payable onlyApprover orderExists(id) refundable {
        Order storage order = _orders[id];
        require(order.status == APPROVED, 'Only for approved order');

        _cancelOrder(id);
    }

    function _cancelOrder(bytes32 id) internal {
        Order storage order = _orders[id];

        order.status = CANCELED;
        _token.transfer(order.owner, order.amount);
        emit OrderUpdated(id, CANCELED);
    }
}