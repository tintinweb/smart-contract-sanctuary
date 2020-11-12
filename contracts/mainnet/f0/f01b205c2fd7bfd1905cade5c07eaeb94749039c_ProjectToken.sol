pragma solidity ^0.5.0;

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowance(address owner, address spender) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Token is ERC20 {
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  using SafeMath for uint;

  function transfer(address _to, uint _value) public returns (bool success) {

    return doTransfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    allowed[_from][msg.sender] = _allowance.sub(_value);

    return doTransfer(_from, _to, _value);
  }

  /// @notice Allows `_spender` to withdraw from your account multiple times up to `_value`.
  /// If this function is called again it overwrites the current allowance with `_value`.
  /// @dev Allows `_spender` to withdraw from your account multiple times up to `_value`.
  /// If this function is called again it overwrites the current allowance with `_value`.
  /// NOTE: To prevent attack vectors, clients SHOULD make sure to create user interfaces
  /// in such a way that they set the allowance first to 0 before setting it
  /// to another value for the same spender
  /// @param _spender Address that is going to be approved
  /// @param _value Number of tokens that spender is going to be able to transfer
  /// @return true if success
  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

  function doTransfer(address _from, address _to, uint _value) internal returns (bool success) {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(_from, _to, _value);

    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/*
  Copyright (C) 2017 Icofunding S.L.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/// @title Mint interface
/// @author Icofunding
contract MintInterface {
  function mint(address recipient, uint amount) public returns (bool success);
}

/**
 * Manages the ownership of a contract
 * Standard Owned contract.
 */
contract Owned {
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner);

    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}

/*
  Copyright (C) 2017 Icofunding S.L.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/// @title Manages the minters of a token
/// @author Icofunding
contract Minted is MintInterface, Owned {
  uint public numMinters; // Number of minters of the token.
  bool public open; // If is possible to add new minters or not. True by default.
  mapping (address => bool) public isMinter; // If an address is a minter of the token or not

  // Log of the minters added
  event NewMinter(address who);

  modifier onlyMinters() {
    require(isMinter[msg.sender]);

    _;
  }

  modifier onlyIfOpen() {
    require(open);

    _;
  }

  constructor() public {
    open = true;
  }

  /// @notice Adds a new minter to the token.
  /// It can only be executed by the Owner if the token is open to new minters.
  /// @dev Adds a new minter to the token.
  /// It can only be executed by the Owner if the token is open to new minters.
  /// @param _minter minter address
  function addMinter(address _minter) public onlyOwner onlyIfOpen {
    if(!isMinter[_minter]) {
      isMinter[_minter] = true;
      numMinters++;

      emit NewMinter(_minter);
    }
  }

  /// @notice Removes a minter of the token.
  /// It can only be executed by the Owner.
  /// @dev Removes a minter of the token.
  /// It can only be executed by the Owner.
  /// @param _minter minter address
  function removeMinter(address _minter) public onlyOwner {
    if(isMinter[_minter]) {
      isMinter[_minter] = false;
      numMinters--;
    }
  }

  /// @notice Blocks the possibility to add new minters.
  /// It can only be executed by the Owner.
  /// @dev Blocks the possibility to add new minters
  /// It can only be executed by the Owner.
  function endMinting() public onlyOwner {
    open = false;
  }
}

 /*
   Copyright (C) 2017 Icofunding S.L.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/// @title Pausable
/// @author Icofunding
contract Pausable is Owned {
  bool public isPaused;

  modifier whenNotPaused() {
    require(!isPaused);

    _;
  }

  /// @notice Makes the token non-transferable
  /// @dev Makes the token non-transferable
  function pause() public onlyOwner {
    isPaused = true;
  }

  /// @notice Makes the token transferable
  /// @dev Makes the token transferable
  function unPause() public onlyOwner {
    isPaused = false;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/*
  Copyright (C) 2017 Icofunding S.L.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/// @title Auth
/// @author Icofunding
contract Auth is Owned {
  mapping (address => bool) authAddresses;

  // Manages the ownership of a contract with multiple managers
  modifier onlyAuth() {
    require(isAuth(msg.sender));

    _;
  }

  function addAuth(address authAddress) public onlyOwner {
    authAddresses[authAddress] = true;
  }

  function removeAuth(address authAddress) public onlyOwner {
    authAddresses[authAddress] = false;
  }

  function isAuth(address authAddress) public view returns (bool) {
    return (authAddresses[authAddress] || authAddress == owner);
  }
}


/*
  Copyright (C) 2017 Icofunding S.L.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/// @title Whitelist
/// @author Icofunding
contract Whitelist is Auth {
  mapping(address => bool) public whitelist;

  using SafeMath for uint;

  modifier whitelisted(address from, address to) {
    require(whitelist[from]);
    require(whitelist[to]);

    _;
  }

  constructor() public {
  }

  /// @notice Adds the address `account` to the whitelist
  /// @dev Adds the address `account` to the whitelist
  /// @param account Address to be added to the whitelist
  function addToWhitelist(address account) public onlyAuth {
    whitelist[account] = true;
  }

  /// @notice Removes the address `account` from the whitelist
  /// @dev Removes the address `account` from the whitelist
  /// @param account Address to be removed from the whitelist
  function removeFromWhitelist(address account) public onlyAuth {
    whitelist[account] = false;
  }
}

/*
  Copyright (C) 2017 Icofunding S.L.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/// @title Token contract
/// @author Icofunding
contract ProjectToken is Token, Minted, Pausable, Whitelist {
  string public name;
  string public symbol;
  uint public decimals;

  uint public transferableDate; // timestamp

  modifier lockUpPeriod() {
    require(now >= transferableDate);

    _;
  }

  /// @notice Creates a token
  /// @dev Constructor
  /// @param _name Name of the token
  /// @param _symbol Acronim of the token
  /// @param _decimals Number of decimals of the token
  /// @param _transferableDate Timestamp from when the token can de transfered
  constructor(
    string memory _name,
    string memory _symbol,
    uint _decimals,
    uint _transferableDate
  ) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    transferableDate = _transferableDate;
  }

  /// @notice Creates `amount` tokens and sends them to `recipient` address
  /// @dev Mints new tokens. This tokens are transfered from the address 0x0
  /// Adds the receiver to the whitelist
  /// @param recipient Address that receives the tokens
  /// @param amount Number of tokens created (plus decimals)
  /// @return true if success
  function mint(address recipient, uint amount)
    public
    onlyMinters
    returns (bool success)
  {
    totalSupply = totalSupply.add(amount);
    balances[recipient] = balances[recipient].add(amount);

    whitelist[recipient] = true;

    emit Transfer(address(0), recipient, amount);

    return true;
  }

  /// @notice Transfers `value` tokens to `to`
  /// @dev Transfers `value` tokens to `to`
  /// @param to The address that will receive the tokens.
  /// @param value The amount of tokens to transfer (plus decimals)
  /// @return true if success
  function transfer(address to, uint value)
    public
    lockUpPeriod
    whenNotPaused
    whitelisted(msg.sender, to)
    returns (bool success)
  {
    return super.transfer(to, value);
  }

  /// @notice Transfers `value` tokens to `to` from `from` account
  /// @dev Transfers `value` tokens to `to` from `from` account.
  /// @param from The address of the sender
  /// @param to The address that will receive the tokens
  /// @param value The amount of tokens to transfer (plus decimals)
  /// @return true if success
  function transferFrom(address from, address to, uint value)
    public
    lockUpPeriod
    whenNotPaused
    whitelisted(from, to)
    returns (bool success)
  {
    return super.transferFrom(from, to, value);
  }

  /// @notice Forces the transfer of `value` tokens from `from` to `to`
  /// @dev Forces the transfer of `value` tokens from `from` to `to`
  /// @param from The address that sends the tokens.
  /// @param to The address that will receive the tokens.
  /// @param value The amount of tokens to transfer (plus decimals)
  /// @return true if success
  function forceTransfer(address from, address to, uint value)
    public
    onlyOwner
    returns (bool success)
  {
    require(whitelist[to]);
    
    return super.doTransfer(from, to, value);
  }
}