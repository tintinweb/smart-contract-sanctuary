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

contract CustomToken is BaseToken, AirdropToken {
    function CustomToken() public {
        totalSupply = 1000000000000000000000000000;
        name = &#39;PenZiBi&#39;;
        symbol = &#39;PZB&#39;;
        decimals = 18;
        balanceOf[0xed1cbf659d5a8dd9e42c95c54c5f789db8fa4bfc] = totalSupply;
        Transfer(address(0), 0xed1cbf659d5a8dd9e42c95c54c5f789db8fa4bfc, totalSupply);

        airAmount = 8888000000000000000000;
        airBegintime = 1524355200;
        airEndtime = 1526947200;
        airSender = 0xed1cbf659d5a8dd9e42c95c54c5f789db8fa4bfc;
        airLimitCount = 1;
    }

    function() public payable {
        airdrop();
    }
}