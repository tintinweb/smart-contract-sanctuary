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

contract AirdropToken is BaseToken {
    uint256 public airAmount;
    uint256 public airBegintime;
    uint256 public airEndtime;
    address public airSender;
    uint32 public airLimitCount;

    mapping (address => uint32) public airCountOf;

    event Airdrop(address indexed from, uint32 indexed count, uint256 tokenValue);

    function airdrop() public payable {
        require(now >= airBegintime && now <= airEndtime);
        require(msg.value == 0);
        if (airLimitCount > 0 && airCountOf[msg.sender] >= airLimitCount) {
            revert();
        }
        _transfer(airSender, msg.sender, airAmount);
        airCountOf[msg.sender] += 1;
        Airdrop(msg.sender, airCountOf[msg.sender], airAmount);
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

contract CustomToken is BaseToken, BurnToken, AirdropToken, LockToken {
    function CustomToken() public {
        totalSupply = 100000000000000000;
        name = &#39;BitValue&#39;;
        symbol = &#39;BV&#39;;
        decimals = 8;
        balanceOf[0xf35e3344cbb5ab8da4294b741f7e378212dc0e89] = totalSupply;
        Transfer(address(0), 0xf35e3344cbb5ab8da4294b741f7e378212dc0e89, totalSupply);

        airAmount = 1000000000;
        airBegintime = 1546149600;
        airEndtime = 2177388000;
        airSender = 0x8efc62dbf088c556503470ddbea0b797d66cf45d;
        airLimitCount = 1;

        lockedAddresses[0x51d013c61026c2819ee7880164c5226654b2092d] = LockMeta({amount: 9000000000000000, endtime: 1551402000});
        lockedAddresses[0x8efc62dbf088c556503470ddbea0b797d66cf45d] = LockMeta({amount: 9000000000000000, endtime: 1559350800});
        lockedAddresses[0x061aa72cbe0e4c02bc53cd7b4edd789f9465344e] = LockMeta({amount: 9000000000000000, endtime: 1575162000});
        lockedAddresses[0x0eb9f24e3b5a0684ee04a23cc90adfce067c4cf5] = LockMeta({amount: 9000000000000000, endtime: 1590973200});
        lockedAddresses[0x92c5c5d223607028e519e694a16999b004e17d49] = LockMeta({amount: 9000000000000000, endtime: 1606784400});
        lockedAddresses[0xcb9ee43e4e2096be331c5be13d0a9a38cac955dc] = LockMeta({amount: 9000000000000000, endtime: 1622509200});
        lockedAddresses[0xba14daefca3575d5b2f0238bf04d4ba2e0bef7ac] = LockMeta({amount: 9000000000000000, endtime: 1638320400});
        lockedAddresses[0x79e8086c0345448b6613e5700b9cae8e05d748a8] = LockMeta({amount: 9000000000000000, endtime: 1654045200});
        lockedAddresses[0x7e1061345337f8cb320d2e08ca6de757d2382c17] = LockMeta({amount: 9000000000000000, endtime: 1669856400});
        lockedAddresses[0xc83ae4bbd5186fcedee714cc841889a835cb97c5] = LockMeta({amount: 9000000000000000, endtime: 1685581200});
    }

    function() public payable {
        airdrop();
    }
}