//SourceUnit: tms.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
   
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
 
    return c;
    }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c;
  }

  
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}
    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this; 
            return msg.data;
        }
    }




contract Ownable is Context {
    address private _owner;
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
}

    interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    pragma experimental ABIEncoderV2;





contract GZAToken is Context, ITRC20, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'Godzilla';
    string private _symbol = 'GZA';
    uint8 private _decimals = 6;
    uint256 private _totalSupply = 999999 * 10**uint256(_decimals);

    address private _burnPool = address(0);
    address private _fundAddress;

    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;
    uint256 public _liquidityFee = 4;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _fundFee = 0;
    uint256 private _previousFundFee = _fundFee;
    uint256 public  MAX_STOP_FEE_TOTAL = 10000 * 10**uint256(_decimals);
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private _burnFeeTotal;
    uint256 private _liquidityFeeTotal;
    uint256 private _fundFeeTotal;

    bool private inSwapAndLiquify = false;
    bool public swapAndLiquifyEnabled = true;

    address public _exchangePool;
    uint256 public constant delay = 15 minutes;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 trxReceived,
        uint256 tokensIntoLiqudity
    );
    event InitLiquidity(
        uint256 tokensAmount,
        uint256 trxAmount,
        uint256 liqudityAmount
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address fundAddress) public {
        _fundAddress = fundAddress;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _balances[_msgSender()] = _totalSupply;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    receive () external payable {}
    

    function name() public view virtual returns (string memory) {
        return _name;
    }

  
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

   
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

  
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxStopFeeTotal(uint256 total) public onlyOwner {
        MAX_STOP_FEE_TOTAL = total;
        restoreAllFee();
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setExchangePool(address exchangePool) public onlyOwner {
        _exchangePool = exchangePool;
    }

    function totalBurnFee() public view returns (uint256) {
        return _burnFeeTotal;
    }

    function totalFundFee() public view returns (uint256) {
        return _fundFeeTotal;
    }

    function totalLiquidityFee() public view returns (uint256) {
        return _liquidityFeeTotal;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (_totalSupply <= MAX_STOP_FEE_TOTAL) {
            removeAllFee();
            _transferStandard(sender, recipient, amount);
        } else {
            if(
                _isExcludedFromFee[sender] || 
                _isExcludedFromFee[recipient] || 
                recipient == _exchangePool
            ) {
                removeAllFee();
            }
            _transferStandard(sender, recipient, amount);
            if(
                _isExcludedFromFee[sender] || 
                _isExcludedFromFee[recipient] || 
                recipient == _exchangePool
            ) {
                restoreAllFee();
            }
        }
    }


    function removeAllFee() private {
        if(_liquidityFee == 0 && _burnFee == 0 && _fundFee == 0) return;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previousFundFee = _fundFee;
        _liquidityFee = 0;
        _burnFee = 0;
        _fundFee = 0;
    }
    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
        _fundFee = _previousFundFee;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        (uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity, uint256 tFund) = _getValues(tAmount);

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        if(
            !_isExcludedFromFee[sender] && 
            !_isExcludedFromFee[recipient] &&
            recipient != _exchangePool
        ) {
            _balances[_exchangePool] = _balances[_exchangePool].add(tLiquidity);
            _liquidityFeeTotal = _liquidityFeeTotal.add(tLiquidity);

            _balances[_fundAddress] = _balances[_fundAddress].add(tFund);
            _fundFeeTotal = _fundFeeTotal.add(tFund);

            _totalSupply = _totalSupply.sub(tBurn);
            _burnFeeTotal = _burnFeeTotal.add(tBurn);

            emit Transfer(sender, _exchangePool, tLiquidity);
            // emit Transfer(sender, _fundAddress, tFund);
            emit Transfer(sender, _burnPool, tBurn);
        }
    
        emit Transfer(sender, recipient, tTransferAmount);
        
    }

    


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function calculateFundFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_fundFee).div(
            10 ** 2
        );
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity, uint256 tFund) = _getTValues(tAmount);

        return (tTransferAmount, tBurn, tLiquidity,  tFund);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256,uint256, uint256) {
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tFund = calculateFundFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tBurn).sub(tLiquidity).sub(tFund);

        return (tTransferAmount, tBurn, tLiquidity, tFund);
    }

}