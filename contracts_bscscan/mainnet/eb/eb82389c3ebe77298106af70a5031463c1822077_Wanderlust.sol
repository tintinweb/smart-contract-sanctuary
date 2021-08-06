/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed

// wanderlust.finance
// t.me/wanderlust_official

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;
 
    function setUniswapRouter(address r) external;

    function withdrawBEP20SentToContractAddress(address tokenAddress) external;
    
    function withdrawBNBSentToContractAddress() external;
    
    function setMarketingAddress(address payable user) external;
    
    function setFees(bool condition) external;
    
    function changeNumTokensSellToAddToLiquidity(uint256 amount) external;
    
    function addToWhiteist(address user) external;
    
    function removeFromWhiteist(address user) external;
    
    function whiteListed(address user) external view returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp  > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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

contract Wanderlust is IERC20, Ownable {

    bool private _fees = false;
    
    address payable private _marketing;
    
    uint256 private _deploymentBlock;
    uint256 private _totalSupply = 1000 * 10**12 * 10**8;
    uint256 private _currentSupply = 1000 * 10**12 * 10**8;
    
    uint256 private _redistributed;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    mapping (address => bool) private _whiteListed;
    
    mapping (address => uint256) private _claimedDays;
    mapping (uint256 => uint256) private _dayrewards;
    mapping (uint256 => uint256) private _totalSupplyOnDay;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    uint256 private numTokensSellToAddToLiquidity = 50 * 10**12 * 10**8;
    
    uint256 private marketingBalance;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor (address routerAddress, address payable marketingAddress)  {
        _marketing = marketingAddress;
        _balances[msg.sender] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        _allowances[address(this)][address(uniswapV2Router)] = 1000 * 10**12 * 10**8;
    }
    
    fallback() external payable {}

    function name() public pure returns (string memory) {
        return "Wanderlust";
    }

    function symbol() public pure returns (string memory) {
        return "WANDER";
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
    if(account == address(0)){return _balances[address(0)];}
        uint256 day = (block.number - _deploymentBlock) / 28800;
        uint256 rewards;
        uint256 balance = _balances[account];
        for(uint256 t = _claimedDays[account]; t < day; ++t){
            rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
        }
        
        return _balances[account] + rewards;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_fees){
            _balances[from] -= amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this)) - marketingBalance;
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && from != uniswapV2Pair && from != address(uniswapV2Router) && from != address(this)) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
            
            
            uint256 toBNB = marketingBalance * 66 / 100;
            marketingBalance -= toBNB;
            _balances[_marketing] += marketingBalance;
            emit Transfer(address(this), _marketing, marketingBalance);
            marketingBalance = 0;
            swapTokensForEth(toBNB);
            _marketing.transfer(address(this).balance);
        }
        
        if(from == address(this)){
        claimRewards(address(this));
        claimRewards(to);
            _balances[address(this)] -= amount;
            _balances[to] += amount;
        }
        else{_tokenTransfer(from,to,amount);}

    }

    function swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 
        
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function applyFee(address user, uint256 amount, uint256 burn, uint256 redistribution, uint256 _liquidity, uint256 Marketing) internal returns(uint256){
        
        uint256 day = (block.number - _deploymentBlock) / 28800; //28800
        
        uint256 _burn = amount * burn / 100;
        uint256 percent3 = amount * redistribution / 100;
        uint256 liquidity = amount * _liquidity / 100;
        uint256 marketing = amount * Marketing / 100;
        
        _dayrewards[day] += percent3;
        _balances[address(0)] += _burn;
        _currentSupply -= burn;
        
        emit Transfer(user, address(0), _burn);
        
        if(_totalSupplyOnDay[day] == 0){_totalSupplyOnDay[day] = _currentSupply - percent3;}
        else{_totalSupplyOnDay[day] -= (burn + percent3);}
        
        marketingBalance += marketing;
        
        _redistributed += percent3;
        _balances[address(this)] += liquidity + marketing;
        emit Transfer(user, address(this), liquidity + marketing);
        
        return (_burn + percent3 + liquidity + marketing);
        
    }
    
    function claimRewards(address user) internal {
        uint256 day = (block.number - _deploymentBlock) / 28800;
        uint256 rewards;
        uint256 balance = _balances[user];
        for(uint256 t = _claimedDays[user]; t < day; ++t){
            rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
        }
        
        _claimedDays[user] = day;
        _balances[user] += rewards;
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        claimRewards(sender);
        claimRewards(recipient);
        
        if(_whiteListed[sender] || _whiteListed[recipient]){
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
        else{
            _balances[sender] -= amount;
            uint256 remaining = amount - applyFee(sender, amount, 1, 3, 3, 3);
            _balances[recipient] += remaining;
            emit Transfer(sender, recipient, remaining);
        }
    }

    function setUniswapRouter(address r) external override onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(r);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }
    
    function withdrawBEP20SentToContractAddress(address tokenAddress) external override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function withdrawBNBSentToContractAddress() public override onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function setMarketingAddress(address payable user) external override onlyOwner {
        _marketing = user;
    }
    
    function setFees(bool condition) external override onlyOwner {
        _fees = condition;
    }
    
    function changeNumTokensSellToAddToLiquidity(uint256 amount) external override onlyOwner {
        numTokensSellToAddToLiquidity = amount;
    }
    
    function addToWhiteist(address user) external override onlyOwner{
        _whiteListed[user] = true;
    }
    
    function removeFromWhiteist(address user) external override onlyOwner{
        _whiteListed[user] = false;
    }
    
    function whiteListed(address user) external view override returns(bool){
        return _whiteListed[user];
    }
}