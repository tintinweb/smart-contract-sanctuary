/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

pragma solidity ^0.4.26;

contract BEP20 {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardBEP20 is BEP20 {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract BEP20Token is StandardBEP20 { 

    string public name;     
    string public symbol;     
    string public version = 'H1.0';
    uint256 public tokenamount; 
    uint256 public totalSupply;
	address public tokenswallet;
	address public salewallet; 
    uint public salesend;
	uint256 public decimals; 

    function BEP20Token() {
		decimals = 18;
        totalSupply = 100000000 * 10 ** decimals;
        name = "COIN";
        symbol = "TIKER";
		salesend = 1640995201; // January 1, 2022 at 00:00:01 AM
		 
		tokenswallet = 0x15E5B1350F63e63F6Cea7F0A1f1C1e0d3dA3A505;
		balances[tokenswallet] = totalSupply;
		
        salewallet = 0xa804b1dff32aef3f91214F0B27BcC6ea68809d78;
    }

    function() payable{
        if (now <= salesend) {
            tokenamount = msg.value * 1000;
        } else {
            tokenamount = 0;
        }

		require(balances[tokenswallet] >= tokenamount);
        balances[tokenswallet] = balances[tokenswallet] - tokenamount;
        balances[msg.sender] = balances[msg.sender] + tokenamount;
        Transfer(tokenswallet, msg.sender, tokenamount);
        salewallet.transfer(msg.value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) returns (bool success) {
		salewallet = 0xa804b1dff32aef3f91214F0B27BcC6ea68809d78;
        return StandardBEP20(tokenAddress).transfer(salewallet, tokens);
    }
    
}