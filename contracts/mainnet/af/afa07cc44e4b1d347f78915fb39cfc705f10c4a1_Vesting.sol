pragma solidity ^0.4.20;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract ERC20 is Owned {
    using SafeMath for uint;

    uint public totalSupply;
    bool public isStarted = false;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    modifier isStartedOnly() {
        require(isStarted);
        _;
    }

    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract Token is ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    function Token(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function start() public only(owner) isNotStartedOnly {
        isStarted = true;
    }

    //================= Crowdsale Only =================
    function mint(address _to, uint _amount) public only(owner) isNotStartedOnly returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) isNotStartedOnly returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }
}

contract TokenWithoutStart is Owned {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function TokenWithoutStart(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint _amount) public only(owner) returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

}



//This contract is used to distribute tokens reserved for Jury.Online team the terms of distirbution are following:
//after the end of ICO tokens are frozen for 6 months and afterwards each months 10% of tokens is unfrozen

contract Vesting {

    //1. Alexander Shevtsov            0x4C67EB86d70354731f11981aeE91d969e3823c39
    //2. Anastasia Bormotova           0x450Eb50Cc83B155cdeA8b6d47Be77970Cf524368
    //3. Artemiy Pirozhkov             0x9CFf3408a1eB46FE1F9de91f932FDCfEC34A568f
    //4. Konstantin Kudryavtsev        0xA14d9fa5B1b46206026eA51A98CeEd182A91a190
    //5. Marina Kobyakova              0x0465f2fA674bF20Fe9484dB70D8570617495b352
    //6. Nikita Alekseev               0x07F8a6Fb0Ad63abBe21e8ef33523D8368618cd10
    //7. Nikolay Prudnikov             0xF29fE8e258b084d40D9cF1dCF02E5CB29837b6D5
    //8. Valeriy Strechen              0x64B557EaED227B841DcEd9f70918cd8f5ca2Bdab
    //9. Igor Lavrenov                 0x05d1e624eaDF70bb7F8A2B11D39A8a5635e5D007
    
    uint public constant interval = 30 days;
    uint public constant distributionStart = 1540994400; //1st of November
    uint public currentStage;
    uint public stageAmount;
    uint public toSendLeft;

    address[] public team;
    Token public token;

    constructor(address[] _team, address _token) {
        token = Token(_token);
        for(uint i=0; i<_team.length; i++) {
            team.push(_team[i]);
        }
    }

    function makePayouts() {
        require(toSendLeft != 0);
        if (now > interval*currentStage + distributionStart) {
			uint balance = stageAmount/team.length;
            for(uint i=0; i<team.length; i++) {
                toSendLeft -= balance;
                require(token.transfer(team[i], balance));
            }
        currentStage+=1;
        }
    }

    function setToSendLeft() {
        require(toSendLeft == 0);
        toSendLeft = token.balanceOf(address(this));
        stageAmount = toSendLeft/10;
    }



}