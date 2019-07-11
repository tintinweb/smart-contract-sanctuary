/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Symbol      : STUM
// Name        : STOTUM
// Total supply: 100,000,000.00000000
// Decimals    : 18
// ----------------------------------------------------------------------------

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract iERC223Token {
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transferFrom(address from, address to, uint value, bytes data) public returns (bool ok);
}

contract ERC223Receiver {
    function tokenFallback( address _origin, uint _value, bytes _data) public returns (bool ok);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract iERC20Token {
    uint256 public totalSupply = 0;
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is iERC20Token {

    using SafeMath for uint256;
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

   /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract FreezableToken is iERC223Token, StandardToken, Ownable {

    event ContractTransfer(address indexed _from, address indexed _to, uint _value, bytes _data);

    bool public freezed;

    modifier canTransfer(address _transferer) {
        require(owner == _transferer || !freezed);
        _;
    }

    function FreezableToken() public {
        freezed = true;
    }

    function transfer(address _to, uint _value, bytes _data) canTransfer(msg.sender)
        public
        canTransfer(msg.sender)
        returns (bool success) {
        //filtering if the target is a contract with bytecode inside it
        require(super.transfer(_to, _value)); // do a normal token transfer
        if (isContract(_to)) {
            require(contractFallback(msg.sender, _to, _value, _data));
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public canTransfer(msg.sender) returns (bool success) {
        require(super.transferFrom(_from, _to, _value)); // do a normal token transfer
        if (isContract(_to)) {
            require(contractFallback(_from, _to, _value, _data));
        }
        return true;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) public canTransfer(msg.sender) returns (bool success) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    //function that is called when transaction target is a contract
    function contractFallback(address _origin, address _to, uint _value, bytes _data) private returns (bool) {
        emit ContractTransfer(_origin, _to, _value, _data);
        ERC223Receiver reciever = ERC223Receiver(_to);
        require(reciever.tokenFallback(_origin, _value, _data));
        return true;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    function unfreeze() public onlyOwner returns (bool){
        freezed = false;
        return true;
    }
}

contract StotumToken is FreezableToken {

    string public constant name = &#39;Stotum&#39;;
    string public constant symbol = &#39;STUM&#39;;
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000 * (10 ** uint256(decimals));

    function StotumToken() public {
        balances[msg.sender]  = totalSupply;
    }
}