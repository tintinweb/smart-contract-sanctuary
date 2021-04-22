/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
            
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
            
        }
        uint256 c = a / b;
        return c;
    }
  
}

// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    
    function balanceOf(address _address) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

// Token contract
contract MulanFinanceV2 is ERC20 {
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address public owner;
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    
    /* 合约数据 */
    // Mulan合约地址
    address public mulanV1Address;
    // 总投资量Mulan
    uint256 public totalLocked;
    // 三种投资分别的总锁仓量Mulan
    uint256[3] public lockedAmount = [0, 0, 0];
    // 三种投资类型对应的时间类型
    uint256 private time = 60; // 测试60(一分钟的秒值), 主网2592000(一个月的秒值)
    uint256[3] public lockedTime = [6, 12, 24];
    // 投资的收益有三种, 分别对应10%收益, 30%, 50%
    uint256[3] public lockedReward = [10, 30, 50];

    
    /* 用户数据 */
    // 用户所有的锁仓数据
    struct locked {
        // 锁仓的金额Mulan
        uint256 value;
        // 锁仓的收益Mulan V2
        uint256 reward;
        // 开始时间
        uint256 start;
        // 结束时间
        uint256 end;
        // 是否已提取
        bool flag;
        // 投资的时间类型; 6, 12, 24
        uint256 time;
    }
    mapping(address => locked[]) public userLockeds;
    // 用户的三种投资总量
    mapping(address => uint256[3]) public userLockedAmount;
    
    
    // "Mulan.Finance V2", "$MULAN V2", 18"
    // Mulan合约地址: 0x7dfb72a2aad08c937706f21421b15bfc34cba9ca
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _mulanV1Address) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        mulanV1Address = _mulanV1Address;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero address error");
        require(balances[msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0), "Zero address error");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Mint(address indexed _from, uint256 _value);
    
    // 铸币Mulan V2
    function mint(address _from, uint256 _value) private returns (bool success) {
        require(_from != address(0), "Zero address error");
        balances[address(this)] = SafeMath.add(balances[address(this)], _value);
        totalSupply = SafeMath.add(totalSupply, _value);
        emit Mint(_from, _value);
        return true;
    }
    
    
    // 管理员修饰符
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not owner");
        _;
        
    }
    
    // 设置新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "Zero address error");
        owner = _owner;
        success = true;
    }
    
    // 锁仓投资
    // 参数1: 投资的金额
    // 参数2: 投资的类型; 6, 12, 24
    function lockedInvest(uint256 _value, uint256 _type) public returns (bool success2) {
        require(_value > 0, "Value must gt Zero");
        // 判断投资类型
        uint256 i = 0;
        bool isTime;
        for(; i < lockedTime.length; i++) {
            if(_type == lockedTime[i]) {
                isTime= true;
                break;
            }
        }
        require(isTime, "Type error");
        // 投资的Mulan转入地址
        (bool success, ) = address(mulanV1Address).call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _value)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        // 转入成功后...
        // 收益Mulan V2
        uint256 v2 = _value * lockedReward[i] / 100;
        // 给用户添加一笔投资; 金额, 收益, 开始时间, 结束时间, 是否已提现, 时间类型
        uint256 t = block.timestamp + lockedTime[i] * time;
        locked memory l = locked(_value, v2, block.timestamp, t, false, lockedTime[i]);
        userLockeds[msg.sender].push(l);
        // 总发行量增加Mulan V2, 总投资额度增加Mulan V1, 对应的池子总量增加Mulan V1, 用户对应的总池子增加Mulan V1
        mint(msg.sender, v2);
        totalLocked = SafeMath.add(totalLocked, _value);
        lockedAmount[i] = SafeMath.add(lockedAmount[i], _value);
        userLockedAmount[msg.sender][i] = SafeMath.add(userLockedAmount[msg.sender][i], _value);
        success2 = true;
    }
    
    // 提取锁仓
    // 参数1: 提取某个锁仓
    function fetchLocked(uint256 _index) public returns (bool success2) {
        // 判断这个提取是否满足提取条件
        locked memory l = userLockeds[msg.sender][_index];
        require(l.flag == false, "Already fetch");
        require(l.end < block.timestamp, "Time is not");
        uint256 v1 = l.value;
        uint256 v2 = l.reward;
        // 修改成已经提取
        userLockeds[msg.sender][_index].flag = true;
        // 给到用户Mulan V1
        (bool success, ) = address(mulanV1Address).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, v1)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        // 给到用户Mulan V2
        balances[address(this)] = SafeMath.sub(balances[address(this)], v2);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], v2);
        emit Transfer(address(this), msg.sender, v2);

        // 总投资额度Mulan V1, 对应的池子总量Mulan V1, 用户对应的总池子Mulan V1; 都将减少
        totalLocked = SafeMath.sub(totalLocked, v1);
        uint256 i = 0;
        for(; i < lockedTime.length; i++) {
            if(l.time == lockedTime[i]) {
                break;
            }
        }
        lockedAmount[i] = SafeMath.sub(lockedAmount[i], v1);
        userLockedAmount[msg.sender][i] = SafeMath.sub(userLockedAmount[msg.sender][i], v1);
        success2 = true;
    }
    
    // 获取三个池子分别的总锁仓量
    function getLockedAmount() public view returns (uint[] memory x) {
        uint256 a = lockedAmount.length;
        x = new uint[](a);
        for(uint256 i = 0; i < a; i++) {
            x[i] = lockedAmount[i];
        }
    }
    
    // 获取用户所有的投资
    // 参数1: 用户的地址
    // mapping(address => locked[]) public userLockeds;
    function getUserLockeds(address _address) public view returns (locked[] memory x) {
        uint256 a = userLockeds[_address].length;
        x = new locked[](a);
        for(uint256 i = 0; i < a; i++) {
            x[i] = userLockeds[_address][i];
        }
    }
    
    // 获取用户三个池子分别的总锁仓量
    // 参数1: 用户的地址
    // mapping(address => uint256[3]) public userLockedAmount;
    function getUserLockedAmount(address _address) public view returns (uint[] memory x) {
        uint256 a = userLockedAmount[_address].length;
        x = new uint[](a);
        for(uint256 i = 0; i < a; i++) {
            x[i] = userLockedAmount[_address][i];
        }
    }
    
}