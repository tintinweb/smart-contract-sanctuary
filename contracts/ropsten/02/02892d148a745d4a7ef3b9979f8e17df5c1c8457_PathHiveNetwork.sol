pragma solidity ^0.4.25;

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);
    uint256 c = _a / _b;

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract Role is Ownable {

    struct AdminGroup {
        mapping (address => bool) administers;
        mapping (address => uint) administerListIndex;
        address[] administerList;
        mapping (address => bool) pausers;
        mapping (address => uint) pauserListIndex;
        address[] pauserList;
    }

    AdminGroup private adminGroup;

    modifier administerAndAbove() {
        require(isAdminister(msg.sender) || msg.sender == owner);
        _;
    }

    modifier pauserAndAbove() {
        require(isPauser(msg.sender) || isAdminister(msg.sender) || msg.sender == owner);
        _;
    }

    function isAdminister(address account) public view returns (bool) {
        return adminGroup.administers[account];
    }

    function addAdminister(address account) public onlyOwner {
        require(!isAdminister(account));
        require(!isPauser(account));
        if (account == owner) { revert(); }
        adminGroup.administers[account] = true;
        adminGroup.administerListIndex[account] = adminGroup.administerList.push(account)-1;
        emit AdministerAdded(account);
    }

    function removeAdminister(address account) public onlyOwner {
        require(isAdminister(account));
        require(!isPauser(account));
        if (adminGroup.administerListIndex[account]==0){
            require(adminGroup.administerList[0] == account);
        }

        if (adminGroup.administerListIndex[account] >= adminGroup.administerList.length) return;

        adminGroup.administers[account] = false;

        for (uint i = adminGroup.administerListIndex[account]; i<adminGroup.administerList.length-1; i++){
            adminGroup.administerList[i] = adminGroup.administerList[i+1];
            adminGroup.administerListIndex[adminGroup.administerList[i+1]] = adminGroup.administerListIndex[adminGroup.administerList[i+1]]-1;
        }
        delete adminGroup.administerList[adminGroup.administerList.length-1];
        delete adminGroup.administerListIndex[account];
        adminGroup.administerList.length--;

        emit AdministerRemoved(account);
    }

    function getAdministerList() view public returns(address[]) {
        return adminGroup.administerList;
    }

    function isPauser(address account) public view returns (bool) {
        return adminGroup.pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        require(!isAdminister(account));
        require(!isPauser(account));
        require(account != owner);
        adminGroup.pausers[account] = true;
        adminGroup.pauserListIndex[account] = adminGroup.pauserList.push(account)-1;
        emit PauserAdded(account);
    }

    function removePauser(address account) public onlyOwner{
        require(isPauser(account));
        require(!isAdminister(account));
        if (adminGroup.pauserListIndex[account]==0){
            require(adminGroup.pauserList[0] == account);
        }

        if (adminGroup.pauserListIndex[account] >= adminGroup.pauserList.length) return;

        adminGroup.pausers[account] = false;

        for (uint i = adminGroup.pauserListIndex[account]; i<adminGroup.pauserList.length-1; i++){
            adminGroup.pauserList[i] = adminGroup.pauserList[i+1];
            adminGroup.pauserListIndex[adminGroup.pauserList[i+1]] = adminGroup.pauserListIndex[adminGroup.pauserList[i+1]]-1;
        }
        delete adminGroup.pauserList[adminGroup.pauserList.length-1];
        delete adminGroup.pauserListIndex[account];
        adminGroup.pauserList.length--;

        emit PauserRemoved(account);
    }

    function getPauserList() view public returns(address[]) {
        return adminGroup.pauserList;
    }

    event AdministerAdded(address indexed account);
    event AdministerRemoved(address indexed account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
}

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PathHiveNetwork is Role, ERC20 {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => bool) private _frozenAccount;
    mapping (address => uint) private _frozenAccountIndex;
    address[] private _frozenAccountList;
    uint256 private _totalSupply;

    bool private _paused = false;

    constructor() public {}

    function paused() public view returns(bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        if(msg.sender==owner){
            _;
        }else{
            require(!_paused);
            _;
        }
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public pauserAndAbove {
        require(!_paused);
        _paused = true;
        emit Paused();
    }

    function unpause() public pauserAndAbove {
        require(_paused);
        _paused = false;
        emit UnPaused();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public constant returns (uint256) {
        return _balances[who];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(!_frozenAccount[msg.sender]);
        require(!_frozenAccount[to]);
        require(msg.sender != to);
        require(to != address(0));
        require(amount > 0);

        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(!_frozenAccount[from]);
        require(!_frozenAccount[to]);
        require(to != address(0));
        require(amount > 0);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(amount);
        _transfer(from, to, amount);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool){
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool){
        require(spender != address(0));
        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function burn(address to, uint256 amount) onlyOwner public returns (bool){
        require(amount > 0);
        require(to != address(0));
        require(amount <= _balances[to]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[to] = _balances[to].sub(amount);
        emit Transfer(to, address(0), amount);
        return true;
    }

    function mint(address to, uint256 amount) public administerAndAbove returns (bool){
        require(to != address(0));
        require(amount > 0);
        require(_totalSupply.add(amount) <= 3500000000  * (10 ** uint256(18)));

        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function freezeAccount(address target, bool freeze) pauserAndAbove public {
        require(target!=owner);
        require(target!=msg.sender);
        if(freeze){
            require(!isFrozenAccount(target));
            _frozenAccount[target] = freeze;
            _frozenAccountIndex[target] = _frozenAccountList.push(target) - 1;
            emit FrozenAccount(target, freeze);
        }else{
            require(isFrozenAccount(target));
            if (_frozenAccountIndex[target]==0){
                require(_frozenAccountList[0] == target);
            }
            for (uint i = _frozenAccountIndex[target]; i<_frozenAccountList.length-1; i++){
                _frozenAccountList[i] = _frozenAccountList[i+1];
                _frozenAccountIndex[_frozenAccountList[i+1]] = _frozenAccountIndex[_frozenAccountList[i+1]]-1;
            }
            delete _frozenAccountList[_frozenAccountList.length-1];
            delete _frozenAccountIndex[target];
            delete _frozenAccount[target];
            _frozenAccountList.length--;
            emit UnFrozenAccount(target, freeze);
        }
    }

    function isFrozenAccount(address who) view public returns(bool) {
        return _frozenAccount[who];
    }

    function getFrozenAccountList() view public returns(address[]) {
        return _frozenAccountList;
    }

    event Approval(address indexed tokenOwner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Paused();
    event UnPaused();
    event FrozenAccount(address target, bool frozen);
    event UnFrozenAccount(address target, bool frozen);
}