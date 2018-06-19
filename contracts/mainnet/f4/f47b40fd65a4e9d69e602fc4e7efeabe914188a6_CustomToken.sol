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

contract ICOToken is BaseToken {
    // 1 ether = icoRatio token
    uint256 public icoRatio;
    uint256 public icoBegintime;
    uint256 public icoEndtime;
    address public icoSender;
    address public icoHolder;

    event ICO(address indexed from, uint256 indexed value, uint256 tokenValue);
    event Withdraw(address indexed from, address indexed holder, uint256 value);

    function ico() public payable {
        require(now >= icoBegintime && now <= icoEndtime);
        uint256 tokenValue = (msg.value * icoRatio * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        if (tokenValue == 0 || balanceOf[icoSender] < tokenValue) {
            revert();
        }
        _transfer(icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
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

contract CustomToken is BaseToken, BurnToken, ICOToken, LockToken {
    function CustomToken() public {
        totalSupply = 300000000000000000000000000;
        name = &#39;Biwanpro&#39;;
        symbol = &#39;BW&#39;;
        decimals = 18;
        balanceOf[0xc50a3762ec6e21d43346441561519878ae2200d7] = totalSupply;
        Transfer(address(0), 0xc50a3762ec6e21d43346441561519878ae2200d7, totalSupply);

        icoRatio = 6000;
        icoBegintime = 1520346600;
        icoEndtime = 1528295400;
        icoSender = 0x6ba6aa2d828e3656e5c05cccacf85bffa9715f62;
        icoHolder = 0xc50a3762ec6e21d43346441561519878ae2200d7;

        lockedAddresses[0x71b0db63d55ff3be82b1aa5e6d116ab794f135ad] = LockMeta({amount: 30000000000000000000000000, endtime: 1551882600});
    }

    function() public payable {
        ico();
    }
}