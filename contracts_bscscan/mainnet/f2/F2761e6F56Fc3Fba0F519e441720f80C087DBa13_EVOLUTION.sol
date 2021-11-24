/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

/*

 _______          _            _             
(_______)        | |      _   (_)            
 _____ _   _ ___ | |_   _| |_  _  ___  ____  
|  ___) | | / _ \| | | | |  _)| |/ _ \|  _ \ 
| |____\ V / |_| | | |_| | |__| | |_| | | | |
|_______)_/ \___/|_|\____|\___)_|\___/|_| |_|


Telegram: https://t.me/TheEvolutionOfficial
Website: https://evolutioncrypto.net/
EvoSwap: https://app.evoswap.net/

Functions:

- EvoBoost
- Evoswap
- NFT Marketplace
- Staking
- Unique Variable BuyBack System
- 4% Reflection to holders



*/
// SPDX-License-Identifier:Unlicensed

pragma solidity ^0.8.4;


interface IBEP20 {

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = payable(_msgSender());
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = payable(address(0));
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until defined days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    
    function swapETHForBuyBackToken(
        address buyBacktoken,
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = buyBacktoken;

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    
    

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }


}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}



contract EVOLUTION is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public winningAmount;
    mapping(address => bool) public _isSniper;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromBuyFee;
    mapping(address => bool) private _isExcludedFromSellFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address[] private _excluded;
    address[] public pool1Winners;
    address[] public pool2Winners;
    address[] public pool3Winners;
    address[] public pool4Winners;
    address[] public pool5Winners;  
    address[] public _confirmedSnipers;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 *1e9 * 1e18;
    
  
    
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Evolution";
    string private _symbol = "EVO";
    uint8 private _decimals = 18;

    IPancakeRouter02 public pancakeRouter;
    address public immutable pancakePair;
    address payable public marketWallet;
    address payable public developmentWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    // replace by default buyback for mainennet launch
    address public buyBacktoken= 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    //

    bool public swapAndLiquifyEnabled = false; // should be true to turn on to liquidate the pool
    bool inSwapAndLiquify = false;
    bool public reflectionFeesdisabled = false;
    bool public buyBackEnabled = false;  // should be true to turn on to buy back from pool
    uint256 public _launchTime; // can be set only once
    uint256 public antiSnipingTime = 4 seconds; 
    bool public _tradingOpen = false; //once switched on, can never be switched off.
    
    bool public AllowContractTosell =true;
    bool public marketingDevSwap = true;
    
    uint256 public _taxFee = 40; // 4% will be distributed among holder as EVO divideneds
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 20; // 2% will be added to the liquidity pool
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _EvoBoostFee = 70;  // 7% will go to the EvoBoost pool 
    uint256 private _previousEvoBoostFee = _EvoBoostFee;
    
    uint256 public _marketFee = 40;  // 4% will go to the market address 
    uint256 private _previousMarketFee = _marketFee;
    
      uint256 public _devFee = 30;  // 3% will go to the market address 
    uint256 private _previousDevFee = _devFee;
    
    uint256 public _BuybackFee = 20;  // 2% will go to the buyBack Token 
    uint256 private _previousBuybackFee = _BuybackFee;
    
    uint256 public minTokenNumberToSell = _tTotal.div(100000); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 public _maxTxAmount = _tTotal.mul(2).div(1000); // should be 0.2% percent per transaction
    
    uint256 public _maxWalletAmount=_tTotal.mul(9).div(1000);
    
    uint256 public minBuy = 0; 
    uint256 buyBackLowerLimit = 0.1 ether;
    uint256 buyBackUpperLimit = 1 ether;

    //EvoBoost pools calculations
    uint256 private pool1Count = 1;
    uint256 private pool2Count = 1;
    uint256 private pool3Count = 1;
    uint256 private pool4Count = 1;
    uint256 private pool5Count = 1;
    uint256 private pool1Amount;
    uint256 private pool2Amount;
    uint256 private pool3Amount;
    uint256 private pool4Amount;
    uint256 private pool5Amount;
    uint256 public pool1EvoBoost = 7;
    uint256 public pool2EvoBoost = 47;
    uint256 public pool3EvoBoost = 127;
    uint256 public pool4EvoBoost = 547;
    uint256 public pool5EvoBoost = 1027;
    uint256 public pool1Percent = 30;
    uint256 public pool2Percent = 10;
    uint256 public pool3Percent = 10;
    uint256 public pool4Percent = 10;
    uint256 public pool5Percent = 10;
    
    mapping  (address => mapping (uint256 => uint256 ))  public countPerUserPerLevel ;

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

    constructor (address payable _marketWallet,address payable _devWallet) {
        _rOwned[owner()] = _rTotal;
        marketWallet = _marketWallet;
        developmentWallet =_devWallet;
        

    IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    //Testnet IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());
    

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(burnAddress)] = true;
        
        
      
        _isExcluded[buyBacktoken] = true;
        //exclude from reward
        _isExcluded[burnAddress] = true;

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(_getRate()));
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account].mul(_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    // admin setter functions
    
    // function setTradingOpen(bool value) external onlyOwner {
    //     _tradingOpen = value;
    // }

    // for 1% input 100
    function setMaxTxPercent(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxAmount).div(10000);
    }
    
     function setMaxWalletBalance(uint256 amount) external onlyOwner{
        _maxWalletAmount = amount;
    }
    
    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }
    
     function setBuyBackToken(address value) public onlyOwner {
        buyBacktoken = value;
        _isExcluded[buyBacktoken] = true;
    }
    
      function setContractSell(bool value) public onlyOwner {
        AllowContractTosell = value;
    }
    
      function setMarketDevSwap(bool value) public onlyOwner {
        marketingDevSwap = value;
    }

    function setBuyback(uint256 _upperAmount, uint256 _lowerAmount, bool _state) public onlyOwner {
        buyBackEnabled = _state;
        buyBackUpperLimit = _upperAmount;
        buyBackLowerLimit = _lowerAmount;
    }

    function includeAndExcludeFromFee(address account, bool _state) public onlyOwner {
        _isExcludedFromFee[account] = _state;
    }

    function includeAndExcludeFromBuyFee(address account, bool _state) public onlyOwner {
        _isExcludedFromBuyFee[account] = _state;
    }

    function includeAndExcludeFromSellFee(address account, bool _state) public onlyOwner {
        _isExcludedFromSellFee[account] = _state;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }
    
    function setEvoBoostFeePercent(uint256 EvoBoostFee) external onlyOwner {
        _EvoBoostFee = EvoBoostFee;
    }
    
    function setMarketFeePercent(uint256 marketFee) external onlyOwner {
        _marketFee = marketFee;
    }
    
    function setDevFeePercent(uint256 devFee) external onlyOwner {
        _devFee  = devFee;
    }
    function setBuybackFeePercent(uint256 BuybackFee) external onlyOwner {
        _BuybackFee = BuybackFee;
    }

    function setMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }    
    
    function setTimeForSniping(uint256 _time) external onlyOwner {
        antiSnipingTime = _time;
    }

    function startTrading() external onlyOwner {
        _tradingOpen = true;
        _launchTime = block.timestamp;
       
        swapAndLiquifyEnabled = true;
        // approve contract
        _approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }
    
    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdisabled = _state;
    }
    
    function setMarketAddress(address payable _marketAddress) external onlyOwner {
        marketWallet = _marketAddress;
    }
    
    function setDevlopmentAddress(address payable value) external onlyOwner {
    developmentWallet = value;
    }
    
    function setPancakeRouter(IPancakeRouter02 _pancakeRouter) external onlyOwner {
        pancakeRouter = _pancakeRouter;
    }

    function setEvoBoostPools(uint256 _count1,uint256 _count2,uint256 _count3,uint256 _count4,uint256 _count5) external onlyOwner {
        pool1EvoBoost = _count1;
        pool2EvoBoost = _count2;
        pool3EvoBoost = _count3;
        pool4EvoBoost = _count4;
        pool5EvoBoost = _count5;
    }

    function setEvoBoostPoolsPercent(uint256 _percent1,uint256 _percent2,uint256 _percent3,uint256 _percent4,uint256 _percent5) external onlyOwner {
        pool1Percent = _percent1;
        pool2Percent = _percent2;
        pool3Percent = _percent3;
        pool4Percent = _percent4;
        pool5Percent = _percent5;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}
    
    function totalFeePerTx(uint256 tAmount) internal view returns(uint256) {
        uint256 percentage = tAmount.mul(_taxFee.add(_liquidityFee).add(_EvoBoostFee).add(_marketFee).add(_devFee).add(_BuybackFee)).div(1e3);
        return percentage;
    }
    
    // distribution to holders
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_taxFee).div(1e3);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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

    function _takeBothPoolFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 tPoolFee = tAmount.mul(_liquidityFee.add(_EvoBoostFee).add(_marketFee).add(_BuybackFee).add(_devFee)).div(1e3);
        uint256 rPoolFee = tPoolFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rPoolFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tPoolFee);
        emit Transfer(_msgSender(), address(this), tPoolFee);
    }
    
    // function _takeMarketFee(uint256 tAmount, uint256 currentRate) internal {
    //     uint256 tMarketFee = tAmount.mul(_marketFee).div(1e3);
    //     uint256 rMarketFee = tMarketFee.mul(currentRate);
    //     _rOwned[marketWallet] = _rOwned[marketWallet].add(rMarketFee);
    //     if (_isExcluded[burnAddress])
    //         _tOwned[marketWallet] = _tOwned[marketWallet].add(tMarketFee);
    //     emit Transfer(_msgSender(), marketWallet, tMarketFee);
    // }
    
    // function _takeBuybackFee(uint256 tAmount, uint256 currentRate) internal {
    //     uint256 BuybackFee = tAmount.mul(_BuybackFee).div(1e3);
    //     uint256 rBuybackFee = BuybackFee.mul(currentRate);
    //     _rOwned[burnAddress] = _rOwned[burnAddress].add(rBuybackFee);
    //     if (_isExcluded[burnAddress])
    //         _tOwned[burnAddress] = _tOwned[burnAddress].add(BuybackFee);
    //     emit Transfer(_msgSender(), burnAddress, BuybackFee);
    // }

    function removeAllFee() private {
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousEvoBoostFee = _EvoBoostFee;
        _previousMarketFee = _marketFee;
        _previousBuybackFee = _BuybackFee;
         _previousDevFee =  _devFee ;

        _taxFee = 0;
        _liquidityFee = 0;
        _EvoBoostFee = 0;
        _marketFee = 0;
        _BuybackFee = 0;
        _devFee=0;
    }
    
    function removeBuyFee() private {
        _previousEvoBoostFee = _EvoBoostFee;

        _EvoBoostFee = 0;
    }
    
    function removeSellFee() private {
        _previousTaxFee = _taxFee;
        _previousDevFee  = _devFee ;

        _taxFee = 0;
        _devFee  = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _EvoBoostFee = _previousEvoBoostFee;
        _marketFee = _previousMarketFee;
        _BuybackFee = _previousBuybackFee;
         _devFee  = _previousDevFee ;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getCurrentPrice() public view returns(uint256){
        (uint256 token, uint256 Wbnb,) = IPancakePair(pancakePair).getReserves();
        uint256 currentRate = Wbnb.div(token.div(1e9));
        return currentRate;
    }

    function _addSniperInList(address account) external onlyOwner() {
        require(account != address(pancakeRouter), 'We can not blacklist pancakeRouter');
        require(!_isSniper[account], "Account is already blacklisted");
        _isSniper[account] = true;
        _confirmedSnipers.push(account);
    }

    function _removeSniperFromList(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
            if (_confirmedSnipers[i] == account) {
                _confirmedSnipers[i] = _confirmedSnipers[_confirmedSnipers.length - 1];
                _isSniper[account] = false;
                _confirmedSnipers.pop();
                break;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: amount must be greater than zero");
        require(!_isSniper[to], "You shall not pass!");
        require(!_isSniper[from], "You shall not pass!");

        if(from == pancakePair && to != address(this)){
            require(amount >= minBuy,"EVO: amount less than minimum buy"); 
        }

        if(_isExcludedFromMaxTx[from] == false && 
            _isExcludedFromMaxTx[to] == false   // by default false
        ){
            require(amount <= _maxTxAmount,"BEP20: amount exceeded max limit");
            
               if(!_isExcludedFromMaxTx[to] && to != pancakePair){
            require(balanceOf(to).add(amount) <= _maxWalletAmount, 'Recipient balance is exceeding maxWalletBalance');
        }    

            if (!_tradingOpen){
                    require(to != pancakePair, "Trading is not enabled");
            }

          if (block.timestamp < _launchTime + antiSnipingTime && from != address(pancakeRouter)) {
                if (from == pancakePair) {
                    _isSniper[to] = true;
                    _confirmedSnipers.push(to);
                }else if (to == pancakePair){
                    _isSniper[from] = true;
                    _confirmedSnipers.push(from);
                }
            }

        }

        // swap
        if (AllowContractTosell == true)
                 swaps(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || reflectionFeesdisabled) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();
        else if(sender == pancakePair){
            if(!_isExcludedFromBuyFee[recipient]){
                removeSellFee();
                checkEvoBoost(recipient, amount);
            }else{
                removeAllFee();
            }
            takeFee = false;
        }
        else{
            if(!_isExcludedFromSellFee[recipient]){
                removeBuyFee();
            }else{
                removeAllFee();
            }
            takeFee = false;
        }

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

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(tAmount, currentRate);

        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(tAmount, currentRate);
    
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(tAmount, currentRate);

        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(tAmount, currentRate);

        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function checkEvoBoost(address user, uint256 amount) internal{

        if(pool1Count == pool1EvoBoost){
            distributeEvoBoost(user, pool1Amount,1);
            pool1Winners.push(user);
            pool1Amount = 0;
            pool1Count = 1;
        }
        if(pool2Count == pool2EvoBoost){
            distributeEvoBoost(user, pool2Amount,2);
            pool2Winners.push(user);
            pool2Amount = 0;
            pool2Count = 1;
        }
        if(pool3Count == pool3EvoBoost){
            distributeEvoBoost(user, pool3Amount,3);
            pool3Winners.push(user);
            pool3Amount = 0;
            pool3Count = 1;
        }
        if(pool4Count == pool4EvoBoost){
            distributeEvoBoost(user, pool4Amount,4);
            pool4Winners.push(user);
            pool4Amount = 0;
            pool4Count = 1;
        }
        if(pool5Count == pool5EvoBoost){
            distributeEvoBoost(user, pool5Amount,5);
            pool5Winners.push(user);
            pool5Amount = 0;
            pool5Count = 1;
        }

        pool1Count++;
        pool2Count++;
        pool3Count++;
        pool4Count++;
        pool5Count++;

        pool1Amount = pool1Amount.add(amount.mul(pool1Percent).div(1000));
        pool2Amount = pool2Amount.add(amount.mul(pool2Percent).div(1000));
        pool3Amount = pool3Amount.add(amount.mul(pool3Percent).div(1000));
        pool4Amount = pool4Amount.add(amount.mul(pool4Percent).div(1000));
        pool5Amount = pool5Amount.add(amount.mul(pool5Percent).div(1000));
    
    }

    function distributeEvoBoost(address user, uint256 amount ,uint256 level) internal{
        winningAmount[user] = winningAmount[user].add(amount);
        countPerUserPerLevel[user][level]++;
        _rOwned[user] = _rOwned[user].add(amount.mul(_getRate()));
        if (_isExcluded[user])
            _tOwned[user] = _tOwned[user].add(amount);
        emit Transfer(address(this), user, amount);
    }

    function swaps(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 swapAmount;
        swapAmount = contractTokenBalance.sub(pool1Amount.add(pool2Amount).add(pool3Amount).add(pool4Amount).add(pool5Amount));
        if (swapAmount >= _maxTxAmount) {
            swapAmount = _maxTxAmount;
        }

        bool shouldSell = swapAmount >= minTokenNumberToSell;

        // can not trigger on buy transactions
        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != pancakePair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == pancakePair) // swap 1 time 
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            // split the contract balance into 2 pieces
            
            swapAmount = minTokenNumberToSell;
            
            
            uint256 liquidityAmtToken = swapAmount * _liquidityFee / (_liquidityFee + _marketFee + _devFee + _BuybackFee);
             uint256 marketAmtToken;
              uint256 devAmtToken;
             
            
            
            

            // add liquidity
            // split the contract balance into 2 pieces
            
            uint256 otherPiece = liquidityAmtToken.div(2);
            uint256 tokenAmountToBeSwapped = liquidityAmtToken.sub(otherPiece);
            
            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(pancakeRouter), tokenAmountToBeSwapped);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract

            uint256 bnbToBeAddedToLiquidity = address(this).balance.sub(initialBalance);

            // add liquidity to pancake
            Utils.addLiquidity(address(pancakeRouter), owner(), otherPiece, bnbToBeAddedToLiquidity);
            
            if(marketingDevSwap == true){
                
                 marketAmtToken = swapAmount * _marketFee / (_liquidityFee + _marketFee + _devFee + _BuybackFee);
                 devAmtToken = swapAmount * _devFee / (_liquidityFee + _marketFee + _devFee + _BuybackFee);
                
                uint256 beforeBalance = address(this).balance;
                 Utils.swapTokensForEth(address(pancakeRouter), marketAmtToken + devAmtToken );
                    uint256 bnbForMarketDev = address(this).balance.sub(beforeBalance);
                    uint256 bnbForMarket = bnbForMarketDev * _marketFee /(_marketFee + _devFee);
                    uint256 bnbForDev = bnbForMarketDev - bnbForMarket;
                   
                    (bool successMark, ) = marketWallet.call{value:bnbForMarket}("");
                    require(successMark, "Transfer failed.");
                    
                     (bool successDev, ) = developmentWallet.call{value:bnbForDev}("");
                    require(successDev, "Transfer failed.");
                
                
            }
            
            if(buyBackEnabled== true){
            
            uint256 remaininigTokens = swapAmount-liquidityAmtToken -marketAmtToken-devAmtToken;
             Utils.swapTokensForEth(address(pancakeRouter), remaininigTokens );
            
            uint256 balanceBeforeBuyback = address(this).balance;
            
            // buy back if balance bnb is exceed upper limit
            if ( balanceBeforeBuyback > uint256(buyBackLowerLimit)) {
                
                if (balanceBeforeBuyback > buyBackUpperLimit)
                    balanceBeforeBuyback = buyBackUpperLimit;
                
                // buyBackTokens(initialBalance.mul(buyBackLowerLimit).div(100));
                Utils.swapETHForBuyBackToken(buyBacktoken,address(pancakeRouter), burnAddress, balanceBeforeBuyback.div(10));
            }
            }
            
            emit SwapAndLiquify(tokenAmountToBeSwapped, bnbToBeAddedToLiquidity, otherPiece);
        }
    }
    
    
}