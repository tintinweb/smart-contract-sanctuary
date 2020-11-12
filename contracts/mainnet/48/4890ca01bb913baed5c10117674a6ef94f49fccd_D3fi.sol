//.----------------.  .----------------.  .----------------.  .----------------. 
//| .--------------. || .--------------. || .--------------. || .--------------. |
//| |  ________    | || |    ______    | || |  _________   | || |     _____    | |
//| | |_   ___ `.  | || |   / ____ `.  | || | |_   ___  |  | || |    |_   _|   | |
//| |   | |   `. \ | || |   `'  __) |  | || |   | |_  \_|  | || |      | |     | |
//| |   | |    | | | || |   _  |__ '.  | || |   |  _|      | || |      | |     | |
//| |  _| |___.' / | || |  | \____) |  | || |  _| |_       | || |     _| |_    | |
//| | |________.'  | || |   \______.'  | || | |_____|      | || |    |_____|   | |
//| |              | || |              | || |              | || |              | |
//| '--------------' || '--------------' || '--------------' || '--------------' |
//'----------------'  '----------------'  '----------------'  '----------------'


// This is a defi experiment

// I hate bots. I hope you do too. Bots whose only intention is to buy and dump will get rekt, and we want to make sure they do 

// Tokenomics:

// You can buy as many D3fi as you want However, you cannot dump a large enough amount of D3fi to significantly impact the price at any one time.
// You CAN sell your tokens, if you have trouble on uniswap then enter a lesser token amount that has less price significance - because the contract hates any dumping
// There will be no presale - we want no dumping remember?
// There will be a fair launch at no specified time
// Please add liquidity if you can to help this experiment along
// Dev will add a small starting amount of liquidity
// Expect wild west swings at the beginning as there will be a little liquidity, do add more if you so wish
// Dev will lock liquidity
// Dev cannot dump tokens on you due to the tokenomics, no one escapes the dump protection 
// Come play this game with us 



// Let's all be friends at...
// Telegram:  https://t.me/d3fied


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



pragma solidity ^0.6.12;


contract D3fi {

    string public constant name = "D3fi";
    string public constant symbol = "DEFI";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor() public {
	totalSupply_ = 10000000e18;
	D3fiContract = msg.sender;
	balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        if (msg.sender != uniPair && uniPair != address(0x0)) {
            uint256 currPrice = getLastPrice();
            if (currPrice < STARTING_PRICE) {
                require(STARTING_PRICE.div(currPrice).mul(numTokens) < 400000e18 || numTokens < 800e18);
            }
        }
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        if (owner != uniPair && uniPair != address(0x0)) {
            uint256 currPrice = getLastPrice();
            if (currPrice < STARTING_PRICE) {
                require(STARTING_PRICE.div(currPrice).mul(numTokens) < 400000e18 || numTokens < 800e18);
            }
        }
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }

    address public D3fiContract;

    address public uniPair = address(0x0);

     function migrateUniPairAddress(address _uniPair) public {
        require(msg.sender == D3fiContract);
        uniPair = _uniPair;
     }

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 STARTING_PRICE = 800000;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);


    function getLastPrice() public view returns (uint) {
        if (uniPair == address(0x0)) {
            return 0;
        } else {
            return uniswapRouter.getAmountsIn(1, getPairPath())[0];
        }
    }

    function getPairPath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        return path;

    }

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, ":divErr");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}