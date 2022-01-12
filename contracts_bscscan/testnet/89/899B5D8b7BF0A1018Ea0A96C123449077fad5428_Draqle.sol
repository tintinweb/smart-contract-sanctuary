/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_) internal pure returns (uint256 percentAmount_) {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_) internal pure returns (uint256 result_) {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_) internal pure returns (uint256) {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_) internal pure returns (uint256) {
        return mul(multiplier_, supply_);
    }
}

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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/security/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/access/[email protected]



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

contract Draqle is Ownable, Pausable {

  using SafeMath for uint256;

  struct PendingLog {
    address buyer;
    address seller;
    uint256 productId;
    
    uint256 depositTime;
    uint256 refundedTime;
    uint256 confirmedTime;
    uint256 claimedTime;
    uint256 acceptedTime;

    bool confirmedBySeller;
    bool acceptedByBuyer;

    bool refundedByBuyer;
    bool claimedBySeller;
  }

  struct UserLog {
    uint256 depositCount;
    uint256 totalDepositAmount;
    mapping(uint256 => bool) currentlyPending;
  }

  struct ProductInfo {
    uint256 id;
    uint256 price;
    address productOwner;
    uint256 saled;
  }

  mapping(address => UserLog) public userInfo;
  uint256 public productCount;
  mapping(uint256 => ProductInfo) public products;

  uint256 public pendinglogsCount;
  mapping(uint256 => PendingLog) public pendinglogs;

  event event_productAdded(address indexed productOwner, uint256 productId);
  event event_depositedByUser(address indexed buyer, uint256 pendingId);
  event event_confirmedBySeller(address indexed seller, uint256 pendingId);
  event event_acceptedByBuyer(address indexed buyer, uint256 pendingId);
  event event_claimedBySeller(address indexed seller, uint256 pendingId);
  event event_refundedByBuyer(address indexed buyer, uint256 pendingId);

  constructor(){
    productCount = 0;
  }

  function addProduct(uint256 _price) external returns (uint256) {
    products[productCount] = ProductInfo({
      id : productCount,
      price : _price,
      productOwner : msg.sender,
      saled : 0
    });
    productCount ++;
    emit event_productAdded(msg.sender, productCount-1);
    return productCount - 1;
  }

  function buyProduct(uint256 _id) payable external returns (uint256) {
    require(_id < productCount, "invalid id");
    require(msg.value >= products[_id].price, "You sent less than the price");
//  deposit 1 BNB or price BNB
    pendinglogs[pendinglogsCount] = PendingLog({
      productId : _id,
      buyer : msg.sender,
      seller : products[_id].productOwner,
      confirmedBySeller : false,
      acceptedByBuyer : false,
      refundedByBuyer : false,
      claimedBySeller : false,
      depositTime : block.timestamp,
      confirmedTime : 0,
      refundedTime : 0,
      claimedTime : 0,
      acceptedTime : 0
    });


    userInfo[msg.sender].totalDepositAmount += msg.value;
    userInfo[msg.sender].currentlyPending[pendinglogsCount - 1] = true;
    userInfo[msg.sender].depositCount ++;
    pendinglogsCount ++;
    emit event_depositedByUser(msg.sender, pendinglogsCount - 1);
    return pendinglogsCount - 1;
  }

  function confirmBySeller(uint256 _id) external {
    require(_id < pendinglogsCount, "invalid _id of pendinglog");
    require(pendinglogs[_id].seller == msg.sender, "you are not the owner of product");
    require(pendinglogs[_id].confirmedBySeller == false, "It is already confirmed");
    require(pendinglogs[_id].refundedByBuyer == false, "It is refunded by buyer");
    require(userInfo[pendinglogs[_id].buyer].currentlyPending[_id] == true, "It is not pended by buyer");
    pendinglogs[_id].confirmedBySeller = true;
    pendinglogs[_id].confirmedTime = block.timestamp;

    emit event_confirmedBySeller(msg.sender, _id);
  }

  function acceptByBuyer(uint256 _id) external {
    require(_id < pendinglogsCount, "invalid _id of pendinglogs");
    require(pendinglogs[_id].buyer == msg.sender, "you are not the buyer of pending");
    require(pendinglogs[_id].confirmedBySeller == true, "It is not confirmed yet");

    userInfo[msg.sender].totalDepositAmount.sub(products[pendinglogs[_id].productId].price);
    userInfo[msg.sender].currentlyPending[_id] = false;
    pendinglogs[_id].acceptedByBuyer = true;
    pendinglogs[_id].acceptedTime = block.timestamp;

    emit event_acceptedByBuyer(msg.sender, _id);
  }

  function refundByBuyer(uint256 _id) external {
    require(_id < pendinglogsCount, "invalid _id of pendinglogs");
    require(pendinglogs[_id].buyer == msg.sender, "you are not the buyer of this pending");
    require(pendinglogs[_id].confirmedBySeller == false, "It is already confirmed yet");
    require(userInfo[msg.sender].currentlyPending[_id] == true, "It is not currently pending");
//    require(block.timestamp > pendinglogs[_id].depositTime + 24 hours, "You can refund after 24 hours");

    pendinglogs[_id].refundedByBuyer = true;
    pendinglogs[_id].refundedTime = block.timestamp;
    userInfo[msg.sender].currentlyPending[_id] = false;
    address payable buyer = payable(msg.sender);
    buyer.transfer(products[pendinglogs[_id].productId].price *  (10 ** 18));
    emit event_refundedByBuyer(msg.sender, _id);
  }

  function claimBySeller(uint256 _id) external returns (uint256){
    require(_id < pendinglogsCount, "invalid _id of pendinglog");
    require(pendinglogs[_id].seller == msg.sender, "you are not the owner of product");
    require(pendinglogs[_id].confirmedBySeller == true, "It is not confirmed by you");
    require(pendinglogs[_id].refundedByBuyer == false, "It is refunded by buyer");
    require(pendinglogs[_id].acceptedByBuyer == true || (pendinglogs[_id].acceptedByBuyer == false && pendinglogs[_id].confirmedTime + 24 hours < block.timestamp), "It is not accepted by buyer or you could claim after 24 hours"); 

    pendinglogs[_id].claimedBySeller = true;
    pendinglogs[_id].claimedTime = block.timestamp;
    userInfo[pendinglogs[_id].buyer].totalDepositAmount.sub(products[pendinglogs[_id].productId].price);
    address payable seller = payable(msg.sender);
    seller.transfer(products[pendinglogs[_id].productId].price * (10 ** 18));
    products[pendinglogs[_id].productId].saled ++;

    emit event_claimedBySeller(msg.sender, _id);
    return _id;
  }
}