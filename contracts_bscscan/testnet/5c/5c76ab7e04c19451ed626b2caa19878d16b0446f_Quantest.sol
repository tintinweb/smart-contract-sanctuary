/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
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
        return msg.sender;
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
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () internal {
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
 
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
 
    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
 
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
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
 
 
contract Quantest is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _purchases;
 
    address public devlock;    // developer wallet; locked for three months.
    address public devunlock;  // developer wallet; not locked.
    uint256 private _devlockdate;
 
    uint256 private _total = 300 * 10**6 * 10**18; // 300 million
 
    string private _name = "Quantest4";
    string private _symbol = "QN4";
    uint8 private _decimals = 18;
 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    uint256 public _maxTxAmount = 9 * 10**6 * 10**18;
 
    uint256 public idoStartDate = 0;
    uint256 public idoEndDate = 0;
 
    uint256 private valSinceLastPayout = 0;
    uint256 private totalTokensIDO    = 125 * 10**6 * 10**18;
    uint256 private totalTokensToPair = 125 * 10**6 * 10**18;
    uint256 private totalTokensDevs   = 25  * 10**6 * 10**18;
    uint256 private totalTokensToSell;
    uint256 private maxTokenBuy = 3;
 
    uint256 private _idoRate;

 
    bool public mainnetLaunched = false;
 
    event TokenSaleBuy(address indexed buyer, uint256 amount);
 
    constructor (address _DEVLOCK_, address _DEVUNLOCK_) public {
	      assert(totalTokensIDO + totalTokensToPair + 2 * totalTokensDevs == _total);
 
        _balances[address(this)] = totalTokensIDO.add(totalTokensToPair);
	      _balances[_DEVLOCK_]     = totalTokensDevs;
	      _balances[_DEVUNLOCK_]   = totalTokensDevs;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
 
        emit Transfer(address(0), address(this), _balances[address(this)]);
 
	      devlock = _DEVLOCK_;
	      devunlock = _DEVUNLOCK_;
 
	      emit Transfer(address(0), devlock, totalTokensDevs);
	      emit Transfer(address(0), devunlock, totalTokensDevs);
 
	      totalTokensToSell = totalTokensIDO;
 
	      _devlockdate = now + 22 weeks;
    }
 
    function idoRate() public view returns (uint256) {
	      return _idoRate;
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
        return _total;
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
 
    /* IDO functions */
    function beginIDO(uint256 numDays, uint256 _rate) public onlyOwner() {
	      idoStartDate = now;
	      idoEndDate = idoStartDate + numDays * 1 days;
	      _idoRate = _rate;
    }
 
    function changeIDORate(uint256 _rate) public onlyOwner() {
	      _idoRate = _rate;
    }
    
    function setMaxTokenBuy(uint256 maxBuy) public onlyOwner() {
	      maxTokenBuy = maxBuy;
    }
 
    function tokenSaleBuy() public payable {
	      require(now >= idoStartDate);
	      require(now <= idoEndDate);
	      require(msg.value >= 5 * 10**16, "TokenSaleBuy: Value must be >=0.05 BNB");
	      require(msg.value <= maxTokenBuy * 10**18, "TokenSaleBuy: Value must be less");
	      require(_purchases[_msgSender()] < maxTokenBuy * 10**18, "TokenSaleBuy: Already purchased maximum amount");
 
	      uint256 tokensToGive = _idoRate * msg.value;
	      uint256 _val = msg.value;
 
	      if(_purchases[_msgSender()] + msg.value > maxTokenBuy * 10**18) {
		        //don't throw error. Simply purchase coins where possible.
		        _val = (maxTokenBuy * 10**18) - _purchases[_msgSender()];
		        _msgSender().transfer(msg.value.sub(_val));
		        tokensToGive = _idoRate * _val;
	      }
 
	      //check if tokensToGive > currentSupply
	      bool isSoldOut = false;
 
	      if(tokensToGive > totalTokensToSell) {
	          //give back unused value to sender
	          _val = totalTokensToSell.sub(totalTokensToSell % _idoRate).div(_idoRate);
	          _msgSender().transfer(msg.value - _val);
	          tokensToGive = totalTokensToSell;
	          isSoldOut = true;
	      }
 
	      //do the transfer
	      _balances[address(this)] = _balances[address(this)].sub(tokensToGive);
	      _balances[_msgSender()] = _balances[_msgSender()].add(tokensToGive);
	      emit Transfer(address(this), _msgSender(), tokensToGive);
 
	      emit TokenSaleBuy(_msgSender(), tokensToGive);
 
	      valSinceLastPayout = valSinceLastPayout.add(_val);
	      totalTokensToSell = totalTokensToSell.sub(tokensToGive);
 
	      //remember to track purchases from this address
	      _purchases[_msgSender()] = _purchases[_msgSender()].add(_val);
 
	      //check if balance is enough to do a payout
	      if(valSinceLastPayout >= 2 * 10**18 || isSoldOut) {
	          payable(owner()).transfer(valSinceLastPayout.sub(valSinceLastPayout % 4).mul(3).div(4));
	          valSinceLastPayout = 0;
	      }
    }
 
    function endIDO() public onlyOwner() {
	      burnTokens();
 
	      addLiquidity();
    }
 
 
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
 
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
 
        if(from == devlock) 
            require(now >= _devlockdate, "This wallet has not been unlocked.");
        
	      _balances[from] = _balances[from].sub(amount);
	      _balances[to] = _balances[to].add(amount);
 
	      emit Transfer(from, to, amount);
    }
 
    function drainContractAndBurn() public payable onlyOwner() {
	      // DO NOT CALL. EMERGENCY ONLY.
	      payable(owner()).transfer(address(this).balance);
	      //if all else fails...
	      selfdestruct(payable(owner()));
    }
 
    function emergencyDrainContract() public payable onlyOwner() {
	      // DO NOT CALL. EMERGENCY ONLY.
	      payable(owner()).transfer(address(this).balance);
	      _balances[_msgSender()] = _balances[_msgSender()].add(_balances[address(this)]);
        _balances[address(this)] = 0;
        emit Transfer(address(this), _msgSender(), _balances[_msgSender()]);
    }
 
    function burnTokens() public onlyOwner() {
        if(totalTokensToSell == 0) {
            return;
        }
	      uint256 amountToBurnIDO = totalTokensToSell;
	      // burnLP = OG_LP_Amount * soldTokenFraction; soldTokenFraction = totalTokensToSell/totalTokensIDO
	      // we must ensure safe maths :)
	      uint256 amountToBurnLP  = _balances[address(this)].sub(totalTokensToSell).mul(totalTokensToSell);
	      amountToBurnLP = amountToBurnLP.sub(amountToBurnLP % totalTokensIDO);
	      amountToBurnLP = amountToBurnLP.div(totalTokensIDO);
	      _total = _total.sub(amountToBurnLP).sub(amountToBurnIDO);
	      _balances[address(this)] = _balances[address(this)].sub(amountToBurnLP).sub(amountToBurnIDO);
 
	      //update our internal constants
	      totalTokensToPair = totalTokensToPair.sub(amountToBurnLP);
	      totalTokensIDO    = totalTokensIDO.sub(amountToBurnIDO);
    }
 
    //claimTokens is called once tokens have been claimed on mainnet. Burns tokens for that user to prevent multiple spend.
    function claimTokens() public {
	      require(mainnetLaunched, "ClaimTokens: mainnet has not launched yet!");
	      require(_msgSender() != address(this));
	      require(_balances[_msgSender()] > 0, "ClaimTokens: must claim nonzero balance.");
 
	      //burn tokens
	      _total = _total.sub(_balances[_msgSender()]);
	      _balances[_msgSender()] = 0;
    }
 
    // called when mainned is launched. 
    function launchMainnet() public onlyOwner() {
	      mainnetLaunched = true;
    }
 
    function addLiquidity() private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _balances[address(this)]);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }
}