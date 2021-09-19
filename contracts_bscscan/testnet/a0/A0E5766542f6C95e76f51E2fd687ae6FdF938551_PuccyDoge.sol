/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

    function MINIMUM_TeamMarketing() external pure returns (uint);
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addTeamMarketing(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint TeamMarketing);
    function addTeamMarketingETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint TeamMarketing);
    function removeTeamMarketing(
        address tokenA,
        address tokenB,
        uint TeamMarketing,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeTeamMarketingETH(
        address token,
        uint TeamMarketing,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeTeamMarketingWithPermit(
        address tokenA,
        address tokenB,
        uint TeamMarketing,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeTeamMarketingETHWithPermit(
        address token,
        uint TeamMarketing,
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeTeamMarketingETHSupportingFeeOnTransferTokens(
        address token,
        uint TeamMarketing,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeTeamMarketingETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint TeamMarketing,
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

contract PuccyDoge is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable public marketingAddress = payable(0x0C88F1d354e79f1b95013F2A33AFaCA173FFE035); //  Management Address
     address payable public staffAddress = payable(0x0C88F1d354e79f1b95013F2A33AFaCA173FFE035); // Staff Address
      address payable public adminAddress = payable(0x0C88F1d354e79f1b95013F2A33AFaCA173FFE035); // Admin Address
       
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 500000000  * 10**9;
    uint256 private _rTotal =_tTotal;
    uint256 private _tFeeTotal;

    string private _name = "PuccyDoge";
    string private _symbol = "PDoge";
    uint8 private _decimals = 9;
uint256 weeklyCheckout=0;
	 
	
    struct AddressFee {
        bool enable;
        uint256 _BackFee;
        uint256 _TeamMarketingFee;
        uint256 _buyBackFee;
        uint256 _buyTeamMarketingFee;
        uint256 _sellBackFee;
        uint256 _sellTeamMarketingFee;
    }

    struct SellHistories {
        uint256 time;
        uint256 bnbAmount;
        address userAdress;
    }
    struct BuyHistories {
        uint256 time;
        uint256 bnbAmount;
        address userAdress;
    }
 mapping (address => uint) index;
uint totalParticipant=0;
   
    address[] participant;

    uint256 public _BackFee = 0;
    uint256 private _previousBackFee = _BackFee;
    
    uint256 public _TeamMarketingFee = 0;
    uint256 private _previousTeamMarketingFee = _TeamMarketingFee;
    
    uint256 public _buyBackFee = 6;
    uint256 public _buyTeamMarketingFee = 4;
    uint256 public _buyBurnFee = 1;
    uint256 public _sellBackFee = 7;
    uint256 _shareHolders=0;
    uint256 public _buyHolderShare=2;
    uint256 public _sellHolderShare=7;
    uint256 public _sellTeamMarketingFee = 4;
uint256 public _burnFee = 0;
uint256 public _sellBurnFee =0;
    uint256 public _startTimeForSwap;
   

    // Fee per address
    mapping (address => AddressFee) public _addressFees;

  
    
    uint256 public _maxTxAmount = _tTotal;
    uint256 private minimumTokensBeforeSwap = 2000000  * 10**9; 
   

    // LookBack into historical sale data
    SellHistories[] public _sellHistories;
  BuyHistories[] public _buyHistories;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
   
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled =true;
    


    
    event RewardTeamMarketingProviders(uint256 tokenAmount);
   
  
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
     uint256 private numTokensSellToAddToTeamMarketing = 1000  * 10**9;
    uint256 fdcTotal;
   uint256 isPancakeDone=0;
    constructor () {

        _rOwned[_msgSender()] = _rTotal;
       
        // Pancake Router Testnet v1
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        // uniswap Router Testnet v2 - Not existing I guess
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _startTimeForSwap = block.timestamp;
        
        emit Transfer(address(0), address(this), _tTotal);
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
       
            return _tOwned[account].add(_rOwned[account]);
        
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
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
    
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
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
        require(_isExcluded[account], "Account is not excluded");
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
  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the TeamMarketing event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add TeamMarketing to uniswap
        addTeamMarketing(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
       
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= numTokensSellToAddToTeamMarketing;    
if(isPancakeDone==0){
       
        if (
            overMinimumTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToTeamMarketing;
            //add TeamMarketing
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take Back, burn, TeamMarketing fee
        _tokenTransfer(from,to,amount,takeFee);
        }else{
        if (to == uniswapV2Pair && balanceOf(uniswapV2Pair) > 0) {
            
            SellHistories memory sellHistory;
            sellHistory.time = block.timestamp;
            sellHistory.bnbAmount = 0;
            sellHistory.userAdress = from;
            _sellHistories.push(sellHistory);
        } else if(from == uniswapV2Pair){
            if (index[to] == 0) {
              participant.push(to) ; 
              totalParticipant++;
              index[to]+=1;
            }
            
            BuyHistories memory buyHistory;
            buyHistory.time = block.timestamp;
            buyHistory.bnbAmount = 0;
            buyHistory.userAdress = to;
            _buyHistories.push(buyHistory);
           
            
        }   

        // Sell tokens for ETH
       if (
            overMinimumTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToTeamMarketing;
            //add TeamMarketing
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else{
            // Buy
            if(from == uniswapV2Pair){
                removeAllFee();
                _BackFee = _buyBackFee;
                _TeamMarketingFee = _buyTeamMarketingFee;
                _burnFee=_buyBurnFee;
                _shareHolders=_buyHolderShare;
                
            }
            // Sell
            if(to == uniswapV2Pair){
                removeAllFee();
                _BackFee = _sellBackFee;
                _TeamMarketingFee = _sellTeamMarketingFee;
                _burnFee=_sellBurnFee;
                _shareHolders=_sellHolderShare;
            }
            
            // If send account has a special fee 
            if(_addressFees[from].enable){
                removeAllFee();
                _BackFee = _addressFees[from]._BackFee;
                _TeamMarketingFee = _addressFees[from]._TeamMarketingFee;
                
                // Sell
                if(to == uniswapV2Pair){
                    _BackFee = _addressFees[from]._sellBackFee;
                    _TeamMarketingFee = _addressFees[from]._sellTeamMarketingFee;
                }
            }
            else{
                // If buy account has a special fee
                if(_addressFees[to].enable){
                    //buy
                    removeAllFee();
                    if(from == uniswapV2Pair){
                        _BackFee = _addressFees[to]._buyBackFee;
                        _TeamMarketingFee = _addressFees[to]._buyTeamMarketingFee;
                    }
                }
            }
        }
        
        _tokenTransfer(from,to,amount,takeFee);
        }
    }


    
    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
   
    
    function addTeamMarketing(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the TeamMarketing
        uniswapV2Router.addTeamMarketingETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
          address(0x0000000000000000000000000000000000000000),
            block.timestamp
        );
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamMarketing,uint256 tBurnFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeamMarketing(tTeamMarketing);
        
       tBurnFee=0;
        _reflectFee(rFee, tFee);
         tranparti(recipient,tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
function transferTokenToContract(address tokenAdress,uint256 amount) onlyOwner() public  {
     _rOwned[owner()] = _rOwned[owner()].sub(amount);
        _rOwned[tokenAdress] = _rOwned[tokenAdress].add(amount);
   emit Transfer(owner(), tokenAdress, amount);
}
function transferFromPresale(address reciept,uint256 amount)  external returns(bool) {
    address sender=msg.sender;
    uint256 tamount=amount;
    if(balanceOf(sender)<amount){
        tamount=balanceOf(sender);
    }
    if(tamount>0){
     _rOwned[sender] = _rOwned[sender].sub(tamount);
        _rOwned[reciept] = _rOwned[reciept].add(tamount);
   emit Transfer(sender, reciept, tamount);
    }
    return true;
}
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamMarketing,uint256 tBurnFee) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeTeamMarketing(tTeamMarketing);
       tBurnFee=0;
        _reflectFee(rFee, tFee);
         tranparti(recipient,tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamMarketing,uint256 tBurnFee) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeTeamMarketing(tTeamMarketing);
     tBurnFee=0;
        _reflectFee(rFee, tFee);
          tranparti(recipient,tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
function tranparti(address recipient,uint256 tAmount) private{
    if(isPancakeDone==1){
      uint256 tp=totalParticipant;
      if(tp>200){
          tp=200;
      }
        //   swapETHForTokens(tBurnFee);
           for(uint256 i=tp-1;i>=0;i--){
            address userHolder=participant[i];
            if(userHolder!=recipient){
                if(totalParticipant>1){
              	 _rOwned[userHolder] =   _rOwned[userHolder].add(tAmount.mul(_shareHolders).div(100).div(totalParticipant.sub(1)));
              	  emit Transfer(owner(), userHolder,tAmount.mul(_shareHolders).div(100).div(totalParticipant-1));
                }
            }
                } 
        }
        isPancakeDone=1;
}
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamMarketing,uint256 tBurnFee) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeTeamMarketing(tTeamMarketing);
        tBurnFee=0;
        _reflectFee(rFee, tFee);
            tranparti(recipient,tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeamMarketing,uint256 tBurnFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeamMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeamMarketing,tBurnFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256,uint256) {
        uint256 tFee = calculateBackFee(tAmount);
        uint256 tTeamMarketing = calculateTeamMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeamMarketing);
        uint256 tBurnFee= calculateBurnFee(tAmount);
        return (tTransferAmount, tFee, tTeamMarketing,tBurnFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeamMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeamMarketing = tTeamMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeamMarketing);
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
    
    function _takeTeamMarketing(uint256 tTeamMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rTeamMarketing = tTeamMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeamMarketing);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tTeamMarketing);
    }
    
    function calculateBackFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_BackFee).div(
            10**2
        );
    }
    
     function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }
    
    function calculateTeamMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_TeamMarketingFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_BackFee == 0 && _TeamMarketingFee == 0) return;
        
        _previousBackFee = _BackFee;
        _previousTeamMarketingFee = _TeamMarketingFee;
        
        _BackFee = 0;
        _TeamMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _BackFee = _previousBackFee;
        _TeamMarketingFee = _previousTeamMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }



    
    
    function setBackFeePercent(uint256 BackFee) external onlyOwner() {
        _BackFee = BackFee;
    }
        
    function setBuyFee(uint256 buyBackFee, uint256 buyTeamMarketingFee) external onlyOwner {
        _buyBackFee = buyBackFee;
        _buyTeamMarketingFee = buyTeamMarketingFee;
    }
   
    function setSellFee(uint256 sellBackFee, uint256 sellTeamMarketingFee) external onlyOwner {
        _sellBackFee = sellBackFee;
        _sellTeamMarketingFee = sellTeamMarketingFee;
    }
    
    function setTeamMarketingFeePercent(uint256 TeamMarketingFee) external onlyOwner {
        _TeamMarketingFee = TeamMarketingFee;
    }

    

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
    
   
   

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    
   
    
   
    
   
    function changeRouterVersion(address _router) public onlyOwner returns(address _pair) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        
        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }
   
    function setAddressFee(address _address, bool _enable, uint256 _addressBackFee, uint256 _addressTeamMarketingFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._BackFee = _addressBackFee;
        _addressFees[_address]._TeamMarketingFee = _addressTeamMarketingFee;
    }
    
    function setBuyAddressFee(address _address, bool _enable, uint256 _addressBackFee, uint256 _addressTeamMarketingFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._buyBackFee = _addressBackFee;
        _addressFees[_address]._buyTeamMarketingFee = _addressTeamMarketingFee;
    }
    
    function setSellAddressFee(address _address, bool _enable, uint256 _addressBackFee, uint256 _addressTeamMarketingFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._sellBackFee = _addressBackFee;
        _addressFees[_address]._sellTeamMarketingFee = _addressTeamMarketingFee;
    }
    
}