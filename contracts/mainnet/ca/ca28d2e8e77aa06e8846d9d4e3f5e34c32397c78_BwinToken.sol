pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

        /* tkn variable is analogue of msg variable of Ether transaction
        *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
        *  tkn.value the number of tokens that were sent   (analogue of msg.value)
        *  tkn.data is data of token transaction   (analogue of msg.data)
        *  tkn.sig is 4 bytes signature of function
        *  if data of token transaction is a function execution
        */
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CrowdsaleFront is Ownable{
    //Crowdsale public provider;
    using SafeMath for uint256;
    mapping (address => uint256) internal userAmounts;
    mapping (address => uint256) internal rewardPayed;
    BwinCommons internal commons;
    function setCommons(address _addr) public onlyOwner {
        commons = BwinCommons(_addr);
    }
    // fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender, 0, 999);
    }

    // low level token purchase function
    function buyTokens(address beneficiary, address _parent, uint256 _top) public payable returns(bool){
      bool ret;
      uint256 tokens;
      (ret, tokens) = Crowdsale(commons.get("Crowdsale")).buyTokens.value(msg.value)(beneficiary, beneficiary, _parent, _top);
      userAmounts[beneficiary] = userAmounts[beneficiary].add(tokens);
      require(ret);
    }

    function getTokensFromBuy(address _addr) public view returns (uint256){
      return userAmounts[_addr];
    }
    function rewardPayedOf(address _user) public view returns (uint256) {
      return rewardPayed[_user];
    }
    function rewardPay(address _user, uint256 amount) public {
      require(msg.sender == commons.get("Crowdsale"));
      rewardPayed[_user] = rewardPayed[_user].add(amount);
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool){
        return Crowdsale(commons.get("Crowdsale")).hasEnded();
    }

}

contract InterestHolder is Ownable{
  using SafeMath for uint256;
  BwinCommons internal commons;
  function setCommons(address _addr) public onlyOwner {
      commons = BwinCommons(_addr);
  }
  bool public locked = true;
  event ReceiveBalanceUpdate(address _addr,address _user);
  event ReceiveBalanceUpdateUserType(address _addr,address _user,uint256 _type);
  function receiveBalanceUpdate(address _user) external returns (bool) {
    emit ReceiveBalanceUpdate(msg.sender, _user);
    Token token = Token(commons.get("Token"));
    User user = User(commons.get("User"));
    if (msg.sender == address(token)){
      uint256 _type;
      (,,_type) = user.getUserInfo(_user);
      emit ReceiveBalanceUpdateUserType(msg.sender, _user, _type);
      if (_type == 0){
          return true;
      }
      process(_user,_type);
      return true;
    }
    return false;
  }
  event ProcessLx(address _addr,address _user, uint256 _type,uint256 lastBalance, uint256 iAmount, uint256 lastTime);
  function process(address _user, uint256 _type) internal{
    Token token = Token(commons.get("Token"));
    User user = User(commons.get("User"));
    uint256 _value = compute(_user, _type);
    uint256 balance = token.balanceOf(_user);
    user.setInterestor(_user,balance.add(_value),now);
    if(_value > 0){
      token.mintForWorker(_user,_value);
      emit ProcessLx(msg.sender, _user, _type, balance, _value, now);
    }
  }
  event GetLx(address _addr,address _user,uint256 _type);

  function compute(address _user, uint256 _type) internal view returns (uint256) {
    User user = User(commons.get("User"));
    uint256 lastBalance = 0;
    uint256 lastTime = 0;
    bool exist;
    (lastBalance,lastTime,exist) = user.getInterestor(_user);
    uint256 _value = 0;
    if (exist && lastTime > 0){
        uint256 times = now.sub(lastTime);
        if (_type == 1){
            _value = lastBalance.div(10000).mul(5).div(86400).mul(times);
        }else if(_type == 2){
            _value = lastBalance.div(10000).mul(8).div(86400).mul(times);
        }
    }
    return _value;
  }
  function getLx() external returns (uint256) {
    User user = User(commons.get("User"));
    uint256 _type;
    (,,_type) = user.getUserInfo(msg.sender);
    emit GetLx(msg.sender, msg.sender, _type);
    if (_type == 0){
        return 0;
    }
    return compute(msg.sender, _type);
  }
}

