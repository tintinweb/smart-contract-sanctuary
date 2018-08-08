pragma solidity ^0.4.19;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract AirdropToken is BaseToken, Ownable{
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
            //拒绝转账
            if(block.timestamp < meta.endtime && remain < meta.remain){
                revert();
            }
        }
		//放行
        super._transfer(_from, _to, _value);
    }
}

contract TTest is BaseToken, BurnToken, AirdropToken, LockToken {

    function TTest() public {
        totalSupply = 36000000000000000;
        name = "ABCToken";
        symbol = "ABC";
        decimals = 8;
		
        owner = msg.sender;

        airAmount = 100000000;
        airSender = 0x8888888888888888888888888888888888888888;
        airLimitCount = 1;

  
        balanceOf[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920] = 3600000000000000;
        Transfer(address(0), 0x7F268F51f3017C3dDB9A343C8b5345918D2AB920, 3600000000000000);
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 3600000000000000, endtime: 1528189200}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 3240000000000000, endtime: 1528192800}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 2880000000000000, endtime: 1528196400}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 2520000000000000, endtime: 1528200000}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 2160000000000000, endtime: 1528203600}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 1800000000000000, endtime: 1528207200}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 1440000000000000, endtime: 1528210800}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 1080000000000000, endtime: 1528214400}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 720000000000000, endtime: 1528218000}));
        lockedAddresses[0x7F268F51f3017C3dDB9A343C8b5345918D2AB920].push(LockMeta({remain: 360000000000000, endtime: 1528221600}));


        balanceOf[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3] = 3600000000000000;
        Transfer(address(0), 0xE4CB2A481375E0208580194BD38911eE6c2d3fA3, 3600000000000000);
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 3600000000000000, endtime: 1528189200}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 3240000000000000, endtime: 1528192800}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 2880000000000000, endtime: 1528196400}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 2520000000000000, endtime: 1528200000}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 2160000000000000, endtime: 1528203600}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 1800000000000000, endtime: 1528207200}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 1440000000000000, endtime: 1528210800}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 1080000000000000, endtime: 1528214400}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 720000000000000, endtime: 1528218000}));
        lockedAddresses[0xE4CB2A481375E0208580194BD38911eE6c2d3fA3].push(LockMeta({remain: 360000000000000, endtime: 1528221600}));


        balanceOf[0x6a15b2BeC95243996416F6baBd8f288f7B4a8312] = 3600000000000000;
        Transfer(address(0), 0x6a15b2BeC95243996416F6baBd8f288f7B4a8312, 3600000000000000);


        balanceOf[0x0863f878b6a1d9271CB5b775394Ff8AF2689456f] = 10800000000000000;
        Transfer(address(0), 0x0863f878b6a1d9271CB5b775394Ff8AF2689456f, 10800000000000000);


        balanceOf[0x73149136faFc31E1bA03dC240F5Ad903F2E1aE2e] = 3564000000000000;
        Transfer(address(0), 0x73149136faFc31E1bA03dC240F5Ad903F2E1aE2e, 3564000000000000);
        lockedAddresses[0x73149136faFc31E1bA03dC240F5Ad903F2E1aE2e].push(LockMeta({remain: 1663200000000000, endtime: 1528182000}));
        lockedAddresses[0x73149136faFc31E1bA03dC240F5Ad903F2E1aE2e].push(LockMeta({remain: 1188000000000000, endtime: 1528181400}));


        balanceOf[0xF63ce8e24d18FAF8D5719f192039145D010c7aBd] = 10836000000000000;
        Transfer(address(0), 0xF63ce8e24d18FAF8D5719f192039145D010c7aBd, 10836000000000000);
        lockedAddresses[0xF63ce8e24d18FAF8D5719f192039145D010c7aBd].push(LockMeta({remain: 2167200000000000, endtime: 1528182000}));
    }
    
    function() public {
        airdrop();
    }
}