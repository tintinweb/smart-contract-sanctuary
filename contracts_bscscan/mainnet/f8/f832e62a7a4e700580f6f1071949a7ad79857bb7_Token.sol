/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT

 /*
   _____           _     _   _____             
  / ____|         (_)   | | |_   _|            
 | |     _____   ___  __| |   | |  _ __  _   _ 
 | |    / _ \ \ / / |/ _` |   | | | '_ \| | | |
 | |___| (_) \ V /| | (_| |  _| |_| | | | |_| |
  \_____\___/ \_/ |_|\__,_| |_____|_| |_|\__,_|
*/
                                               
pragma solidity ^0.8.7;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router {
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


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}






contract Token is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    uint256 private immutable _totalSupply;
    string private _name;
    string private _symbol;

    address public _marketingWallet = 0x08cA5d83b547287BdaaF5291D207c72775b38cA7;
    address public  _treasuryWallet = 0xAC5C80E34Fcd8248219EfE441f0bF91e7CE9A53a;
    address public _lpWallet = 0xB92dBd16BAc60fD583bA67aCd36a78240B31150E;

    uint8 public constant _maxTotalFee = 8;
    uint8 public _totalFee = 8;
    uint8 public _liquidityFee = 4;
    uint8 public _marketingFee = 3;
    uint8 public _treasuryFee = 1;

    address constant public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingStarted = false;
    bool public distributeFeesEnabled = false;
    bool private inDistributeFees = false;

    modifier lockDistributeFees {
        inDistributeFees = true;
        _;
        inDistributeFees = false;
    }

    // our community launch logic
    uint256 private _firstBlock;
    uint256 private _communityLaunchDuration = 1800;
    uint256 private constant _maxWalletDuringLaunch = 5600000000 * 10**18;          // fees
    mapping (address => bool) private _whitelisted;

    receive() external payable {}
    
    constructor() {
        _name = "Covid Inu";
        _symbol = "CINU";
        _transferOwnership(_msgSender());

        uint256 amount = 1000000000000 * 10**18;

        _totalSupply = amount;
        _balances[owner()] = amount;
        emit Transfer(address(0), owner(), amount);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(routerAddress);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_treasuryWallet] = true;
        _isExcludedFromFee[_lpWallet] = true;
        _isExcludedFromFee[owner()] = true;

        whitelistAddresses(); 
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(tradingStarted || ( sender == owner() ), "go away bot :)");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(block.timestamp < _firstBlock + _communityLaunchDuration){
            if(recipient != uniswapV2Pair && recipient != address(this) && recipient != address(uniswapV2Router)){
                require(_whitelisted[recipient],"you cannot buy right now");
                require(_balances[recipient] + amount <= _maxWalletDuringLaunch);      
            }
        }

        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        if( 
            ( balanceOf(address(this)) > totalSupply()/1000 ) 
            && distributeFeesEnabled 
            && recipient == uniswapV2Pair 
            && !inDistributeFees 
            && _totalFee > 0 ){
                _distributeFees();
        }

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            _transferWithoutFees(recipient, amount);
        } else {
            _transferWithFees(recipient, amount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _transferWithoutFees(address recipient, uint256 amount) internal virtual {
        _balances[recipient] += amount;
    }

    function _transferWithFees(address recipient, uint256 amount) internal virtual {
        uint256 fee = (amount / 100) * _totalFee;
        uint256 value = amount - fee;

        _balances[recipient] += value;
        _balances[address(this)] += fee;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function distributeFees() external onlyOwner{
        _distributeFees();

        // sending extra bnb locked in the contract to the _marketingWallet
        if(address(this).balance > 1){
            address payable wallet = payable(_marketingWallet);
            uint256 balance = address(this).balance;
            wallet.transfer(balance);
        }

    }

    function _distributeFees() internal lockDistributeFees {
        require(balanceOf(address(this)) > 0, "distribute: balance = 0!");
        require(_totalFee > 0, "zero division");

        uint256 total = balanceOf(address(this));

        uint256 marketingFee = (total / _totalFee) * _marketingFee;
        _transfer(address(this), _marketingWallet, marketingFee);

        uint256 treasuryFee = (total / _totalFee) * _treasuryFee;
        _transfer(address(this), _treasuryWallet, treasuryFee);

        if(_liquidityFee == 0){
            return;
        }

        uint256 liquidityFee = total - marketingFee - treasuryFee;
        uint256 half = liquidityFee/2;
        uint256 otherHalf = liquidityFee - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        require(account != address(this));
        _isExcludedFromFee[account] = false;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpWallet,
            block.timestamp
        );
        
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "ZERO ADDRESS");
        _marketingWallet = newMarketingWallet;
        excludeFromFee(newMarketingWallet);
    }

    function setTreasuryWallet(address newTreasuryWallet) external onlyOwner {
        require(newTreasuryWallet != address(0), "ZERO ADDRESS");
        _treasuryWallet = newTreasuryWallet;
        excludeFromFee(newTreasuryWallet);
    }

    function setLpWallet(address newLpWallet) external onlyOwner {
        require(newLpWallet != address(0), "ZERO ADDRESS");
        _lpWallet = newLpWallet;
        excludeFromFee(newLpWallet);
    }

    function setAllFees(uint8 newMarketingFee, uint8 newTreasuryFee, uint8 newLiquidityFee) external onlyOwner {
        // we can't set fees higher than 8% (_maxTotalFee is a constant).
        require(newMarketingFee + newTreasuryFee + newLiquidityFee <= _maxTotalFee, "too high");
        _liquidityFee = newLiquidityFee;
        _marketingFee = newMarketingFee;
        _treasuryFee = newTreasuryFee;
        _totalFee = newLiquidityFee + newMarketingFee + newTreasuryFee;
    }

    function startTrading() external onlyOwner {
        require(!tradingStarted);
        tradingStarted = true;
        _firstBlock = block.timestamp;
    }

    function enableDistributeFees() external onlyOwner {
        distributeFeesEnabled = true;
    }

    function disableDistributeFees() external onlyOwner {
        distributeFeesEnabled = false;
    }

    function isWhitelisted(address account) public view returns(bool) {
        return _whitelisted[account];
    }

    // whitelisting all 120 addresses for first 30 minutes of trading
    function whitelistAddresses() private{
        _whitelisted[0x8D71960dA5b0bA3Da1C70992C0F9cb46c6d14F70] = true;
        _whitelisted[0x62d08E5B4cedF753C566A816A0653fD5864b23D1] = true;
        _whitelisted[0x613C033a1e4FFb4611795DBA1EDb0A58f8AFa53D] = true;
        _whitelisted[0xa32416271737FdC218b74AB9e6E6803Ad7793690] = true;
        _whitelisted[0xdBc5dd76913d0B7f534d7fc97B5aA859C83DBbde] = true;
        _whitelisted[0x11c5A81B8A503ACc7dcC9bd4fCfd5ad4D14A5b15] = true;
        _whitelisted[0x52b94e6a4f1D00373f58CC935D5ab234e61156b6] = true;
        _whitelisted[0xf89DCBA1f1A44Ecd2CD5B1d71F3e96a7B162Dc5b] = true;
        _whitelisted[0xb7eE1037A278cF9Bd44bd8B023ab89589a2a29Cd] = true;
        _whitelisted[0xc92487f3764F4636545234e3918FFB349f36d6D5] = true;
        _whitelisted[0x777D713C05C48Faf56f37D67A4500C3FEB212F50] = true;
        _whitelisted[0x4F6692cfb6cf0856f8279b51a6b73d8858813E58] = true;
        _whitelisted[0x043048851d3f73cC898a9C8086B60B426E9a9449] = true;
        _whitelisted[0x715caCAB58c0E3e767910A7a6d0699b3e9aD13b6] = true;
        _whitelisted[0x4D44DDec0985fd0ba5eCa540341af41385EB5B36] = true;
        _whitelisted[0x9dF93c6b420D0A42ccD490EF30Ed2aE8F6D48f04] = true;
        _whitelisted[0x84A7938E6Dd1E07b9592B5844541EBf481F6354A] = true;
        _whitelisted[0xd61bc90DE4B63fcda18D0448BE71119f1779015F] = true;
        _whitelisted[0xe5bdd8F5a08A4D65437daC272910Bc79c07392Ec] = true;
        _whitelisted[0xa52d35191a9c4259E02fEE13E6f37e0A8BD0C594] = true;
        _whitelisted[0x57DCad4358EA89bE8fA4dDb6fC07fc0435C95B3F] = true;
        _whitelisted[0x02D18dB270022F1A356BA73b1f3070e3D2531EEe] = true;
        _whitelisted[0xFE46Bb327eA84e55e41359864896fffdbA5770d2] = true;
        _whitelisted[0xf524543D71a5Cc49de18418a197C55AE5e87777e] = true;
        _whitelisted[0x413a3057C45670702C264fDd946725FEbc157fB8] = true;
        _whitelisted[0x9339Ec421BA6137a844685eE8B00AA8F8d4E3775] = true;
        _whitelisted[0x5137fD5B7D7a59D4F1bAadEbEBEFa062775Cc7d0] = true;
        _whitelisted[0x3989D51D704FC978fe6425524b8F9dCcDd1B30D0] = true;
        _whitelisted[0x7EEde23aC865423Eaf977AAC6503F376442d53dD] = true;
        _whitelisted[0x2160789cFc24C3C21f892535B0bf71050efE3d20] = true;
        _whitelisted[0xB4D371E5e89A3Eb640644B9b6cAA43FAE3b54d5d] = true;
        _whitelisted[0x80130D9D391E889F571cD5c0a040311659789D31] = true;
        _whitelisted[0x8312EbBC432Ecea752A37F091Be247abBA2C5907] = true;
        _whitelisted[0xA19baD9FA64f5063184Daaa8F2ae7865907F1eD7] = true;
        _whitelisted[0xd4d4A5D71371d43db499417c149A9Ef60B76cA7D] = true;
        _whitelisted[0x35e264c2486a0457bb5B83AE0287e7ce6e61Ec05] = true;
        _whitelisted[0x53Af9B9FF521C172B192b00D499425688fC348c8] = true;
        _whitelisted[0x162fBbDf355b3e3a06c1FFCe3E623d65662DBb1D] = true;
        _whitelisted[0x70ba6D7C9175155a763dCA04D2a8823D9145cec7] = true;
        _whitelisted[0xB56C8AA86F7Af774444239B37f8E2824c377fE90] = true;
        _whitelisted[0xe503a714c71C808278895B1ee5c57Db084FBE033] = true;
        _whitelisted[0x2EF8e1bb758Ceb9a74eadfC168e8064645BeF5Eb] = true;
        _whitelisted[0xA0772318F5F51d6232FF4127334bFCCBCF9F9d29] = true;
        _whitelisted[0xc6e85cE4fEf7822008a986171C9c0EB358424A1F] = true;
        _whitelisted[0x935f950e7eCEeD32C047Fa72b620B1Fd1d5673e7] = true;
        _whitelisted[0xBA8CF32cb453a8017A7cd1f6eC85CD9cdD47AEF1] = true;
        _whitelisted[0xE250a6ee82F084f8D28dB9B9815D641D5dF5De23] = true;
        _whitelisted[0x0049042E6C2373B4b3e3f8bffEb065af07d36b22] = true;
        _whitelisted[0xdE1107aD561D1432248B9F33B0b667F63BF57FA1] = true;
        _whitelisted[0xB4FD0B7533cF3941d0fd60f90Fa00aF996A7b0eb] = true;
        _whitelisted[0x7bD219d37AB5FD7f42709EeF881F9Aa79476bE37] = true;
        _whitelisted[0x64884dD4B8525b4813187D9240aA2a9A109d0989] = true;
        _whitelisted[0xf361C8DFfBFAf37eDA47E64690Fa90E5AaDe7C53] = true;
        _whitelisted[0x3ADe89cA90BFB31Aa2b312194f177391A1CCABE3] = true;
        _whitelisted[0x02fbbdEbf17d1cb9eAea8Ff4db86300441DB60c0] = true;
        _whitelisted[0xc5C619c22E79004Ee137583FEef9861240AB1F18] = true;
        _whitelisted[0x23f958C68D64a31e6Bae9D97e689C7b1394fcFa8] = true;
        _whitelisted[0x6a30d62ad21a568e74702068EA5A682D78561260] = true;
        _whitelisted[0x7851B71D2440443812E649985f7C0A9cA83df37a] = true;
        _whitelisted[0xF1279E4373B7FeBa8AC8290C2837E664e76dbd18] = true;
        _whitelisted[0x689e88D4a7704126dD0AeafaF5E5a9D26C57a2dC] = true;
        _whitelisted[0x20f17A903Ab66bFD58ae355DaB7a1856A2b451c3] = true;
        _whitelisted[0x67a5fccA052BfD666dA1C9498272AAc00Ed57d00] = true;
        _whitelisted[0xeBdE34804C8C385322da49F7A1179f9e9bDBde6C] = true;
        _whitelisted[0xAfF24e16539218b417eaD517e6c3544a8E2c7532] = true;
        _whitelisted[0xaf5a1dA1CbB3d86A104065526c02afab7aF922E3] = true;
        _whitelisted[0x9ec10CDBaA6550eD4126034eA4638F4FF8F16814] = true;
        _whitelisted[0xEf009c0C814d21dDB518Be2F6d95fcE8dDA66242] = true;
        _whitelisted[0x2940C1D55FdE3E60F0F2C128982873257131C6a1] = true;
        _whitelisted[0xe9b10b2B493aC7734aa5038FeA22639ac1ecb13D] = true;
        _whitelisted[0x959B05eA2f313c62895bB6642882AeFab55D3716] = true;
        _whitelisted[0xf2EB8262e703738E9516b6977F5945b362aCC1Ce] = true;
        _whitelisted[0xBFb7Efb033CF400f3834EDb9Fe1bA2878c72Aad0] = true;
        _whitelisted[0xdB4bB65ae13033bf6aeA82b382cBdedEf3B44BfE] = true;
        _whitelisted[0xB96E0d4433A2d5aB615621AEBA6A7E154515f058] = true;
        _whitelisted[0xb7f28618DC28D920552fb4D5Ca52CE0a14b71F8b] = true;
        _whitelisted[0x8D483613e70D287e573351bCEcef4Bac15Ce7C00] = true;
        _whitelisted[0x3920b9a86dD12b841179b028D26Bf00B2258bbc2] = true;
        _whitelisted[0x0C4516De4B4A721e0c0FBD4BdCEC8C41B617031E] = true;
        _whitelisted[0x671e87bb50051f8579ed2936fad596ae10547607] = true;
        _whitelisted[0xdA69df6f0Fe2d275B0eB7Fc6209E50c73268f2f7] = true;
        _whitelisted[0x6A9700EB8CbedD387a9063310D00AeE2D4C81aFB] = true;
        _whitelisted[0x9Ce6EE6659932f04bC6Ad4287471c75806Ac0eCF] = true;
        _whitelisted[0x4331353c9C18B09be595F991b2cd43Cb5c25dF5E] = true;
        _whitelisted[0xBCD05Ad86C0E902Dc84C9c77e7F0CD07bB0dFA19] = true;
        _whitelisted[0x3d603D92A4e9c4c4d30C1E5E24F7e10B9E768897] = true;
        _whitelisted[0xa1C655045ac90ee2daB3EEBD0508aB37016e006b] = true;
        _whitelisted[0xbbE080c6a6cbe8590c72C34D915C2745e1236997] = true;
        _whitelisted[0x76CC5113447E10d1B6c0F8F037968Bf0F6D1E229] = true;
        _whitelisted[0xAfF24e16539218b417eaD517e6c3544a8E2c7532] = true;
        _whitelisted[0xa77AB79D57963721A69F1868ABA691d64CE3Fd2d] = true;
        _whitelisted[0xD14B59906B5674ff2d242C8d448e40F6A651c4A3] = true;
        _whitelisted[0x101EDBCC6c5b013544a89321b817b243C842010e] = true;
        _whitelisted[0x90dCFA82A0b2eEDB8DDb4073d4722e95254020bB] = true;
        _whitelisted[0xB62e676e3567eE984C93728d7e140BfC64dD48d1] = true;
        _whitelisted[0x4753F477a398b1ACB1c7E98749B07334Db75614c] = true;
        _whitelisted[0x5C8b724652806fCA8FC5BbD494A9ca86C66126Ca] = true;
        _whitelisted[0x840B036685A6A0DbAD901d10d5Af36400f8bb4C5] = true;
        _whitelisted[0xA9FA87aB0b1C3722856074E84C96c4e4001D5867] = true;
        _whitelisted[0x935f950e7eCEeD32C047Fa72b620B1Fd1d5673e7] = true;
        _whitelisted[0xD122b9621dBc5836c8C704c842AFB63cc1c596a9] = true;
        _whitelisted[0x5C8b724652806fCA8FC5BbD494A9ca86C66126Ca] = true;
        _whitelisted[0x61E14Bcd59E67CF4902C75110Ca0BA82805b81E2] = true;
        _whitelisted[0x19Ea14574A05572D4800E08083C7871A298638D9] = true;
        _whitelisted[0x4D8Ee85E6CdEBFD7627AF8a106280186b1c4A0f7] = true;
        _whitelisted[0x2932133e7156266b36854366482Ab0b0F734C2E7] = true;
        _whitelisted[0x35c2ee0A83db8Bf8638C392203D9E2eeca74B9BD] = true;
        _whitelisted[0xfcd6b5d73c5a90554d06c88471773401e3Fb3Cc0] = true;
        _whitelisted[0x41df140b1abBE7B6CB1c56C002b8a10113e5FA70] = true;
        _whitelisted[0x224927285495071Ac2e88e7F458dC5B76aBF799F] = true;
        _whitelisted[0xF1701C11476a2804B23a26847b9803F3a28c3260] = true;
        _whitelisted[0x9F0a9D578378a5d6B1d948D2E15d33e29e4202DE] = true;
        _whitelisted[0x4082E69B4f7190E88F03E9072C44811DB5756aeA] = true;
        _whitelisted[0x94ACbae5d882D8493D41e94406826B379bE4d964] = true;
        _whitelisted[0x9A9d75BD98fe530Ef2B2bA04CB57Ec15Cd3E2f42] = true;
        _whitelisted[0x48EEb9Dec637366a3b565A30a8F49AD9e5912525] = true;
        _whitelisted[0x8b0605bf79ab2AdB55a59BCA2757f7d0106b996D] = true;
        _whitelisted[0x35798bCCF238CF9725b9a6221A3674e735e301b3] = true;
        _whitelisted[0x709aCc6535fbca5f5dcD1be9fC9495A8B9c95178] = true;
        _whitelisted[0x8EE880e3f20950704Db1a77E31FCE1F9DA36843a] = true;
        _whitelisted[0xf2dC95dc814b28BA13181Fcb3d4c85F1206D1362] = true;
    }

}