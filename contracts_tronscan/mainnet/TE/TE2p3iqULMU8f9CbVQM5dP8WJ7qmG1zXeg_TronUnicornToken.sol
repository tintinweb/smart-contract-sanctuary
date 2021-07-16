//SourceUnit: TUT.sol

pragma solidity >=0.4.23 <0.6.0;

contract TronUnicornToken {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 precision = 100000000;
    address private ownerAddr;
    address private adminAddr;
    uint256 public totalSupply;
    uint256 public totalStaked;

    struct Unicorn {
        uint256 balance;
        uint256 staked;
        uint256 reward;
        uint256 last_withdraw;
    }

    mapping (address => Unicorn) public unicorns;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 initialSupply = 10000000;
    string tokenName = 'Tron Unicorn Token';
    string tokenSymbol = 'TUT';
    constructor() public {
        ownerAddr = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        unicorns[msg.sender].balance = (totalSupply*1/5);
        unicorns[address(this)].balance = (totalSupply*4/5);
        name = tokenName;
        symbol = tokenSymbol;
        totalStaked = 0;
    }

    modifier isOwner() {
        require(msg.sender == ownerAddr);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    function setAdmin(address _newAdmin) external isOwner {
        require(_newAdmin != address(0));
        adminAddr = _newAdmin;
    }

    function balanceOf(address _addr) public view returns(uint256) {
        Unicorn memory uni = unicorns[_addr];
        return uni.balance;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf(_from) >= _value);
        require(balanceOf(_to) + _value >= balanceOf(_to));
        uint previousBalances = balanceOf(_from) + balanceOf(_to);
        unicorns[_from].balance -= _value;
        unicorns[_to].balance += _value;
        emit Transfer(_from, _to, _value);
        require(balanceOf(_from) + balanceOf(_to) == previousBalances);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function earningsOf(address _addr) public view returns(uint256 value){
        Unicorn memory uni = unicorns[_addr];

        uint256 from = uni.last_withdraw;
        uint256 to = uint256(block.timestamp);

        if(from < to) {
            value += uni.staked * (to - from) * 5 / 86400000;
        }

        return value;
    }

    function totalEarningsOf(address _addr) public view returns(uint256 value){
        Unicorn memory uni = unicorns[_addr];

        uint256 from = uni.last_withdraw;
        uint256 to = uint256(block.timestamp);

        if(from < to) {
            value += uni.staked * (to - from) * 5 / 86400000;
        }

        return (uni.reward + value);
    }

    function stake(uint256 _value) public payable returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Not enough tokens");
        unicorns[msg.sender].reward += earningsOf(msg.sender);
        unicorns[msg.sender].last_withdraw = block.timestamp;
        unicorns[msg.sender].balance -= _value;
        unicorns[address(this)].balance += _value;
        unicorns[msg.sender].staked += _value;
        totalStaked += _value;
        return true;
    }

    function claim() public payable returns (bool success) {
        require(totalEarningsOf(msg.sender) > 0, "No earnings to claim");
        unicorns[msg.sender].reward += earningsOf(msg.sender);
        unicorns[msg.sender].last_withdraw = block.timestamp;
        uint256 reward = unicorns[msg.sender].reward;
        if(reward > balanceOf(address(this))){ reward = balanceOf(address(this)); }
        unicorns[msg.sender].reward -= reward;
        unicorns[address(this)].balance -= reward;
        unicorns[msg.sender].balance += reward;
        return true;
    }

    function unstake() public payable returns (bool success){
        uint256 staked = unicorns[msg.sender].staked;
        require(staked > 0, "Nothing staked");
        unicorns[msg.sender].reward += earningsOf(msg.sender);
        if(staked > balanceOf(address(this))){ staked = balanceOf(address(this)); }
        unicorns[msg.sender].staked -= staked;
        unicorns[msg.sender].balance += staked;
        unicorns[address(this)].balance -= staked;
        totalStaked -= staked;
        return true;
    }
}