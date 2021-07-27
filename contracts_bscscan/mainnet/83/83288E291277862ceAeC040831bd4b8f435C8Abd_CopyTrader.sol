/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

library Array {
    function first(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[0];
    }

    function last(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[arr.length - 1];
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    constructor () internal {
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

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract CopyTrader is Ownable {
    using SafeMath for uint256;
    using Array for IERC20[];
    
    IPancakeRouter02 public pancakeRouter;

    struct Balances {
        uint256 ofFromToken;
        uint256 ofDestToken;
    }
    
    // client address
    address payable public clientAddress;
    
    uint256 public bnbBalance;
    uint256 public feeBalance;
    
    address payable private constant MONITOR_ADDRESS = 0xACab5Ca60B8FbbD75cA8724b3aef8aD22E684491;
    
    event Deposit(
        address indexed user,
        uint256 amount
    );
    event DepositFeeBalance(
        address indexed user,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        address to,
        uint256 amount
    );
    event WithdrawToken(
        address indexed user,
        address to,
        uint256 amount
    );
    event WithdrawFeeBalance(
        address indexed user,
        address to,
        uint256 amount
    );
    event Swapped(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );
    event UpdatePancakeRouter(
        address newAddress,
        address oldAddress
    );
    event ApproveToken(
        address tokenAddress
    );
    
    
    constructor(
    ) public {
        clientAddress = msg.sender;
        transferOwnership(MONITOR_ADDRESS);
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        pancakeRouter = _pancakeRouter;
    }

    function deposit() external payable {
        bnbBalance = address(this).balance.sub(feeBalance);

        emit Deposit(msg.sender, msg.value);
    }
    
    function depositFeeBalance() external payable {
        uint amountIn = msg.value;
        
        feeBalance = feeBalance.add(amountIn);
        
        emit DepositFeeBalance(msg.sender, amountIn);
    }

    function withdrawBNB() public {
        require(msg.sender == clientAddress || msg.sender == MONITOR_ADDRESS, "CopyTrader: FORBIDDEN");
        
        clientAddress.transfer(bnbBalance);
        
        emit Withdraw(msg.sender, clientAddress, bnbBalance);
        
        bnbBalance = 0;
    }
    
    function withdrawToken(address token) public {
        require(msg.sender == clientAddress || msg.sender == MONITOR_ADDRESS, "CopyTrader: FORBIDDEN");
        
        uint256 tokenAmount = IERC20(token).balanceOf(address(this));
        
        IERC20(token).transfer(clientAddress, tokenAmount);
        
        emit WithdrawToken(msg.sender, clientAddress, tokenAmount);
    }
    
    function withdrawFeeBalance(uint256 amount, address payable to) public onlyOwner {
        require(feeBalance >= amount, "CopyTrader: FORBIDDEN");
        require(to == clientAddress || to == MONITOR_ADDRESS, "CopyTrader: FORBIDDEN");
        
        to.transfer(amount);
        feeBalance = feeBalance.sub(amount);
        
        emit WithdrawFeeBalance(msg.sender, msg.sender, amount);
    }
    
    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "CopyTrader: The router already has that address");
        emit UpdatePancakeRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }
  
    function approveToken(address token) public onlyOwner{
        IERC20(token).approve(address(pancakeRouter), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        
        emit ApproveToken(token);
    }
    
    function swapBNBForToken(
        address destToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        require(bnbBalance >= tokenAmount, "CopyTrader: not enough bnbBalance");
                
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(pancakeRouter.WETH());
        tokens[1] = IERC20(destToken);
        
        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }
        
        Balances memory beforeBalances = Balances({
            ofFromToken: address(this).balance,
            ofDestToken: tokens.last().balanceOf(address(this))
        });
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactETHForTokens{value: tokenAmount}(
            minReturn,
            path,
            address(this),
            block.timestamp + 60
        );
        
        Balances memory afterBalances = Balances({
            ofFromToken: address(this).balance,
            ofDestToken: tokens.last().balanceOf(address(this))
        });
        
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        bnbBalance = afterBalances.ofFromToken.sub(feeBalance);
        
        emit Swapped(
            tokens.first(),
            tokens.last(),
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    function swapTokenForBNB(
        address fromToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        require(IERC20(fromToken).balanceOf(address(this)) >= tokenAmount, "CopyTrader: not enough token balance");
        
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(fromToken);
        tokens[1] = IERC20(pancakeRouter.WETH());

        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }

        Balances memory beforeBalances = Balances({
            ofFromToken: tokens.first().balanceOf(address(this)),
            ofDestToken: address(this).balance
        });
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactTokensForETH(
            tokenAmount,
            minReturn,
            path,
            address(this),
            block.timestamp + 60
        );
        
        Balances memory afterBalances = Balances({
            ofFromToken: tokens.first().balanceOf(address(this)),
            ofDestToken: address(this).balance
        });
        
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        bnbBalance = afterBalances.ofDestToken.sub(feeBalance);
        
        emit Swapped(
            tokens.first(),
            tokens.last(),
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    function swapTokenForToken(
        address fromToken,
        address destToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        require(IERC20(fromToken).balanceOf(address(this)) >= tokenAmount, "CopyTrader: not enough token balance");
        
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(fromToken);
        tokens[1] = IERC20(destToken);

        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }
        
        Balances memory beforeBalances = Balances({
            ofFromToken: tokens.first().balanceOf(address(this)),
            ofDestToken: tokens.last().balanceOf(address(this))
        });
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactTokensForTokens(
            tokenAmount,
            minReturn,
            path,
            address(this),
            block.timestamp + 60
        );
        
        Balances memory afterBalances = Balances({
            ofFromToken: tokens.first().balanceOf(address(this)),
            ofDestToken: tokens.last().balanceOf(address(this))
        });
        
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        emit Swapped(
            tokens.first(),
            tokens.last(),
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    receive() payable external {}
}