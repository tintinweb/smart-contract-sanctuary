/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: Unlicensed

/*


functions to set fees 
burn at 1%
send bnb to a contract or wallet and process it 
set transaction limits
set buy timers
- issue with the address(0) for burn?



 */

pragma solidity ^0.8.3;


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
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x2240a100BCb9b846C0F2e0cb1A1E4bf38a3cc46C; //TEST2 wallet
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract D2E_3 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    //_isCommunity = Can Buy at Launch! <-----for community 
    //_isBlacklisted = Can not buy or sell or transfer tokens at all <-----for bots! 
    mapping (address => bool) public _isCommunity;
    mapping (address => bool) public _isBlacklisted;
    
    //private launch - Only approved people can buy! 
    //need to add uniswapV2Pair address to communiity list in order to add liquidity 
    bool public onlyCommunity = false;
   

    address[] private _excluded;
    address payable private _promotionsWalletAddress = payable(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf);  //TEST D2E Marketing
    address payable private _burnWalletAddress = payable(0x000000000000000000000000000000000000dEaD);



    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "D2E_3";
    string private _symbol = "D2E_3";
    uint8 private _decimals = 9;


    //hold some GEN!
    IERC20 GEN1 = IERC20(0xd4294c0f64eBA74089315D4b0278698f7181037e);
    IERC20 GEN2 = IERC20(0x9973885595Cf0C17accD7E46f96dbd937A7E627C);
     
    //need to hold about 0.2 bnb of GEN or GEN2 to be able to buy on day one
    uint256 public howMuchGEN1 = 2500000 * 10**6 * 10**9; 
    uint256 public howMuchGEN2 = 1500000 * 10**6 * 10**9; 

    //do we need to be holding gen for this?
    bool public bringOutYourGEN = false; //<---yes, yes you do. Go and buy some!

    //what if GEN moons before launch? Don't worry, we gotcha!
    function gen_checkYourGEN(uint256 gen1Needed) external onlyOwner() {
        howMuchGEN1 = gen1Needed;
    }
    function gen_checkYourGEN2(uint256 gen2Needed) external onlyOwner() {
        howMuchGEN2 = gen2Needed;
    }

    //do I really need to hold some gen?
    mapping (address => bool) public putYourGenAway;

    //I'll let you off this time, but you really should buy some gen...
    function gen_youDontNeedGEN(address account) public onlyOwner {
        putYourGenAway[account] = true;
    }

    //I've changed my mind, go buy some gen, stop being a cheap ass!
    function gen_youDoNeedGEN(address account) public onlyOwner {
        putYourGenAway[account] = false;
    }

    //I can't decide if you need gen or not, let me mull it over 
    function gen_onlyGenHolders(bool needGen) public onlyOwner {
        bringOutYourGEN = needGen;
    }

    //change the address for GEN1 for testing!
    function gen_useTestTokenGEN1(address dummyGen1) external onlyOwner(){
        GEN1 = IERC20(dummyGen1);
    }
    //change the address for GEN2 for testing!
    function gen_useTestTokenGEN2(address dummyGen2) external onlyOwner(){
        GEN2 = IERC20(dummyGen2);
    }

   
    
    //refection fee
    uint256 public _reflectionFee = 0;
    uint256 private _previousReflectionFee = _reflectionFee;
     
    //setting the fees for auto LP and marketing wallet 
    uint256 public _liquidityFee = 10;



    uint256 public _FeeMarketing_X100 = 150; // 1.5%
    uint256 public _FeeDev_X100 = 50; // 0.5%
    uint256 public _FeeAnimator_X100 = 200; // 2%

    uint256 _promoFee = (_FeeMarketing_X100+_FeeDev_X100+_FeeAnimator_X100)/100;


       //Not BNB
    uint256 _FeeBurn_X100 = 100; // 1%   XXX need to add the burn!
       
      

    //token wallet fee for burns and giveaways = BEING USED FOR BURN!!
    uint256 public _tokenGiveawayFee = 1;
    uint256 private _previousTokenGiveawayFee = _tokenGiveawayFee;

    //fee for the auto LP and the marketing wallet 
    uint256 private _liquidityAndPromoFee = _liquidityFee+_promoFee;
    uint256 private _previousLiquidityAndPromoFee = _liquidityAndPromoFee;
    
    //max wallet holding 10000000 * 10**6 * 10**9 is 1% of 1000000000 * 10**6 * 10**9 (total supply)
    uint256 public _maxWalletToken = 1000000000 * 10**6 * 10**9;
                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    //this is the maximum transaction amount (in tokens) at launch this is set to 1% of total supply - 0.5% of supply!
    uint256 public _maxTxAmount = 1000000000 * 10**6 * 10**9;

    //this is the number of tokens to accumulate before adding liquidity or taking the promotion fee
    //amount (in tokens) at launch set to 0.4% of total supply
    uint256 public _numTokensSellToAddToLiquidity = 5000000 * 10**6 * 10**9;  //half percent 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // <---for testing things! 
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true; //dead
        _isExcludedFromFee[address(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf)] = true; //fee collector
        
        //other wallets are added to the communtiy list manually post launch
        _isCommunity[address(0x000000000000000000000000000000000000dEaD)] = true; //dead
        _isCommunity[address(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf)] = true; //fee collector

        //don't need to hold GEN
        putYourGenAway[address(0x000000000000000000000000000000000000dEaD)] = true; //dead
        putYourGenAway[address(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf)] = true; //fee collector

        // #loopsareforlosers++
        
        
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    //shall we make it fair? Let everybody have a go at getting in cheap? yes. yes we will. 
    bool public slowFairBuys = false;
    uint8 public justChillFor = 0;
    mapping (address => uint) private stillWaiting;

    //slow it down and make it fair, restrict buying in seconds
    function sefeLaunch_keepCalmAndBuySlowly(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        justChillFor = numSeconds;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
   
    //set Only Community Members <---whitelist!
    function safeLaunch_setOnlyCommunity(bool _enabled) public onlyOwner {
        onlyCommunity = _enabled;
    }
    
    
    //set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    //set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    //set the number of tokens required to activate auto-liquidity and promotion wallet payout
    function process_setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }
    
    //set the fee that is automatically distributed to all holders (reflection) 
    function fees_setFeeReflectionPercent(uint256 reflectionFee) external onlyOwner() {
        _reflectionFee = reflectionFee;
    }

    //set fee for the giveaway and manual burn wallet 
    function fees_setFeeTokenGiveawayPercent(uint256 tokenGiveawayFee) external onlyOwner() {
        _tokenGiveawayFee = tokenGiveawayFee;
    }
    
    //set fee for auto liquidity
    function fees_setFeeLiquidityPercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    //set fee for the marketing (BNB) wallet 
    function fees_setFeePromoPercent(uint256 promoFee) external onlyOwner() {
        _promoFee = promoFee;
    }
   
    //set the Max transaction amount (percent of total supply)
    function safeLaunch_setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    
    //set the Max transaction amount (in tokens)
     function safeLaunch_setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    
    
    //settting the maximum permitted wallet holding (percent of total supply)
     function safeLaunch_setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _tTotal.mul(maxWallPercent).div(
            10**2
        );
    }
    
    //settting the maximum permitted wallet holding (in tokens)
     function safeLaunch_setMaxWalletTokens(uint256 maxWallTokens) external onlyOwner() {
        _maxWalletToken = maxWallTokens;
    }
    
    
    
    //toggle on and off to activate auto liquidity and the promo wallet 
    function process_setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    //receive pancakes from BNB Router
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    
    //Remove from Community 
    function safeLaunch_removeFromCommunity(address account) external onlyOwner {
        _isCommunity[account] = false;
    }
    
    //Remove from Blacklist 
    function safeLaunch_removeFromBlackList(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }
    
    
    //adding people to the GEN Community approved list - these people are the only ones that will be able to buy at launch! 
    function safeLaunch_addToCommunity(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isCommunity[addresses[i]] = true;
      }
    }
    
    //adding multiple addresses to the blacklist - Used to manually block known bots and scammers
    function safeLaunch_addToBlackList(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = true;
      }
    }
    
   
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityAndPromoFee(tAmount);
        uint256 tDev = calculateTokenGiveawayFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDev);
        return (tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDev);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
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
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rDev);
        if(_isExcluded[_burnWalletAddress])
            _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(tDev);
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(
            10**2
        );
    }

    function calculateTokenGiveawayFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tokenGiveawayFee).div(
            10**2
        );
    }

    function calculateLiquidityAndPromoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityAndPromoFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_reflectionFee == 0 && _liquidityAndPromoFee == 0) return;
        
        _previousReflectionFee = _reflectionFee;
        _previousTokenGiveawayFee = _tokenGiveawayFee;
        _previousLiquidityAndPromoFee = _liquidityAndPromoFee;
        
        _reflectionFee = 0;
        _tokenGiveawayFee = 0;
        _liquidityAndPromoFee = 0;
    }
    
    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;
        _tokenGiveawayFee = _previousTokenGiveawayFee;
        _liquidityAndPromoFee = _previousLiquidityAndPromoFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Nope, can't do that. Sorry, the owner is... dead!");
        require(spender != address(0), "No puedo hacer esta, disculpa.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        
        //limits the amount of tokens that each person can buy - launch limit is 2% of total supply!
        if (to != owner() && to != address(this)  && to != address(0x000000000000000000000000000000000000dEaD) && to != uniswapV2Pair && to != _promotionsWalletAddress){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"WOOT! WOOT! WHALE INCOMMING! You can't buy that much dude!");}
        
        //if onlyCommunity is set to true, then only people that have been approved can buy 
        if (onlyCommunity){
        require(_isCommunity[to], "Sale restricted to whitelsited wallets! Pass your wallet to an admin, or come back later");}

        //blacklisted addreses can not buy! If you have ever used a bot, or scammed anybody, then you're wallet address will probably be blacklisted
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Nope. Not gunna happen. This address is blacklisted");
        require(from != address(0), "from 0 address");
        require(to != address(0), "to 0 address");
        require(amount > 0, "no tokens, just burning gas");


        //slow trades are fair trades! You can buy 1/2 of max holding at a time, but you need to wait 1 min
        //to buy the 2nd half, giving everybody the chance to get in when the price is low :) 
        //only active during initial launch phase
        if (from == uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(stillWaiting[to] < block.timestamp,"You buy so fast! Relax, buy sloooowly, give other people a chance for 1 min.");
            stillWaiting[to] = block.timestamp + justChillFor;
        }

        //Dude, where's your GEN? Didn't you get the memo? You need some GEN!
         if(bringOutYourGEN)
                {require(putYourGenAway[to]
                    || GEN1.balanceOf(to) >= howMuchGEN1 || GEN2.balanceOf(to) >= howMuchGEN2
                    ,"To buy this early you need to hold some GEN. Pop back tomorrow, or buy some GEN!");}
           


        
        //limit the maximum number of tokens that can be bought or sold in one transaction
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Easy there tiger! Put your fat wallet away, that's too much!");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
       
         require(to != address(0), "ERC20: transfer to the zero address");
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }
    
     function sendToPromoWallet(uint256 amount) private {
            _promotionsWalletAddress.transfer(amount);
        }


    function precDiv(uint a, uint b, uint precision) internal pure returns ( uint) {
     return a*(10**precision)/b;
         
    } 

     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
       uint256 __splitPromo = 0;
       uint256 __tokensToPromo = 0;
       

        //send BNB to external wallet. Inc: Prize Pool, developer and marketing funds
        //all required BNB is processed together to avoid too much red on the chart!
        //otherwise it looks like a blood bath and paper-hands dump like headless chickens

        if (_promoFee != 0){


             __splitPromo = precDiv(_promoFee,_liquidityAndPromoFee,2);
             __tokensToPromo = contractTokenBalance*__splitPromo/100;


                   
        //send to wallet as BNB - get current balance of BNB on contract
        uint256 balanceBeforePromoWallet = address(this).balance;
        swapTokensForEth(__tokensToPromo);
        uint256 balanceToSendPromo = address(this).balance - balanceBeforePromoWallet;
        sendToPromoWallet(balanceToSendPromo);
        }

             
        if (_liquidityFee != 0){
        uint256 __tokenstoLP = contractTokenBalance-__tokensToPromo;
         //chop tokens in half like a silent ninja, and do some funky shit
        uint256 firstHalf = __tokenstoLP.div(2);
        uint256 secondHalf = __tokenstoLP.sub(firstHalf);
        uint256 balanceBeforeLP = address(this).balance;
        swapTokensForEth(firstHalf); 
        uint256 swappedLP = address(this).balance.sub(balanceBeforeLP);
        addLiquidity(secondHalf, swappedLP);
        emit SwapAndLiquify(firstHalf, swappedLP, secondHalf);
        }
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
            owner(),
            block.timestamp
        );
    }    
    
    //manually purge tokens from contract, swap to bnb and send to promo wallet
    function process_TokensFromContract(uint256 tokenAmount) public onlyOwner {
        uint256 tokensOnWallet = balanceOf(address(this));
        if (tokenAmount > tokensOnWallet) {tokenAmount = tokensOnWallet;}
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 balanceToSend = address(this).balance - balanceBefore;
        sendToPromoWallet(balanceToSend);
    }

    //manually purge BNB from contract to promo wallet
    function process_BNBFromContract(uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        sendToPromoWallet(bnbAmount);
    }
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
         
        
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
                
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
       
       
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

   



    
    

}