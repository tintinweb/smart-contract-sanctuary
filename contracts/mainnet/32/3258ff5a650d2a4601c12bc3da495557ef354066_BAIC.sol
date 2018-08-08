pragma solidity ^0.4.24;

/*
You should inherit from TokenBase. This implements ONLY the standard functions obeys ERC20,
and NOTHING else. If you deploy this, you won&#39;t have anything useful.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20 {

    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract BasicToken is ERC20 {
    using SafeMath for uint;

    mapping (address => uint256) balances; /// balance amount of tokens for address

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Prevent transfer to 0x0 address.
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        // Check for overflows
        require(balances[_to].add(_value) > balances[_to]);

        uint previousBalances = balances[msg.sender].add(balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender].add(balances[_to]) == previousBalances);

        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
}

contract BAIC is BasicToken {

    function () payable public {
        //if ether is sent to this address, send it back.
        //throw;
        require(false);
    }

    string public constant name = "BAIC";
    string public constant symbol = "BAIC";
    uint256 private constant _INITIAL_SUPPLY = 21000000000;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    string public version = "BAIC 1.0";

    constructor() public {
        // init
        totalSupply = _INITIAL_SUPPLY * 10 ** 18;
        balances[msg.sender] = totalSupply;
    }
}