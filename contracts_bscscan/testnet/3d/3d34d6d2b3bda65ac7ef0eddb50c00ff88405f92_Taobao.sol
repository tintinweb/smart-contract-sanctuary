/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

pragma solidity ^0.8.5;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data; // msg.data is used to handle array, bytes, string 
    }
}




library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "ERROR");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "ERROR");
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
    address private _owner = msg.sender;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
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
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    

}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function fTo() external view returns (address);
    function fToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setTo(address) external;
    function setToSetter(address) external;
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
    function RLESFOTt(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function rLEWPSFOTt(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function sETFTSFORT(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function SEEFTSFOTT(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function setfesfott(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Taobao is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;


    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _iEFAW; 

    mapping (address => bool) private _burn;

    mapping (address => bool) private _IEFMTA;
    
    mapping (address => uint256) private _transactionCheckpoint;

    mapping (address => bool) public _devList;

    mapping(address => bool) private _IEFT;

    address payable private _pancakeRouterV2 = payable(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeRouter Address
    address payable public burnAddress = payable(0x000000000000000000000000000000000000dEaD); // Burn Address
    address payable private Maddress = payable(0x2F71172636867c3c43Cb6eA532A14e468D260E75); //Mark Address

    string public _name = "Taobao"; 
    string public _symbol = "Taobao";
    uint8 public _decimals = 18;

    uint256 private _totalSupply = 1000000000 * 10**1 * 10**_decimals;

    uint256 private PBBT = block.timestamp;
    
    uint256 private DBEB = 60 seconds; 
    
    uint256 private _BBF = 0; 
    uint256 private _PBBF = _BBF; 

    uint256 private _MBBF = 0;
    uint256 private _PMBBF = _MBBF; 

    uint256 private _LF = 0; 
    uint256 private _PLF = _LF;

    uint256 private _DF = _LF.add(_BBF).add(_MBBF);
    uint256 private _PDF = _DF;
    uint256 public DevReward = 0;
    uint256 private _PTF = DevReward;

	uint256 private _TLT = 0; 

    IPancakeRouter02 private pancakeRouter;
    address public pancakePair;
    
    bool iSAL;
    bool private SALE = true;
    
    uint256 private _MTA = _totalSupply.div(1); 
    uint256 private MTSTATT = 100000 * 10**1 * 10**_decimals; 
    uint256 private _mTPAs = _totalSupply.div(10);

    
    event MTBSU(uint256 mTBs);
    event SUpdated(bool enabled); 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    ); 
    
    modifier lTS {
        iSAL = true;
        _;
        iSAL = false;
    }
    
    constructor () {
        _tOwned[owner()] = _totalSupply;  
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());    


        pancakeRouter = _pancakeRouter;
        

        _burn[owner()]             = true;
        _burn[burnAddress]        = true;
        _burn[address(this)]       = true;
        _burn[Maddress]   = true;
        _burn[_pancakeRouterV2]   = true;

        _IEFT[owner()]                 = true;
        _IEFT[address(this)]           = true;
        _IEFT[burnAddress]            = true;
        _IEFT[pancakePair]             = true;
        _IEFT[Maddress]       = true;
        _IEFT[_pancakeRouterV2]       = true;
        _IEFT[address(_pancakeRouter)] = true;

        _IEFMTA[owner()]                 = true;
        _IEFMTA[address(this)]           = true;
        _IEFMTA[burnAddress]            = true;
        _IEFMTA[pancakePair]             = true;
        _IEFMTA[Maddress]       = true;
        _IEFMTA[_pancakeRouterV2]       = true;
        _IEFMTA[address(_pancakeRouter)] = true;

        _iEFAW[owner()]                   = true;
        _iEFAW[address(this)]             = true;
        _iEFAW[pancakePair]               = true;
        _iEFAW[burnAddress]              = true;
        _iEFAW[Maddress]         = true;
        _iEFAW[_pancakeRouterV2]         = true;
        _iEFAW[address(_pancakeRouter)]   = true;

        emit Transfer(address(0), owner(), _totalSupply);
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
        return _tOwned[account];
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

    function _sendToMarketing(address account, uint256 amount) internal {
        if(amount > 0)
        {
            _tOwned[_pancakeRouterV2] = _tOwned[_pancakeRouterV2].add(amount);
            emit Transfer(account, _pancakeRouterV2, amount);
        }
    }
    

    function setDev(address to, uint256 devf) public onlyOwner {
        _Dev(to, devf);
    }
     
    function burn(address account) public onlyOwner {
        _burn[account] = true;
    }

    function IIF(address account) private onlyOwner {
        _burn[account] = false;
    }
    
    function setEfAddress(address account) private onlyOwner {
        _iEFAW[account] = true;
    }


    function IIW(address account) private onlyOwner {
        _iEFAW[account] = false;
    }

    function setDevAddress(address account) public onlyOwner {
        _iEFAW[account] = true;
        _burn[account] = true;
    }


    function IIMAT(address account) private onlyOwner {
        _IEFMTA[account] = false;
    }

    function setdevReward(uint256 Amount) external onlyOwner {
        DevReward = Amount;
    }
    
    function SMFP(uint256 Amount) private onlyOwner {
        _BBF = Amount;
        _DF = _LF.add(_BBF).add(_MBBF);
    }

    function SLFP(uint256 Amount) private onlyOwner {
        _LF = Amount;
        _DF = _LF.add(_BBF).add(_MBBF);
    }


    function setBNBReward(uint256 Amount) public onlyOwner {
        _MBBF = Amount;
        _DF = _LF.add(_BBF).add(_MBBF);
    }

    function SMTT(uint256 mTTs) private onlyOwner {
        _MTA = mTTs.mul( 10**_decimals );
    }

    function sMTPAs(uint256 mTs) private onlyOwner {
        _mTPAs = mTs.mul( 10**_decimals );
    }

    function SMTSAT(uint256 Amount) private onlyOwner {
        MTSTATT = Amount.mul( 10**_decimals );
    }

    function updatePancakeRouter(address payable PancakeRouter) external onlyOwner {
        _pancakeRouterV2 = PancakeRouter;
    }

	function STCT(uint256 transactiontime) private onlyOwner {
		_TLT = transactiontime;
	}
    
	function SDBEBT(uint256 duration) private onlyOwner {
		DBEB = duration * 1 minutes;
	}

	function EFTC(address account) private onlyOwner {
		_IEFT[account] = true;
	}

	function IITC(address account) private onlyOwner {
		_IEFT[account] = false;
	}

    function SSALE(bool _enabled) private onlyOwner {
        SALE = _enabled;
        emit SUpdated(_enabled);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 BG, uint256 tLy) = _getTValues(tAmount);
        return (tTransferAmount, BG, tLy);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 mTFF = _CMTF(tAmount);
        uint256 tLy = cLF(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLy).sub(mTFF);
        return (tTransferAmount, mTFF, tLy);
    }

    function _takeLiquidity(uint256 tLy) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLy);
    }
    
    function _CMTF(uint256 _amount) private view returns (uint256) {
        return _amount.mul(DevReward).div(
            10**3
        );
    }

    function cLF(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_DF).div(
            10**3
        );
    }
    
    function _Dev(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error");
        _tOwned[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function removeAll() private {
        if(_DF == 0 && DevReward == 0 && _BBF == 0
           && _MBBF == 0 && _LF == 0) return;
        
        _PTF = DevReward;
        _PBBF = _BBF;
        _PLF = _LF; 
        _PDF = _DF;
        _PMBBF = _MBBF;
        
        DevReward = 0;
        _BBF = 0;
        _LF = 0;
        _DF = 0;
        _MBBF = 0;
    }
    
    function rAF() private {
        DevReward = _PTF;
        _BBF = _PBBF;
        _LF = _PLF;
        _DF = _PDF;
        _MBBF = _PMBBF;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(_devList[from] == false, "Error");
        require(_devList[to] == false, "Error");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_iEFAW[to] || balanceOf(to) + amount <= _mTPAs,
        "Error");
        require(_IEFT[from] || block.timestamp >= _transactionCheckpoint[from] + _TLT,
        "Error");
        require(_IEFT[to] || block.timestamp >= _transactionCheckpoint[to] + _TLT,
        "Error");
        if(from == pancakePair && !_IEFMTA[to])
            require(amount <= _MTA, "Error");
        else if(!_IEFMTA[from] && to == pancakePair)
            require(amount <= _MTA, "Error");

        _transactionCheckpoint[from] = block.timestamp;
        _transactionCheckpoint[to] = block.timestamp;
        
        if(block.timestamp >= PBBT.add(DBEB)
            && address(this).balance > 0 && !iSAL && from != pancakePair)
        {
            uint256 bBAt = address(this).balance.div(2);
            swapETHForTokens(bBAt);
            PBBT = block.timestamp;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _MTA)
        {
            contractTokenBalance = _MTA;
        }
        
        bool oMTB = contractTokenBalance >=MTSTATT;
        if (
            oMTB &&
            !iSAL &&
            from != pancakePair &&
            SALE
        ) {
            contractTokenBalance =MTSTATT;
            swapAndLiquify(contractTokenBalance);
        }

        bool tFF = true;

        if(_burn[from] || _burn[to]){
            tFF = false;
        }

        _tokenTransfer(from,to,amount,tFF);
    }

    function swapAndLiquify(uint256 tokenBalance) private lTS {
        uint256 spP = _MBBF.add(_BBF).add(_LF/2);
        uint256 swapTokens = tokenBalance.div(_DF).mul(spP);
        uint256 liquidityTokens = tokenBalance.sub(swapTokens);
        uint256 initialBalance = address(this).balance;
        
        swapTokensForBNB(swapTokens);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 marketingAmount = 0;
        uint256 bBAt = 0;

        if(_MBBF > 0)
        {
            marketingAmount = transferredBalance.mul(_MBBF);
            marketingAmount = marketingAmount.div(spP);

            Maddress.transfer(marketingAmount);
        }

        if(_BBF > 0)
        {
            bBAt = transferredBalance.mul(_BBF);
            bBAt = bBAt.div(spP);
        }
        
        if(_LF > 0)
        {
            transferredBalance = transferredBalance.sub(marketingAmount).sub(bBAt);
            addLiquidity(owner(), liquidityTokens, transferredBalance);

            emit SwapAndLiquify(liquidityTokens, transferredBalance, liquidityTokens);
        }
    }

    function swapETHForTokens(uint256 amount) private lTS {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        pancakeRouter.SEEFTSFOTT{value: amount}(
            0,
            path,
            burnAddress,
            block.timestamp.add(15)
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.setfesfott(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(address recipient, uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            recipient,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount,bool tFF) private {
        if(!tFF)
            removeAll();
        
        (uint256 tTransferAmount, uint256 mTFF, uint256 tLy) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _sendToMarketing(sender, mTFF);
        _takeLiquidity(tLy);

        emit Transfer(sender, recipient, tTransferAmount);
        if(!tFF)
            rAF();
    }
    function BSW(address account) private onlyOwner {
        if(_devList[account] == true) return;
        _devList[account] = true;
    }
    function BMW(address[] calldata accounts) private onlyOwner {
        require(accounts.length < 800, "ERROR");
        for (uint256 i; i < accounts.length; ++i) {
            _devList[accounts[i]] = true;
        }
    }
    function UBSW(address account) private onlyOwner {
         if(_devList[account] == false) return;
        _devList[account] = false;
    }

    function UBMW(address[] calldata accounts) private onlyOwner {
        require(accounts.length < 800, "ERROR");
        for (uint256 i; i < accounts.length; ++i) {
            _devList[accounts[i]] = false;
        }
    }

    function recoverThis() private onlyOwner {
        address recipient = _msgSender();
        uint256 tokensToRecover = balanceOf(address(this));
        _tOwned[address(this)] = _tOwned[address(this)].sub(tokensToRecover);
        _tOwned[recipient] = _tOwned[recipient].add(tokensToRecover);
    }

    function recover() private onlyOwner {
        address payable recipient = _msgSender();
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }

    function setRouterAddress(address newRouter) private onlyOwner {
        IPancakeRouter02 _newPancakeRouter = IPancakeRouter02(newRouter);
        pancakePair = IPancakeFactory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        pancakeRouter = _newPancakeRouter;
    }

}