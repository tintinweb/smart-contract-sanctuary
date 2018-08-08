pragma solidity ^0.4.23;

contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);

    function name() public constant returns (string _name);
    function symbol() public constant returns (string _symbol);
    function decimals() public constant returns (uint8 _decimals);
    function totalSupply() public constant returns (uint256 _supply);

    function transfer(address to, uint value) public returns (bool _success);
    function transfer(address to, uint value, bytes data) public returns (bool _success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Burn(address indexed _burner, uint256 _value);
}

/**
 * https://peeke.io
 * - Peeke Private Coupon -  
 * These tokens form a binding receipt for the initial private sale and can be redeemed onchain 1:1 with the PKE token once deployed.
 * Unsold tokens will be burnt at the end of the private campaign.
 **/
 
contract PeekePrivateTokenCoupon is ERC223 {
    using SafeMath for uint;

    mapping(address => uint) balances;

    string public name    = "Peeke Private Coupon";
    string public symbol  = "PPC-PKE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 155000000 * (10**18);

    constructor(PeekePrivateTokenCoupon) public {
        balances[msg.sender] = totalSupply;
    }

    // Function to access name of token.
    function name() constant public returns (string _name) {
        return name;
    }

    // Function to access symbol of token.
    function symbol() constant public returns (string _symbol) {
        return symbol;
    }

    // Function to access decimals of token.
    function decimals() constant public returns (uint8 _decimals) {
        return decimals;
    }

    // Function to access total supply of tokens.
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalSupply;
    }

    // Function that is called when a user or another contract wants to transfer funds.
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data.
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
        // Standard function transfer similar to ERC20 transfer with no _data
        // Added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    // Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private constant returns (bool is_contract) {
      uint length;
      assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // Function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // Function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver reciever = ContractReceiver(_to);
        reciever.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // Function to burn unsold tokens at the end of the private contribution.
    function burn() public {
        uint256 tokens = balances[msg.sender];
        balances[msg.sender] = 0;
        totalSupply = totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}


contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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