/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// File: contracts/TK1.sol

pragma solidity ^0.6.12;


interface IERC20 {







    
    function balanceOf(address account) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function totalSupply() external view returns (uint256);




    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);

}

library SafeMath {

   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b <= a, errorMessage);

        uint256 c = a - b;



        return c;

    }
    



  

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return sub(a, b, "SafeMath: subtraction overflow");

    }



   function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");



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





  



  

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");

    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }
  

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        return mod(a, b, "SafeMath: modulo by zero");

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

     function functionCall(address target, bytes memory data) internal returns (bytes memory) {

      return functionCall(target, data, "Address: low-level call failed");

    }

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



    



   

   




    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }



  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {

        require(address(this).balance >= value, "Address: insufficient balance for call");

        return _functionCallWithValue(target, data, value, errorMessage);

    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {

        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }



   
function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");

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


function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }
   

    function renounceOwnership() public virtual onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    

    







   

}

interface IUniswapV2Factory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    

    function feeToSetter() external view returns (address);


    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

  function feeTo() external view returns (address);



    function createPair(address tokenA, address tokenB) external returns (address pair);

  function allPairsLength() external view returns (uint);


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

contract TK1 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Test Token 1";
    string private _symbol = "TK1";
    uint8 private _decimals = 9;
	uint256 private supply = 1000000000000;
    uint256 private constant MAX = ~uint256(0);
	
	bool test = true; //true for Testnet

	uint256 public _rewardFee = 80;
    uint256 public _burnFee = 0;
    uint256 public _charityAndMarketingFee = 20;
	uint256 public _lpFee = 60;

    address public walletMarketing = 0x88434294d84B82C66dEE6e81685D8Df996b2d2c4; //need to update ***

    mapping (address => bool) private _isExcluded;
	mapping (address => bool) private _isExcludedFromFee;
    address[] private _excluded;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint256 private _previousRewardFee = _rewardFee;
    uint256 private _previousBurnFee = _burnFee;  
    uint256 public _previousCharityAndMarketingFee = _charityAndMarketingFee;
    uint256 private _previousLPFee = _lpFee;
    uint256 private _tDistributedRewardTotal;
	uint256 private _tTotal = supply * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private numTokenSwapThreshold = supply / 100 * 10**9;  

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address deadAddress = DEAD;

    bool inSwap;
    bool public swapEnabled = true;
    uint256 public launchTime;
    uint256 public launchBlock;
    bool public antiWhaleEnable = true;
	//address Router;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
		address Router;
		if(test){
			Router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //Testnet
		} else {
			Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //Mainnet	
		}
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(Router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

	function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

	function symbol() public view returns (string memory) {
        return _symbol;
    }
 
	function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

	function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

	function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
	
	function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
	
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function totalRewardDistributed() public view returns (uint256) {
        return _tDistributedRewardTotal;
    }

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
	
	function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
	
	function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function setFeePercent(uint256 taxFee, uint256 burnFee, uint256 charityAndMarketingFee, uint256 lpFee) external onlyOwner() {
        _rewardFee = taxFee;
        _burnFee = burnFee;
        _charityAndMarketingFee = charityAndMarketingFee;
		_lpFee = lpFee;
    }

    receive() external payable {}

    function _reflectReward(uint256 rReward, uint256 tReward) private {
        _rTotal = _rTotal.sub(rReward);
        _tDistributedRewardTotal = _tDistributedRewardTotal.add(tReward);
    }
	
	function _burn(uint256 amount) internal {
        if(amount > 0)
        {
            _tTotal = _tTotal.sub(amount);
            _rTotal = _rTotal.sub(amount.mul(_getRate()));
            emit Transfer(msg.sender, address(this), amount);
        }
    }
    
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {

        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate =  _getRate();

        return rAmount.div(currentRate);

    }


	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        

        _takeBurnCharityAndMarketingFee(tBurnCharityAndMarketingFee, sender);

        _reflectReward(rReward, tReward);

        emit Transfer(sender, recipient, tTransferAmount);

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

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeBurnCharityAndMarketingFee(tBurnCharityAndMarketingFee, sender);

        _reflectReward(rReward, tReward);

        emit Transfer(sender, recipient, tTransferAmount);

    }
	
	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {

        uint256 tReward = calculateRewardFee(tAmount);

        uint256 tBurnCharityAndMarketingFee = calculateBurnCharityAndMarketingFee(tAmount);

        uint256 tTransferAmount = tAmount.sub(tReward).sub(tBurnCharityAndMarketingFee);

        return (tTransferAmount, tReward, tBurnCharityAndMarketingFee);

    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {

        (uint256 tTransferAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee) = _getTValues(tAmount);

        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward) = _getRValues(tAmount, tReward, tBurnCharityAndMarketingFee, _getRate());

        return (rAmount, rTransferAmount, rReward, tTransferAmount, tReward, tBurnCharityAndMarketingFee);

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

    function _getRValues(uint256 tAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {

        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rReward = tReward.mul(currentRate);

        uint256 rBurnCharityAndMarketingFee = tBurnCharityAndMarketingFee.mul(currentRate);

        uint256 rTransferAmount = rAmount.sub(rReward).sub(rBurnCharityAndMarketingFee);

        return (rAmount, rTransferAmount, rReward);

    }

     
	function _takeBurnCharityAndMarketingFee(uint256 tBurnCharityAndMarketingFee, address sender) private {

        if(_burnFee + _charityAndMarketingFee > 0){
            uint256 currentRate =  _getRate();
            uint256 tBurn =  tBurnCharityAndMarketingFee.mul(_burnFee).div(_burnFee + _charityAndMarketingFee);
            uint256 tCharityAndMarketingFee = tBurnCharityAndMarketingFee.sub(tBurn);
            _burn(tBurn);

            // Keep Charity & Marketing in contract

            uint256 rCharityAndMarketingFee = tCharityAndMarketingFee.mul(currentRate);

            _rOwned[address(this)] = _rOwned[address(this)].add(rCharityAndMarketingFee);

            if(_isExcluded[address(this)])

                _tOwned[address(this)] = _tOwned[address(this)].add(tCharityAndMarketingFee);

            emit Transfer(sender, address(this), tCharityAndMarketingFee);

        }

    }

	function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10**3);
    }
	
    function calculateBurnCharityAndMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee + _charityAndMarketingFee + _lpFee).div(10**3);
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _burnFee = _previousBurnFee;
        _charityAndMarketingFee = _previousCharityAndMarketingFee;
		_lpFee = _previousLPFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function removeAllFee() private {
        if(_rewardFee == 0 && _burnFee == 0 && _charityAndMarketingFee == 0 && _lpFee == 0) return;
        _previousRewardFee = _rewardFee;
        _previousBurnFee = _burnFee;
        _previousCharityAndMarketingFee = _charityAndMarketingFee;
		_previousLPFee = _lpFee;
        _rewardFee = 0;
        _burnFee = 0;
        _charityAndMarketingFee = 0;
		_lpFee = 0;
    }

    function _transfer(

        address from,

        address to,

        uint256 amount

    ) private {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");





        if(launchTime == 0 && to == uniswapV2Pair){

            launchTime = block.timestamp;

            launchBlock = block.number;

        }else{

            if(block.number >= launchBlock && block.number < launchBlock + 2){

                require(false, "Sniffer defending");

            }



            if(antiWhaleEnable && block.timestamp > launchTime && block.timestamp < launchTime + 0){

                uint256 nTokenInPair = balanceOf(uniswapV2Pair);

                uint256 nBNBInPair = IERC20(uniswapV2Router.WETH()).balanceOf(uniswapV2Pair);

                uint256 nTokenPerBNB = nTokenInPair.div(nBNBInPair).mul(10**9);

                require(amount <= nTokenPerBNB/2, "In 30 min after launching, only number of token worth 0.5 BNB is allowed");

            }

        }

        uint256 contractTokenBalance = balanceOf(address(this));



        bool overMinTokenBalance = contractTokenBalance >= numTokenSwapThreshold;

        if (

            overMinTokenBalance &&

            !inSwap &&

            from != uniswapV2Pair &&

            swapEnabled

       ) {

            //add liquidity

            swapAndSendOutFee(contractTokenBalance);

        }

        

        //indicates if fee should be deducted from transfer

        bool takeFee = true;

        

        //if any account belongs to _isExcludedFromFee account then remove the fee

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){

            takeFee = false;

        }

        

        //transfer amount, it will take tax, burn, liquidity fee

        _tokenTransfer(from, to, amount, takeFee);

    }



	function enableAntiWhale(bool enabled) public onlyOwner() {
        antiWhaleEnable = enabled;
    }
	
    function updateMarketingWallet(address account) public onlyOwner() {
        walletMarketing = account;
    }

	function swapAndSendOutFee(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 bnbBalance = address(this).balance;
        payable(walletMarketing).transfer(bnbBalance);
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

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeBurnCharityAndMarketingFee(tBurnCharityAndMarketingFee, sender);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tBurnCharityAndMarketingFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeBurnCharityAndMarketingFee(tBurnCharityAndMarketingFee, sender);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}