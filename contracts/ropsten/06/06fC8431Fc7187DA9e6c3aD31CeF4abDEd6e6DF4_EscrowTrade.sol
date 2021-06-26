/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// 
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

// 
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

// 
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

// 
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// 
contract EscrowTrade is Ownable {

    enum Status{PENDING, BROKEN, SUCCESS}

    using SafeMath for uint256;

    event contractCreated(uint256 contractID, address buyer, address seller);
    event confirmedByBuyer(uint256 contractID);
    event confirmedBySeller(uint256 contractID);
    event contractBroken(uint256 contractID);
    event contractSuccess(uint256 contractID);

    struct Contract{
        address buyer;
        address seller;
        address buyerToken; // if buyerToken address equals 0x0, it means BNB
        address sellerToken;
        uint256 buyAmount;
        uint256 sellAmount;
        uint256 collateral;
        uint256 lockTime;
        bool buyerConfirmed;
        bool sellerConfirmed;
        Status state;
    }

    mapping(uint256 => Contract) list;
    mapping(uint256 => bool) isExist;

    uint256 public lockDuration = 1 days;

    constructor() public {}

    function createContract(
        uint256 contractId,
        address _buyer,
        address _seller,
        address _buyToken,
        address _sellToken,
        uint256 _buyAmount,
        uint256 _sellAmount) external onlyOwner {
        require(isExist[contractId] == false, "CreateContract: already exist");
        Contract memory newContract = Contract({
            buyer: _buyer,
            seller: _seller,
            buyerToken: _buyToken,
            sellerToken: _sellToken,
            buyAmount: _buyAmount,
            sellAmount: _sellAmount,
            collateral: _buyAmount.div(2),
            lockTime: lockDuration.add(block.timestamp),
            buyerConfirmed: false,
            sellerConfirmed: false,
            state: Status.PENDING
        });
        list[contractId] = newContract;
        isExist[contractId] = true;

        emit contractCreated(contractId, _buyer, _seller);
    }

    function confirmByBuyer(uint256 contractID) external payable {
        require(isExist[contractID] == true, "ConfirmByBuyer: not exist");
        require(msg.sender == list[contractID].buyer, "ConfirmByBuyer: not buyer");
        require(list[contractID].buyerConfirmed == false, "ConfirmByBuyer: already confirmed");
        require(list[contractID].state == Status.PENDING, "ConfirmByBuyer: finished");

        address buyerToken = list[contractID].buyerToken;
        uint256 buyAmount = list[contractID].buyAmount;

        if(buyerToken == address(0x0)){
            require(msg.value >= buyAmount, "ConfirmByBuyer: insufficient funds");
        }else{
            IERC20(buyerToken).transferFrom(msg.sender, address(this), buyAmount);
        }
        list[contractID].buyerConfirmed = true;

        emit confirmedByBuyer(contractID);
    }

    function confirmBySeller(uint256 contractID) external payable {
        require(isExist[contractID] == true, "ConfirmBySeller: not exist");
        require(msg.sender == list[contractID].seller, "ConfirmBySeller: not seller");
        require(list[contractID].sellerConfirmed == false, "ConfirmBySeller: already confirmed");
        require(list[contractID].state == Status.PENDING, "ConfirmBySeller: finished");

        address buyerToken = list[contractID].buyerToken;
        uint256 collateral = list[contractID].collateral;

        if(buyerToken == address(0x0)){
            require(msg.value >= collateral, "ConfirmByBuyer: insufficient funds");
        }else{
            IERC20(buyerToken).transferFrom(msg.sender, address(this), collateral);
        }
        list[contractID].sellerConfirmed = true;

        emit confirmedBySeller(contractID);
    }

    function breakContract(uint256 contractID) external {
        require(isExist[contractID] == true, "breakContract: not exist");
        require(msg.sender == list[contractID].seller, "breakContract: not seller");
        require(list[contractID].state == Status.PENDING, "breakContract: finished");
        require(list[contractID].sellerConfirmed == true, "breakContract: not confirmed by seller");
        require(list[contractID].lockTime <= block.timestamp, "breakContract: not unlocked");

        address buyerToken = list[contractID].buyerToken;
        uint256 buyAmount = list[contractID].buyAmount;
        uint256 collateral = list[contractID].collateral;

        address buyer = list[contractID].buyer;

        if(buyerToken == address(0x0)){
            payable(buyer).transfer(buyAmount.add(collateral));

        }else{
            IERC20(buyerToken).transfer(buyer, buyAmount.add(collateral));
        }

        list[contractID].state = Status.BROKEN;

        emit contractBroken(contractID);
    }

    function successContract(uint256 contractID) external {
        require(isExist[contractID] == true, "breakContract: not exist");
        require(msg.sender == list[contractID].seller, "breakContract: not seller");
        require(list[contractID].state == Status.PENDING, "breakContract: finished");
        require(list[contractID].sellerConfirmed == true, "breakContract: not confirmed by seller");
        require(list[contractID].lockTime <= block.timestamp, "breakContract: not unlocked");

        address buyer = list[contractID].buyer;
        address sellerToken = list[contractID].sellerToken;
        uint256 sellAmount = list[contractID].sellAmount;

        IERC20(sellerToken).transferFrom(msg.sender, buyer, sellAmount);

        address buyerToken = list[contractID].buyerToken;
        uint256 buyAmount = list[contractID].buyAmount;
        uint256 collateral = list[contractID].collateral;

        if(buyerToken == address(0x0)){
            payable(msg.sender).transfer(buyAmount.add(collateral));

        }else{
            IERC20(buyerToken).transfer(msg.sender, buyAmount.add(collateral));
        }

        list[contractID].state = Status.SUCCESS;

        emit contractSuccess(contractID);
    }
}