pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract BurnToken is BaseToken {
    event Burn(address indexed from, uint256 value);

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

contract LockToken is BaseToken {
    struct LockMeta {
        uint256 amount;
        uint256 endtime;
    }
    
    mapping (address => LockMeta) public lockedAddresses;

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        LockMeta storage meta = lockedAddresses[_from];
        require(now >= meta.endtime || meta.amount <= balanceOf[_from] - _value);
        super._transfer(_from, _to, _value);
    }
}

contract CustomToken is BaseToken, BurnToken, LockToken {
    function CustomToken() public {
        totalSupply = 1000000000000000000000000000;
        name = &#39;BtonCoin&#39;;
        symbol = &#39;TON&#39;;
        decimals = 18;
        balanceOf[0xddf091e5f385aba4a2054ef1235a12908a0a8943] = totalSupply;
        Transfer(address(0), 0xddf091e5f385aba4a2054ef1235a12908a0a8943, totalSupply);

        lockedAddresses[0xe2b012b781c6d75e12f3ac601f087bbfec2cbc48] = LockMeta({amount: 30000000000000000000000000, endtime: 1582992000});
        lockedAddresses[0xa591b18831e6967dd2a12d1e71f3be70e24d2bbf] = LockMeta({amount: 60000000000000000000000000, endtime: 1614528000});
        lockedAddresses[0x542b823064d62904fac2f616d30a3423d02f6168] = LockMeta({amount: 60000000000000000000000000, endtime: 1646064000});
        lockedAddresses[0x44c73469fb6fc14529536b961d7eacdf1bbf4a57] = LockMeta({amount: 75000000000000000000000000, endtime: 1677600000});
        lockedAddresses[0x96714f5a4f09455bde78fbb143a9da41ef43cd9a] = LockMeta({amount: 75000000000000000000000000, endtime: 1709222400});
    }
}