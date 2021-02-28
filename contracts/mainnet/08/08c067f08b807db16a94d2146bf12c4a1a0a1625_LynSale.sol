/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol



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
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/LynSale.sol

pragma solidity ^0.6.0;



contract LynSale is Ownable {
    using SafeMath for uint256;
    uint256 private marketPrice;
    address public usdtToken;
    address public lynToken;

    bool private buyable;
    
    uint256 private constant LYN_DECIMAL = 10**18;
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant BALANCE_OF_SELECTOR = bytes4(keccak256(bytes('balanceOf(address)')));

    event Buy(address indexed buyer, uint256 usdtAmount, uint256 lynAmount);
    event ChangePrice(uint256 newPrice);
    event ChangeBuyalbe(bool isBuyable);

    modifier onlyBuyable() {
        require(buyable, "Not buyable");
        _;
    }

    /**
     * Price is the usdt per lyn.
     * 1lyn = 5USDT --> Price = 5*10^6
     * 1lyn = 0.5USDT --> Price = 0.5*10^6
     */
    constructor(
        address _usdtTokenAddr,
        address _lynTokenAddr,
        uint256 _price
    ) public {
        usdtToken = _usdtTokenAddr;
        lynToken = _lynTokenAddr;
        marketPrice = _price;
        emit ChangePrice(_price);
    }

    //////////////////////////////////////
    // OPERATION FUNCTIONS
    //////////////////////////////////////

    /**
     * The input must be multiplied by 10^decimals
     */
    function changePrice(uint256 _newPrice) external onlyOwner() {
        require(_newPrice > 0 && _newPrice != marketPrice, "Invalid price");
        marketPrice = _newPrice;
        emit ChangePrice(_newPrice);
    }

    function setBuyable(bool _isBuyable) external onlyOwner() {
        buyable = _isBuyable;
        emit ChangeBuyalbe(_isBuyable);
    }

    // Transfer LYN to owner address
    function drainLyn() external onlyOwner() {
        uint256 balance = _getBalanceOf(lynToken, address(this));
        _safeTransfer(lynToken, msg.sender, balance);
    }

    // Transfer USDT to owner address
    function drainUSDT() external onlyOwner() {
        uint256 balance = _getBalanceOf(usdtToken, address(this));
        _safeTransfer(usdtToken, msg.sender, balance);
    }

    //////////////////////////////////////
    // PUBLIC FUNCTIONS
    //////////////////////////////////////

    /**
     * This function transfer `_usdtAmount` USDT to the smart contract
     * and calculate the amount of Lyn then send Lyn to the buyer
     */
    function buy(uint256 _usdtAmount) onlyBuyable() external {
        // Calculate lyn amount
        uint256 lynAmount = _usdtAmount.mul(LYN_DECIMAL).div(marketPrice);

        // Transfer usdt to this contract
        _safeTransferFrom(address(usdtToken), msg.sender, address(this), _usdtAmount);

        // Transfer lyn to buyer
        _safeTransfer(lynToken, msg.sender, lynAmount);

        emit Buy(msg.sender, _usdtAmount, lynAmount);
    }

    //////////////////////////////////////
    // GET FUNCTIONS
    //////////////////////////////////////
    function checkPrice() public view returns(uint256) {
        return marketPrice;
    }

    function checkLynAmount() public view returns(uint256) {
        return _getBalanceOf(lynToken, address(this));
    }

    function checkUSDTAmount() public view returns(uint256) {
        return _getBalanceOf(usdtToken, address(this));
    }

    function checkBuyable() public view returns(bool) {
        return buyable;
    }

    //////////////////////////////////////
    // UTILITY FUNCTIONS
    //////////////////////////////////////

    // ERC20:
    // Functions `transfer`, `transferFrom` should return bool
    // but some token returns void instead of following the standard
    // Since, we need to accept void return as a successful transfer
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _safeTransferFrom(address token, address from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    function _getBalanceOf(address token, address account) private view returns(uint256) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(BALANCE_OF_SELECTOR, account));
        require(success, 'BALACE_OF_FAILED');
        uint256 balance = abi.decode(data,(uint256));
        return balance;
    }
}