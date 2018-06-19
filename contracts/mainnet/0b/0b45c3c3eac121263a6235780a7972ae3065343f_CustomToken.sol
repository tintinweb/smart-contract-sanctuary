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

contract CustomToken is BaseToken, ICOToken, LockToken {
    function CustomToken() public {
        totalSupply = 2100000000000000000000000000;
        name = &#39;ekkoblockTokens&#39;;
        symbol = &#39;ebkc&#39;;
        decimals = 18;
        balanceOf[0x1a5e273c23518af490ca89d31c23dadd9f3df3a5] = totalSupply;
        Transfer(address(0), 0x1a5e273c23518af490ca89d31c23dadd9f3df3a5, totalSupply);

        icoRatio = 2000;
        icoBegintime = 1525104000;
        icoEndtime = 1546185600;
        icoSender = 0xce2f76a6b7d3fa0a2e47161536f34db869710b70;
        icoHolder = 0xce2f76a6b7d3fa0a2e47161536f34db869710b70;

        lockedAddresses[0xfb955f286e3366409b6cf1ee858648609c65fc2c] = LockMeta({amount: 630000000000000000000000000, endtime: 1556640000});
    }

    function() public payable {
        ico();
    }
}