pragma solidity ^0.4.24;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public
    restricted
  {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public
    restricted
  {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) public
        onlyOwner
    {
        owner = _newOwner;
    }
}

contract Redeemer is Owner {
    address public redeemer;
    bool public _isRedeemActive;

    constructor(address _redeemer) public {
        redeemer = _redeemer;
    }

    modifier onlyRedeemer() {
        require(msg.sender != redeemer);
        _;
    }

    modifier isRedeemActive() {
        require(_isRedeemActive);
        _;
    }

    function changeRedeemer(address _newRedeemer) public
        onlyOwner
    {
        redeemer = _newRedeemer;
    }

    function toggleRedeemActive() public
        onlyOwner
    {
        _isRedeemActive = !_isRedeemActive;
    }
}

contract PTSBContract is Owner {
    address internal PTSbAddress;

    constructor(address _PTSbAddress) public {
        PTSbAddress = _PTSbAddress;
    }

    modifier onlyPTSBContract() {
        require(msg.sender != PTSbAddress);
        _;
    }

    function changePTSBAddress(address _newPTSBAddress) public
        onlyOwner
    {
        PTSbAddress = _newPTSBAddress;
    }
}

contract PTSEvent {
    event Redeem(address indexed _redeemer, address indexed _user, uint256 _value);
    event BurnToken(address indexed _user, uint256 _amount);
    event Refund(address indexed _user, uint256 _amount);
    event RevokeToken(address indexed _user, uint256 _amount);
}


contract PTSInterface is Owner, Redeemer, PTSBContract, PTSEvent {
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalRemainingToken;
    mapping(address => uint256) public balanceOf;
}

contract PTS is PTSInterface {

    constructor(address _redeemerAddr, address _PTSbAddr, uint _totalSupply) public
        Redeemer(_redeemerAddr)
        PTSBContract(_PTSbAddr)
    {
        name = "PTS";
        decimals = 0;
        totalSupply = _totalSupply;
        totalRemainingToken = _totalSupply;
    }

    function redeem(address _user, uint256 _amount)
        public
        isRedeemActive
        onlyRedeemer
        returns (bool)
    {
        uint256 _balanceOf = balanceOf[_user];
        if (totalRemainingToken < _amount) return false;
        if (_balanceOf + _amount < _balanceOf) return false;
        totalRemainingToken -= _amount;
        balanceOf[_user] += _amount;
        emit Redeem(msg.sender, _user, _amount);
        return true;
    }

    function burnToken(address _user)
        public
        onlyPTSBContract
        returns (bool)
    {
        uint256 _balanceOf = balanceOf[_user];
        if (_balanceOf <= 0) return false;
        balanceOf[_user] = 0;
        emit BurnToken(_user, _balanceOf);
        return true;
    }

    function refund(address _user)
        public
        onlyOwner
        returns (bool)
    {
        uint256 _balanceOf = balanceOf[_user];
        if (_balanceOf <= 0) return false;
        balanceOf[_user] = 0;
        emit Refund(_user, _balanceOf);
        return true;
    }

    function revokeToken(address _user, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        if (balanceOf[_user] < _amount) return false;
        if (totalRemainingToken + _amount < totalRemainingToken) return false;
        balanceOf[_user] -= _amount;
        totalRemainingToken += _amount;
        emit RevokeToken(_user, _amount);
        return true;
    }

    function() public{
        revert();
    }
}