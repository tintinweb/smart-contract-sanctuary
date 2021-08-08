/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        return c;
    }
}

contract Ownable is Context
{
    address private _owner;
    address internal _creator;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _creator = msgSender;
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
}

contract Chibz is Context, IERC20, Ownable
{
  using SafeMath for uint256;

  string private _name = 'CHIBIZILLA';
  string private _symbol = 'CHIBZ';

  mapping (address => uint256) private _presaleLog;
  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcluded;
  address[] private _excluded;
  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 100 * 10**9 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;
  uint8 private _decimals = 9;
  uint8 private _inPresale;
  uint256 private _tPresold;
  uint256 public weiPrice;

  event Presale(address _buyer, uint256 _amount, uint256 _cost);

  constructor ()
  {
      _inPresale = 1;
      weiPrice = 0;
      _rOwned[_msgSender()] = _rTotal;
      emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function StartPresale() public onlyOwner
  {
      require(_inPresale == 0, "presale already started");
      _inPresale = 1;
  }

  function EndPresale() public onlyOwner
  {
      require(_inPresale != 0, "presale already ended");
      _inPresale = 0;
  }

  function SetPresalePrice(uint256 price) public onlyOwner
  {
      weiPrice = price;
  }

  function GetPresaleQuote(uint256 amount) public view returns (uint256)
  {
      return amount.mul(10**_decimals).div(weiPrice);
  }
  receive() external payable
  {
      // contract state checks
      require(_inPresale != 0, "presale ended");
      require(weiPrice > 0, "presale price not yet set");

      // transfer eth value checks
      uint256 _msgValue = msg.value;
      require(_msgValue <= (1 * 10**18), "Maximum buy limit of 1 ETH");
      require(_msgValue >= (5 * 10**16), "Minimum buy limit of 0.05 ETH");

      // token limit checks
      uint256 _tokensToBuy = GetPresaleQuote(_msgValue);
      require(_tPresold + _tokensToBuy <= _tTotal.mul(40).div(100), "Insufficient Presale pool, try to buy less");
      require(_tokensToBuy <= balanceOf(owner()), "Insufficient tokens remain, try to buy less");

      // address limit checks
      address _msgSender = msg.sender;
      uint256 _prebought = _presaleLog[_msgSender];
      require(_prebought.add(_tokensToBuy) <= _tTotal.div(100), "Tx exceed address presale quota of 1% holdings");

      // process the order
      _tPresold = _tPresold.add(_tokensToBuy);
      _transfer(owner(), _msgSender, _tokensToBuy);
      _presaleLog[_msgSender] = _prebought.add(_tokensToBuy);
      emit Presale(_msgSender, _tokensToBuy, _msgValue);
  }
  function CollectFunds() public onlyOwner
  {
      payable(owner()).transfer(address(this).balance);
  }

  function WeiPerToken() public view returns (uint256)
  {
      return weiPrice;
  }

  function name() public view returns (string memory)
  {
      return _name;
  }

  function symbol() public view returns (string memory)
  {
      return _symbol;
  }

  function decimals() public view returns (uint8)
  {
      return _decimals;
  }

  function totalSupply() public view override returns (uint256)
  {
      return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256)
  {
      if (_isExcluded[account]) return _tOwned[account];
      return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool)
  {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool)
  {
      _approve(_msgSender(), spender, amount);
      return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool)
  {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
      return true;
  }

  function isExcluded(address account) public view returns (bool)
  {
      return _isExcluded[account];
  }

  function totalFees() public view returns (uint256)
  {
      return _tFeeTotal;
  }

  function reflect(uint256 tAmount) public
  {
      address sender = _msgSender();
      require(!_isExcluded[sender], "Excluded addresses cannot call this function");
      (uint256 rAmount,,,,) = _getValues(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _rTotal = _rTotal.sub(rAmount);
      _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256)
  {
      require(tAmount <= _tTotal, "Amount must be less than supply");
      if (!deductTransferFee) {
          (uint256 rAmount,,,,) = _getValues(tAmount);
          return rAmount;
      } else {
          (,uint256 rTransferAmount,,,) = _getValues(tAmount);
          return rTransferAmount;
      }
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256)
  {
      require(rAmount <= _rTotal, "Amount must be less than total reflections");
      uint256 currentRate =  _getRate();
      return rAmount.div(currentRate);
  }

  function excludeAccount(address account) external onlyOwner()
  {
      require(!_isExcluded[account], "Account is already excluded");
      if(_rOwned[account] > 0) {
          _tOwned[account] = tokenFromReflection(_rOwned[account]);
      }
      _isExcluded[account] = true;
      _excluded.push(account);
  }

  function includeAccount(address account) external onlyOwner()
  {
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

  function _approve(address owner, address spender, uint256 amount) private
  {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");
      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  function _transfer(address sender, address recipient, uint256 amount) private
  {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");
      require(amount > 0, "Transfer amount must be greater than zero");

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
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private
  {
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
      _reflectFee(rFee, tFee);
      emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private
  {
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
      _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
      _reflectFee(rFee, tFee);
      emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private
  {
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
      _tOwned[sender] = _tOwned[sender].sub(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
      _reflectFee(rFee, tFee);
      emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private
  {
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
      _tOwned[sender] = _tOwned[sender].sub(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
      _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
      _reflectFee(rFee, tFee);
      emit Transfer(sender, recipient, tTransferAmount);
  }

  function _reflectFee(uint256 rFee, uint256 tFee) private
  {
      _rTotal = _rTotal.sub(rFee);
      _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256)
  {
      (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
      uint256 currentRate =  _getRate();
      (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
      return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
  }

  function _getTValues(uint256 tAmount) private view returns (uint256, uint256)
  {
      uint256 tFee = tAmount.div(100).mul(5);
      if (_inPresale != 0)
        tFee = 0;
      uint256 tTransferAmount = tAmount.sub(tFee);
      return (tTransferAmount, tFee);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256)
  {
      uint256 rAmount = tAmount.mul(currentRate);
      uint256 rFee = tFee.mul(currentRate);
      uint256 rTransferAmount = rAmount.sub(rFee);
      return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns(uint256)
  {
      (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
      return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns(uint256, uint256)
  {
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
}