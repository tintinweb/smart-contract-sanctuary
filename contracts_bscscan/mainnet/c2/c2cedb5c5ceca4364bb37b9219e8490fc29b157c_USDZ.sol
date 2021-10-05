// Submitted for verification at BscScan.com on 2021-10-05

/*
USDZ, a currency paired to the dollar with 100% guaranteed backing, transparently and securely, with transactions 
between In portfolios a fee is applied, part is redistributed within the holders' portfolios and part is used for 
currency management, marketing and operations fees.

Name: USDZ
Symbol: USDZ
Decimals: 6
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./BEP20Token.sol";

contract USDZ is BEP20Token {

  struct Wallet {
    address holders;
    address operation;
  }
  Wallet internal _wallet; 

  struct FeeSplit {
    uint8 holders;
    uint8 operation;
  }
  FeeSplit internal _feeSplit;

  struct Range {
    uint256 value1;
    uint8   fee1;
    uint256 value2;
    uint8   fee2;
    uint256 value3;
    uint8   fee3;
    uint256 value4;
    uint8   fee4;
    uint256 value5;
    uint8   fee5;
    uint256 value6;
    uint8   fee6;
    uint256 value7;
    uint8   fee7;
    uint256 value8;
    uint8   fee8;
    uint256 value9;
    uint8   fee9;
    uint256 value10;
    uint8   fee10;
  }
  Range internal _standartRange;

  struct Lock {
    uint256 amount;
    uint256 start;
    uint256 end;
  }

  mapping (address => Lock) internal _locks;
  mapping (address => bool) internal _noFee;
  mapping (address => Range) internal _customRange;

  bool _allLock = false;

  event setLockEvent(address indexed wallet, uint256 amount, uint256 start, uint256 end);
  
  constructor() {
    _name = "USDZ";
    _symbol = "USDZ";
    _decimals = 6;
    _totalSupply = 1 * 10 ** 6;
    _balances[msg.sender] = _totalSupply;

    _wallet.holders   = 0xaE83daD938B0ebeced560C9c929921C8Eb2A2A3E;
    _wallet.operation = 0x8cE3384202ba5B3179BC0231BC61E464Fc0A5E42;

    _feeSplit.holders   = 50;
    _feeSplit.operation = 50;

    _noFee[msg.sender]        = true;
    _noFee[_wallet.holders]   = true;
    _noFee[_wallet.operation] = true;

    // _range.fee =  x / 1000 . ex.  20 = 20/1000 = 2% 
    _standartRange.value1  = 1000 * 10 ** 6;
    _standartRange.fee1    = 20;
    _standartRange.value2  = 10000 * 10 ** 6;
    _standartRange.fee2    = 18;
    _standartRange.value3  = 100000 * 10 ** 6;
    _standartRange.fee3    = 15;
    _standartRange.value4  = 500000 * 10 ** 6;
    _standartRange.fee4    = 13;
    _standartRange.value5  = 1000000 * 10 ** 6;
    _standartRange.fee5    = 12;
    _standartRange.value6  = 9;
    _standartRange.fee6    = 10;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }


  /**
   * @dev set blocking for transfers.
   */
  function setAllLock(bool lock) external onlyOwner {
    _allLock   = lock;
  }

  /**
   * @dev returns lock setting.
   */
  function getAllLock() external view returns (bool)  {
    return (_allLock);
  }

  /**
   * @dev set wallets.
   */
  function setWallet(address holders, address operation) external onlyOwner {
    _wallet.holders   = holders;
    _wallet.operation = operation;
  }

  /**
   * @dev returns the addresses of the wallets receiving fees.
   */
  function getWallet() external view returns (address, address)  {
    return (_wallet.holders, _wallet.operation);
  }

  /**
   * @dev sets the default fee for all address
   */
  function setStandartRange( Range memory range ) external onlyOwner {
    _standartRange = range;
  }

  function getStandartRange() external view returns (Range memory)  {
    return (_standartRange);
  }

  function setCustomRange( address wallet, Range memory range ) external onlyOwner {
    _customRange[wallet] = range;
  }

  function getCustomRange(address wallet) external view returns (Range memory)  {
    return (_customRange[wallet]);
  }

  /**
   * @dev sets the percentages of fee sharing in the wallets.
   */
  function setFeeSplit(uint8 holders, uint8 operation) external onlyOwner {
    require(holders + operation == 100, "BEP20: split sum has to be 100.");
    _feeSplit.holders   = holders;
    _feeSplit.operation = operation;
  }

  /**
   * @dev returns fee split setting.
   */
  function getFeeSplit() external view returns (uint8, uint8)  {
    return (_feeSplit.holders, _feeSplit.operation);
  }

  /**
   * @dev set address without transaction fee implications (true) or with fee (false).
   */
  function setNoFee(address wallet, bool noFee) external onlyOwner {
    _noFee[wallet] = noFee;
  }

  /**
   * @dev returns fee status of an address
   */
  function getNoFee(address wallet) external view returns (bool)  {
    return (_noFee[wallet]);
  }

   /**
   * @dev set lock in a address.
   */
  function setLock(address wallet, uint256 amount, uint256 start, uint256 end) external onlyOwner {
    _locks[wallet].amount = amount;
    _locks[wallet].end    = end;
    _locks[wallet].start  = start;
    emit setLockEvent( wallet, amount, start, end);
  }

  /**
   * @dev Returns the lock info of a address.
   */
  function getLockInfo(address wallet) external view returns (uint256, uint256, uint256) {
    uint256 amount = _locks[wallet].amount;
    uint256 start = _locks[wallet].start;
    uint256 end = _locks[wallet].end;

    return (amount, start, end);
  }
  
  /**
  * @dev returns the fee for a transfer based on parameters
  */
  function _getFee (address sender, uint256 amount) internal view returns(uint8) {
    if ( _noFee[sender] ) {
      return 0;
    }

    if ( _customRange[sender].value1 != 0 ) {
      if (_customRange[sender].value1 >= amount || _customRange[sender].value1 == 9 ) {
        return _customRange[sender].fee1;
      }
      if (_customRange[sender].value2 >= amount || _customRange[sender].value2 == 9) {
        return _customRange[sender].fee2;
      }
      if (_customRange[sender].value3 >= amount || _customRange[sender].value3 == 9 ) {
        return _customRange[sender].fee3;
      }
      if (_customRange[sender].value4 >= amount || _customRange[sender].value4 == 9 ) {
        return _customRange[sender].fee4;
      }
      if (_customRange[sender].value5 >= amount || _customRange[sender].value5 == 9 ) {
        return _customRange[sender].fee5;
      }
      if (_customRange[sender].value5 >= amount || _customRange[sender].value6 == 9 ) {
        return _customRange[sender].fee5;
      }
      if (_customRange[sender].value6 >= amount || _customRange[sender].value7 == 9 ) {
        return _customRange[sender].fee6;
      }
      if (_customRange[sender].value7 >= amount || _customRange[sender].value8 == 9 ) {
        return _customRange[sender].fee7;
      }
      if (_customRange[sender].value8 >= amount || _customRange[sender].value9 == 9 ) {
        return _customRange[sender].fee8;
      }
      if (_customRange[sender].value9 >= amount || _customRange[sender].value10 == 9 ) {
        return _customRange[sender].fee9;
      }
      return _customRange[sender].fee10;
    }

    if (_standartRange.value1 >= amount || _standartRange.value1 == 9 ) {
      return _standartRange.fee1;
    }
    if (_standartRange.value2 >= amount || _standartRange.value2 == 9) {
      return _standartRange.fee2;
    }
    if (_standartRange.value3 >= amount || _standartRange.value3 == 9 ) {
      return _standartRange.fee3;
    }
    if (_standartRange.value4 >= amount || _standartRange.value4 == 9 ) {
      return _standartRange.fee4;
    }
    if (_standartRange.value5 >= amount || _standartRange.value5 == 9 ) {
      return _standartRange.fee5;
    }
    if (_standartRange.value5 >= amount || _standartRange.value6 == 9 ) {
      return _standartRange.fee5;
    }
    if (_standartRange.value6 >= amount || _standartRange.value7 == 9 ) {
      return _standartRange.fee6;
    }
    if (_standartRange.value7 >= amount || _standartRange.value8 == 9 ) {
      return _standartRange.fee7;
    }
    if (_standartRange.value8 >= amount || _standartRange.value9 == 9 ) {
      return _standartRange.fee8;
    }
    if (_standartRange.value9 >= amount || _standartRange.value10 == 9 ) {
      return _standartRange.fee9;
    }
    return _standartRange.fee10;
  }

   /**
   * @dev token-specific transfer function - considers locked tokens and transaction fee
   */
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    
    require(_allLock == false, "BEP20: USDZ Locked for transfers.");
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
  
    if (block.timestamp > _locks[sender].end) {
      _locks[sender].amount = 0;
      _locks[sender].start  = 0;
      _locks[sender].end    = 0;
    }
    uint256 balance     = _balances[sender];
    uint256 balanceLock = _locks[sender].amount;
    uint256 balanceFree = balance - balanceLock;
    require(balanceFree >= amount, "BEP20: transfer amount exceeds balance free");
    
    uint256 amountFree = amount;
    uint8 _realFee = _getFee(sender, amount);

    if (_realFee > 0) {
      uint256 _feeAmount = (amount * _realFee * 10) / 10000;
      uint256 amountHolders   = (_feeAmount * _feeSplit.holders   * 100) / 10000;
      uint256 amountOperation = (_feeAmount * _feeSplit.operation * 100) / 10000;
      amountFree = amount - amountHolders - amountOperation;
      _balances[_wallet.holders]   += amountHolders;
      _balances[_wallet.operation] += amountOperation;
    }

    _balances[sender] -= amount;
    _balances[recipient] += amountFree;
    emit Transfer(sender, recipient, amountFree);
  }

}