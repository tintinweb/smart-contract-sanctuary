pragma solidity ^0.4.16;



contract zhaoToken {
    string public name = "zhao Token";
    string public symbol = "zhao";
    uint8 public decimals = 5;  // 18 是建议的默认值
    uint256 public totalSupply = 1000 * (10**(uint256(decimals)));

    mapping (address => uint256) public balanceOf;  // 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);




    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];//记录发送者和接受者交易前的余额
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }//由于该函数是internal类型，其需要接受transfer函数返回的参数

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }    //通过外部输入参数给_transfer函数

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }//先判断调用该合约用户的账户转的币数量是否小于本身的余额，再把合约账户里面减去相应的钱，最后把数据传入_transfer当中

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }//输入用户可以花费的代币数量


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
}