pragma solidity ^0.4.11;


contract VCCoin  {
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    string public name = "VC Coin";
    string public symbol = "VCC";
    uint public decimals = 18;


    // Initial founder address (set in constructor)
    // All deposited ETH will be instantly forwarded to this address.
    address public founder = 0x0;

    uint256 public totalSupply = 5625000 * 10**decimals;

    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //constructor
    function VCCoin(address founderInput) {
        founder = founderInput;
        balances[founder] = totalSupply;
    }



    function transfer(address _to, uint256 _value) returns (bool success) {

        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (msg.sender != founder) revert();

        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function() {
        revert();
    }

    // only owner can kill
    function kill() { 
        if (msg.sender == founder) suicide(founder); 
    }

}