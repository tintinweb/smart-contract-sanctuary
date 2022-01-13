/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
   
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
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
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Router02  {

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
contract TokenReceiver{
    constructor (address token) public{
        IERC20(token).approve(msg.sender,1000000000000* 10**18);
    }
}

contract SworldToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "S-world";
    string private _symbol = "S-world";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 450;
    uint256 public _liquidityFee = 375;
    uint256 public _burnFee = 450;
    uint256 public _fundFee = 225;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    
    address public tokenReceiver;
    address public taxReceiver;
    address public fundReceiver;
    IERC20 public usdt;
    address public holder;
    address constant internal burnAddress = address(0);

    uint256 public _maxTxAmount = 5000000 * 10**9;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (address _factory,address _usdt,address _route,address _holder,address _fundAddress,address _taxAddress) public {

        taxReceiver = _taxAddress;
        fundReceiver = _fundAddress;
        
        usdt = IERC20(_usdt);
        holder = _holder;
        _rOwned[_holder] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_route);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_factory)
            .createPair(address(this), _usdt);

        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[_holder] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxReceiver] = true;
         _isExcludedFromFee[fundReceiver] = true;
        
        emit Transfer(address(0), _holder, _tTotal);
    }

    function initTokenReceiver()external onlyOwner{
        if( tokenReceiver == address(0)){
            tokenReceiver = address(new TokenReceiver(address(usdt)));
        }
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

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        Param memory param = _getValues(tAmount,false);
        _rOwned[sender] = _rOwned[sender].sub(param.rAmount);
        _rTotal = _rTotal.sub(param.rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            Param memory param = _getValues(tAmount,false);
            return param.rAmount;
        } else {
            Param memory param = _getValues(tAmount,false);
            return param.rTransferAmount;
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
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setFundFeePercent(uint256 fundFee) external onlyOwner() {
        _fundFee = fundFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    struct Param{
        uint rAmount;
        uint rTransferAmount;
        uint tTransferAmount;
        uint tFee;
        uint tLiquidity;
        uint tBurn;
        uint tFund;
    }

    function _getValues(uint256 tAmount,bool takeFee) private view returns (Param memory param ) {
        uint256 tFee = 0;
        uint256 tLiquidity = 0; 
        uint256 tBurn = 0;
        uint256 tFund = 0; 

        if( takeFee ){
            tFee = tAmount * _taxFee / 10000; 
            tLiquidity = tAmount * _liquidityFee / 10000; 
            tBurn = tAmount * _burnFee / 10000; 
            tFund = tAmount * _fundFee / 10000;
        }
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn).sub(tFund);

        uint currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rFee = 0;
        uint256 rLiquidity = 0;
        uint256 rBurn = 0;
        uint256 rFund = 0;

        if( takeFee ){
            rFee = tFee.mul(currentRate);
            rLiquidity = tLiquidity.mul(currentRate);
            rBurn = tBurn.mul(currentRate);
            rFund = tFund.mul(currentRate);
        }
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn).sub(rFund);

        param = Param(
            rAmount,rTransferAmount,tTransferAmount,tFee,tLiquidity,tBurn,tFund
        );
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
    
    function _take(address sender,uint256 tLiquidity,uint256 tBurn,uint256 tFund,uint tTax) private {
        uint256 currentRate =  _getRate();
        
        if( tLiquidity > 0 ){
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)]){
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            }
            emit Transfer(sender, address(this), tLiquidity);
        }
        
        if( tBurn > 0 ){
            uint256 rBurn = tBurn.mul(currentRate);
            _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
            if(_isExcluded[burnAddress]){
                _tOwned[burnAddress] = _tOwned[burnAddress].add(tBurn);
            }
            emit Transfer(sender, burnAddress, tBurn);
        }
        
        if( tFund > 0){
            uint256 rFund = tFund.mul(currentRate);
            _rOwned[fundReceiver] = _rOwned[fundReceiver].add(rFund);
            if(_isExcluded[fundReceiver]){
                _tOwned[fundReceiver] = _tOwned[fundReceiver].add(tFund);
            }
            emit Transfer(sender, fundReceiver, tFund);
        }
        
        if( tTax > 0){
            uint256 rTax = tTax.mul(currentRate);
            _rOwned[taxReceiver] = _rOwned[taxReceiver].add(rTax);
            if(_isExcluded[taxReceiver]){
                _tOwned[taxReceiver] = _tOwned[taxReceiver].add(tTax);
            }
            emit Transfer(sender, taxReceiver, tTax);  
        }
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
       
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount){
            contractTokenBalance = _maxTxAmount;

             if (!inSwapAndLiquify && from != uniswapV2Pair) {

                swapAndLiquify(contractTokenBalance);
            }
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = usdt.balanceOf(tokenReceiver);// address(this).balance;

        swapTokensForEth(half); 

        uint256 newBalance = usdt.balanceOf(tokenReceiver).sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            tokenReceiver,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
       
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        usdt.transferFrom(tokenReceiver,address(this),ethAmount);

        usdt.approve(address(uniswapV2Router),ethAmount);

        uniswapV2Router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            ethAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            holder,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount,takeFee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount,takeFee);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount,takeFee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount,takeFee);
        } else {
            _transferStandard(sender, recipient, amount,takeFee);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        Param memory param = _getValues(tAmount,takeFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(param.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(param.rTransferAmount); 

        _take(sender,param.tLiquidity,param.tBurn,param.tFund,param.tFee);    
        //_reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, param.tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        Param memory param = _getValues(tAmount,takeFee);
        _rOwned[sender] = _rOwned[sender].sub(param.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(param.rTransferAmount);
        _take(sender,param.tLiquidity,param.tBurn,param.tFund,param.tFee); 
        emit Transfer(sender, recipient, param.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        Param memory param = _getValues(tAmount,takeFee);
        _rOwned[sender] = _rOwned[sender].sub(param.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(param.rTransferAmount);           
        _take(sender,param.tLiquidity,param.tBurn,param.tFund,param.tFee); 
        emit Transfer(sender, recipient, param.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        Param memory param = _getValues(tAmount,takeFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(param.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(param.rTransferAmount);   
        _take(sender,param.tLiquidity,param.tBurn,param.tFund,param.tFee); 
        emit Transfer(sender, recipient, param.tTransferAmount);
    }

    
    function donateDust(address addr, uint256 amount) external onlyOwner {
        require(addr != address(this), "not allow");
        TransferHelper.safeTransfer(addr, _msgSender(), amount);
    }

    
    function donateEthDust(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), amount);
    }
}