contract TokenHolder is Ownable{
  using SafeMath for uint256;

  BwinCommons internal commons;
  function setCommons(address _addr) public onlyOwner {
      commons = BwinCommons(_addr);
  }
  bool locked = true;
  mapping (address => uint256) lockedAmount;
  event ReceiveLockedAmount(address _addr, address _user, uint256 _amount);
  function receiveLockedAmount(address _user, uint256 _amount) external returns (bool) {
    address cds = commons.get("Crowdsale");
    if (msg.sender == address(cds)){
      lockedAmount[_user] = lockedAmount[_user].add(_amount);
      emit ReceiveLockedAmount(msg.sender, _user, _amount);
      return true;
    }
    return false;
  }

  function balanceOf(address _user) public view returns (uint256) {
    return lockedAmount[_user];
  }
  function balance() public view returns (uint256) {
    return lockedAmount[msg.sender];
  }

  function setLock(bool _locked) public onlyOwner{
    locked = _locked;
  }

  function withDrawlocked() public view returns (bool) {
      return locked;
  }

  function withDrawable() public view returns (bool) {
    User user = User(commons.get("User"));
    uint256 _type;
    (,,_type) = user.getUserInfo(msg.sender);
    return !locked && (_type > 0) && lockedAmount[msg.sender] > 0;
  }

  function withDraw() external {
    assert(!locked);//用户必须是种子钱包
    BwinToken token = BwinToken(commons.get("BwinToken"));
    User user = User(commons.get("User"));
    uint256 _type;
    (,,_type) = user.getUserInfo(msg.sender);
    assert(_type > 0);
    uint _value = lockedAmount[msg.sender];
    lockedAmount[msg.sender] = 0;
    token.transfer(msg.sender,_value);
  }

}

contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract EtherHolder is Destructible{
  using SafeMath for uint256;
  bool locked = false;

  BwinCommons internal commons;
  function setCommons(address _addr) public onlyOwner {
      commons = BwinCommons(_addr);
  }
  struct Account {
    address wallet;
    address parent;
    uint256 radio;
    bool exist;
  }
  mapping (address => uint256) private userAmounts;
  uint256 internal _balance;
  event ProcessFunds(address _topWallet, uint256 _value ,bool isContract);

  event ReceiveFunds(address _addr, address _user, uint256 _value, uint256 _amount);
  function receiveFunds(address _user, uint256 _amount) external payable returns (bool) {
    emit ReceiveFunds(msg.sender, _user, msg.value, _amount);
    Crowdsale cds = Crowdsale(commons.get("Crowdsale"));
    User user = User(commons.get("User"));
    assert(msg.value == _amount);
    if (msg.sender == address(cds)){
        address _topWallet;
        uint _percent=0;
        bool _contract;
        uint256 _topValue = 0;
        bool _topOk;
        uint256 _totalShares = 0;
        uint256 _totalSharePercent = 0;
        bool _shareRet;
        if(user.hasUser(_user)){
          (_topWallet,_percent,_contract) = user.getTopInfoDetail(_user);
          assert(_percent <= 1000);
          (_topValue,_topOk) = processFunds(_topWallet,_amount,_percent,_contract);
        }else{
          _topOk = true;
        }
        (_totalShares,_totalSharePercent,_shareRet) = processShares(_amount.sub(_topValue));
        assert(_topOk && _shareRet);
        assert(_topValue.add(_totalShares) <= _amount);
        assert(_totalSharePercent <= 1000);
        _balance = _balance.add(_amount);
        return true;
    }
    return false;
  }
  event ProcessShares(uint256 _amount, uint i, uint256 _percent, bool _contract,address _wallet);
  function processShares(uint256 _amount) internal returns(uint256,uint256,bool){
      uint256 _sended = 0;
      uint256 _sharePercent = 0;
      User user = User(commons.get("User"));
      for(uint i=0;i<user.getShareHolderCount();i++){
        address _wallet;
        uint256 _percent;
        bool _contract;
        emit ProcessShares(_amount, i, _percent, _contract,_wallet);
        assert(_percent <= 1000);
        (_wallet,_percent,_contract) = user.getShareHolder(i);
        uint256 _value;
        bool _valueOk;
        (_value,_valueOk) = processFunds(_wallet,_amount,_percent,_contract);
        _sharePercent = _sharePercent.add(_percent);
        _sended = _sended.add(_value);
      }
      return (_sended,_sharePercent,true);
  }
  function getAmount(uint256 _amount, uint256 _percent) internal pure returns(uint256){
      uint256 _value = _amount.div(1000).mul(_percent);
      return _value;
  }
  function processFunds(address _topWallet, uint256 _amount ,uint256 _percent, bool isContract) internal returns(uint,bool) {
      uint256 _value = getAmount(_amount, _percent);
      userAmounts[_topWallet] = userAmounts[_topWallet].add(_value);
      emit ProcessFunds(_topWallet,_value,isContract);
      return (_value,true);
  }

  function balanceOf(address _user) public view returns (uint256) {
    return userAmounts[_user];
  }

  function balanceOfme() public view returns (uint256) {
    return userAmounts[msg.sender];
  }

  function withDrawlocked() public view returns (bool) {
      return locked;
  }
  function getBalance() public view returns (uint256, uint256) {
    return (address(this).balance,_balance);
  }
  function lock(bool _locked) public onlyOwner{
    locked = _locked;
  }
  event WithDraw(address caller, uint256 _amount);

  function withDraw(uint256 _amount) external {
    assert(!locked);
    assert(userAmounts[msg.sender] >= _amount);
    userAmounts[msg.sender] = userAmounts[msg.sender].sub(_amount);
    _balance = _balance.sub(_amount);
    msg.sender.transfer(_amount);
    emit WithDraw(msg.sender, _amount);
  }
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

contract BwinCommons is RBAC, Destructible {
    mapping (string => address) internal addresses;
    mapping (address => string) internal names;

    event UpdateRegistration(string key, address old, address n);

    function register(string key, address ad) public onlyAdmin {
        emit UpdateRegistration(key, addresses[key], ad);
        addresses[key] = ad;
        names[ad] = key;
    }

    function get(string key) public view returns(address) {
        return addresses[key];
    }

    function remove() public {
      string memory key = names[msg.sender];
      delete addresses[key];
      delete names[msg.sender];
    }
}

contract User is RBAC ,Destructible{
    struct UserInfo {
        //推荐人
        address parent;
        uint256 top;
        bool exist;
        uint256 userType;
    }

    struct Partner {
      address addr;
      uint256 percent;
      bool exist;
      bool iscontract;
    }

    struct UserBalance{
        address user;
        uint256 balance;
        uint256 lastTime;
        bool exist;
    }
    mapping (address => UserBalance) internal balanceForInterests;
    uint256[] internal tops;
    mapping (uint256 => Partner) internal topDefine;

    uint256[] internal shareHolders;
    mapping (uint256 => Partner) internal shareHolderInfos;
    mapping (address => UserInfo) internal tree;
    BwinCommons internal commons;
    function setCommons(address _addr) public onlyAdmin {
        commons = BwinCommons(_addr);
    }


    address[] internal users;
    event SetInterestor(address caller, address _user, uint256 _balance, uint256 _lastTime);
    event SetShareHolders(address caller, uint256 topId, address _topAddr, uint256 _percent, bool iscontract);
    event SetTop(address caller, uint256 topId, address _topAddr, uint256 _percent, bool iscontract);
    event AddUser(address caller, address _parent, uint256 _top);
    event SetUser(address caller, address _user, address _parent, uint256 _top, uint256 _type);
    event SetUserType(address caller, address _user, uint _type);
    event RemoveUser(address caller, uint _index);

    function setInterestor(address _user, uint256 _balance, uint256 _lastTime) public onlyRole("INTEREST_HOLDER"){
        balanceForInterests[_user] = UserBalance(_user,_balance,_lastTime,true);
        emit SetInterestor(msg.sender,_user,_balance,_lastTime);
    }

    function getInterestor(address _user) public view returns(uint256,uint256,bool){
        return (balanceForInterests[_user].balance,balanceForInterests[_user].lastTime,balanceForInterests[_user].exist);
    }
    function setShareHolders(uint256 topId, address _topAddr, uint256 _percent, bool iscontract) public onlyAdmin {
        if (!shareHolderInfos[topId].exist){
          shareHolders.push(topId);
        }
        shareHolderInfos[topId] = Partner(_topAddr, _percent, true, iscontract);
        emit SetShareHolders(msg.sender,topId,_topAddr,_percent,iscontract);
    }
    function getShareHolder(uint256 _index) public view returns(address, uint256, bool){
        uint256 shareHolderId = shareHolders[_index];
        return getShareHoldersInfo(shareHolderId);
    }
    function getShareHolderCount() public view returns(uint256){
        return shareHolders.length;
    }
    function getShareHoldersInfo(uint256 shareHolderId) public view returns(address, uint256, bool){
      return (shareHolderInfos[shareHolderId].addr, shareHolderInfos[shareHolderId].percent, shareHolderInfos[shareHolderId].iscontract);
    }

    function setTop(uint256 topId, address _topAddr, uint256 _percent, bool iscontract) public onlyAdmin {
        if (!topDefine[topId].exist){
          tops.push(topId);
        }
        topDefine[topId] = Partner(_topAddr, _percent, true, iscontract);
        emit SetTop(msg.sender, topId, _topAddr, _percent, iscontract);
    }
    function getTopInfoDetail(address _user) public view returns(address, uint256, bool){
        uint256 _topId;
        address _wallet;
        uint256 _percent;
        bool _contract;
        (,_topId,) = getUserInfo(_user);
        (_wallet,_percent,_contract) = getTopInfo(_topId);
        return (_wallet,_percent,_contract);
    }
    function getTopInfo(uint256 topId) public view returns(address, uint256, bool){
      return (topDefine[topId].addr, topDefine[topId].percent, topDefine[topId].iscontract);
    }
    function addUser(address _parent, uint256 _top) public {
        require(msg.sender != _parent);
        if (_parent != address(0)) {
            require(tree[_parent].exist);
        }
        require(!hasUser(msg.sender));
        tree[msg.sender] = UserInfo(_parent, _top, true, 0);
        users.push(msg.sender);
        emit AddUser(msg.sender, _parent, _top);
    }

    function getUsersCount() public view returns(uint) {
        return users.length;
    }

    function getUserInfo(address _user) public view returns(address, uint256, uint256) {
        return (tree[_user].parent, tree[_user].top, tree[_user].userType);
    }

    function hasUser(address _user) public view returns(bool) {
        return tree[_user].exist;
    }

    function setUser(address _user, address _parent, uint256 _top, uint256 _type) public onlyAdmin {
      if(!tree[_user].exist){
        users.push(_user);
      }
      tree[_user] = UserInfo(_parent, _top, true, _type);
      emit SetUser(msg.sender, _user, _parent, _top, _type);
    }

    function setUserType(address _user, uint _type) public onlyAdmin {
        require(hasUser(_user));
        tree[_user].userType = _type;
        emit SetUserType(msg.sender, _user, _type);
    }
    function indexOfUserInfo(uint _index) public view returns (address) {
        return users[_index];
    }

    function removeUser(uint _index) public onlyAdmin {
        address _user = indexOfUserInfo(_index);
        delete users[_index];
        delete tree[_user];
        emit RemoveUser(msg.sender, _index);
    }
}

contract Pausable is RBAC {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyAdmin whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyAdmin whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BwinToken is ERC20, Pausable, Destructible{
    //Token t;

    BwinCommons internal commons;
    function setCommons(address _addr) public onlyOwner {
        commons = BwinCommons(_addr);
    }
    string public constant name = "FFgame Coin";
    string public constant symbol = "FFC";
    uint8 public constant decimals = 18;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function BwinToken() public {
      addRole(msg.sender, ROLE_ADMIN);
    }
    function totalSupply() public view returns (uint256){
      Token t = Token(commons.get("Token"));
      return t.totalSupply();
    }
    function balanceOf(address who) public view returns (uint256){
      Token t = Token(commons.get("Token"));
      return t.balanceOf(who);
    }
    function transfer(address to, uint256 value) public returns (bool){
      bytes memory empty;
      Token t = Token(commons.get("Token"));
      if(t.transfer(msg.sender, to, value,empty)){
          emit Transfer(msg.sender, to, value);
          return true;
      }
      return false;
    }


    function allowance(address owner, address spender) public view returns (uint256){
      Token t = Token(commons.get("Token"));
      return t.allowance(owner, spender);
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool){
      Token t = Token(commons.get("Token"));
      if(t._transferFrom(msg.sender, from, to, value)){
          emit Transfer(from, to, value);
          return true;
      }
      return false;
    }
    function approve(address spender, uint256 value) public returns (bool){
      Token t = Token(commons.get("Token"));
      if (t._approve(msg.sender, spender, value)){
          emit Approval(msg.sender, spender, value);
          return true;
      }
      return false;
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
      Token t = Token(commons.get("Token"));
      if(t._increaseApproval(msg.sender, _spender, _addedValue)){
          emit Approval(msg.sender, _spender, _addedValue);
          return true;
      }
      return false;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
      Token t = Token(commons.get("Token"));
      if (t._decreaseApproval(msg.sender,_spender, _subtractedValue)){
          emit Approval(msg.sender, _spender, _subtractedValue);
          return true;
      }
      return false;
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Token is RBAC, Pausable{
    using SafeMath for uint256;

    BwinCommons internal commons;
    function setCommons(address _addr) public onlyAdmin {
        commons = BwinCommons(_addr);
    }
    event TokenApproval(address indexed owner, address indexed spender, uint256 value);
    event TokenTransfer(address indexed from, address indexed to, uint256 value);
    event MintForSale(address indexed to, uint256 amount);
    event MintForWorker(address indexed to, uint256 amount);
    event MintForUnlock(address indexed to, uint256 amount);

    function Token() public {
        addRole(msg.sender, ROLE_ADMIN);
    }

    function totalSupply() public view returns (uint256) {
      TokenData td = TokenData(commons.get("TokenData"));
      return td.totalSupply();
    }
    function balanceOf(address _owner) public view returns (uint256) {
      TokenData td = TokenData(commons.get("TokenData"));
      return td.balanceOf(_owner);
    }
    function _transferFrom(address _sender, address _from, address _to, uint256 _value) external whenNotPaused onlyRole("FRONT_TOKEN_USER") returns (bool) {
      InterestHolder ih = InterestHolder(commons.get("InterestHolder"));
      TokenData td = TokenData(commons.get("TokenData"));
      uint256 _balanceFrom = balanceOf(_from);
      uint256 _balanceTo = balanceOf(_to);
      uint256 _allow = allowance(_from, _sender);
      require(_from != address(0));
      require(_sender != address(0));
      require(_to != address(0));
      require(_value <= _balanceFrom);
      require(_value <= _allow);
      td.setBalance(_from,_balanceFrom.sub(_value));
      td.setBalance(_to,_balanceTo.add(_value));
      td.setAllowance(_from, _sender, _allow.sub(_value));
      if(ih != address(0)){
        ih.receiveBalanceUpdate(_from);
        ih.receiveBalanceUpdate(_to);
      }
      emit TokenTransfer(_from, _to, _value);
      return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
      TokenData td = TokenData(commons.get("TokenData"));
      return td.allowance(_owner,_spender);
    }
    function _approve(address _sender, address _spender, uint256 _value) public onlyRole("FRONT_TOKEN_USER")  whenNotPaused returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      return td.setAllowance(_sender, _spender, _value);
    }
    function _increaseApproval(address _sender, address _spender, uint _addedValue) public onlyRole("FRONT_TOKEN_USER") whenNotPaused returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      td.setAllowance(_sender, _spender, allowance(_sender, _spender).add(_addedValue));
      emit TokenApproval(_sender, _spender, allowance(_sender, _spender));
      return true;
    }
    function _decreaseApproval(address _sender, address _spender, uint _subtractedValue) public onlyRole("FRONT_TOKEN_USER") whenNotPaused returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      uint oldValue = allowance(_sender, _spender);
      if (_subtractedValue > oldValue) {
          td.setAllowance(_sender, _spender, 0);
          //allowed[msg.sender][_spender] = 0;
      } else {
          td.setAllowance(_sender, _spender, oldValue.sub(_subtractedValue));
          //allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit TokenApproval(_sender, _spender, allowance(_sender, _spender));
      return true;
    }

    function unlockAmount(address _to, uint256 _amount) external onlyAdmin returns (bool){
      TokenData td = TokenData(commons.get("TokenData"));
      require(td.totalSupply().add(_amount) <= td.TotalCapacity());
      uint256 unlockedAmount = td.valueOf("unlockedAmount");
      if(_mint(_to, _amount)){
          td.setValue("unlockedAmount",unlockedAmount.add(_amount));
          emit MintForUnlock(_to, _amount);
          return true;
      }
      return false;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      InterestHolder ih = InterestHolder(commons.get("InterestHolder"));
      require(_to != address(0));
      require(_amount > 0);
      uint256 totalMinted = td.valueOf("totalMinted");
      td.setTotal(td.totalSupply().add(_amount));
      td.setBalance(_to,balanceOf(_to).add(_amount));
      td.setValue("totalMinted",totalMinted.add(_amount));
      if(address(ih) != address(0)){
        ih.receiveBalanceUpdate(_to);
      }
      return true;
    }

    function mintForSale(address _to, uint256 _amount) external onlyRole("TOKEN_SALE") whenNotPaused returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      require(td.totalSupply().add(_amount) <= td.TotalCapacity());
      uint256 saledAmount = td.valueOf("saledAmount");
      if(_mint(_to, _amount)){
          td.setValue("saledAmount",saledAmount.add(_amount));
          emit MintForSale(_to, _amount);
          return true;
      }
      return false;
    }
    function mintForWorker(address _to, uint256 _amount) external onlyRole("TOKEN_WORKER") whenNotPaused returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      require(td.totalSupply().add(_amount) <= td.TotalCapacity());
      uint256 minedAmount = td.valueOf("minedAmount");
      if(_mint(_to, _amount)){
        td.setValue("minedAmount",minedAmount.add(_amount));
        emit MintForWorker(_to, _amount);
        return true;
      }
      return false;
    }
    function transfer(address _from, address _to, uint _value, bytes _data) external whenNotPaused onlyRole("FRONT_TOKEN_USER")  returns (bool success) {

        if (isContract(_to)) {
            return transferToContract(_from, _to, _value, _data);
        }else {
            return transferToAddress(_from, _to, _value);
        }
    }
    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) internal view returns (bool) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      TokenData td = TokenData(commons.get("TokenData"));
      InterestHolder ih = InterestHolder(commons.get("InterestHolder"));
      require(_to != address(0));
      require(_value <= balanceOf(_from));
      td.setBalance(_from,balanceOf(_from).sub(_value));
      td.setBalance(_to,balanceOf(_to).add(_value));
      if(ih != address(0)){
        ih.receiveBalanceUpdate(_from);
        ih.receiveBalanceUpdate(_to);
      }
      emit TokenTransfer(_from, _to, _value);
      return true;
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _from, address _to, uint _value) internal returns (bool success) {
        require(balanceOf(_from) >= _value);
        require(_transfer(_from, _to, _value));
        emit TokenTransfer(_from, _to, _value);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _from, address _to, uint _value, bytes _data) internal returns (bool success) {
        require(balanceOf(_from) >= _value);
        require(_transfer(_from, _to, _value));
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit TokenTransfer(msg.sender, _to, _value);
        return true;
    }



}

