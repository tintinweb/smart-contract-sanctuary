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

contract Ownable {
  address public owner;
  address public manager;
  address public behalfer;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event SetManager(address indexed _manager);

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyManager() {
      require(msg.sender == manager);
      _;
  }
  
  modifier onlyBehalfer() {
      require(msg.sender == behalfer);
      _;
  }
  
  function setManager(address _manager)public onlyOwner returns (bool) {
      manager = _manager;
      return true;
  }
  
  function setBehalfer(address _behalfer)public onlyOwner returns (bool) {
      behalfer = _behalfer;
      return true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BasicBF is Pausable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public balances;
    // match -> team -> amount
    mapping (uint256 => mapping (uint256 => uint256)) public betMatchBalances;
    // match -> team -> user -> amount
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public betMatchRecords;

    event Withdraw(address indexed user, uint256 indexed amount);
    event WithdrawOwner(address indexed user, uint256 indexed amount);
    event Issue(address indexed user, uint256 indexed amount);
    event BetMatch(address indexed user, uint256 indexed matchNo, uint256 indexed teamNo, uint256 amount);
    event BehalfBet(address indexed user, uint256 indexed matchNo, uint256 indexed teamNo, uint256 amount);
}

contract BF is BasicBF {
    constructor () public {}
    
    function betMatch(uint256 _matchNo, uint256 _teamNo) public whenNotPaused payable returns (bool) {
        uint256 amount = msg.value;
        betMatchRecords[_matchNo][_teamNo][msg.sender] = betMatchRecords[_matchNo][_teamNo][msg.sender].add(amount);
        betMatchBalances[_matchNo][_teamNo] = betMatchBalances[_matchNo][_teamNo].add(amount);
        balances[this] = balances[this].add(amount);
        emit BetMatch(msg.sender, _matchNo, _teamNo, amount);
        return true;
    }
    
    function behalfBet(address _user, uint256 _matchNo, uint256 _teamNo) public whenNotPaused onlyBehalfer payable returns (bool) {
        uint256 amount = msg.value;
        betMatchRecords[_matchNo][_teamNo][_user] = betMatchRecords[_matchNo][_teamNo][_user].add(amount);
        betMatchBalances[_matchNo][_teamNo] = betMatchBalances[_matchNo][_teamNo].add(amount);
        balances[this] = balances[this].add(amount);
        emit BehalfBet(_user, _matchNo, _teamNo, amount);
        return true;
    }
    
    function issue(address[] _addrLst, uint256[] _amtLst) public whenNotPaused onlyManager returns (bool) {
        require(_addrLst.length == _amtLst.length);
        for (uint i=0; i<_addrLst.length; i++) {
            balances[_addrLst[i]] = balances[_addrLst[i]].add(_amtLst[i]);
            balances[this] = balances[this].sub(_amtLst[i]);
            emit Issue(_addrLst[i], _amtLst[i]);
        }
        return true;
    }
    
    function withdraw(uint256 _value) public whenNotPaused returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        msg.sender.transfer(_value);
        emit Withdraw(msg.sender, _value);
        return true;
    }
    
    function withdrawOwner(uint256 _value) public onlyManager returns (bool) {
        require(_value <= balances[this]);
        balances[this] = balances[this].sub(_value);
        msg.sender.transfer(_value);
        emit WithdrawOwner(msg.sender, _value);
        return true;
    }
    
    function () public payable {}
}