/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

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
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
         _owner = 0x8eDb6116Ab81FC57696993B109CBf1679BDeD410;
        // _owner = 0x03AA1cf0097041Df7Ee901518697bEDde21CCaB5;
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
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

interface IpancakePair {
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

interface IpancakeRouter01 {
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

interface IPancakeV2Router02 is IpancakeRouter01 {
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


contract KwikBuck is Context, IBEP20, Ownable , ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public userreward;
    mapping(address => bool) private _isSniper;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    address[] private _confirmedSnipers;
    uint256 public _launchTime; // can be set only once
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 50000000000 *1e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "KwikBuck";
    string private _symbol = "Bucks";
    uint8 private _decimals = 9;
    
    uint256 public _holderFee = 20;
    uint256 private _previousTaxFee = _holderFee;
    
    uint256 public _liquidityFee = 40;
    uint256 private _previousLiquidityFee = _liquidityFee;
	
	uint256 public _devFee = 15; 
	uint256 private _previousdevFee = _devFee;
	
	uint256 public _charityFee = 5; 
	uint256 private _previouscharityFee = _charityFee;
	
	uint256 public _rewardFee = 20; 
	uint256 private _previousrewardFee = _rewardFee;	
		
	address payable public devWallet;
	address payable public charityWallet;


    IPancakeV2Router02 public immutable pancakeRouter;
    address public immutable  pancakePair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public _tradingOpen = false;
    
    uint256 public _numTokensSellToAddToLiquidity = 100000*1e9;
    
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
    
    constructor ()  {
        _rOwned[owner()] = _rTotal; 

        IPancakeV2Router02 _pancakeRouter = IPancakeV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
         // Create a uniswap pair for this new token
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        
        
        //exclude owner and other wallets from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        charityWallet = payable(0xb496453eb7089eC8b6E1FF8B1052E216C80bf50d);
        devWallet = payable(0xfdce9bB38d69c9d56b947BeDB4F7C6d3bA499836);


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
            uint256 rTransferAmount = rAmount.sub(takeTransferFee(tAmount).mul(_getRate()));
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal);
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account]);
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setHolderPercent(uint256 percentage) external onlyOwner() {
        _holderFee = percentage;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setdevFeePercent(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
    }
    
    function setCharityFeePercent(uint256 charityFee) external onlyOwner() {
        _charityFee = charityFee;
    }
    
    
    function setrewardFeePercent(uint256 rewardFee) external onlyOwner() {
        _rewardFee = rewardFee;
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 minAmountForLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = minAmountForLiquidity;
    }

    function setdevWallet(address payable _devWallet) public onlyOwner{
        devWallet = _devWallet;
    }

    function setCharityWallet(address payable _charityWallet) public onlyOwner{
        charityWallet = _charityWallet;
    }


    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    
     //to recieve ETH from pancakeRouter when swaping
    receive() external payable {}

    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_holderFee).div(100);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    
    function _takeLiquidity(uint256 tAmount) private {
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(100);
        uint256 rLiquidity = tLiquidity.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(_msgSender(), address(this), tLiquidity);
    }
    
    function _takeDevFee(uint256 tAmount) private {
        uint256 tDevFee = tAmount.mul(_devFee).div(100);
		uint256 rDevFee = tDevFee.mul(_getRate());
		_rOwned[devWallet] = _rOwned[devWallet].add(rDevFee);
        if(_isExcluded[devWallet])
            _tOwned[devWallet] = _tOwned[devWallet].add(tDevFee);
        emit Transfer(_msgSender(), devWallet, tDevFee);
    }
    
    
    function _takeCharityFee(uint256 tAmount) private {
        uint256 tCharityFee = tAmount.mul(_charityFee).div(100);
		uint256 rCharityFee = tCharityFee.mul(_getRate());
		_rOwned[charityWallet] = _rOwned[charityWallet].add(rCharityFee);
        if(_isExcluded[charityWallet])
            _tOwned[charityWallet] = _tOwned[charityWallet].add(tCharityFee);
        emit Transfer(_msgSender(), charityWallet, tCharityFee);
    }
    
    function _takeReward(uint256 tAmount, address _to)private {
        uint256 tReward = tAmount.mul(_rewardFee).div(100);
		uint256 rReward = tReward.mul(_getRate());
		_rOwned[address(this)] = _rOwned[address(this)].add(rReward);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tReward);
        emit Transfer(_msgSender(), address(this), tReward);
        if (
            !inSwapAndLiquify &&
            _msgSender() != pancakePair &&
            _to != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(tReward > contractTokenBalance){
                tReward = contractTokenBalance;
            }
            //add liquidity
            swapreward(tReward);
            
        }
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
    function startTrading() external onlyOwner {
        _tradingOpen = true;
        _launchTime = block.timestamp;
        // approve contract
        _approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
        swapAndLiquifyEnabled = true;
    }

    function migrateToken(address _newadress , uint256 _amount) public onlyOwner {
        removeAllFee();
        _transferStandard(address(this), _newadress, _amount, 0);
        restoreAllFee();
    }

    function migrateBnb(address payable _newadd,uint256 amount) public onlyOwner {
        _newadd.transfer(amount);
    }
 
    function removeAllFee() private {
        _previousTaxFee = _holderFee;
        _previousLiquidityFee = _liquidityFee;
        _previousdevFee = _devFee;
        _previousrewardFee=_rewardFee;
        _previouscharityFee=_charityFee;
        _holderFee = 0;
        _liquidityFee = 0;
        _charityFee=0;
        _devFee = 0;
        _rewardFee=0;
    }

