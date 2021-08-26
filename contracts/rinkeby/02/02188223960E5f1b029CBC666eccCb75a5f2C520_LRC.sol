// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract LRC is DummyToken {

    constructor() DummyToken(
        "LRC_TEST",
        "LRC",
        18,
        10 ** 27
        )
    {
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../lib/MathUint.sol";
import "./LRCToken.sol";

/// @author Kongliang Zhong - <[email protected]>
contract DummyToken is LRCToken {

    using MathUint for uint;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8         _decimals,
        uint          _totalSupply
    ) LRCToken(
        _name,
        _symbol,
        _decimals,
        _totalSupply,
        msg.sender
        )
    {
    }

    function setBalance(
        address _target,
        uint _value
        )
        public
    {
        uint currBalance = balanceOf(_target);
        if (_value < currBalance) {
            totalSupply_ = totalSupply_.sub(currBalance.sub(_value));
        } else {
            totalSupply_ = totalSupply_.add(_value.sub(currBalance));
        }
        balances[_target] = _value;
    }

    function addBalance(
        address _target,
        uint _value
        )
        public
    {
        uint currBalance = balanceOf(_target);
        require(_value + currBalance >= currBalance, "INVALID_VALUE");
        totalSupply_ = totalSupply_.add(_value);
        balances[_target] = currBalance.add(_value);
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../lib/MathUint.sol";

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address who) public view virtual returns (uint);
    function transfer(address to, uint value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;
    mapping (address => uint) balances;
    uint totalSupply_;
    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view override virtual returns (uint) {
        return totalSupply_;
    }
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value) public override virtual returns (bool) {
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[msg.sender], "TRANSFER_INSUFFICIENT_BALANCE");
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return balance An uint representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view override virtual returns (uint balance) {
        return balances[_owner];
    }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract AbsERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual returns (bool);
    function approve(address spender, uint value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is AbsERC20, BasicToken {
    using MathUint for uint;

    mapping (address => mapping (address => uint)) internal allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) public override returns (bool) {
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_from], "TRANSFERFROM_INSUFFICIENT_BALANCE");
        require(_value <= allowed[_from][msg.sender], "TRANSFERFROM_INSUFFICIENT_ALLOWANCE");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view override returns (uint) {
        return allowed[_owner][_spender];
    }
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract LRCToken is StandardToken {
    using SafeMath for uint;

    string     public name = "New Loopring token on ethereum";
    string     public symbol = "LRC";
    uint8      public decimals = 18;

    event Burn(address indexed burner, uint value);

    function burn(uint _value) public returns (bool) {
        require(_value <= balances[msg.sender], "BURN_INSUFFICIENT_BALANCE");

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }

    function burnFrom(address _owner, uint _value) public returns (bool) {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_owner], "BURNFROM_INSUFFICIENT_BALANCE");
        require(_value <= allowed[_owner][msg.sender], "BURNFROM_INSUFFICIENT_ALLOWANCE");

        balances[_owner] = balances[_owner].sub(_value);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(_owner, _value);
        emit Transfer(_owner, address(0), _value);
        return true;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8         _decimals,
        uint          _totalSupply,
        address       _firstHolder
        )
    {
        require(_totalSupply > 0, "INVALID_VALUE");
        require(_firstHolder != address(0), "ZERO_ADDRESS");
        checkSymbolAndName(_symbol,_name);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;

        balances[_firstHolder] = totalSupply_;
    }

    // Make sure symbol has 3-8 chars in [A-Za-z._] and name has up to 128 chars.
    function checkSymbolAndName(
        string memory _symbol,
        string memory _name
        )
        internal
        pure
    {
        bytes memory s = bytes(_symbol);
        require(s.length >= 3 && s.length <= 8, "INVALID_SIZE");
        for (uint i = 0; i < s.length; i++) {
            // make sure symbol contains only [A-Za-z._]
            require(
                s[i] == 0x2E || (
                s[i] == 0x5F) || (
                s[i] >= 0x41 && s[i] <= 0x5A) || (
                s[i] >= 0x61 && s[i] <= 0x7A), "INVALID_VALUE");
        }
        bytes memory n = bytes(_name);
        require(n.length >= s.length && n.length <= 128, "INVALID_SIZE");
        for (uint i = 0; i < n.length; i++) {
            require(n[i] >= 0x20 && n[i] <= 0x7E, "INVALID_VALUE");
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}