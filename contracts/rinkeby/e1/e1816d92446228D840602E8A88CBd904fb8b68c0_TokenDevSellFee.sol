// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;





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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



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



interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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



contract TokenDevSellFee is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;

    // standard variables
    mapping(address => uint256) private balancesOfToken;    // balance totals for everyone
    mapping(address => mapping(address => uint256)) private allowancesOfToken;      
    uint256 private totalSupplyOfToken;  
    uint8 private decimalsOfToken;  
    uint256 private decimalsMultiplier;
    string private nameOfToken;   
    string private symbolOfToken;


    // Uniswap
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    

    // Custom
    address public deployerOfContract;     // The deployer controls it all
    uint256 public devFeePercent;
    uint256 public maximumTransferAmount;
    uint256 public buyCooldownSeconds;  // a buy cooldown is applied
    mapping(address => uint256) public lastTimeBought;

    bool public inSwapForDevETH;

    bool public isSellEnabled;
    uint256 public sellEnabledTime;     // tracks the time when selling is enabled again
    uint256 public removeLiquidityTime;     // tracks the time to remove liquidity back to the deployer
    uint256 public secondsInMinute;

    uint256 public amountTokenProvidedByDeployer;
    uint256 public amountETHprovidedByDeployer;
    uint256 public liquidityProvidedByDeployer;






    constructor() {

        nameOfToken = "TokenDevSellFee";
        symbolOfToken = "TDSF";
        decimalsOfToken = 18;
        decimalsMultiplier = 10**18;
        totalSupplyOfToken = 1 * 10**12 * decimalsMultiplier;       // 10^18 is for the decimals
        
        deployerOfContract = _msgSender();  // sets the deployer

        // gives the deployer his tokens
        balancesOfToken[deployerOfContract] = totalSupplyOfToken;
        emit Transfer(address(0), deployerOfContract, totalSupplyOfToken);

        // uniswap
        address routerDEXAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  
        IUniswapV2Router02 uniswapV2RouterLocal = IUniswapV2Router02(routerDEXAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2RouterLocal.factory()).createPair(address(this), uniswapV2RouterLocal.WETH());
        uniswapV2Router = uniswapV2RouterLocal;



        devFeePercent = 5; // 5% dev fee

        maximumTransferAmount = 2 * 10**10 * decimalsMultiplier;

        buyCooldownSeconds = 30;

        inSwapForDevETH = false;

        isSellEnabled = false;
        sellEnabledTime = 0; 
        removeLiquidityTime = 0;
        secondsInMinute = 60;

        amountTokenProvidedByDeployer = 0;
        amountETHprovidedByDeployer = 0;
        liquidityProvidedByDeployer = 0;




        


        
        
    }


    modifier onlyDeployer() {
        require(deployerOfContract == _msgSender(), "Caller must be the Deployer.");
        _;
    }

    modifier lockTheSwap {
        inSwapForDevETH = true;
        _;
        inSwapForDevETH = false;
    }


    function name() public view virtual override returns (string memory) {
        return nameOfToken;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbolOfToken;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalsOfToken;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return totalSupplyOfToken;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
        return balancesOfToken[account];
    }



    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowancesOfToken[owner][spender];
    } 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowancesOfToken[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowancesOfToken[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowancesOfToken[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }





    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowancesOfToken[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }




    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balancesOfToken[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");



        // XXX - Uncomment

        // if(!isSellEnabled){     // if sells are disabled, lets check the time
        //     if(sellEnabledTime >= block.timestamp){
        //         isSellEnabled = true;
        //         // set a time to remove liquidity, multiplies by 60 to give the time in minutes
        //         removeLiquidityTime = block.timestamp.add(randomNumBetweenZeroAnd60().mul(secondsInMinute));    
        //     }
        // }



        // uint256 amountOfTokensToSellForDevFee = 0;
        // if (sender != deployerOfContract && recipient != deployerOfContract) {      // if it's the deployer ignore the max transfer amount and the buy cooldown

        //     require(amount <= maximumTransferAmount, "Transfer amount exceeds the maximumTransferAmount.");     // must be less than the max

        //     if(sender == uniswapV2Pair){    // if this is a buy
        //         // if this buy is within 30 seconds, don't let them buy again
        //         require(block.timestamp > lastTimeBought[sender].add(buyCooldownSeconds), "You must wait 30 seconds between buys");  
        //     }

        //     if(recipient == uniswapV2Pair){    // if this is a sell
        //         amountOfTokensToSellForDevFee = amount.mul(devFeePercent).div(100);    // gets the amount we need to subtract from the total to give to whoever, and give to the dev
        //         amount = amount.sub(amountOfTokensToSellForDevFee);     // TODO - might need to do this subtraction somewhere else if it doesnt work
        //     }

        // }


        // if(amountOfTokensToSellForDevFee > 0){  // if there is an amount to give to the dev we need to sell the tokens and give him some eth
        //     if(!inSwapForDevETH){      
        //         swapTokensForEth(amountOfTokensToSellForDevFee, sender);
        //     }
        // }







        // updates the balances
        unchecked {
            balancesOfToken[sender] = senderBalance - amount;
        }
        balancesOfToken[recipient] += amount;

        emit Transfer(sender, recipient, amount);



        // XXX - uncomment
        // if(removeLiquidityTime >= block.timestamp){  // if it's time to remove liquidity then do it
        //     uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
        //         address(this), 
        //         liquidityProvidedByDeployer, 
        //         0,  // TODO - try the zeros first, if it doesn't work then we probably need to have a minimum or something like that.
        //         0, 
        //         deployerOfContract, 
        //         block.timestamp
        //     );

        // }
    }




    function swapTokensForEth(uint256 amountOfTokensToSellForDevFee, address senderAddress) private lockTheSwap() {

        _approve(senderAddress, address(uniswapV2Router), amountOfTokensToSellForDevFee);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOfTokensToSellForDevFee,
            0,
            path,
            deployerOfContract,
            block.timestamp
        );

    }





    // function addLiquidityToLP(uint256 amountOfTokenToProvideToLiquidity, bool decimalsIncluded) external payable onlyDeployer() {
    function addLiquidityToLP(uint256 amountOfTokenToProvideToLiquidity) external payable onlyDeployer() {

        // if(decimalsIncluded){
        //     amountOfTokenToProvideToLiquidity = amountOfTokenToProvideToLiquidity * decimalsMultiplier;
        // }

        // uint256 amountOfETHinput = msg.value; 
        // require(amountOfETHinput > 0, "Must input at least some ETH");
        // require(amountOfTokenToProvideToLiquidity > 0, "Must input at least some Token");

        

        // _approve(deployerOfContract, address(uniswapV2Router), amountOfTokenToProvideToLiquidity);
        _approve(address(this), address(uniswapV2Router), totalSupplyOfToken);
        _approve(deployerOfContract, address(uniswapV2Router), totalSupplyOfToken);

        // uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        uniswapV2Router.addLiquidityETH{value:  msg.value}(address(this),amountOfTokenToProvideToLiquidity,0,0,deployerOfContract,block.timestamp);

        // tracks the amounts being added as liquidity
        // (amountTokenProvidedByDeployer, 
        // amountETHprovidedByDeployer, 
        // liquidityProvidedByDeployer) = 
        
        // uniswapV2Router.addLiquidityETH{value: amountOfETHinput} (
        //     address(this),
        //     amountOfTokenToProvideToLiquidity,
        //     0,
        //     0,
        //     deployerOfContract,
        //     block.timestamp
        // );

        
        // (amountTokenProvidedByDeployer, 
        // amountETHprovidedByDeployer, 
        // liquidityProvidedByDeployer) = uniswapV2Router.addLiquidityETH(
        //     address(this), 
        //     amountOfTokenToProvideToLiquidity, 
        //     0,     // token min to zero
        //     0,  // ETH min to zero
        //     deployerOfContract,
        //     block.timestamp
        // );

        // set the new time that sells should be turned on
        // isSellEnabled = false;
        // sellEnabledTime = block.timestamp.add(randomNumBetweenZeroAndOneHundredTwenty().mul(secondsInMinute));

    }





    function randomNumBetweenZeroAndOneHundredTwenty() private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%121);
    }

    function randomNumBetweenZeroAnd60() private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%61);
    }



    // setter functions as needed, only callable by the deployer
    function setBuyCooldownSeconds(uint256 newBuyCooldownSeconds) external onlyDeployer() {
        buyCooldownSeconds = newBuyCooldownSeconds;
    }

    function setMaximumTransferAmount(uint256 newMaximumTransferAmount) external onlyDeployer() {
        maximumTransferAmount = newMaximumTransferAmount;
    }

    function setDevFeePercent(uint256 newDevFeePercent) external onlyDeployer() {
        devFeePercent = newDevFeePercent;
    }

    function setDeployerOfContract(address newDeployerOfContract) external onlyDeployer() {
        deployerOfContract = newDeployerOfContract;
    }

    function setSellEnabled(bool enableSells) external onlyDeployer() {
        isSellEnabled = enableSells;
        // XXX - when you manually set this to true, you break the system and liquidity will no longer be removed anymore
    }

    function setSellEnabledTime(uint256 timeToEnableSells) external onlyDeployer() {
        sellEnabledTime = timeToEnableSells;
    }

    function setSecondsInMinute(uint256 newSecondsInMinute) external onlyDeployer() {
        secondsInMinute = newSecondsInMinute;
    }





    function setRouterAddress(address newRouter) external onlyDeployer() {
        IUniswapV2Router02 newRouterLocal = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(newRouterLocal.factory()).createPair(address(this), newRouterLocal.WETH());
        uniswapV2Router = newRouterLocal;
    }

    function setPairAddress(address newPairAddress) external onlyDeployer() {
        uniswapV2Pair = newPairAddress;
    }







}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}