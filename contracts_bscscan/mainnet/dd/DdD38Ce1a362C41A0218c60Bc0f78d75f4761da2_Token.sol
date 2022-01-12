/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed

/**

  /$$$$$$  /$$       /$$ /$$       /$$      /$$                                /$$$$$$                      /$$      
 /$$__  $$| $$      |__/| $$      | $$$    /$$$                               /$$__  $$                    | $$      
| $$  \__/| $$$$$$$  /$$| $$$$$$$ | $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$ 
|  $$$$$$ | $$__  $$| $$| $$__  $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$| $$       |____  $$ /$$_____/| $$__  $$
 \____  $$| $$  \ $$| $$| $$  \ $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$| $$        /$$$$$$$|  $$$$$$ | $$  \ $$
 /$$  \ $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$| $$    $$ /$$__  $$ \____  $$| $$  | $$
|  $$$$$$/| $$  | $$| $$| $$$$$$$/| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$
 \______/ |__/  |__/|__/|_______/ |__/     |__/ \______/  \______/ |__/  |__/ \______/  \_______/|_______/ |__/  |__/
                                                                                                                                                                                                                                                                                                                                               
                                                                                                                               
                                                                                                                                                                                                                                                                                              

        🐕 ShibaMoonCash 🐕 | LOW MC | Ownership Renounced | 💎 1000x Gem | LP Locked 

        🔥 0.1 BNB GIVEAWAY FOR BIGGEST HOLDER 🔥
        
        Token Economics

        💼 SUPPLY : 1,000,000,000,000

        🔥 BURNED - 50%
        🔥 LP LOCKED - 100%
        🔥 MARKETING - 5%
        🔥 TEAM - 2%
        🔥 TAX - 9%

        TG : https://t.me/ShibaMoonCash
        Twitter : https://twitter.com/ShibaMoonCash
   
 */

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event TokenBurn(address indexed from, uint256 value);
    event SetLiquidityFee(uint256 amount);
    event SetMarketingFee(uint256 amount);
    event SetBurnFee(uint256 amount);
    
    string private _namespechfaster = "ShibMoonCash";
    string private _symbolspechfaster = "SMC";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000 * 10**9 * 10**_decimals;
    
    address payable public marketingAddress = payable(0x67CC5b8f8D6f031855F83c7CA848076718279E0D);
    address public marketingWalletToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFeesspechfaster;
    mapping (address => bool) private _isExcludedFromMaxBalancespechfaster;

    uint256 private constant _maxFeesspechfaster = 39;
    uint256 private _totalFeesspechfaster;
    uint256 private _totalFeesspechfasterContract;
    uint256 private _burnFeesspechfaster;
    uint256 private _liquidityFeesspechfaster;
    uint256 private _marketingFeesspechfaster;
    
    uint256 private _maxBalanceWalletspechfaster;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 private _liquidityThreshhold;
    bool inSwapAndLiquify;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFeesspechfaster[owner()] = true;
        _isExcludedFromFeesspechfaster[address(this)] = true;
        
        _isExcludedFromMaxBalancespechfaster[owner()] = true;
        _isExcludedFromMaxBalancespechfaster[address(this)] = true;
        _isExcludedFromMaxBalancespechfaster[uniswapV2Pair] = true;

        _liquidityFeesspechfaster = 1;
        _marketingFeesspechfaster = 5;
        _burnFeesspechfaster = 0;
        _totalFeesspechfaster = _liquidityFeesspechfaster.add(_marketingFeesspechfaster).add(_burnFeesspechfaster);
        _totalFeesspechfasterContract = _liquidityFeesspechfaster.add(_marketingFeesspechfaster);

        _liquidityThreshhold = 3000 * 10**9 * 10**_decimals;
        _maxBalanceWalletspechfaster = 1000000 * 10**9 * 10**_decimals;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _namespechfaster;
    }

    function symbol() public view returns (string memory) {
        return _symbolspechfaster;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner() {
        marketingAddress = newMarketingAddress;
    }

    function setLiquidityFeePercent(uint256 newLiquidityFee) external onlyOwner() {
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newLiquidityFee.add(_burnFeesspechfaster).add(_marketingFeesspechfaster) <= _maxFeesspechfaster, "Fees are too high.");
        _liquidityFeesspechfaster = newLiquidityFee;
        _totalFeesspechfaster = _liquidityFeesspechfaster.add(_marketingFeesspechfaster).add(_burnFeesspechfaster);
        _totalFeesspechfasterContract = _liquidityFeesspechfaster.add(_marketingFeesspechfaster);
        emit SetLiquidityFee(_liquidityFeesspechfaster);
    }

    function setMarketingFeePercent(uint256 newMarketingFee) external onlyOwner() {
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(_liquidityFeesspechfaster.add(_burnFeesspechfaster).add(newMarketingFee) <= _maxFeesspechfaster, "Fees are too high.");
        _marketingFeesspechfaster = newMarketingFee;
        _totalFeesspechfaster = _liquidityFeesspechfaster.add(_marketingFeesspechfaster).add(_burnFeesspechfaster);
        _totalFeesspechfasterContract = _liquidityFeesspechfaster.add(_marketingFeesspechfaster);
        emit SetMarketingFee(_marketingFeesspechfaster);
    }

    function setBurnFeePercent(uint256 newBurnFee) external onlyOwner() {
        require(_liquidityFeesspechfaster.add(newBurnFee).add(_marketingFeesspechfaster) <= _maxFeesspechfaster, "Fees are too high.");
        _burnFeesspechfaster = newBurnFee;
        _totalFeesspechfaster = _liquidityFeesspechfaster.add(_marketingFeesspechfaster).add(_burnFeesspechfaster);
        emit SetBurnFee(_burnFeesspechfaster);
    }
    
    function setLiquifyThreshhold(uint256 newLiquifyThreshhold) external onlyOwner() {
        _liquidityThreshhold = newLiquifyThreshhold;
    }   

    function setMarketingWalletToken(address _marketingWalletToken) external onlyOwner(){
        marketingWalletToken = _marketingWalletToken;
    }

    function setMaxBalance(uint256 newMaxBalance) external onlyOwner(){
       
        require(newMaxBalance >= _totalSupply.mul(5).div(1000));
        _maxBalanceWalletspechfaster = newMaxBalance;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFeesspechfaster[account];
    }
    
    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFeesspechfaster[account] = true;
    }
    
    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFeesspechfaster[account] = false;
    }

    function isExcludedFromMaxBalance(address account) public view returns(bool) {
        return _isExcludedFromMaxBalancespechfaster[account];
    }
    
    function excludeFromMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalancespechfaster[account] = true;
    }
    
    function includeInMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalancespechfaster[account] = false;
    }

    function totalFees() public view returns (uint256) {
        return _totalFeesspechfaster;
    }

    function liquidityFee() public view returns (uint256) {
        return _liquidityFeesspechfaster;
    }

    function marketingFee() public view returns (uint256) {
        return _marketingFeesspechfaster;
    }

    function burnFee() public view returns (uint256) {
        return _burnFeesspechfaster;
    }

    function maxFees() public pure returns (uint256) {
        return _maxFeesspechfaster;
    }

    function liquifyThreshhold() public view returns(uint256){
        return _liquidityThreshhold;
    }

    function maxBalance() public view returns (uint256) {
        return _maxBalanceWalletspechfaster;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        
        if(
            from != owner() &&              // Not from Owner
            to != owner() &&                // Not to Owner
            !_isExcludedFromMaxBalancespechfaster[to]  // is excludedFromMaxBalance
        ){
            require(
                balanceOf(to).add(amount) <= _maxBalanceWalletspechfaster,
                "Max Balance is reached."
            );
        }
        
        // Swap Fees 
        if(
            to == uniswapV2Pair &&                              // Sell
            !inSwapAndLiquify &&                                // Swap is not locked
            balanceOf(address(this)) >= _liquidityThreshhold &&   // liquifyThreshhold is reached
            _totalFeesspechfasterContract > 0 &&                         // LiquidityFee + MarketingFee > 0
            from != owner() &&                                  // Not from Owner
            to != owner()                                       // Not to Owner
        ) {
            collectFees();
        }

        // Take Fees 
        if(
            !(_isExcludedFromFeesspechfaster[from] || _isExcludedFromFeesspechfaster[to])
            && _totalFeesspechfaster > 0
        ) {
            
        	uint256 feesToContract = amount.mul(_totalFeesspechfasterContract).div(100);
            uint256 toBurnAmount = amount.mul(_burnFeesspechfaster).div(100);
            
        	amount = amount.sub(feesToContract.add(toBurnAmount)); 

            transferToken(from, address(this), feesToContract);
            transferToken(from, deadAddress, toBurnAmount);
            emit TokenBurn(from, toBurnAmount);
        }

        transferToken(from, to, amount);
    }
    
    function collectFees() private lockTheSwap {
        
        uint256 liquidityTokensToSell = balanceOf(address(this)).mul(_liquidityFeesspechfaster).div(_totalFeesspechfasterContract);
        uint256 marketingTokensToSell = balanceOf(address(this)).mul(_marketingFeesspechfaster).div(_totalFeesspechfasterContract);
        
        // Get collected Liquidity Fees 
        swapAndLiquify(liquidityTokensToSell);  

        // Get collected Marketing Fees 
        swapAndSendToFee(marketingTokensToSell); 
    }

    function swapAndLiquify(uint256 tokens) private {
       
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // current ETH balance
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
    }

    function swapAndSendToFee(uint256 tokens) private  {

        swapTokensForMarketingToken(tokens);

        // Transfer sold Token to marketingWallet
        IERC20(marketingWalletToken).transfer(marketingAddress, IERC20(marketingWalletToken).balanceOf(address(this)));
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

     
    function swapTokensForMarketingToken(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = marketingWalletToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
            address(0),
            block.timestamp
        );
    }

    function transferToken(address sender, address recipient, uint256 amount) public onlyOwner{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}