    function restoreAllFee() private {
        _holderFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee=_previouscharityFee;
        _devFee = _previousdevFee;
        _rewardFee = _previousrewardFee;
        
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        require(!_isSniper[to], "Beep Beep Boop, You're a piece of poop");
        require(!_isSniper[from], "Beep Beep Boop, You're a piece of poop");
            

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 fee=0;
        if((!_isExcludedFromFee[from] || !_isExcludedFromFee[to])&& from != pancakePair){
                fee = takeTransferFee(amount);
                if(to == pancakePair){
                    fee = takeSellFee(amount);
                }
        
            if (!_tradingOpen ){
                    require(to != pancakePair, "Trading is not enabled");
            }
        

            if (block.timestamp < _launchTime + 120 seconds) {
                if ((from == pancakePair || to == pancakePair)
                && from != address(pancakeRouter)) {
                    _isSniper[from] = true;
                    _confirmedSnipers.push(from);
                }
            }
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
    
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            
            //add liquidity
            swapAndLiquify(contractTokenBalance);
            
        }
        
        
        
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee,fee);
         
    }
    
    function swapreward(uint256 tokens) private lockTheSwap {
        
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(tokens); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        payable(_msgSender()).transfer(newBalance);

        userreward[_msgSender()] = userreward[_msgSender()].add(newBalance);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();        

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee,uint256 fee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount,fee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount,fee);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount,fee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount,fee);
        } else {
            _transferStandard(sender, recipient, amount,fee);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,uint256 fee) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rfeeofsender = fee.mul(currentRate);
        uint256 rTransferAmount = rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount).sub(rfeeofsender);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(fee);
        _takeDevFee(fee);
        _takeCharityFee(fee);
        _reflectFee(fee);
        _takeReward(fee, recipient);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount,uint256 fee) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rfeeofsender = fee.mul(currentRate);
        uint256 rTransferAmount = rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount).sub(rfeeofsender);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(fee);
        _takeDevFee(fee);
        _takeCharityFee(fee);
        _takeReward(fee, recipient);
        _reflectFee(fee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount,uint256 fee) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rfeeofsender = fee.mul(currentRate);
        uint256 rTransferAmount = rAmount;
        _tOwned[sender] = _tOwned[sender].sub(tAmount).sub(rfeeofsender);
        _rOwned[sender] = _rOwned[sender].sub(rAmount).sub(rfeeofsender);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(fee);
        _takeDevFee(fee);
        _takeCharityFee(fee);
        _takeReward(fee, recipient);
        _reflectFee(fee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount,uint256 fee) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rfeeofsender = fee.mul(currentRate);
        uint256 rTransferAmount = rAmount;
        _tOwned[sender] = _tOwned[sender].sub(tAmount).sub(rfeeofsender);
        _rOwned[sender] = _rOwned[sender].sub(rAmount).sub(rfeeofsender);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(fee);
        _takeDevFee(fee);
        _takeCharityFee(fee);
        _takeReward(fee, recipient);
        _reflectFee(fee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    
    function takeSellFee(uint256 amount)public pure returns(uint256){
        
        
        if(amount<10e9){
            return(amount.mul(25).div(1000));
        }else if(amount>=10e9 && amount<100e9){
            return(amount.mul(10).div(100));
        }
        else if(amount>=100e9 && amount < 500e9){
            return(amount.mul(9).div(100));
        }
        else if(amount>=500e9 && amount < 1000e9){
            return(amount.mul(8).div(100));
        }
        else if(amount>=1000e9 && amount < 5000e9){
            return(amount.mul(7).div(100));
        }
        else if(amount>=5000e9 && amount < 10000e9){
            return(amount.mul(6).div(100));
        }
        else if(amount>=10000e9 && amount < 100000e9){
            return(amount.mul(5).div(100));
        }
        else if(amount>=100000e9 && amount < 500000e9){
            return(amount.mul(15).div(100));
        }
        else if(amount>=500000e9 && amount < 1000000e9){
            return(amount.mul(20).div(100));
        }
        else if(amount>=1000000e9 && amount < 2500000e9){
            return(amount.mul(25).div(100));
        }
        else if(amount>=2500000e9 && amount < 5000000e9){
            return(amount.mul(30).div(100));
        }
        else if(amount>=5000000e9 && amount < 10000000e9){
            return(amount.mul(35).div(100));
        }
        else{
            return(amount.mul(45).div(100));
        }
        
    }
    function takeTransferFee(uint256 amount)public pure returns(uint256 val){
        
        if(amount<10e9){
            return(amount.mul(25).div(1000));
        }else if(amount>=10e9 && amount<100e9){
            return(amount.mul(10).div(100));
        }
        else if(amount>=100e9 && amount < 500e9){
            return(amount.mul(9).div(100));
        }
        else if(amount>=500e9 && amount < 1000e9){
            return(amount.mul(8).div(100));
        }
        else if(amount>=1000e9 && amount < 5000e9){
            return(amount.mul(7).div(100));
        }
        else if(amount>=5000e9 && amount < 10000e9){
            return(amount.mul(6).div(100));
        }
        else if(amount>=10000e9 ){
            return(amount.mul(5).div(100));
        }
    }
}