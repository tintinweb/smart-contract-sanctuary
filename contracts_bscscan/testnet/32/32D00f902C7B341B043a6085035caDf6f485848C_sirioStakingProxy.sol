//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "Ownable.sol";

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

interface IMdexRouter {
    function factory() external pure returns (address);

    function WBNB() external pure returns (address);

    function swapMining() external pure returns (address);

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

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external view returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, address token0, address token1) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, address token0, address token1) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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


pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function mint(address to, uint256 amount) external;
    
    function burn(uint256 amount) external;

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

interface IMasterChefBSC {
    function pendingCake(uint256 pid, address user) external view returns (uint256);

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function emergencyWithdraw(uint256 pid) external;
}

interface IWbnb{
    function deposit() payable external;
}

interface IMDEXMining{
    function takerWithdraw() external;
}

interface IPancakeMasterchef{
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}


contract sirioStakingProxy is Ownable{
    using SafeMath for uint256;
    
    IERC20 usdt;
    IERC20 busd;
    IERC20 wbnb;
    IWbnb wbnbAddress;
    IERC20 LPTokenMDEX;
    IERC20 LPTokenPancake;
    IERC20 sirioDiversifyToken;
    IERC20 sirio;
    IERC20 mdex;
    IERC20 pancake;
    IMdexRouter mdexRouter;
    IPancakeRouter02 pancakeRouter;
    IMasterChefBSC pool;
    IPancakeMasterchef pancakeMasterchef;
    IMDEXMining mdexMining;
    address payable communityWallet;
    address payable devWallet;
    uint256 SirioAmount;
    mapping (address=>uint256) balances;
    mapping (address=>uint256) sirioStaked;
    mapping (address=>uint256) pancakeLPBalances;
    mapping (address=>uint256) MDEXLPBalances;
    uint256 totalLPpancake;
    uint256 totalLPMdex;
   
    
    constructor (){
        usdt=IERC20(0x53D2d436eebceB509E95d1153Ca70D86938eb497);
        busd=IERC20(0x085320e91209edBB70829D1F94D6FD3D61597b85);
        mdexRouter=IMdexRouter(0xeE96e4Fa234f8875be876939B3748972961aEdcC);
        wbnb=IERC20(0x48f7D56c057F20668cdbaD0a9Cd6092B3dc83684);
        wbnbAddress=IWbnb(0x48f7D56c057F20668cdbaD0a9Cd6092B3dc83684);
        communityWallet=payable (0x6E7c48A6E83100DDFe19B78dd6334f73381a9586);
        devWallet=payable(0x6E7c48A6E83100DDFe19B78dd6334f73381a9586);
        pool=IMasterChefBSC(0xa166e0b4E0E30C0Ad205d16577792aAA441c17D9);
        mdex=IERC20(0x12DfF50683Bd65984CC22988F46893fe66884dB5);
        pancake=IERC20(0xCa82A9A24953ec83168A21470e273Dd9ee7A0a10);
        mdexMining=IMDEXMining(0x72796791FB612ca8A8Ac30410089f56Ab4f53afe);
        pancakeRouter=IPancakeRouter02(0x124a92aae2f9c75C3cc8809E7ea92c0ea70c3753);
        LPTokenMDEX=IERC20(0x1D2acDce5C2D5648B4e2d52E58F65705a23451D3);
        LPTokenPancake=IERC20(0x3789dAbd869f1d86B6913DBDF093828CBC5e9e37);
        sirio=IERC20(0x0acf3c6e1e0B28C15608C091147e175913e9F606);
        sirioDiversifyToken=IERC20(0x390c0a19d50Af95C57057e81788aB36Ac51cf445);
        pancakeMasterchef=IPancakeMasterchef(0xa49f4F5c5b17cE047c3b35b49804A4aCAbd51a84);
        SirioAmount=1000000000000000000;
    }
    
    function diversify() payable public{
        if(sirioStaked[msg.sender]==SirioAmount){
            uint256 depositFee=msg.value.div(100);
            uint256 depositFeeDev=depositFee.div(2);
            devWallet.transfer(depositFeeDev);
            communityWallet.transfer(depositFee.sub(depositFeeDev));
            uint256 MDEXAmount=(msg.value.sub(depositFee)).div(2);
            uint256 amountToSwap=(MDEXAmount).div(2);
            address[] memory path = new address[](2);
            path[0]=address(wbnb);
            path[1]=address(usdt);
            mdexRouter.swapExactETHForTokens{value : amountToSwap}(0,path, address(this), block.timestamp+1000);
            usdt.approve(address(mdexRouter),100000000000000000000000000000000000000000);
            wbnb.approve(address(mdexRouter),100000000000000000000000000000000000000000);
            wbnbAddress.deposit{value:MDEXAmount.sub(amountToSwap)}();
            mdexRouter.addLiquidity(address(wbnb),address(usdt),MDEXAmount.sub(amountToSwap),usdt.balanceOf(address(this)),0,0,address(this),block.timestamp+1000);
            uint256 pancakeAmount=(msg.value.sub(depositFee)).sub(MDEXAmount);
            uint256 amountToSwap2=pancakeAmount.div(2);
            address[] memory path2 = new address[](2);
            path2[0]=address(wbnb);
            path2[1]=address(busd);
            pancakeRouter.swapExactETHForTokens{value : amountToSwap2}(0,path2, address(this), block.timestamp+1000);
            busd.approve(address(pancakeRouter),100000000000000000000000000000000000000000);
            wbnb.approve(address(pancakeRouter),100000000000000000000000000000000000000000);
            wbnbAddress.deposit{value:pancakeAmount.sub(amountToSwap2)}();
            pancakeRouter.addLiquidity(address(wbnb),address(busd),pancakeAmount.sub(amountToSwap2),busd.balanceOf(address(this)),0,0,address(this),block.timestamp+1000);
            LPTokenMDEX.approve(address(pool),100000000000000000000000000000000000000000);
            sirioDiversifyToken.mint(msg.sender,LPTokenMDEX.balanceOf(address(this)));
            MDEXLPBalances[msg.sender]=MDEXLPBalances[msg.sender].add(LPTokenMDEX.balanceOf(address(this)));
            //0 in testnet
            pool.deposit(0,LPTokenMDEX.balanceOf(address(this)));
            LPTokenPancake.approve(address(pancakeMasterchef),100000000000000000000000000000000000000000);
            pancakeLPBalances[msg.sender]=pancakeLPBalances[msg.sender].add(LPTokenPancake.balanceOf(address(this)));
            //1 in testnet
            pancakeMasterchef.deposit(1,LPTokenPancake.balanceOf(address(this)));
            usdt.transfer(msg.sender,usdt.balanceOf(address(this)));
            busd.transfer(msg.sender,busd.balanceOf(address(this)));
            
        }
        else{
            require(sirio.balanceOf(msg.sender)>=SirioAmount,"not enough sirio");
            sirio.transferFrom(msg.sender,address(this),SirioAmount);
            sirioStaked[msg.sender]=SirioAmount;
            uint256 depositFee=msg.value.div(100);
            uint256 depositFeeDev=depositFee.div(2);
            devWallet.transfer(depositFeeDev);
            communityWallet.transfer(depositFee.sub(depositFeeDev));
            uint256 MDEXAmount=(msg.value.sub(depositFee)).div(2);
            uint256 amountToSwap=(MDEXAmount).div(2);
            address[] memory path = new address[](2);
            path[0]=address(wbnb);
            path[1]=address(usdt);
            mdexRouter.swapExactETHForTokens{value : amountToSwap}(0,path, address(this), block.timestamp+1000);
            usdt.approve(address(mdexRouter),100000000000000000000000000000000000000000);
            wbnb.approve(address(mdexRouter),100000000000000000000000000000000000000000);
            wbnbAddress.deposit{value:MDEXAmount.sub(amountToSwap)}();
            mdexRouter.addLiquidity(address(wbnb),address(usdt),MDEXAmount.sub(amountToSwap),usdt.balanceOf(address(this)),0,0,address(this),block.timestamp+1000);
            uint256 pancakeAmount=(msg.value.sub(depositFee)).sub(MDEXAmount);
            uint256 amountToSwap2=pancakeAmount.div(2);
            address[] memory path2 = new address[](2);
            path2[0]=address(wbnb);
            path2[1]=address(busd);
            pancakeRouter.swapExactETHForTokens{value : amountToSwap2}(0,path2, address(this), block.timestamp+1000);
            busd.approve(address(pancakeRouter),100000000000000000000000000000000000000000);
            wbnb.approve(address(pancakeRouter),100000000000000000000000000000000000000000);
            wbnbAddress.deposit{value:pancakeAmount.sub(amountToSwap2)}();
            pancakeRouter.addLiquidity(address(wbnb),address(busd),pancakeAmount.sub(amountToSwap2),busd.balanceOf(address(this)),0,0,address(this),block.timestamp+1000);
            LPTokenMDEX.approve(address(pool),100000000000000000000000000000000000000000);
            sirioDiversifyToken.mint(msg.sender,LPTokenMDEX.balanceOf(address(this)));
            MDEXLPBalances[msg.sender]=MDEXLPBalances[msg.sender].add(LPTokenMDEX.balanceOf(address(this)));
            //0 in testnet
            pool.deposit(0,LPTokenMDEX.balanceOf(address(this)));
            LPTokenPancake.approve(address(pancakeMasterchef),100000000000000000000000000000000000000000);
            pancakeLPBalances[msg.sender]=pancakeLPBalances[msg.sender].add(LPTokenPancake.balanceOf(address(this)));
            //1 in testnet
            pancakeMasterchef.deposit(1,LPTokenPancake.balanceOf(address(this)));
            usdt.transfer(msg.sender,usdt.balanceOf(address(this)));
            busd.transfer(msg.sender,busd.balanceOf(address(this)));
        }
    }
    
    function changeSirioAmount(uint256 _newAmount) public onlyOwner{
        SirioAmount=_newAmount;
    }
    
    function getSirioStaked() view public returns (uint256){
        return sirioStaked[msg.sender];
    }
    
   function unstake () public{
        //0 in testnet
        require(sirioDiversifyToken.balanceOf(msg.sender)>=MDEXLPBalances[msg.sender],"you have to return Diversify tokens");
        sirioDiversifyToken.transferFrom(msg.sender,address(this),MDEXLPBalances[msg.sender]);
        sirioDiversifyToken.burn(MDEXLPBalances[msg.sender]);
        sirio.transfer(msg.sender, sirioStaked[msg.sender]);
        sirioStaked[msg.sender]=0;
        pool.withdraw(0,MDEXLPBalances[msg.sender]);
        //1 in testnet
        pancakeMasterchef.withdraw(1,pancakeLPBalances[msg.sender]);
        MDEXLPBalances[msg.sender]=0;
        pancakeLPBalances[msg.sender]=0;
        LPTokenMDEX.approve(address(mdexRouter),100000000000000000000000000000000000000000);
        LPTokenPancake.approve(address(pancakeRouter),100000000000000000000000000000000000000000);
        mdexRouter.removeLiquidityETH(address(usdt),LPTokenMDEX.balanceOf(address(this))-1,0,0,address(this),block.timestamp+1000);
        pancakeRouter.removeLiquidityETH(address(busd),LPTokenPancake.balanceOf(address(this))-1,0,0,address(this),block.timestamp+1000);
        uint256 feeBnb=address(this).balance.mul(1).div(100);
        uint256 feeUsdt=usdt.balanceOf(address(this)).mul(1).div(100);
        uint256 feeBusd=busd.balanceOf(address(this)).mul(1).div(100);
        uint256 feeMdex=mdex.balanceOf(address(this)).mul(20).div(100);
        uint256 feePancake=pancake.balanceOf(address(this)).mul(20).div(100);
        payable(msg.sender).transfer(address(this).balance.sub(feeBnb));
        usdt.transfer(msg.sender,usdt.balanceOf(address(this)).sub(feeUsdt));
        busd.transfer(msg.sender,busd.balanceOf(address(this)).sub(feeBusd));
        mdex.transfer(communityWallet,mdex.balanceOf(address(this)).sub(feeMdex));
        pancake.transfer(communityWallet,pancake.balanceOf(address(this)).sub(feePancake));
        payable(devWallet).transfer(feeBnb);
        usdt.transfer(devWallet,feeUsdt);
        busd.transfer(devWallet,feeBusd);
        mdex.transfer(devWallet,feeMdex);
        pancake.transfer(devWallet,feePancake);
    }
    
    function getMdexTaker() external{
        mdexMining.takerWithdraw();
    }

    
    receive() external payable {}
    
}