/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

contract Token{
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner,address _spender) public view returns (uint256 remaining);
    function transfer(address _to,uint256 _value) public returns (bool success);
    function approve(address _spender,uint256 _value) public returns(bool success);
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}
contract StandardToken is Token{
    function balanceOf(address _owner)public view returns(uint256 balance){
        return balances[_owner];
    }
    function allowance(address _owner,address _spender) public view returns(uint256 remaining){
        return allowed[_owner][_spender];
    }
    function transfer(address _to,uint256 _value)public returns(bool success){
        
        require(balances[msg.sender]>=_value);
        balances[msg.sender]-=_value;
        balances[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function approve(address _spender,uint256 _value)public returns(bool success)
    {
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success){
        require(balances[_from]>=_value&&allowed[_from][msg.sender]>=_value);
        balances[_to]+=_value;
        balances[_from]-=_value;
        allowed[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;
        
    }
    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256))allowed;
}
contract DToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    
    function DARkToken() public{
        balances[msg.sender]=100000000000000000000000;// 初始token数量给予消息发送者
        totalSupply=100000000000000000000000;//设置初始总量
        name="Darkhorsetoken";   //全称
        decimals=8;     //小数位数
        symbol="dos";  //token 简称
    }
    
}