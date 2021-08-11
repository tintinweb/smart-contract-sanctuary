/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// File: UniswapInterface.sol


pragma solidity >=0.7.2;

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

// pragma solidity >=0.7.2;

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



// pragma solidity >=0.7.2;

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
// File: SafeMath.sol

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



// File: Owner.sol



pragma solidity ^0.7.2;

    contract Owner
    {
        address private _owner;
        mapping(address=> bool) blacklist;
        event AddToBlackList(address _blacklisted);
        event RemoveFromBlackList(address _whitelisted);
        constructor() 
        {
            _owner = msg.sender;
        }
        
        function getOwner() public view returns(address) { return _owner; }
        
        modifier isOwner()
        {
            require(msg.sender == _owner,'Your are not Authorized user');
            _;
            
        }
        
        modifier isblacklisted(address holder)
        {
            require(blacklist[holder] == false,"You are blacklisted");
            _;
        }
        
        function chnageOwner(address newOwner) isOwner() external
        {
            _owner = newOwner;
        }
        
        function addtoblacklist (address blacklistaddress) isOwner()  public
        {
            blacklist[blacklistaddress] = true;
            emit AddToBlackList(blacklistaddress);
        }
        
        function removefromblacklist (address whitelistaddress) isOwner()  public
        {
            blacklist[whitelistaddress]=false;
            emit RemoveFromBlackList(whitelistaddress);
        }
        
        function showstateofuser(address _address) public view returns (bool)
        {
            return blacklist[_address];
        }
    }

// File: HOPE.sol


pragma solidity ^0.7.2;




