/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

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
 * Copyright (c) 2016-2021 Cyril Lapinte
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
 * Flatten Contract: MintableTokenERC20
 *
 **************************************************************************/

// File @c-layer/common/contracts/interface/[email protected]

pragma solidity ^0.8.0;


/**
 * @title IERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://github.com/ethereum/EIPs/issues/179
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


// File @c-layer/common/contracts/token/[email protected]

pragma solidity ^0.8.0;

/**
 * @title Token ERC20
 * @dev Token ERC20 default implementation
 *
 * @author Cyril Lapinte - <[email protected]>
 *
 * Error messages
 *   TE01: Recipient is invalid
 *   TE02: Not enougth tokens
 *   TE03: Approval too low
 */
contract TokenERC20 is IERC20 {

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
  ) {
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

  function totalSupply() external override virtual view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) external override virtual view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender)
    external override view returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) external override virtual returns (bool) {
    return transferFromInternal(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value)
    external override virtual returns (bool)
  {
    return transferFromInternal(_from, _to, _value);
  }

  function transferFromInternal(address _from, address _to, uint256 _value)
    internal virtual returns (bool)
  {
    require(_to != address(0), "TE01");
    require(_value <= balances[_from], "TE02");

    if (_from != msg.sender) {
      require(_value <= allowed[_from][msg.sender], "TE03");
      allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    }

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
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
    allowed[msg.sender][_spender] =
      allowed[msg.sender][_spender] + _addedValue;
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
      allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}


// File @c-layer/common/contracts/operable/[email protected]

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * @dev functions, this simplifies the implementation of "user permissions".
 *
 * Error messages
 *   OW01: Message sender is not the owner
 *   OW02: New owner must be valid
*/
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "OW01");
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "OW02");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


// File contracts/interface/IMintableERC20.sol

pragma solidity ^0.8.0;


/**
 * @title IMintableERC20 interface
 */
interface IMintableERC20 {

  event Burn(address indexed from, uint256 value);
  event Mint(address indexed to, uint256 value);
  event FinishMinting();

  function mintingFinished() external view returns (bool);
  function allTimeMinted() external view returns (uint256);

  function burn(uint256 _amount) external;
  function mint(address[] memory _recipients, uint256[] memory _amounts) external;
  function finishMinting() external;
}


// File contracts/monolithic/MintableTokenERC20.sol

pragma solidity ^0.8.0;



/**
 * @title Mintable Token ERC20
 * @dev Mintable Token ERC20 default implementation
 *
 * @author Cyril Lapinte - <[email protected]>
 *
 * Error messages
 *   MT01: Unable to mint
 *   MT02: Invalid number of recipients and amounts
 */
contract MintableTokenERC20 is IMintableERC20, Ownable, TokenERC20 {

  bool internal mintingFinished_;
  uint256 internal allTimeMinted_;

  modifier canMint {
    require(!mintingFinished_, "MT01");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    address _initialAccount,
    uint256 _initialSupply
  ) TokenERC20(
    _name,
    _symbol,
    _decimals,
    address(this),
    0)
  {
    mintInternal(_initialAccount, _initialSupply);
  }

  function mintingFinished() external override view returns (bool) {
    return mintingFinished_;
  }

  function allTimeMinted() external override view returns (uint256) {
    return allTimeMinted_;
  }

  /**
   * @dev Function to burn tokens
   * @param _amount The amount of tokens to burn.
   */
  function burn(uint256 _amount) external override onlyOwner
  {
    burnInternal(msg.sender, _amount);
  }

  /**
   * @dev Function to mint all tokens at once
   * @param _recipients The addresses that will receive the minted tokens.
   * @param _amounts The amounts of tokens to mint.
   */
  function mint(address[] memory _recipients, uint256[] memory _amounts)
    external override canMint onlyOwner
  {
    require(_recipients.length == _amounts.length, "MT02");
    for (uint256 i=0; i < _recipients.length; i++) {
      mintInternal(_recipients[i], _amounts[i]);
    }
  }

  /**
   * @dev Function to stop minting new tokens.
   */
  function finishMinting() external override canMint onlyOwner
  {
    mintingFinished_ = true;
    emit FinishMinting();
  }

  /**
   * @dev Function to mint tokens internal
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   */
  function mintInternal(address _to, uint256 _amount) internal virtual
  {
    totalSupply_ = totalSupply_ + _amount;
    balances[_to] = balances[_to] + _amount;
    allTimeMinted_ = allTimeMinted_ + _amount;

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

  /**
   * @dev Function to burn tokens internal
   * @param _from The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   */
  function burnInternal(address _from, uint256 _amount) internal virtual
  {
    totalSupply_ = totalSupply_ - _amount;
    balances[_from] = balances[_from] - _amount;

    emit Transfer(_from, address(0), _amount);
    emit Burn(_from, _amount);
  }
}