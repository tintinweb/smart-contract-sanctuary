pragma solidity 0.8.0;

import './Ownable.sol';

contract tokenRedistribution is Ownable {

  /*
    * Private variables required to track reflection balance, fees,
    * and standard balances:
    * _reflectPct is the percentage of transaction amount to be redistributed
    * to token holders.
    * _scaledBalance holds token balance for addresses included in fee
    * redistribution (balances are scaled up by reflection coefficient).
    * _neutralBalance holds token balance for addresses excluded from fee
    * redistribution.
    * _isExcluded will track address excluded from fee redistribution.
    * _excluded array allows us to iterate over _isExcluded accounts.
    * MAX constant is maximum value allowed for unint256 (to be used for
    * initial reflection coefficient calculation).
    * _neutralSupply is total token supply without scaling.
    * _scaledSupply is total token supply scaled.
   */



  mapping (address => uint256) private _scaledBalance;
  mapping (address => uint256) private _neutralBalance;
  mapping (address => bool) public _isExcluded;
  address[] public _excluded;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _neutralSupply;
  uint256 private _scaledSupply;
  string private _name;
  string private _symbol;
  uint8 private _reflectPct = 0;
  uint8 private _decimals = 9;
  uint256 private _neutralFeeTotal;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
    * @notice Constructor function sets name and symbol for token and mints
    * total token supply to msg.sender. Note that _scaledSupply is not the
    * actual amount minted since this balance is de-scaled back to _neutralSupply
    * whenever balanceOf()function is called.
   **/

  constructor(string memory name_, string memory symbol_, uint256 supply_) {
      _name = name_;
      _symbol = symbol_;
      _neutralSupply = supply_ * 10**9;
      _scaledSupply = (MAX - (MAX % _neutralSupply));
      _neutralBalance[msg.sender] = _neutralSupply;
      _scaledBalance[msg.sender] = _scaledSupply;
      emit Transfer(address(0), msg.sender, _neutralSupply);
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

  function totalSupply() public view returns (uint256) {
      return _neutralSupply;
  }

   function neutralFeeTotal() public view returns (uint256) {
      return _neutralFeeTotal;
  }

  /**
    * Functions includeAccount and excludeAccount are required to manage
    * which addresses are entitled to receive fee redistribution. For example,
    * contracts where token liquidity pools are kept should be excluded from
    * receiving redistributions. Likewise, centralized exchange accounts are
    * another set of accounts which should be excluded.
   **/

  function includeAccount(address account) external onlyOwner {
    require(_isExcluded[account], "Account already included");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _excluded.pop();
        _isExcluded[account] = false;
        _scaledBalance[account] = _neutralBalance[account] * _getRate();
        break;
      }
    }
  }

  function excludeAccount(address account) external onlyOwner {
    require(!_isExcluded[account], "Account already excluded");
    require(balanceOf(account) < _neutralSupply, "Cannot exclude total supply");
     _neutralBalance[account] = balanceOf(account);
     _excluded.push(account);
    _isExcluded[account] = true;
  }

  function setFee(uint8 feePct) external onlyOwner {
    require(feePct < 100, "Redistribution fee must be less than 100%");
    _reflectPct = feePct;
  }

  /**
    * @notice balanceOf function checks whether the parameter account is an
    * excluded account. If excluded account then function returns _neutralBalance
    * else function returns _scaledBalance de-scaled by current rate.
   **/

  function balanceOf(address account) public view returns (uint256) {
      if (_isExcluded[account]) return _neutralBalance[account];
      return _scaledBalance[account] / _getRate();
  }

  function transferFrom(
      address sender,
      address recipient,
      uint256 amount
  ) public returns (bool) {
      uint256 currentAllowance = _allowances[sender][msg.sender];
      require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

      _transfer(sender, recipient, amount);

      _approve(sender, msg.sender, currentAllowance - amount);

      return true;
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {

      _transfer(msg.sender, recipient, amount);
      return true;
  }

  /**
    * _transfer function perform basic checks on sender, receiver, and amount.
    * On a transfer event, the mapping that must be updated (_scaledBalance or _neutralBalance)
    * depends entirely on the counterparties. If both counterparties are included in scaled
    * redistribution then the _scaledBalance mapping must updated for both. In case both
    * counterparties are excluded from fee redistribution, then their _neutralBalance mapping
    * must be updated. Therefore, we have four possible transfer scenarios to be considered.
   **/

  function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        _transferToExcluded(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
        _transferBothExcluded(sender, recipient, amount);
    } else {
        _transferStandard(sender, recipient, amount);
    }
  }

  function _transferStandard(address sender, address recipient, uint256 neutralAmount) private {
        (uint256 scaledAmount, uint256 scaledTransferAmount, uint256 scaledFee, uint256 neutralTransferAmount,
        uint256 neutralFee) = _getValues(neutralAmount);
        require(_scaledBalance[sender] >= scaledAmount, "Insufficient funds for transaction");
        _scaledBalance[sender] = _scaledBalance[sender] - scaledAmount;
        _scaledBalance[recipient] = _scaledBalance[recipient] + scaledTransferAmount;
        _reflectFee(scaledFee, neutralFee);
        emit Transfer(sender, recipient, neutralTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 neutralAmount) private {
        (uint256 scaledAmount, uint256 scaledTransferAmount, uint256 scaledFee, uint256 neutralTransferAmount,
        uint256 neutralFee) = _getValues(neutralAmount);
        require(_scaledBalance[sender] >= scaledAmount, "Insufficient funds for transaction");
        _scaledBalance[sender] = _scaledBalance[sender] - scaledAmount;
        _neutralBalance[recipient] = _neutralBalance[recipient] + neutralTransferAmount;
        _reflectFee(scaledFee, neutralFee);
        emit Transfer(sender, recipient, neutralTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 neutralAmount) private {
       (uint256 scaledAmount, uint256 scaledTransferAmount, uint256 scaledFee, uint256 neutralTransferAmount,
       uint256 neutralFee) = _getValues(neutralAmount);
       require(_neutralBalance[sender] >= neutralAmount, "Insufficient funds for transaction");
       _neutralBalance[sender] = _neutralBalance[sender] - neutralAmount;
       _scaledBalance[recipient] = _scaledBalance[recipient] + scaledTransferAmount;
       _reflectFee(scaledFee, neutralFee);
       emit Transfer(sender, recipient, neutralTransferAmount);
   }

   function _transferBothExcluded(address sender, address recipient, uint256 neutralAmount) private {
        (uint256 scaledAmount, uint256 scaledTransferAmount, uint256 scaledFee, uint256 neutralTransferAmount,
        uint256 neutralFee) = _getValues(neutralAmount);
        require(_neutralBalance[sender] >= neutralAmount, "Insufficient funds for transaction");
        _neutralBalance[sender] = _neutralBalance[sender] - neutralAmount;
        _neutralBalance[recipient] = _neutralBalance[recipient] + neutralTransferAmount;
        _reflectFee(scaledFee, neutralFee);
        emit Transfer(sender, recipient, neutralTransferAmount);
    }

    function _getValues(uint256 neutralAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 neutralFee = neutralAmount * _reflectPct / 100;
        uint256 neutralTransferAmount = neutralAmount - neutralFee;
        uint256 currentRate = _getRate();

        uint256 scaledAmount = neutralAmount * currentRate;
        uint256 scaledFee = neutralFee * currentRate;
        uint256 scaledTransferAmount = scaledAmount - scaledFee;

        return (scaledAmount, scaledTransferAmount, scaledFee, neutralTransferAmount, neutralFee);
    }

    function _reflectFee(uint256 scaledFee, uint256 neutralFee) private {
      _scaledSupply = _scaledSupply - scaledFee;
      _neutralFeeTotal = _neutralFeeTotal + neutralFee;
  }

  function _getRate() private view returns(uint256) {
     (uint256 scaledSupply, uint256 neutralSupply) = _getIncludedSupply();
     return scaledSupply / neutralSupply;
 }

 function _getIncludedSupply() private view returns(uint256, uint256) {
    uint256 inclScaledSupply = _scaledSupply;
    uint256 inclNeutralSupply = _neutralSupply;
    for(uint256 i = 0; i < _excluded.length; i++) {
        inclScaledSupply = inclScaledSupply - _scaledBalance[_excluded[i]];
        inclNeutralSupply = inclNeutralSupply - _neutralBalance[_excluded[i]];
    }
    return (inclScaledSupply, inclNeutralSupply);
}

  function allowance(address owner, address spender) public view returns (uint256) {
      return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, amount);
      return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
      return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      uint256 currentAllowance = _allowances[msg.sender][spender];
      require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
      unchecked {
          _approve(msg.sender, spender, currentAllowance - subtractedValue);
      }

      return true;
  }

  function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}