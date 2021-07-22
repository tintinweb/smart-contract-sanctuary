/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: Unlicensed



/*

SET UP THE WALLETS FOR THE TESTING!
CHANAGE TEST NET ROUTER AFTER TESTING!

BURN NEEDS ADDING (1% PER TRANSACTION) - PROCESS WITH TOKEN WALLET!  *
REMOVE ALL FEES *
RESTORE ALL FEES *

SET UP FOR PRESALE *
RESTORE STATUS AFTER PRE SALE *

CHECK FEES ARE NEVER DOING BREAKING MATH 
CHECK FEES WORK WHEN REMOVE AND RESTORE IS USED 

CHECK LIMITS FOR HOLD AND MAX TRANS 
DETAILS FOR THE CONTRACT COMMENTS
EASTER EGGS IN CONTRACT COMMENTS 
ASCII ART IN CONTRACT 
UPDATE HARD CODED OWNER ADDRESS 
ABILITY TO SWAP PCS ADDRESS 
NAME AND SYMBOL FOR TOKEN 
GET ALL WALLET ADDRESSES 
REMOVE OLD SET FEE FUNCITON *
ADD NEW SET FEE 100X FUNCTIONS *
REMOVE OLD FEE TRACKING 


Supply: 10 million tokens
1% dev fund
4% early advisors and promos
0% burnt
95% fair launch {liquidity pool}

Tokenomics: 15%
1% burnt each transaction  /////////XXXXX

10% added to liquidity
2% animation fund
0.5% dev {for us, maintaining the project}
1.5% marketing

DEV NOTES

When updating fees they must be set at 100x to allow for up to 2 decimal places 

10%  = 1000  Liquidity
2%   = 200   Animation Fund
0.5% = 50    Developer Micro-Management
1.5% = 150   Marketing Fund
----------------------------
15%  = 1500  Total Fees
(plus burn at 1% not 100x!)
----------------------------

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
    
    //stripped to only the functions used 
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
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
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

contract D2E is Context, IERC20, Ownable {
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
    bool public onlyCommunity = true;

    address[] private _excluded;
    address payable private wallet_Marketing = payable(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf);
    address payable private wallet_Dev = payable(0x54338DF60770184219ac146f66C29B1dCBEEFB86);
    address payable private wallet_Animator = payable(0x18fcA8704312760A0D4ef10608C5Cf85Dd01F6Ba);
    address payable private wallet_Tokens = payable(0x6380AD4BdEc5B2c562Cd55dddD650E1d5a7c1eCf);
    address payable private wallet_Burn = payable(0x000000000000000000000000000000000000dEaD);


    //functions to change all wallets
    function changeWallet_Marketing (address newWalletAddress) external onlyOwner() {
        wallet_Marketing = payable(newWalletAddress);
        _isExcludedFromFee[wallet_Marketing] = true;
    }

    function changeWallet_Dev (address newWalletAddress) external onlyOwner() {
        wallet_Dev = payable(newWalletAddress);
        _isExcludedFromFee[wallet_Dev] = true;
    }

    function changeWallet_Animator (address newWalletAddress) external onlyOwner() {
        wallet_Animator = payable(newWalletAddress);
        _isExcludedFromFee[wallet_Animator] = true;
    }

    function changeWallet_Tokens (address newWalletAddress) external onlyOwner() {
        wallet_Tokens = payable(newWalletAddress);
        _isExcludedFromFee[wallet_Tokens] = true;
    }






    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "D2E";
    string private _symbol = "D2E";
    uint8 private _decimals = 9;


      /*
       
       Fees are all multiplied by 100 to allow for up to 2 decimal places in fee calculations
       
       */
        
        //BNB Fees - set to 100x to allow for decimals on solidity code
    uint256 public _FeeLP_X100 = 1000; // 10%
    uint256 public _FeePromo_X100 = 150; // 1.5%
    uint256 public _FeeDev_X100 = 50; // 0.5%
    uint256 public _FeeAnimator_X100 = 200; // 2%
        //Not BNB - token fees set as actual number
    uint256 public _FeeBurn = 1; // Burn 1% on every transaction
    uint256 public _FeeTokenGiveaway = 0; // Can be added later if needed
    uint256 private  _totalFeeTokens = _FeeBurn+_FeeTokenGiveaway;
        //reflection - can be added later if needed
    uint256 public _reflectionFee = 0;
    

    uint256 private _Pre_FeeLP_X100 = _FeeLP_X100; 
    uint256 private _Pre_FeePromo_X100 = _FeePromo_X100; 
    uint256 private _Pre_FeeDev_X100 = _FeeDev_X100; 
    uint256 private _Pre_FeeAnimator_X100 = _FeeAnimator_X100;
    uint256 private _Pre_FeeBurn = _FeeBurn; 
    uint256 private _Pre_FeeTokenGiveaway = _FeeTokenGiveaway;
    uint256 private _Pre_reflectionFee = _reflectionFee ;

    

       
    uint256 public _____totalFeePercent = ((_FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100)/100)+_FeeBurn+_FeeTokenGiveaway;
       
       
    uint256 _totalBNBFees = (_FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100)/100;
    uint256 _totalBNBFees_X100 = _FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100;

       
    uint256 _otherBNB_X100 = _FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100;
      
    
    uint256 ___percentLP;
    uint256 ___tokensLP;
    uint256 ___percentOtherBNB;
    uint256 ___tokensOtherBNB;
    




    //fee for the auto LP and all bnb fees
    uint256 private _liquidityAndPromoFee = (_FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100)/100;
    uint256 private _previousLiquidityAndPromoFee = _liquidityAndPromoFee;
    
    //max wallet holding  - set to 1% of 10,000,000 tokens
    uint256 public _maxWalletToken = 100000 * 10**9; //XXX
                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    //this is the maximum transaction amount (in tokens)  - set to 1% of 10,000,000 tokens
    uint256 public _maxTxAmount = 100000 * 10**9;  //XXXXX

    //this is the number of tokens to accumulate before adding liquidity or taking the promotion fee
    //amount (in tokens) at launch set to 0.4% of total supply
    //XXXXXXXX  THIS NEEDS TO BE MICRO MANAGED GOING FORWARD  XXXXXXXXXX
    uint256 public _numTokensSellToAddToLiquidity = 100000  * 10**9;
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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //<---for testing things! 
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[wallet_Burn] = true;
        _isExcludedFromFee[wallet_Marketing] = true;
        _isExcludedFromFee[wallet_Dev] = true;
        _isExcludedFromFee[wallet_Animator] = true;
        
        //other wallets are added to the communtiy list manually post launch
        _isCommunity[owner()] = true;
        _isCommunity[wallet_Burn] = true;
        _isCommunity[wallet_Marketing] = true;
        _isCommunity[wallet_Dev] = true;
        _isCommunity[wallet_Animator] = true;

        
        
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

    function precDiv(uint a, uint b, uint precision) public pure returns ( uint) {
     return a*(10**precision)/b;
         
    }   

    //shall we make it fair? Let everybody have a go at getting in cheap? yes. yes we will. 
    bool public slowFairBuys = true;
    uint8 public buy_buy_delay = 10;
    uint8 public buy_sell_delay = 5;
    mapping (address => uint) private buy_buy;
    mapping (address => uint) private buy_sell;

    //delay between 2 buys in seconds
    function sefeLaunch_buy_buy_delay(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        buy_buy_delay = numSeconds;
    }

    //delay from a buy to a sell in seconds
    function sefeLaunch_buy_sell_delay(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        buy_sell_delay = numSeconds;
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
    

    //get remove all of the fees and disable swap and liquify ready for presale
    function setup_removeFeesForPreSale() external onlyOwner {
        process_setSwapAndLiquifyEnabled(false);
        removeAllFee();
    }
    
    //restore all fees and enable swap and liquify when presale is over
    function setup_restoreFeesAfterPreSale() external onlyOwner {
        process_setSwapAndLiquifyEnabled(true);
        restoreAllFee();
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
    
   
    /*




    Set Fees




    */




    //set fee for auto liquidity (must be 100x)
    function fees_setFeeLiquidity_X100(uint256 liquidityFee) external onlyOwner() {
        _FeeLP_X100 = liquidityFee;
    }

    //set fee for marketing (must be 100x)
    function fees_setFeeMarketing_X100(uint256 promoFee) external onlyOwner() {
        _FeePromo_X100 = promoFee;
    }

    //set fee for ongoing management (must be 100x)
    function fees_setFeeDev_X100(uint256 devFee) external onlyOwner() {
        _FeeDev_X100 = devFee;
    }

    //set fee for animator (must be 100x)
    function fees_setFeeAnimator_X100(uint256 animatorFee) external onlyOwner() {
        _FeeAnimator_X100 = animatorFee;
    }

    //set fee for burn (NOT 100x - actual percent!)
    function fees_setFeeBurn(uint256 burnFee) external onlyOwner() {
        _FeeBurn = burnFee;
    }

    //set fee for token wallet (giveaways) (NOT 100x - actual percent!)
    function fees_setFeeTokenGiveaway(uint256 giveawayFee) external onlyOwner() {
        _FeeTokenGiveaway = giveawayFee;
    }

    //set fee for reflections (NOT 100x - actual percent!)
    function fees_setFeeReflections(uint256 reflectFee) external onlyOwner() {
        _reflectionFee = reflectFee;
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
    
    //receive bnb
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    
    //Remove from whitelist 
      function safeLaunch_removeFromWhitelist(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isCommunity[addresses[i]] = false;
      }
    }
    
    //Remove from Blacklist 
     function safeLaunch_removeFromBlackList(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = false;
      }
    }
    
    
    //adding people to the whitelist - these people are the only ones that will be able to buy at launch! 
    function safeLaunch_addToWhitelist(address[] calldata addresses) external onlyOwner {
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
        uint256 tDev = calculateTotalFeeTokens(tAmount);
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
        //used to take token giveaway fee and burn fee
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);


        //if token giveaway but no burn
        if (_FeeBurn == 0 && _FeeTokenGiveaway > 0) { 
             _rOwned[wallet_Tokens] = _rOwned[wallet_Tokens].add(rDev);
        if(_isExcluded[wallet_Tokens])
            _tOwned[wallet_Tokens] = _tOwned[wallet_Tokens].add(tDev);
        }

        //if burn but no token giveaway 
        if (_FeeBurn > 0 && _FeeTokenGiveaway == 0) { 
             _rOwned[wallet_Burn] = _rOwned[wallet_Burn].add(rDev);
        if(_isExcluded[wallet_Burn])
            _tOwned[wallet_Burn] = _tOwned[wallet_Burn].add(tDev);
        }

        //if burn and token giveaway
        if (_FeeBurn > 0 && _FeeTokenGiveaway > 0) { 

        //calculate the split to giveaway wallet and to burn
        uint256 totalTokenFee = _FeeBurn+_FeeTokenGiveaway;
        uint256 ___percentBurn = precDiv(totalTokenFee,_FeeBurn,2);
        uint256 ___percentGive = precDiv(totalTokenFee,_FeeTokenGiveaway,2);

        uint256 ___tokensBurn_t = tDev*___percentBurn/100;
        uint256 ___tokensBurn_r = rDev*___percentBurn/100;
        uint256 ___tokensGive_t = tDev*___percentGive/100;
        uint256 ___tokensGive_r = rDev*___percentGive/100;

        //send some tokens to the burn wallet
             _rOwned[wallet_Burn] = _rOwned[wallet_Burn].add(___tokensBurn_r);
        if(_isExcluded[wallet_Burn])
            _tOwned[wallet_Burn] = _tOwned[wallet_Burn].add(___tokensBurn_t);

        //send some tokens to the giveaway wallet
             _rOwned[wallet_Tokens] = _rOwned[wallet_Tokens].add(___tokensGive_r);
        if(_isExcluded[wallet_Tokens])
            _tOwned[wallet_Tokens] = _tOwned[wallet_Tokens].add(___tokensGive_t);
        }


      
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(
            10**2
        );
    }

    function calculateTotalFeeTokens(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalFeeTokens).div(
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
                
    _FeeLP_X100 = 0; 
    _FeePromo_X100 = 0; 
    _FeeDev_X100 = 0; 
    _FeeAnimator_X100 = 0;
    _FeeBurn = 0; 
    _FeeTokenGiveaway = 0;
    _totalFeeTokens = 0;
    _reflectionFee = 0;
    _totalBNBFees = 0;
    _totalBNBFees_X100 = 0;
    _otherBNB_X100 = 0;
    _liquidityAndPromoFee = 0;

    }
    
    function restoreAllFee() private {  
        
    _FeeLP_X100 = _Pre_FeeLP_X100; 
    _FeePromo_X100 = _Pre_FeePromo_X100; 
    _FeeDev_X100 = _Pre_FeeDev_X100; 
    _FeeAnimator_X100 = _Pre_FeeAnimator_X100;
    _FeeBurn = _Pre_FeeBurn; 
    _FeeTokenGiveaway = _Pre_FeeTokenGiveaway;
    _totalFeeTokens = _FeeBurn+_FeeTokenGiveaway;
    _reflectionFee = _Pre_reflectionFee;
    _totalBNBFees = (_FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100)/100;
    _totalBNBFees_X100 = _FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100;
    _otherBNB_X100 = _FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100;
    _liquidityAndPromoFee = (_FeeLP_X100+_FeePromo_X100+_FeeDev_X100+_FeeAnimator_X100)/100;

    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Owner is zero address!");
        require(spender != address(0), "Spender is zero address!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        

        //limits the amount of tokens that each person can buy - launch limit is 2% of total supply!
        if (to != owner() 
        && to != address(this)  
        && to != uniswapV2Pair 
        && to != wallet_Burn 
        && to != wallet_Marketing
        && to != wallet_Dev
        && to != wallet_Animator
        && to != wallet_Tokens
        && to != wallet_Tokens
        
        ){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy over the max wallet holding");}
        
        //if onlyCommunity is set to true, then only people that have been approved can buy 
        if (onlyCommunity){
        require(_isCommunity[to], "Sale currently restricted to whitelsited wallets");}

        //blacklisted addreses can not buy! If you have ever used a bot, or scammed anybody, then you're wallet address will probably be blacklisted
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "The address is blacklisted");
        require(from != address(0), "from 0 address");
        require(to != address(0), "to 0 address");
        require(amount > 0, "Must be more that 0");


        //slow trades are fair trades!
        if (from == uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(buy_buy[to] < block.timestamp,"Need to wait a few seconds before you can buy again.");
            buy_buy[to] = block.timestamp + buy_buy_delay;
            buy_sell[to] = block.timestamp + buy_sell_delay;

        }

        if (from != uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(buy_sell[from] < block.timestamp,"Need to wait a few seconds before selling.");
        }

       

        
        //limit the maximum number of tokens that can be bought or sold in one transaction
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "You are trying to buy more than the maximum transaction amount");

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
    


    function sendBNBToWallet(address payable walletAddress, uint256 amount) private {
            walletAddress.transfer(amount);
        }




     function swapAndLiquify(uint256 numTokens) private lockTheSwap {
        
     

        if (_FeeLP_X100 > 0) {
            
            ___percentLP = precDiv(_FeeLP_X100,_totalBNBFees_X100,2);
            ___tokensLP = numTokens*___percentLP/100;
            //split tokens in half and send to liquify
            uint256 firstHalf = ___tokensLP.div(2);
            uint256 secondHalf = ___tokensLP.sub(firstHalf);
            uint256 balanceBeforeLP = address(this).balance;
            swapTokensForEth(firstHalf); 
            uint256 swappedLP = address(this).balance.sub(balanceBeforeLP);
            addLiquidity(secondHalf, swappedLP);
            emit SwapAndLiquify(firstHalf, swappedLP, secondHalf);
             
        }
        
        //3 lines of red = One for the sale, one for the LP and one for all other BNB fees
        //Process all of the BNB fees together - so only one additional line of red, then split them by ratio

        
        if (_otherBNB_X100 > 0) {
            
            ___percentOtherBNB = precDiv(_otherBNB_X100,_totalBNBFees_X100,2);
            ___tokensOtherBNB = numTokens*___percentOtherBNB/100;
            //swap these tokens for BNB in one transaction
            uint256 balanceBeforeOtherBNB = address(this).balance;
            swapTokensForEth(___tokensOtherBNB);
            uint256 balanceTotalOtherBNB = address(this).balance - balanceBeforeOtherBNB;
            //split based on the ratio
            
            if (_FeePromo_X100 > 0) {
                //find the marketing ratio and send to wallet
                uint256 ___percentPromo = precDiv(_FeePromo_X100,_otherBNB_X100,2);
                uint256 ___bnbPromo = balanceTotalOtherBNB*___percentPromo/100;
                sendBNBToWallet(wallet_Marketing, ___bnbPromo);

            }
            
            if (_FeeDev_X100 > 0) {
                //find the dev fee ratio and send to wallet
                uint256 ___percentDev = precDiv(_FeeDev_X100,_otherBNB_X100,2);
                uint256 ___bnbDev = balanceTotalOtherBNB*___percentDev/100;
                sendBNBToWallet(wallet_Dev, ___bnbDev);

            }
            
            if (_FeeAnimator_X100 > 0) {
                //find the animator fee ratio and send to wallet
                uint256 ___percentAnimator = precDiv(_FeeAnimator_X100,_otherBNB_X100,2);
                uint256 ___bnbAnimator = balanceTotalOtherBNB*___percentAnimator/100;
                sendBNBToWallet(wallet_Animator, ___bnbAnimator);

            }
            
            
            
                    
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
            owner(), //XXXX
            block.timestamp
        );
    } 


    //manually purge tokens from contract and liquify
    function process_TokensFromContract_LP(uint256 tokenAmount) public onlyOwner {
            uint256 tokensOnContract = balanceOf(address(this));
            if (tokenAmount > tokensOnContract) {tokenAmount = tokensOnContract;}
            uint256 firstHalf = tokenAmount.div(2);
            uint256 secondHalf = tokenAmount.sub(firstHalf);
            uint256 balanceBeforeLP = address(this).balance;
            swapTokensForEth(firstHalf); 
            uint256 swappedLP = address(this).balance.sub(balanceBeforeLP);
            addLiquidity(secondHalf, swappedLP);
            emit SwapAndLiquify(firstHalf, swappedLP, secondHalf);
    }    
    

    //manually purge tokens from contract, swap to bnb and send to a wallet
    function process_TokensFromContract_BNB_Wallet(address payable sendTo, uint256 tokenAmount) public onlyOwner {
        uint256 tokensOnContract = balanceOf(address(this));
        if (tokenAmount > tokensOnContract) {tokenAmount = tokensOnContract;}
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 bnbAmount = address(this).balance - balanceBefore;
        sendBNBToWallet(sendTo, bnbAmount);
    }

    //manually purge BNB from contract to a wallet
    function process_BNBFromContract_Wallet(address payable sendTo, uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        sendBNBToWallet(sendTo, bnbAmount);
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



//created by gentokens.com