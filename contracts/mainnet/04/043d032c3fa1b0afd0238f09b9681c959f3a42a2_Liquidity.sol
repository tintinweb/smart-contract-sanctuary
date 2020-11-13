// SPDX-License-Identifier: MIT

/**
 * @title Liquidity Contract
 * @author: Muhammad Zaryab Khan
 * Developed By: BLOCK360
 * Date: Septemeber 17, 2020
 * Version: 1.0.0
 */

pragma solidity 0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface TokenInterface {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface DexInterface {
    function collectedFee(string calldata currency)
        external
        view
        returns (uint256);
}

contract Liquidity is Ownable {
    using SafeMath for uint256;
    string public version = "1.0.0";
    address public DEX;
    string[] public allLiquidities;
    mapping(string => address) public contractAddress;

    event DEXUpdated(address oldDEX, address newDEX);
    event TokenUpdated(string symbol, address newContract);
    event PaymentReceived(address from, uint256 amount);
    event LiquidityWithdraw(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event LiquidityTransfer(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Throws if called by any account other than the DEX.
     */
    modifier onlyDEX() {
        require(DEX == _msgSender(), "Liquidity: caller is not DEX");
        _;
    }

    constructor(
        address owner,
        address gsu,
        address usdt
    ) public {
        require(owner != address(0x0), "[Liquidity], owner is zero address");
        require(gsu != address(0x0), "[Liquidity], gsu is zero address");
        require(usdt != address(0x0), "[Liquidity], usdt is zero address");

        allLiquidities.push("ETH");

        newLiquidity(gsu);
        newLiquidity(usdt);
        transferOwnership(owner);
    }

    fallback() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function withdraw(string calldata symbol, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "[Liquidity] amount is zero");
        require(
            balanceOf(symbol).sub(amount) >=
                DexInterface(DEX).collectedFee(symbol),
            "[Liquidity] amount exceeds available funds"
        );

        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(owner(), amount);
        else address(uint160(owner())).transfer(amount);

        emit LiquidityWithdraw(symbol, owner(), amount, block.timestamp);
    }

    function transfer(
        string calldata symbol,
        address payable recipient,
        uint256 amount
    ) external onlyDEX returns (bool) {
        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(recipient, amount);
        else recipient.transfer(amount);

        emit LiquidityTransfer(symbol, recipient, amount, block.timestamp);

        return true;
    }

    function balanceOf(string memory symbol) public view returns (uint256) {
        if (isERC20Token(symbol))
            return
                TokenInterface(contractAddress[symbol]).balanceOf(
                    address(this)
                );
        else return address(this).balance;
    }

    function isERC20Token(string memory symbol) public view returns (bool) {
        return contractAddress[symbol] != address(0x0);
    }

    function setDex(address newDEX) external onlyOwner returns (bool) {
        emit DEXUpdated(DEX, newDEX);
        DEX = newDEX;
        return true;
    }

    function newLiquidity(address _contract) private onlyOwner returns (bool) {
        string memory symbol = TokenInterface(_contract).symbol();
        allLiquidities.push(symbol);
        contractAddress[symbol] = _contract;
        return true;
    }

    function setTokenContract(string calldata symbol, address newContract)
        external
        onlyOwner
        returns (bool)
    {
        require(isERC20Token(symbol));
        contractAddress[symbol] = newContract;
        emit TokenUpdated(symbol, newContract);
        return true;
    }

    function totalLiquidities() external view returns (uint256) {
        return allLiquidities.length;
    }

    function destroy() external onlyOwner {
        // index 0 is ethereum
        for (uint8 a = 1; a < allLiquidities.length; a++) {
            string memory currency = allLiquidities[a];
            TokenInterface(contractAddress[currency]).transfer(
                owner(),
                balanceOf(currency)
            );
        }

        selfdestruct(payable(owner()));
    }
}