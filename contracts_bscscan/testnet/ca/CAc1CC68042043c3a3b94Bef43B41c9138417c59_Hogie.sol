/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

/*
2% Auto LP
5% Marketing
1% team
2% Staking Pool

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract Hogie is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Hogie";
    string private constant _symbol = "HOGIE";
    uint8 private constant _decimals = 18;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _tTotal = 100000000000 * 10**18; // 100 Bilion
    uint256 public _maxWalletAmount;


    // fees
    uint256 public _liquidityFee = 2; // divided by 100
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _marketingFee = 5; // divided by 100
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _teamFee = 1; // divided by 100
    uint256 private _previousTeamFee = _teamFee;
    uint256 public _stakingPoolFee = 1; // divided by 100
    uint256 private _previousStakingPoolFee = _stakingPoolFee;
    
    
    uint256 private _marketingPercent = 83;
    uint256 private _teamPercent = 17;
    // uint256 private _stakingPoolPercent = 17;

    address payable public _marketingAddress = payable(0xA5347334AF09Bbc6C2456AB435F54ef8189FA709);
    address payable public _teamAddress = payable(0x5cCaA2b9f967019FE5ea59AC572407dBe0858cbE);
    address public _stakingPoolAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _maxTxAmount;
    bool public swapAndLiquifyEnabled = false;
    uint256 public _minTokenBeforeSwap = 10000 * 10**18;

    bool private inSwap = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _teamPercent/*, uint256 _stakingPoolPercent*/);
    event FeesUpdated(uint256 _marketingFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _stakingPoolFee);
    event MaxWalletAmountUpdated(uint256 amount);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ExcludedFromFees(address account);
    event IncludedInFees(address account);
    event StakingPoolUpdated(address stakingPool);
    event MarkettingAddressUpdated(address markettingAddress);
    event TeamAddressUpdated(address teamAddress);


    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _stakingPoolAddress = address(0xBD92de26245518A172732222749e662Fb28b4674);
        _maxTxAmount = _tTotal.div(100); // start off transaction limit at 1% of total supply
        _maxWalletAmount = _tTotal.mul(3).div(100); // 3%

        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeAllFee() private {
        if (_marketingFee == 0 && _liquidityFee == 0 && _teamFee == 0 && _stakingPoolFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousStakingPoolFee = _stakingPoolFee;
        
        _marketingFee = 0;
        _liquidityFee = 0;
        _teamFee = 0;
        _stakingPoolFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _teamFee = _previousTeamFee;
        _stakingPoolFee = _previousStakingPoolFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _maxTxAmount, "Amount exceeds Max Transaction Amount");

        bool takeFee = true;

        if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys
            require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
        }

        if (!inSwap && from != uniswapV2Pair) { //sells, transfers
                
            if(to != uniswapV2Pair) {       
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > _minTokenBeforeSwap && swapAndLiquifyEnabled) {
                swapAndLiquify(contractTokenBalance); 
            }

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }              
        } 

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              address(this),
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = _liquidityFee.mul(contractTokenBalance).div(_marketingFee.add(_teamFee).add(_stakingPoolFee).add(_liquidityFee));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(otherHalf); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);

        // add liquidity to pancakeswap
        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _teamAddress.transfer(amount.mul(_teamPercent).div(100));
        // _stakingPoolAddress.transfer(amount.mul(_stakingPoolPercent).div(100));
    }

    function manualTrigger() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapAndLiquify(contractBalance);
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 0) {
                sendETHToFee(contractETHBalance);
            }
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        _transferStandard(sender, recipient, amount);
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        // FeeBreakdown memory fees;
        uint256 tMarketing = amount.mul(_marketingFee).div(100);
        uint256 tLiquidity = amount.mul(_liquidityFee).div(100);
        uint256 tTeam = amount.mul(_teamFee).div(100);
        uint256 tStakingPool = amount.mul(_stakingPoolFee).div(100);
        
        uint256 tAmount = amount.sub(tMarketing).sub(tLiquidity).sub(tTeam).sub(tStakingPool);
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tAmount);
        _balances[address(this)] = _balances[address(this)].add(tMarketing.add(tLiquidity).add(tTeam)/*.add(tStakingPool)*/);
        _balances[_stakingPoolAddress] = _balances[_stakingPoolAddress].add(tStakingPool);
        
        emit Transfer(sender, recipient, tAmount);
        emit Transfer(sender, _stakingPoolAddress, tStakingPool);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > _tTotal.div(10000), "Amount must be greater than 0.01% of supply");
        require(maxTxAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }

    function setTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 teamFee, uint256 stakingPoolFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(teamFee).add(stakingPoolFee);
        require(totalFee <= 15, "Sum of fees must be less than or equals to 15");

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _teamFee = teamFee;
        _stakingPoolFee = stakingPoolFee;
        
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousStakingPoolFee = _stakingPoolFee;
        
        uint256 totalBNBfees = _marketingFee.add(_teamFee);/*.add(_stakingPoolFee)*/
        
        _marketingPercent = (_marketingFee.mul(100)).div(totalBNBfees);
        _teamPercent = (_teamFee.mul(100)).div(totalBNBfees);
        // _stakingPoolPercent = (_stakingPoolFee.mul(100)).div(totalBNBfees);
        
        emit FeesUpdated(_marketingFee, _liquidityFee, _teamFee, _stakingPoolFee);
    }

    function updateMinTokenBeforeSwap(uint256 minTokenBeforeSwap) external onlyOwner() {
        _minTokenBeforeSwap = minTokenBeforeSwap;
        emit MinTokensBeforeSwapUpdated(_minTokenBeforeSwap);
    }

    function updatestakingPoolAddress(address stakingPoolAddress) external onlyOwner() {
        _stakingPoolAddress = stakingPoolAddress;
        emit StakingPoolUpdated(_stakingPoolAddress);
    }
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
        emit MarkettingAddressUpdated(_marketingAddress);
    }
    
    function updateTeamAddress(address payable teamAddress) external onlyOwner() {
        _teamAddress = teamAddress;
        emit TeamAddressUpdated(_teamAddress);
    }
}