abstract contract  ERC20Interface {
   
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    function balanceOf(address to) virtual public view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface SafeTranser{
    function safeTransfer(address to,uint amount,bool init) external returns(bool);
}

interface LpTransferReward{
    function LpTransfer(address to,uint amount) external returns (bool);
}

interface IReward{
    function isRewardPool() external returns(bool);
}

interface IRefill{
    function refillPool(uint _refillAmout) external;
}

interface IUniPair{
    function UniPair() external view returns(address);
}

contract HOLD is ERC20Interface,Owner,LpTransferReward,SafeTranser,IUniPair
{

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public  totalSupply;
    
    
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;
    
    // uint public Tax = 4;

    uint public treasuryPer = 33; 
    uint public rewardPoolPer = 33;
    uint public tokenSalePer = 10;
    uint public teamPer = 15;
    uint public marketingPer = 9;

    uint public redistribute = 3;
    uint public buyBackLP = 2;

    bool public swapAndLiquify;
    bool public inSwapAndLiquify;
    
    uint MAX_TOKEN_FOR_BUYBACK = 1 * 10**12 * 10**18;
    
    event check(address a);

    mapping(address => bool) public isExcluded;
    mapping(address => bool) public isInclude;

    address[] public tokenHolders;

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    event Mint(address to,uint amount);
    event Burn(uint amount);

    event Redistribute(address _to,uint amount);

     modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address router,
                address treasury,
                address rewardPool,
                // address tokenSale,
                address team,
                address marketing
    )
    {
        name = "HOPE";
        symbol = "HOPE";
        decimals = 18;
        totalSupply =  1 * 10**15 * 10**18;

        _balanceOf[treasury] = totalSupply.mul(treasuryPer).div(100);
        _balanceOf[rewardPool] = totalSupply.mul(rewardPoolPer).div(100);
        _balanceOf[getOwner()] = totalSupply.mul(tokenSalePer).div(100);
        // balanceOf[tokenSale]  = totalSupply.mul(tokenSalePer).div(100);
        _balanceOf[team] = totalSupply.mul(teamPer).div(100);
        _balanceOf[marketing] = totalSupply.mul(marketingPer).div(100);

        // IRefill(rewardPool).refillPool(totalSupply.mul(rewardPoolPer).div(100));

        // balanceOf[getOwner()] = totalSupply;
        newTokenHolder(getOwner());
        newTokenHolder(treasury);
        newTokenHolder(rewardPool);

        isExcluded[router] = true;

        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0),treasury,_balanceOf[treasury]);
        emit Transfer(address(0),rewardPool,_balanceOf[rewardPool]);
        emit Transfer(address(0),getOwner(),_balanceOf[getOwner()]);
        emit Transfer(address(0),team,_balanceOf[team]);
        emit Transfer(address(0),marketing,_balanceOf[marketing]);
    }
    
    
    function MintTokens(address to, uint amount) isvalid() external {
         totalSupply = totalSupply.add(amount);

        _balanceOf[to] = _balanceOf[to].add(amount);
        emit Mint(to,amount);
    }

    function BurnTokens(address user,uint amount) isvalid() external {
       totalSupply = totalSupply.sub(amount);

        _balanceOf[user] = _balanceOf[user].sub(amount);
        emit Burn(amount);
    }
    
    modifier isvalid(){
        require(msg.sender == address(this),"Not Authenticated User !!!");  
        _;
    }

    function addToExclude(address to) external {
        require(isExcluded[to] == false,"Already excluded !!!");
        isExcluded[to] = true;
    }
   
    function balanceOf(address to) public view override returns(uint){
        return _balanceOf[to];
    }

    function allowance(address from, address who) isblacklisted(from) public override view returns (uint remaining)
    {
        return allowed[from][who];
    }
    
    function transfer(address to, uint tokens) isblacklisted(msg.sender) public override returns (bool success)
    {
        if(!swapAndLiquify){
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(tokens);
            _balanceOf[to] = _balanceOf[to].add(tokens);
        }else{
        _transfer(msg.sender, to, tokens);
        }

       emit Transfer(msg.sender,to,tokens);
        return true;
    }
    
    function approve(address to, uint tokens) isblacklisted(msg.sender) public override returns (bool success)
    {
        allowed[msg.sender][to] = tokens;
        emit Approval(msg.sender,to,tokens);
        return true;
    }
    
    function _approve(address from,address to, uint tokens) isblacklisted(msg.sender) internal  returns (bool success)
    {
        allowed[from][to] = tokens;
        emit Approval(from,to,tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) isblacklisted(from) public override returns (bool success)
    {
        require(allowed[from][msg.sender] >= tokens || from == msg.sender,"Not sufficient allowance");
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        if(!swapAndLiquify){
            _balanceOf[from] = _balanceOf[from].sub(tokens);
            _balanceOf[to] = _balanceOf[to].add(tokens);
        }else{
        _transfer(from, to, tokens);
        }

        emit Transfer(from,to,tokens);
        return true;
    }

    function _transfer(address from,address to,uint amount) private {

        uint redistri = getValues(amount, redistribute);
        uint buyBack = 0;
        
        RedistributeFee(redistri,from);
        
        emit check(from);
        if(amount >= MAX_TOKEN_FOR_BUYBACK && !inSwapAndLiquify && from != address(uniswapV2Pair)){
            // uint a = balanceOf[address(this)];
            // BuyBackAndBurn(buyBack);
            buyBack = getValues(amount, buyBackLP);
            _balanceOf[address(this)] = _balanceOf[address(this)].add(buyBack);
            recurse(buyBack);
        }

        _balanceOf[from] = _balanceOf[from].sub(amount);
        _balanceOf[to] = _balanceOf[to].add(amount).sub(redistri).sub(buyBack);

        newTokenHolder(to);
        

    }

    function RedistributeFee(uint amount,address sender) private {
        for(uint i=0;i<tokenHolders.length;i++){
            if(isExcluded[tokenHolders[i]] == false && tokenHolders[i] != sender){
                uint userShare = amount.mul(_balanceOf[tokenHolders[i]]).div(totalSupply);
                _balanceOf[tokenHolders[i]] = _balanceOf[tokenHolders[i]].add(userShare);
                emit Redistribute(tokenHolders[i],userShare);
            }
        }
        
        
    }

    function recurse(uint amount) lockTheSwap  internal {
       BuyBackAndBurn(amount);
    }

    receive() external payable {}

    function swapWithETH(uint tokens) internal{

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokens);

       // Do swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 30 days
        );
    }

    function addLiquidity(uint token,uint eth) internal {
        _approve(address(this), address(uniswapV2Router), token);

        //add the liquidity
        uniswapV2Router.addLiquidityETH{value: eth}(
            address(this),
            token,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp + 30 days
        );
    }

    function newTokenHolder(address to) private {
        if(isInclude[to] == false){
            isInclude[to] = true;
            tokenHolders.push(to);
        }
    }

    function BuyBackAndBurn(uint amount) lockTheSwap private {

        uint initialEthBalance = address(this).balance;
        uint half = amount.div(2);
        swapWithETH(half);

        uint finalEthBalance = address(this).balance.sub(initialEthBalance);
        uint token = amount.sub(half);

        addLiquidity(token,finalEthBalance);

    }

    function getValues(uint amount,uint _tax) public pure returns(uint) {
        return amount.mul(_tax).div(100);
    }

    function length() public view returns(uint){
        return tokenHolders.length;
    }

    function LpTransfer(address to,uint amount) external override returns(bool){
        require(IReward(address(msg.sender)).isRewardPool(),"Only Reward Pool !!!");

        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amount);
        _balanceOf[to] = _balanceOf[to].add(amount);
        return true;        
    }

    function safeTransfer(address to,uint amount,bool init) external override returns(bool){
        require(msg.sender == getOwner(),"You are not owner !!!");
        require(IReward(to).isRewardPool(),"Destination is not Reward Pool");
        if(!init){
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amount);
            _balanceOf[to] = _balanceOf[to].add(amount);
        }
        IRefill(to).refillPool(amount);
        return true;
    }

    function UniPair() external view override returns(address){
        return uniswapV2Pair;
    }

    function setSwapAndLiquify(bool _liquify) external {
        require(msg.sender == getOwner(),"only owner can !!!");
        swapAndLiquify = _liquify;
    }
}