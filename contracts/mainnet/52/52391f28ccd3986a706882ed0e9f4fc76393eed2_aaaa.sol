/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity ^0.4.22;
interface Token {

    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && _value >= 0);
        require(allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function totalSupply() public view returns (uint256) {
        return supply;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 supply;
}

contract aaaa is StandardToken { 
    string public name;                  
    uint8 public decimals;                
    string public symbol;                 
    string public version = 'H1.0';
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;         
    address public fundsWallet;           

    function aaaa() public {
        balances[msg.sender] = 10000000000000000000000000000;            
        supply = 10000000000000000000000000000 ;                     
        name = "ezswap";                                  
        decimals = 18;                                               
        symbol = "EZ";                                             
        unitsOneEthCanBuy = 5000000;                                  
        fundsWallet = msg.sender;                                   
    }

    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        emit Transfer(fundsWallet, msg.sender, amount); 
        fundsWallet.transfer(msg.value);                             
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}