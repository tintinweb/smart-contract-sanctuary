pragma solidity ^0.4.24;

contract EIP20Interface{
    //获取_owner地址的余额
    function balanceOf(address _owner) public view returns (uint256 balance);
    //转账:从自己账户向_to地址转入_value个Token
    function transfer(address _to, uint256 _value)public returns (bool success);
    //转账:从_from向_to转_value个Token
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    //允许_spender从自己(调用方)账户转走_value个Token
    function approve(address _spender, uint256 _value) returns (bool success);
    //自己_owner查询__spender地址可以转走自己多少个Token
    function allowance(address _owner, address _spender) view returns (uint256 remaining);
    //转账的时候必须要调用的时间，比如Tranfer,TransferFrom
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //成功执行approve方法后调用的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract YJCToken is EIP20Interface {
    //1.获取token名字，比如"YaJing Coin"
    string public name;
     //2.获取Token简称,比如"YJC"
    string public symbol;
    //3.获取小数位，比如以太坊的decimals为18
    uint8 public decimals;
     //4.获取token发布的总量，比如HT 5亿
    uint256 public totalSupply;

    mapping(address=>uint256) balances ;
    mapping(address=>mapping(address=>uint256)) allowances;
    function YJCToken(string _name,string _symbol, uint8 _decimals,uint256 _totalSupply) public{       
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balances[msg.sender] = _totalSupply;
    }

    //获取_owner地址的余额
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    //转账:从自己账户向_to地址转入_value个Token
    function transfer(address _to, uint256 _value)public  returns (bool success){
        require(_value >0 && balances[_to] + _value > balances[_to] && balances[msg.sender] > _value);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        Transfer(msg.sender, _to,_value);

        return true;
    }

    //转账:从_from向_to转_value个Token
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        uint256 allowan = allowances[_from][_to];
        require(allowan > _value && balances[_from] >= _value && _to == msg.sender && balances[_to] + _value>balances[_to]);
        allowances[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from,_to,_value);
        return true;
    }
    //允许_spender从自己(调用方)账户转走_value个Token
    function approve(address _spender, uint256 _value) returns (bool success){
        require(_value >0 && balances[msg.sender] > _value);
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender,_spender,_value);
                return true;
    }
    //自己_owner查询_spender地址可以转走自己多少个Token
    function allowance(address _owner, address _spender) view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }

}