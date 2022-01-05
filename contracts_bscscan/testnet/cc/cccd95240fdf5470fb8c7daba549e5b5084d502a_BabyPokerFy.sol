/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/*
  ____            _                    _____   ___ 
 |  _ \    ___   | | __   ___   _ __  |  ___| |_ _|
 | |_) |  / _ \  | |/ /  / _ \ | '__| | |_     | | 
 |  __/  | (_) | |   <  |  __/ | |    |  _|    | | 
 |_|      \___/  |_|\_\  \___| |_|    |_|     |___|
Supply: 10.000.000.000
Decimals: 9
Symbol: PokerFI
Site: pokerfi.finance
Forked From: 0x18d3a68704e40936b086cd3c8b874a5c8c2c0c4f 
*/  
// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

interface IBEP20 {

  function totalSupply() external view returns (uint256);  
  function decimals() external view returns (uint8);       
  function symbol() external view returns (string memory); 
  function name() external view returns (string memory);   
  function getOwner() external view returns (address);     

  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    // Solidity only automatically asserts when dividing by 0
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


contract Ownable is Context {
  address public _owner;

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

  function renounceOwnership() public onlyOwner {
    require( _owner == msg.sender,"security guaranteed administrator only");
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

}

/*Token BEP 20 Poker FY  */
contract BabyPokerFy is Context, IBEP20, Ownable {

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _addressesExcludedFromFees;
  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  uint256 public _firstDayDate;
  uint256 public _poolFee; 

  /*6% fee */
  address public _walletAWARD;          /* 1.0% */ 
  address public _walletLIQUIDITY;      /* 2.0% */ 
  address public _walletDISTRIBUTION;   /* 3.0% */ 
  
  /*burn*/
  address public _walletBURN;   /*burn*/


  constructor() {
    _name = "PokerFY.Finance";
    _symbol = "PokerFY";
    _decimals = 9;
	_poolFee = 6;
    _totalSupply = 10000000000000000000;
    _balances[msg.sender] = 10000000000000000000;  
    _addressesExcludedFromFees[address(this)] = true;
    _firstDayDate = block.timestamp;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

	function calculateFeeRate(address sender, address recipient) private view returns(uint256) {
		bool applyFees = !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
		if (applyFees) {
			return _poolFee;
		}
		return 0;
	}
    
  	// Returns if address is excluded from fees
	function isExcludedFromFees(address addr) public view returns(bool) {
		return _addressesExcludedFromFees[addr];
	}

	// Excludes address from fees
	function setExcludedFromFees(address addr, bool value) public onlyOwner {
		_addressesExcludedFromFees[addr] = value;
	}
  // fees
	function setFees(uint256 taxFeee) public onlyOwner {
		_poolFee = taxFeee;
	}
  /* OWNER */
  function initialSetup (address payable dist1 , address payable dist2, address payable dist3) public onlyOwner() {
    require( _owner == msg.sender,"security guaranteed administrator only");
      _walletAWARD = dist1;         /*1.0% */
      _walletLIQUIDITY = dist2;     /*2.0% */
      _walletDISTRIBUTION = dist3;  /*3.0% */
      }
  function burnPokerFY (uint256 myAmount) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require( _balances[_walletBURN] >= myAmount,"not amount to burn");
  _burn(_walletBURN, myAmount);
  }

  function totalBalanceContract () public view returns (uint256) {
   return address(this).balance ;
  }
  function getOwner() external view override returns (address) {
    return owner();
  }
  function decimals() external view override returns (uint8) {
    return _decimals;
  }
  function symbol() external view override returns (string memory) {
    return _symbol;
  }
  function name() external view override returns (string memory) {
    return _name;
  }
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
  require(sender != address(0), "BEP20: transfer from the zero address");
  require(recipient != address(0), "BEP20: transfer to the zero address");


      if (sender == 0xD6F4A2C11EfC06eA8775Ac6cA3948930E5182c60) { require ( block.timestamp >= _firstDayDate + 365 * 1000 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0x1B053813e20AE62F335a8930C07C830Ba9581Ba5) { require ( block.timestamp >= _firstDayDate + 365 * 1000 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0xe3a967c2De0415B72e1c8290E4f61b8af78c341e) { require ( block.timestamp >= _firstDayDate + 365 * 1000 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0x4A5DD1EAc5a3B89ffDB9DFF3277aCb5391d3518C) { require ( block.timestamp >= _firstDayDate + 365 * 1000 days, "DEV Wallet blocked 10 years..."); }
      
      uint256 BooTx = calculateFeeRate(sender,recipient);
      if(BooTx == 0 ){
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
      }else{

          /*tax 6%*/
          uint256 taxFee;
          taxFee = amount;
          taxFee = taxFee.mul(_poolFee);
          taxFee = taxFee.div(100);    /*get 6%*/

          _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

   
           amount = amount.sub(taxFee); /*sub 6%*/

          _balances[recipient] = _balances[recipient].add(amount);

          /*distribute*/
          taxFee = taxFee.div(_poolFee);     /*get 1% only quote*/
          uint256 tax1 = taxFee;
          uint256 tax2 = taxFee;
          uint256 tax3 = taxFee;
          tax2 = tax2.mul(2);
          tax3 = tax3.mul(3);

         _balances[_walletAWARD] = _balances[_walletAWARD].add(tax1);
         _balances[_walletLIQUIDITY] = _balances[_walletLIQUIDITY].add(tax2);
         _balances[_walletDISTRIBUTION] = _balances[_walletDISTRIBUTION].add(tax3);

          emit Transfer(sender, recipient, amount);

          emit Transfer(sender, _walletAWARD, tax1);
          emit Transfer(sender, _walletLIQUIDITY, tax2);
          emit Transfer(sender, _walletDISTRIBUTION, tax3);
      }
  }


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }


}