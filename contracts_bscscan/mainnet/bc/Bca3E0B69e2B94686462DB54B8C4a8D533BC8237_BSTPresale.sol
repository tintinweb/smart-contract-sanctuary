/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later Or MIT

/**
 *Submitted for verification at BscScan.com on 2021-05-28
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);

    function approve(address spender, uint256 amount) external returns (bool);
}

// pragma solidity >=0.6.2;

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

contract BSTPresale {
    using SafeMath for uint256;

    IBEP20 public BST;
    
    address payable public owner;

    uint256 public startDate = 1642060800;                  // 2022/01/13 08:00:00 UTC
    uint256 public endDate = 1642665600;                    // 2022/01/20 08:00:00 UTC
    uint256 public lockDate = 1645344000;                    // 2022/02/20 08:00:00 UTC
    
    uint256 public totalTokensToSell = 40000000 * 10**18;          // 40000000 BST tokens for sell
    uint256 public bstPerBnb = 18000 * 10**18;             // 1 BNB = 18000 BST
    uint256 public minPerTransaction = 270 * 10**18;         // min amount per transaction (0.015BNB)
    uint256 public maxPerUser = 180000 * 10**18;                // max amount per user (10BNB)
    uint256 public totalSold;

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    bool public saleEnded;
    
    mapping(address => uint256) public bstPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);
    event addLiquidityEvent(uint256 tokenAmount, uint256 ethAmount, uint256 allowance);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(now >= startDate && now < endDate, 'Blockstar Presale Launchpad time passed');
        require(saleEnded == false, 'Sale ended');
        require(
            buyAmount > 0 && buyAmount <= unsoldTokens(),
            'Insufficient buy amount'
        );
        _;
    }

    modifier checkWithdrawLPRequirements() {
        require(now >= lockDate, 'LP is locked.');
        require(saleEnded == true, 'Sale not finished.');
        _;
    }

    constructor(
        address _BST        
    ) public {
        owner = msg.sender;
        BST = IBEP20(_BST);
    }

    // Function to buy BST using BNB token
    function buyWithBNB(uint256 buyAmount) public payable checkSaleRequirements(buyAmount) {
        uint256 amount = calculateBNBAmount(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
        require(buyAmount >= minPerTransaction, 'Lower than the minimal transaction amount');
        
        uint256 sumSoFar = bstPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        bstPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);
        
        BST.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    //function to change the owner
    //only owner can call this function
    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    // function to set the presale start date
    // only owner can call this function
    function setStartDate(uint256 _startDate) public {
        require(msg.sender == owner && saleEnded == false);
        startDate = _startDate;
    }

    // function to set the presale end date
    // only owner can call this function
    function setEndDate(uint256 _endDate) public {
        require(msg.sender == owner && saleEnded == false);
        endDate = _endDate;
    }

    // function to set the presale end date
    // only owner can call this function
    function setLockDate(uint256 _lockDate) public {
        require(msg.sender == owner && saleEnded == false);
        lockDate = _lockDate;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTotalTokensToSell(uint256 _totalTokensToSell) public {
        require(msg.sender == owner);
        totalTokensToSell = _totalTokensToSell;
    }

    // function to set the minimal transaction amount
    // only owner can call this function
    function setMinPerTransaction(uint256 _minPerTransaction) public {
        require(msg.sender == owner);
        minPerTransaction = _minPerTransaction;
    }

    // function to set the maximum amount which a user can buy
    // only owner can call this function
    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTokenPricePerBNB(uint256 _bstPerBnb) public {
        require(msg.sender == owner);
        require(_bstPerBnb > 0, "Invalid BST price per BNB");
        bstPerBnb = _bstPerBnb;
    }

    //function to end the sale
    //only owner can call this function
    function endSale() public {
        require(msg.sender == owner && saleEnded == false);
        saleEnded = true;
        
        uint256 bnbAmount = address(this).balance.mul(90).div(100);
        uint256 tokenAmount = BST.balanceOf(address(this));
        
        addLiquidity(tokenAmount, bnbAmount);
    }

    //function to withdraw collected tokens by sale.
    //only owner can call this function

    function withdrawCollectedTokens() public {
        require(msg.sender == owner);
        require(address(this).balance > 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    function claimTokens(uint256 amount) public {
        require(msg.sender == owner);
        require(amount > 0, "Invalid amount");
        require(address(this).balance > amount, "Insufficient balance");
        owner.transfer(amount);
    }

    //function to withdraw unsold tokens
    //only owner can call this function
    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, "No remained tokens");
        BST.transfer(owner, remainedTokens);
    }

    //function to withdraw locked lp tokens
    //only owner can call this function
    function withdrawLockedLPTokens() public checkWithdrawLPRequirements(){
        require(msg.sender == owner);
        uint256 lockedLPTokens = lockedLPTokens();
        require(lockedLPTokens > 0, "No locked LP tokens");

        IUniswapV2Pair(uniswapV2Pair).transfer(owner, lockedLPTokens);
    }

    //function to return the amount of unsold tokens
    function unsoldTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return BST.balanceOf(address(this));
    }

    //function to return the amount of unsold tokens
    function lockedLPTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return IUniswapV2Pair(uniswapV2Pair).balanceOf(address(this));
    }

    //function to calculate the quantity of BST token based on the BST price of bnbAmount
    function calculateBSTAmount(uint256 bnbAmount) public view returns (uint256) {
        uint256 bstAmount = bstPerBnb.mul(bnbAmount).div(10**18);
        return bstAmount;
    }

    //function to calculate the quantity of bnb needed using its BST price to buy `buyAmount` of BST tokens.
    function calculateBNBAmount(uint256 bstAmount) public view returns (uint256) {
        require(bstPerBnb > 0, "BST price per BNB should be greater than 0");
        uint256 bnbAmount = bstAmount.mul(10**18).div(bstPerBnb);
        return bnbAmount;
    }

    function setRouter(address _router) public {
        require(msg.sender == owner && saleEnded == false);
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(_router);

        if (IUniswapV2Factory(_newPancakeRouter.factory()).getPair(address(BST), _newPancakeRouter.WETH()) == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(BST), _newPancakeRouter.WETH());
        } else {
            uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).getPair(address(BST), _newPancakeRouter.WETH());
        }
        
        uniswapV2Router = _newPancakeRouter;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        BST.approve(address(uniswapV2Router), tokenAmount);
        uint256 allowance = BST.allowance(address(this), address(uniswapV2Router));
        
        emit addLiquidityEvent(tokenAmount, ethAmount, allowance);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(BST),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}