contract TokenData is RBAC, Pausable{
  //using SafeMath for uint256;
  event TokenDataBalance(address sender, address indexed addr, uint256 value);
  event TokenDataAllowance(address sender, address indexed from, address indexed to, uint256 value);
  event SetTotalSupply(address _addr, uint256 _total);
  mapping(address => uint256) internal balances;
  mapping(string => uint256) internal values;

  mapping (address => mapping (address => uint256)) internal allowed;

  address[] internal users;

  uint256 internal totalSupply_;
  uint256 internal totalCapacity_;

  string internal  name_;
  string internal  symbol_;
  uint8 internal  decimals_;
  function TokenData(uint256 _totalSupply, uint256 _totalCapacity) public {
    addRole(msg.sender, ROLE_ADMIN);
    totalSupply_ = _totalSupply;
    totalCapacity_ = _totalCapacity;
  }

  BwinCommons internal commons;
  function setCommons(address _addr) public onlyAdmin {
      commons = BwinCommons(_addr);
  }
  function setTotal(uint256 _total) public onlyRole("TOKEN_DATA_USER") {
      totalSupply_ = _total;
      emit SetTotalSupply(msg.sender, _total);
  }
  event SetValue(address _addr, string name, uint256 _value);

  function setValue(string name, uint256 _value) external onlyRole("TOKEN_DATA_USER") {
      values[name] = _value;
      emit SetValue(msg.sender, name, _value);
  }

  event SetTotalCapacity(address _addr, uint256 _total);

  function setTotalCapacity(uint256 _total) external onlyRole("TOKEN_DATA_USER") {
      totalCapacity_ = _total;
      emit SetTotalCapacity(msg.sender, _total);
  }

  function valueOf(string _name) public view returns(uint256){
      return values[_name];
  }


  function TotalCapacity() public view returns (uint256) {
    return totalCapacity_;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }



  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }



  function setBalance(address _addr, uint256 _value) external whenNotPaused onlyRole("TOKEN_DATA_USER") returns (bool) {
    return _setBalance(_addr, _value);
  }
  function setAllowance(address _from, address _to, uint256 _value) external whenNotPaused onlyRole("TOKEN_DATA_USER") returns (bool) {
    return _setAllowance(_from, _to, _value);
  }

  function setBalanceAdmin(address _addr, uint256 _value) external onlyAdmin returns (bool) {
    return _setBalance(_addr, _value);
  }
  function setAllowanceAdmin(address _from, address _to, uint256 _value) external onlyAdmin returns (bool) {
    return _setAllowance(_from, _to, _value);
  }

  function _setBalance(address _addr, uint256 _value) internal returns (bool) {
    require(_addr != address(0));
    require(_value >= 0);
    balances[_addr] = _value;
    emit TokenDataBalance(msg.sender, _addr, _value);
    return true;
  }
  function _setAllowance(address _from, address _to, uint256 _value) internal returns (bool) {
    require(_from != address(0));
    require(_to != address(0));
    require(_value >= 0);
    allowed[_from][_to] = _value;
    emit TokenDataAllowance(msg.sender, _from, _to, _value);
    return true;
  }
}

contract Crowdsale is Ownable, Pausable{
  using SafeMath for uint256;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public saleCapacity;
  uint256 public saledAmount;
  uint256 public rate;
  uint256 public weiRaised;
  event TokenPurchase(address payor, address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  BwinCommons internal commons;
  function setCommons(address _addr) public onlyOwner {
      commons = BwinCommons(_addr);
  }
  function buyTokens(address payor, address beneficiary, address _parent, uint256 _top) public  payable returns(bool, uint256);
  function hasEnded() public view returns (bool){
      return (now > endTime || saledAmount >= saleCapacity);
  }
  modifier onlyFront() {
      require(msg.sender == address(commons.get("CrowdsaleFront")));
      _;
  }
  function validPurchase() internal view returns (bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool withinCapacity = saledAmount <= saleCapacity;
      return withinPeriod && withinCapacity;
  }

  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
      return weiAmount.mul(rate);
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}