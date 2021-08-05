/**
 *Submitted for verification at Etherscan.io on 2020-12-19
*/

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity >=0.5.0;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

pragma solidity ^0.6.0;

contract PrivateSale {
    
    using SafeMath for uint256;
    
    address payable public owner;
    uint256 public ratio = 9000000000000;
    IERC20 public token;
    IERC20 public usdc;
    IUniswapV2Pair public uni;
    uint256 public tokensSold;
    bool public saleEnded;
    uint256 public minimum = 45000 ether;
    uint256 public limit = 180000 ether;
    
    mapping(address => uint256) public permitted;
    
    event TokensPurchased(address indexed buyer, uint256 tokens, uint256 usdc, uint256 eth);
    event SaleEnded(uint256 indexed unsoldTokens, uint256 indexed collectedUSDC, uint256 indexed collectedETH);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to access this function.");
        _;
    }
    
    constructor (address tokenAddress, address usdcAddress, address uniAddress) public {
        
        token = IERC20(tokenAddress);
        usdc = IERC20(usdcAddress);
        uni = IUniswapV2Pair(uniAddress);
        owner = msg.sender;
    }


    function permit(address account) onlyOwner public {
        permitted[account] += limit;
    }
    
    function setLimits(uint256 min, uint256 max) onlyOwner public {
        minimum = min;
        limit = max;
    }
    
    receive() external payable {
        buyWithETH();
    }
    
    function buyWithUSDC(uint256 amountUSDC) public {

        uint256 tokens = amountUSDC.mul(ratio);
        require(!saleEnded, "Sale has already ended");
        require(tokens <= token.balanceOf(address(this)), "Not enough tokens for sale");
        require(tokens <= permitted[msg.sender], "The amount exceeds your limit");
        require(tokens >= minimum, "The amount is less than minimum");
        permitted[msg.sender] -= tokens;
        require(usdc.transferFrom(msg.sender, address(this), amountUSDC));        
        require(token.transfer(msg.sender, tokens));
        tokensSold += tokens;

        emit TokensPurchased(msg.sender, tokens, amountUSDC, 0);
    }

    function buyWithETH() payable public {

        (uint112 a, uint112 b, uint32 c) = uni.getReserves();
        uint256 tokens = msg.value.mul(ratio).mul(a).div(b);
        require(!saleEnded, "Sale has already ended");
        require(tokens <= token.balanceOf(address(this)), "Not enough tokens for sale");
        require(tokens <= permitted[msg.sender], "The amount exceeds your limit");
        require(tokens >= minimum, "The amount is less than minimum");
        permitted[msg.sender] -= tokens;
        token.transfer(msg.sender, tokens);
        tokensSold += tokens;

        emit TokensPurchased(msg.sender, tokens, 0, msg.value);
    }
    
    function endSale() onlyOwner public {
        uint256 tokens = token.balanceOf(address(this));
        uint256 usd = usdc.balanceOf(address(this));
        uint256 eth = address(this).balance;
        token.transfer(owner, tokens);
        usdc.transfer(owner, usd);
        owner.transfer(eth);
        saleEnded = true;
        emit SaleEnded(tokens, usd, eth);
    }
    
    
}