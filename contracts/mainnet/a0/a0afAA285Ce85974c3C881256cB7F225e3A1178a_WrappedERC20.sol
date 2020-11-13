/**************************************************************************
 *            ____        _                              
 *           / ___|      | |     __ _  _   _   ___  _ __ 
 *          | |    _____ | |    / _` || | | | / _ \| '__|
 *          | |___|_____|| |___| (_| || |_| ||  __/| |   
 *           \____|      |_____|\__,_| \__, | \___||_|   
 *                                     |___/             
 * 
 **************************************************************************
 *
 *  The MIT License (MIT)
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2020 Cyril Lapinte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************
 *
 * Flatten Contract: WrappedERC20
 *
 * Git Commit:
 * https://github.com/c-layer/contracts/commit/9993912325afde36151b04d0247ac9ea9ffa2a93
 *
 **************************************************************************/


// File: @c-layer/common/contracts/interface/IERC20.sol

pragma solidity ^0.6.0;


/**
 * @title IERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://github.com/ethereum/EIPs/issues/179
 *
 */
interface IERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function increaseApproval(address _spender, uint256 _addedValue)
    external returns (bool);

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    external returns (bool);
}

// File: @c-layer/common/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: @c-layer/common/contracts/token/TokenERC20.sol

pragma solidity ^0.6.0;




/**
 * @title Token ERC20
 * @dev Token ERC20 default implementation
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   TE01: Address is invalid
 *   TE02: Not enougth tokens
 *   TE03: Approval too low
 */
contract TokenERC20 is IERC20 {
  using SafeMath for uint256;

  string internal name_;
  string internal symbol_;
  uint256 internal decimals_;

  uint256 internal totalSupply_;
  mapping(address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    address _initialAccount,
    uint256 _initialSupply
  ) public {
    name_ = _name;
    symbol_ = _symbol;
    decimals_ = _decimals;
    totalSupply_ = _initialSupply;
    balances[_initialAccount] = _initialSupply;

    emit Transfer(address(0), _initialAccount, _initialSupply);
  }

  function name() external override view returns (string memory) {
    return name_;
  }

  function symbol() external override view returns (string memory) {
    return symbol_;
  }

  function decimals() external override view returns (uint256) {
    return decimals_;
  }

  function totalSupply() external override view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) external override view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender)
    external override view returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) external override returns (bool) {
    require(_to != address(0), "TE01");
    require(_value <= balances[msg.sender], "TE02");

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
    external override returns (bool)
  {
    require(_to != address(0), "TE01");
    require(_value <= balances[_from], "TE02");
    require(_value <= allowed[_from][msg.sender], "TE03");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) external override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue)
    external override returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue)
    external override returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

// File: contracts/interface/IWrappedERC20.sol

pragma solidity ^0.6.0;



/**
 * @title WrappedERC20
 * @dev WrappedERC20
 * @author Cyril Lapinte - <cyril@openfiz.com>
 *
 * Error messages
 */
abstract contract IWrappedERC20 is IERC20 {

  function base() public view virtual returns (IERC20);

  function deposit(uint256 _value) public virtual returns (bool);
  function depositTo(address _to, uint256 _value) public virtual returns (bool);

  function withdraw(uint256 _value) public virtual returns (bool);
  function withdrawFrom(address _from, address _to, uint256 _value) public virtual returns (bool);

  event Deposit(address indexed _address, uint256 value);
  event Withdrawal(address indexed _address, uint256 value);
}

// File: contracts/WrappedERC20.sol

pragma solidity ^0.6.0;




/**
 * @title WrappedERC20
 * @dev WrappedERC20
 * @author Cyril Lapinte - <cyril@openfiz.com>
 *
 * Error messages
 *   WE01: Unable to transfer tokens to address 0
 *   WE02: Unable to deposit the base token
 *   WE03: Not enougth tokens
 *   WE04: Approval too low
 *   WE05: Unable to withdraw the base token
 */
contract WrappedERC20 is TokenERC20, IWrappedERC20 {

  IERC20 internal base_;
  uint256 internal ratio_;

  /**
   * @dev constructor
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    IERC20 _base
  ) public
    TokenERC20(_name, _symbol, _decimals, address(0), 0)
  {
    ratio_ = 10 ** _decimals.sub(_base.decimals());
    base_ = _base;
  }

  /**
   * @dev base token
   */
  function base() public view override returns (IERC20) {
    return base_;
  }

  /**
   * @dev deposit
   */
  function deposit(uint256 _value) public override returns (bool) {
    return depositTo(msg.sender, _value);
  }

  /**
   * @dev depositTo
   */
  function depositTo(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "WE01");
    require(base_.transferFrom(msg.sender, address(this), _value), "WE02");

    uint256 wrappedValue = _value.mul(ratio_);
    balances[_to] = balances[_to].add(wrappedValue);
    totalSupply_ = totalSupply_.add(wrappedValue);
    emit Transfer(address(0), _to, wrappedValue);
    return true;
  }

  /**
   * @dev withdraw
   */
  function withdraw(uint256 _value) public override returns (bool) {
    return withdrawFrom(msg.sender, msg.sender, _value);
  }

  /**
   * @dev withdrawFrom
   */
  function withdrawFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "WE01");
    uint256 wrappedValue = _value.mul(ratio_);
    require(wrappedValue <= balances[_from], "WE03");

    if (_from != msg.sender) {
      require(wrappedValue <= allowed[_from][msg.sender], "WE04");
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(wrappedValue);
    }

    balances[_from] = balances[_from].sub(wrappedValue);
    totalSupply_ = totalSupply_.sub(wrappedValue);
    emit Transfer(_from, address(0), wrappedValue);

    require(base_.transfer(_to, _value), "WE05");
    return true;
  }
}