/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

contract ERC20Interface {  
    string public constant name = "Apollo";    //代币名称  
    string public constant symbol = "APO";      //代币符号  
    uint8 public constant decimals = 18;        //代币小数点位数  
  
    function totalSupply() public constant returns (uint);  //代币发行总量  
    function balanceOf(address tokenOwner) public constant returns (uint balance);  //查看对应账号代币余额  
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);   //返回授权花费的代币数  
    function transfer(address to, uint tokens) public returns (bool success);   //实现代币转账交易  
    function approve(address spender, uint tokens) public returns (bool success);   //授权用户可代表我们花费的代币数  
    function transferFrom(address from, address to, uint tokens) public returns (bool success);     //给被授权的用户使用  
  
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);  
}  

pragma solidity ^0.4.16;  
  
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }  
  
contract TokenERC20 {  
    string public name;  
    string public symbol;  
    uint8 public decimals = 18;  // 18 是建议的默认值  
    uint256 public totalSupply;  
  
    mapping (address => uint256) public balanceOf;  //  
    mapping (address => mapping (address => uint256)) public allowance;  
  
    event Transfer(address indexed from, address indexed to, uint256 value);  
  
    event Burn(address indexed from, uint256 value);  
  
  
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {  
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;  
        name = tokenName;  
        symbol = tokenSymbol;  
    }  
  
  
    function _transfer(address _from, address _to, uint _value) internal {  
        require(_to != 0x0);  
        require(balanceOf[_from] >= _value);  
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        uint previousBalances = balanceOf[_from] + balanceOf[_to];  
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        Transfer(_from, _to, _value);  
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);  
    }  
  
    function transfer(address _to, uint256 _value) public returns (bool) {  
        _transfer(msg.sender, _to, _value);  
        return true;  
    }  
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {  
        require(_value <= allowance[_from][msg.sender]);     // Check allowance  
        allowance[_from][msg.sender] -= _value;  
        _transfer(_from, _to, _value);  
        return true;  
    }  
  
    function approve(address _spender, uint256 _value) public  
        returns (bool success) {  
        allowance[msg.sender][_spender] = _value;  
        return true;  
    }  
  
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {  
        tokenRecipient spender = tokenRecipient(_spender);  
        if (approve(_spender, _value)) {  
            spender.receiveApproval(msg.sender, _value, this, _extraData);  
            return true;  
        }  
    }  
  
    function burn(uint256 _value) public returns (bool success) {  
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] -= _value;  
        totalSupply -= _value;  
        Burn(msg.sender, _value);  
        return true;  
    }  
  
    function burnFrom(address _from, uint256 _value) public returns (bool success) {  
        require(balanceOf[_from] >= _value);  
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] -= _value;  
        allowance[_from][msg.sender] -= _value;  
        totalSupply -= _value;  
        Burn(_from, _value);  
        return true;  
        }
    }