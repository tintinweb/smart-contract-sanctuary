pragma solidity ^0.4.19;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BaseToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract BurnToken is BaseToken {
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }
}

contract AirdropToken is BaseToken, Ownable {
    uint256 public airAmount;
    address public airSender;
    uint256 public airLimitCount;

    mapping (address => uint256) public airCountOf;

    event Airdrop(address indexed from, uint256 indexed count, uint256 tokenValue);

    function airdrop() public {
        require(airAmount > 0);
        if (airLimitCount > 0 && airCountOf[msg.sender] >= airLimitCount) {
            revert();
        }
        _transfer(airSender, msg.sender, airAmount);
        airCountOf[msg.sender] = airCountOf[msg.sender].add(1);
        Airdrop(msg.sender, airCountOf[msg.sender], airAmount);
    }

    function changeAirAmount(uint256 newAirAmount) public onlyOwner {
        airAmount = newAirAmount;
    }

    function changeAirLimitCount(uint256 newAirLimitCount) public onlyOwner {
        airLimitCount = newAirLimitCount;
    }
}

contract LockToken is BaseToken {
    struct LockMeta {
        uint256 remain;
        uint256 endtime;
    }
    
    mapping (address => LockMeta[]) public lockedAddresses;

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        uint256 remain = balanceOf[_from].sub(_value);
        uint256 length = lockedAddresses[_from].length;
        for (uint256 i = 0; i < length; i++) {
            LockMeta storage meta = lockedAddresses[_from][i];
            if(block.timestamp < meta.endtime && remain < meta.remain){
                revert();
            }
        }
        super._transfer(_from, _to, _value);
    }
}

contract ADEToken is BaseToken, BurnToken, AirdropToken, LockToken {

    function ADEToken() public {
        totalSupply = 36000000000000000;
        name = "ADE Token";
        symbol = "ADE";
        decimals = 8;
		
        owner = msg.sender;

        airAmount = 100000000;
        airSender = 0x8888888888888888888888888888888888888888;
        airLimitCount = 1;

        //基金会持有
        balanceOf[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7] = 3600000000000000;
        Transfer(address(0), 0xf03A4f01713F38EB7d63C6e691C956E8C56630F7, 3600000000000000);
        //创世块 至 2019/06/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 3600000000000000, endtime: 1559923200}));
        //2019/06/08 00:00:00 至 2019/07/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 3240000000000000, endtime: 1562515200}));
        //2019/07/08 00:00:00 至 2019/08/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 2880000000000000, endtime: 1565193600}));
        //2019/08/08 00:00:00 至 2019/09/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 2520000000000000, endtime: 1567872000}));
        //2019/09/08 00:00:00 至 2019/10/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 2160000000000000, endtime: 1570464000}));
        //2019/10/08 00:00:00 至 2019/11/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 1800000000000000, endtime: 1573142400}));
        //2019/11/08 00:00:00 至 2019/12/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 1440000000000000, endtime: 1575734400}));
        //2019/12/08 00:00:00 至 2020/01/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 1080000000000000, endtime: 1578412800}));
        //2020/01/08 00:00:00 至 2020/02/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 720000000000000, endtime: 1581091200}));
        //2020/02/08 00:00:00 至 2020/03/07 23:59:59
        lockedAddresses[0xf03A4f01713F38EB7d63C6e691C956E8C56630F7].push(LockMeta({remain: 360000000000000, endtime: 1583596800}));
        
        //团队持有
        balanceOf[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20] = 3600000000000000;
        Transfer(address(0), 0x76d2dbf2b1e589ff28EcC9203EA781f490696d20, 3600000000000000);
        //创世块 至 2018/12/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 3600000000000000, endtime: 1544198400}));
        //2018/12/08 00:00:00 至 2019/01/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 3240000000000000, endtime: 1546876800}));
        //2019/01/08 00:00:00 至 2019/02/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 2880000000000000, endtime: 1549555200}));
        //2019/02/08 00:00:00 至 2019/03/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 2520000000000000, endtime: 1551974400}));
        //2019/03/08 00:00:00 至 2019/04/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 2160000000000000, endtime: 1554652800}));
        //2019/04/08 00:00:00 至 2019/05/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 1800000000000000, endtime: 1557244800}));
        //2019/05/08 00:00:00 至 2019/06/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 1440000000000000, endtime: 1559923200}));
        //2019/06/08 00:00:00 至 2019/07/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 1080000000000000, endtime: 1562515200}));
        //2019/07/08 00:00:00 至 2019/08/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 720000000000000, endtime: 1565193600}));
        //2019/08/08 00:00:00 至 2019/09/07 23:59:59
        lockedAddresses[0x76d2dbf2b1e589ff28EcC9203EA781f490696d20].push(LockMeta({remain: 360000000000000, endtime: 1567872000}));

        //市场营销
        balanceOf[0x62d545CD7e67abA36e92c46cfA764c0f1626A9Ae] = 3600000000000000;
        Transfer(address(0), 0x62d545CD7e67abA36e92c46cfA764c0f1626A9Ae, 3600000000000000);

        //激励
        balanceOf[0x8EaA35b0794ebFD412765DFb2Faa770Abae0f36b] = 10800000000000000;
        Transfer(address(0), 0x8EaA35b0794ebFD412765DFb2Faa770Abae0f36b, 10800000000000000);

        //基石轮
        balanceOf[0x8ECeAd3B4c2aD7C4854a42F93A956F5e3CAE9Fd2] = 3564000000000000;
        Transfer(address(0), 0x8ECeAd3B4c2aD7C4854a42F93A956F5e3CAE9Fd2, 3564000000000000);
        //创世块 至 2018/09/07 23:59:59
        lockedAddresses[0x8ECeAd3B4c2aD7C4854a42F93A956F5e3CAE9Fd2].push(LockMeta({remain: 1663200000000000, endtime: 1536336000}));
        //2018/09/08 00:00:00 至 2018/12/07 23:59:59
        lockedAddresses[0x8ECeAd3B4c2aD7C4854a42F93A956F5e3CAE9Fd2].push(LockMeta({remain: 1188000000000000, endtime: 1544198400}));

        //机构轮
        balanceOf[0xC458A9017d796b2b4b76b416f814E1A8Ce82e310] = 10836000000000000;
        Transfer(address(0), 0xC458A9017d796b2b4b76b416f814E1A8Ce82e310, 10836000000000000);
        //创世块 至 2018/09/07 23:59:59
        lockedAddresses[0xC458A9017d796b2b4b76b416f814E1A8Ce82e310].push(LockMeta({remain: 2167200000000000, endtime: 1536336000}));
    }
    
    function() public {
        airdrop();
    }
}