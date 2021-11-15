// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./uniSwap/interfaces/IUniswapV2Router02.sol";
import "../node_modules/openzeppelin-solidity/contracts/interfaces/IERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Investors.sol";
import "./Utils.sol";

contract Game is Investors {

    event PaidToGame(address to, uint256 amount);
    event GameShareChanged(uint256 from, uint256 to);
    event InvestorsShareChanged(uint256 from, uint256 to);
    event GameShareHolderChanged(address from, address to);


    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    IUniswapV2Router02 public uniswapRouter;

    uint public gameShare = 30;
    uint public investorsShare = 70;
    address public gameShareHolder;
    address public tokenAddress;

    constructor(address _gameShareHolder,address _tokenAddress) public {
        // set address of game share holder
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        gameShareHolder = _gameShareHolder;
        tokenAddress = _tokenAddress;
    }
    
    function convertEthToToken(uint tokenAmount,address tokenAdd,uint ethAmount) public {

        uint deadline1 = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapExactETHForTokens{ value: ethAmount }(tokenAmount, getPathForETHtoToken(tokenAdd), address(this), deadline1);

    }

    function getPathForETHtoToken(address tokenAdd) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = tokenAdd;

        return path;
    }
    
    function getEstimatedETHforToken(uint tokAmount , address tokenAdd) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(tokAmount, getPathForETHtoToken(tokenAdd));
    }
    
    receive() payable external {
        
        IERC20 tokk = IERC20(tokenAddress);

        uint256 eth_amount = msg.value;
        
        convertEthToToken(getEstimatedETHforToken(eth_amount,tokenAddress)[1],tokenAddress,eth_amount);

        uint256 shareX = Utils.percent(eth_amount, gameShare);
        uint256 shareY = Utils.percent(eth_amount, investorsShare);

        // transfer amount to game
        //payable(gameShareHolder).transfer(shareX);
        
        tokk.transfer(gameShareHolder,shareX);
        emit PaidToGame(gameShareHolder, shareX);

        // transfer remainig amount to all investors
       transferAmount(tokenAddress,shareY);

    }


    function percent1(uint numerator, uint denominator, uint precision) 
        public pure returns(uint quotient) {
            // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 5) / 10;
            return ( _quotient);
    }

    /**
     * @dev change the game share.
     * @param _share new share percent of game
    */

    function updateGameShare(uint256 _share) onlyOwner public {
        require(_share > 0, "Game: game share should be greater then 0");
        require(_share <= 100, "Game: Invalid share");
        
        uint256 oldShare = gameShare;
        uint256 oldInvestorsShare = investorsShare;

        // update game share
        gameShare = _share;

        // update investors share
        investorsShare = (100 - _share);

        emit GameShareChanged(oldShare, _share);
        emit InvestorsShareChanged(oldInvestorsShare, investorsShare);
    }

    /**
     * @dev change the address of game share holder.
     * @param _holder the address of new account
    */
    function changeGameShareHolder(address _holder) onlyOwner public {
        require(_holder != address(0), "Game: Invalid address for game share holder");

        address oldHolder = gameShareHolder;

        // change game share holder address
        gameShareHolder = _holder;

        emit GameShareHolderChanged(oldHolder, _holder);
    }

    /**
    * @dev return share percent of game
    */
    function getGameShare() public view returns (uint256) {
        return gameShare;
    }

    /**
    * @dev return share percent of all investors
    */
    function getInvestorsShare() public view returns (uint256) {
        return investorsShare;
    }

    /**
    * @dev Add new investor
    * @param account the address of new investor
    * @param share the percent of new investor
    */
    function addNewInvestor(address account, uint256 share) onlyOwner public {
        addInvestor(account, share);
    }

    function getInvestors() public view  returns (address[] memory, uint256[] memory) {
        return getAllInvestors();
    }
    
    function setPairAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "../node_modules/openzeppelin-solidity/contracts/interfaces/IERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Utils.sol";
contract Investors is Ownable {
    event PaidToInvestor(address to, uint256 share, uint256 amount);
    event InvestorAdded(address to, uint256 share);
    event InvestorRemove(address investor);
    event InvestorShareChange(address investor, uint256 from, uint256 to);

    struct Investor {
        address account;
        uint256 percent;
    }

    Investor[] public investors;

    constructor() public {
        investors.push(Investor(0x051502351ddaeb6f6e392950947C526BCAd81B1D, 100));
    }

    /**
    * @dev get all investors with their account and share
    */
    function getAllInvestors() public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](investors.length);
        uint256[] memory share = new uint[](investors.length);

        for (uint i = 0; i < investors.length; i++) {
            Investor storage person = investors[i];
            addrs[i] = person.account;
            share[i] = person.percent;
        }
        
        return (addrs, share);
    }

    /**
    * @dev transfer amount to all investors according their share percentage.
    * @param amount total amount to distribute
    */

    function transferAmount(address tokenAddress,uint256 amount) public {
        require(investors.length > 0, "Investors: No investors found");
        IERC20 tokk = IERC20(tokenAddress);

        
        for (uint i= 0; i < investors.length; i++) {
            Investor storage person = investors[i];
            uint256 shareY = Utils.percent(amount, person.percent);
            //payable(person.account).transfer(shareY);
            tokk.transfer(person.account,shareY);
            emit PaidToInvestor(person.account, shareY, amount);
        }
    }

    /**
    * @dev remove an investor.
    * @param index index no of that investor
    */

    function removeInvestor(uint index) onlyOwner public {
        require(index < investors.length, "Investors: Invalid index");

        Investor memory removedInvestor = investors[index];
        for (uint i = index; i < investors.length-1; i++){
            investors[i] = investors[i+1];
        }
        delete investors[investors.length-1];

        emit InvestorRemove(removedInvestor.account);
    }

    /**
    * @dev add a new investor.
    * @param account address of investor
    * @param share percent of share
    //todo need to add mofifer for only onwner acc
    */

    function addInvestor(address account, uint256 share) onlyOwner public {
        require(account != address(0), "Investors: Invalid address");
        require(share > 0, "Investors: share is 0");

        investors.push(Investor(account, share));

        emit InvestorAdded(account, share);
    }

    /**
    * @dev Update share percentage of investor.
    * @param index index of investor
    * @param share percent of share
    */
    function updateShare(uint index, uint256 share) onlyOwner public {
        require(share > 0, "Investors: Share should be greator then 0");

        Investor storage investor = investors[index];
        investor.percent = share;

        emit InvestorShareChange(investor.account, investor.percent, share);

    } 


    modifier shareShould100() {
         uint256 investorsShare;
        for (uint i = 0; i < investors.length; i++) {
            Investor storage person = investors[i];
            investorsShare = investorsShare + person.percent;
        }
        require(investorsShare == 100, "Investors: Unacceptable share");
        _;
    }
    
}

pragma solidity =0.6.6;

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

library Utils {
    function percent(uint256 eth_amount, uint256 percent_amount) public pure returns(uint256 amount) {
        amount = (eth_amount * percent_amount) / 100;
        return (amount);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

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
    constructor() public {
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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

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

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

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
         {
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
         {
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
         {
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
         {
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
         {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
         {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
         {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
         {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

