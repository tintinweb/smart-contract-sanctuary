/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


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



contract Token{
    using SafeMath for uint256;
    string public name="ABFF";
    string public symbol="ABF";
    uint8 public decimals=9;
    uint256 public totalSupply= 100000000 * 10**uint256(decimals);
    uint256 public trusteeship= 38000000 * 10**uint256(decimals);
    uint256 public owner_amount=62000000 * 10 **uint256(decimals);
    
    uint256 public numTokensSellToAddToLiquidity=100000 * 10**uint256(decimals);
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    mapping(address=>uint256)public balanceOf;
    address private owner;
    address public Marketing=0x64a04F35697F1D1a411568b96d0751805d484e1E;
    address public trusteeship_addr=0x4fE9832305011fc07809F7433D57223D87eCD4A5;
    address public BurnAddr = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => bool) public _isExcludedFromFee;
    uint256 public Shell_burn=1;
    uint256 public Marketing_rate=41;
    uint256 public Shell_LP=7;

    uint256 public Buy_LP=5;
    
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    constructor()public{
        owner=msg.sender;
        balanceOf[owner]=owner_amount;
        balanceOf[trusteeship_addr]=trusteeship;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3   0x10ED43C718714eb63d5aA57B78B54704E256024E
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner]=true;
        _isExcludedFromFee[trusteeship_addr]=true;
        
        
        emit Transfer(address(0), owner, owner_amount);
        emit Transfer(address(0), trusteeship_addr, trusteeship);   
    }
    
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
   
     function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != address(0x0),"err:");
		require(_value > 0,"err:");
        require(balanceOf[_from]>= _value);  
        require(balanceOf[_to].add(_value)  > balanceOf[_to]); 
        
        uint256 contractTokenBalance = balanceOf[address(this)];
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            _from != uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            _isExcludedFromFee[_from]==false&&
            _isExcludedFromFee[_to]==false
        ) {
            inSwapAndLiquify==true;
            uint256 Marketing_value = contractTokenBalance.mul(Marketing_rate).div(10**2);
            uint256 LP_value = contractTokenBalance.sub(Marketing_value);
            //add liquidity
            swapAndLiquify(LP_value);
            swapTokensForEthToMarketing(Marketing_value);
            inSwapAndLiquify=false;
        }
        
        
        if(_to==uniswapV2Pair&&_isExcludedFromFee[_from]==false&&_isExcludedFromFee[_to]==false){
            (uint256 amount,uint256 burn_amount,uint256 lp_amount)=get_Shell_rate(_value);
            balanceOf[_from] = balanceOf[_from].sub( _value);
            balanceOf[_to] = balanceOf[_to].add(amount);
            //balanceOf[Marketing] = balanceOf[Marketing].add(Marketing_amount);
            balanceOf[address(this)] = balanceOf[address(this)].add(lp_amount);
            balanceOf[BurnAddr] = balanceOf[BurnAddr].add(burn_amount);
            
            emit Transfer(_from, address(this), lp_amount);
            emit Transfer(_from, BurnAddr, burn_amount);
            emit Transfer(_from, _to, amount);
        }else if(_from==uniswapV2Pair&&_isExcludedFromFee[_from]==false&&_isExcludedFromFee[_to]==false){
            (uint256 amount,uint256 lp_amount)=get_Buy_rate(_value);
            balanceOf[_from] = balanceOf[_from].sub( _value);
            balanceOf[_to] = balanceOf[_to].add(amount);
            //balanceOf[Marketing] = balanceOf[Marketing].add(Marketing_amount);
            balanceOf[address(this)] = balanceOf[address(this)].add(lp_amount);

            emit Transfer(_from, address(this), lp_amount);
            emit Transfer(_from, _to, amount);
            
        }else{
            balanceOf[_from] = balanceOf[_from].sub( _value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
        }
        
        return true;
     }
     
    
     function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);     // Check allowance
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public returns (bool success) {
        _approve(address(msg.sender),_spender,_value);
        return true;
    }
    
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    receive()external payable {
        
    }
    
    function get_Shell_rate(uint256 _value)public view returns(uint256,uint256,uint256){
        uint256 _burn =_value.mul(Shell_burn).div(10**2);
        //uint256 _Marketing=_value.mul(Shell_Marketing).div(10**2);
        uint256 _LP=_value.mul(Shell_LP).div(10**2);
        uint256 _amount=_value.sub(_burn).sub(_LP);
        return (_amount,_burn,_LP);
    }
    
    function get_Buy_rate(uint256 _value)public view returns(uint256,uint256){
        //uint256 _Marketing=_value.mul(Buy_Marketing).div(10**2);
        uint256 _LP=_value.mul(Buy_LP).div(10**2);
        uint256 _amount=_value.sub(_LP);
        return (_amount,_LP);
    }
    
    function Burn_amount()external view returns(uint256){
        return balanceOf[BurnAddr];
    }
    
    
   
    
    function swapAndLiquify(uint256 contractTokenBalance) private  {//lockTheSwap
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        //uniswapV2Router.WETH()

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEthToMarketing(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(Marketing),
            block.timestamp
        );
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );
    }
    
    

    
}