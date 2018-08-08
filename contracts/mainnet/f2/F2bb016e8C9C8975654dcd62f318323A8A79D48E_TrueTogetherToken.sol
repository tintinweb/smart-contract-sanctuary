pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TrueTogetherToken {

    string public constant name = "TRUE Together Token";
    string public constant symbol = "TTR";
    uint256 public constant decimals = 18;
    uint256 _totalSupply = 100000000 * 10 ** decimals;
    address public founder = 0x0;
    uint256 public voteEndTime;
    uint256 airdropNum = 1 ether;
    uint256 public distributed = 0;

    mapping (address => bool) touched;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public frozen;
    mapping (address => uint256) public totalVotes;
	
    mapping (address => mapping (address => uint256)) public votingInfo;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Vote(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public { 
        founder = msg.sender;
        voteEndTime = 1534348800;
    }

    function totalSupply() view public returns (uint256 supply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public returns (uint256 balance) {
        if (!touched[_owner] && SafeMath.add(distributed, airdropNum) < _totalSupply && now < voteEndTime) {
            touched[_owner] = true;
            distributed = SafeMath.add(distributed, airdropNum);
            balances[_owner] = SafeMath.add(balances[_owner], airdropNum);
            emit Transfer(this, _owner, airdropNum);
        }
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_to != 0x0);

        if (now > voteEndTime) {
            require((balances[msg.sender] >= _value));
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;	 
        } else {
            require(balances[msg.sender] >= SafeMath.add(frozen[msg.sender], _value));
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;	 
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != 0x0);

        if (now > voteEndTime) {
            require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(_from, _to, _value);
            return true;	 
        } else {
            require(balances[_from] >= SafeMath.add(frozen[_from], _value) && allowed[_from][msg.sender] >= _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(_from, _to, _value);
            return true;	 
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function distribute(address _to, uint256 _amount) public returns (bool success) {
        require(msg.sender == founder);
        require(SafeMath.add(distributed, _amount) <= _totalSupply);

        distributed = SafeMath.add(distributed, _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);
        touched[_to] = true;
        emit Transfer(this, _to, _amount);
        return true;
    }
	
    function distributeMultiple(address[] _tos, uint256[] _values) public returns (bool success) {
        require(msg.sender == founder);
		
        uint256 total = 0;
        uint256 i = 0; 
        for (i = 0; i < _tos.length; i++) {
            total = SafeMath.add(total, _values[i]);
        }

        require(SafeMath.add(distributed, total) < _totalSupply);

        for (i = 0; i < _tos.length; i++) {
            distributed = SafeMath.add(distributed, _values[i]);
            balances[_tos[i]] = SafeMath.add(balances[_tos[i]], _values[i]);
            touched[_tos[i]] = true;
            emit Transfer(this, _tos[i], _values[i]);
        }

        return true;
    }

    function vote(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0 && now < voteEndTime);
        require(balances[msg.sender] >= SafeMath.add(frozen[msg.sender], _value));

        frozen[msg.sender] = SafeMath.add(frozen[msg.sender], _value);
        totalVotes[_to] = SafeMath.add(totalVotes[_to], _value);
        votingInfo[_to][msg.sender] = SafeMath.add(votingInfo[_to][msg.sender], _value);
        emit Vote(msg.sender, _to, _value);
        return true;
    }

    function voteAll(address _to) public returns (bool success) {
        require(_to != 0x0 && now < voteEndTime);
        require(balances[msg.sender] > frozen[msg.sender]);
        
        uint256 votesNum = SafeMath.sub(balances[msg.sender], frozen[msg.sender]);
        frozen[msg.sender] = balances[msg.sender];
        totalVotes[_to] = SafeMath.add(totalVotes[_to], votesNum);
        votingInfo[_to][msg.sender] = SafeMath.add(votingInfo[_to][msg.sender], votesNum);
        emit Vote(msg.sender, _to, votesNum);
        return true;
    }
	
    function setEndTime(uint256 _endTime) public {
        require(msg.sender == founder);
        voteEndTime = _endTime;
    }
	
    function ticketsOf(address _owner) view public returns (uint256 tickets) {
        return SafeMath.sub(balances[_owner], frozen[_owner]);
    }

    function changeFounder(address newFounder) public {
        require(msg.sender == founder);

        founder = newFounder;
    }

    function kill() public {
        require(msg.sender == founder);

        selfdestruct(founder);
    }
}