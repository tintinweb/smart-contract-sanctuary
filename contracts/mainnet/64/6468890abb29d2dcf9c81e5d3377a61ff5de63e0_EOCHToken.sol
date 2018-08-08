pragma solidity ^0.4.16;

contract EOCHToken {

    string public name = "Everything On Chain for Health";      //  token name
    string public symbol = "EOCH";           //  token symbol
    uint256 public decimals = 6;            //  token digit
    uint256 constant valueFounder = 16000000000000000;

    mapping (address => uint256) public balanceMap;
    mapping (address => uint256) public frozenOf; // ##
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;
    bool public isMultiply = true;

    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier isMulti {
        assert (isMultiply);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function EOCHToken() {
        owner = msg.sender;
        totalSupply = valueFounder;
        balanceMap[owner] = valueFounder;
        Transfer(0x0, owner, valueFounder);
    }

    function transfer(address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceMap[msg.sender] >= _value);
        require(balanceMap[_to] + _value >= balanceMap[_to]);
        balanceMap[msg.sender] -= _value;
        balanceMap[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferMulti(
        address _to_1,
        address _to_2,
        address _to_3,
        address _to_4,
        address _to_5,
        address _to_6,
        address _to_7,
        address _to_8,
        address _to_9,
        address _to_10,
        uint256 _value) isRunning validAddress isMulti returns (bool success) {

        require(10 * _value > 0 && balanceMap[msg.sender] >= 10 * _value);
        require(balanceMap[_to_1] + _value >= balanceMap[_to_1]) ;
        require(balanceMap[_to_2] + _value >= balanceMap[_to_2]) ;
        require(balanceMap[_to_3] + _value >= balanceMap[_to_3]) ;
        require(balanceMap[_to_4] + _value >= balanceMap[_to_4]) ;
        require(balanceMap[_to_5] + _value >= balanceMap[_to_5]) ;
        require(balanceMap[_to_6] + _value >= balanceMap[_to_6]) ;
        require(balanceMap[_to_7] + _value >= balanceMap[_to_7]) ;
        require(balanceMap[_to_8] + _value >= balanceMap[_to_8]) ;
        require(balanceMap[_to_9] + _value >= balanceMap[_to_9]) ;
        require(balanceMap[_to_10] + _value >= balanceMap[_to_10]) ;

        balanceMap[msg.sender] -= 10 * _value;
        balanceMap[_to_1] += _value;
        balanceMap[_to_2] += _value;
        balanceMap[_to_3] += _value;
        balanceMap[_to_4] += _value;
        balanceMap[_to_5] += _value;
        balanceMap[_to_6] += _value;
        balanceMap[_to_7] += _value;
        balanceMap[_to_8] += _value;
        balanceMap[_to_9] += _value;
        balanceMap[_to_10] += _value;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceMap[_from] >= _value);
        require(balanceMap[_to] + _value >= balanceMap[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceMap[_to] += _value;
        balanceMap[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() isOwner {
        stopped = true;
    }

    function start() isOwner {
        stopped = false;
    }

    function stopMulti() isOwner {
        isMultiply = false;
    }

    function startMulti() isOwner {
        isMultiply = true;
    }

    function setName(string _name) isOwner {
        name = _name;
    }

    function burn(uint256 _value) {
        require(balanceMap[msg.sender] >= _value);
        balanceMap[msg.sender] -= _value;
        balanceMap[0x0] += _value;
        Transfer(msg.sender, 0x0, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // ##

    function balanceOf(address _owner) public constant returns (uint256 balance){
        return balanceMap[_owner] + frozenOf[_owner];
    }

    function frozen(address targetAddress , uint256 value) public isOwner returns (bool success){

        require(balanceMap[targetAddress] >= value); // check has enough

        uint256 count = balanceMap[targetAddress] + frozenOf[targetAddress];

        balanceMap[targetAddress] -= value;
        frozenOf[targetAddress] += value;

        require(count == balanceMap[targetAddress] + frozenOf[targetAddress]);

        return true;
    }

    function unfrozen(address targetAddress, uint256 value) public isOwner returns (bool success){

        require(frozenOf[targetAddress] >= value); // check has enough

        uint256 count = balanceMap[targetAddress] + frozenOf[targetAddress];

        balanceMap[targetAddress] += value;
        frozenOf[targetAddress] -= value;

        require(count == balanceMap[targetAddress] + frozenOf[targetAddress]);

        return true;
    }

    function frozenOf(address targetAddress) public constant returns (uint256 frozen){
        return frozenOf[targetAddress];
    }

    function frozenOf() public constant returns (uint256 frozen){
        return frozenOf[msg.sender];
    }
}