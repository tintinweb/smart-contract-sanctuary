pragma solidity ^0.4.11;

/*
AVC coin as a simple implementation of ERC20
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
*/

contract ApprovalReceiver {
    function receiveApproval(address,uint256,address,bytes);
}

contract AviaC01n  {

	function AviaC01n (){
		balances[msg.sender] = totalSupply;
	}


	/// explicitely reject ethers
	function () { revert(); }

	/// ====== ERC20 optional token descriptors ======
    string public name = "Avia C01n";
    uint8 public decimals = 18;
    string public symbol  = "AC0";
    string public version = &#39;0.1.0&#39;;
    
	/// ====== ERC20 implementation starts here =====

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

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

    /// ======= ERC20 extension =======
    
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
    
    /// ======= events  =======
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /// ======= states =====
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	uint256 public constant totalSupply = 10000000 * 1 finney;
	
}