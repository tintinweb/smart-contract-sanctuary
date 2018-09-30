pragma solidity ^0.4.18;

// TODO
// 销毁合约
// 数据迁移方法方法

contract Owned {
  address public _owner;

  function Owned() public {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function setOwner(address newOwner) public onlyOwner {
    _owner = newOwner;
  }
}

contract RunManager is Owned {

  bool public isRun;

  function RunManager(bool isrun) public {
    isRun = isrun;
  }

  modifier isRunning {
    assert (isRun);
    _;
  }
  function stop() public onlyOwner {
    isRun = false;
  }
  function start() public onlyOwner {
    isRun = true;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  // function sub32(uint32 a, uint32 b) internal returns (uint32) {
  //   assert(b <= a);
  //   return a - b;
  // }
}

contract ERC20 {
  function totalSupply() public constant returns (uint supply);
  function balanceOf( address who ) public constant returns (uint value);
  function allowance( address owner, address spender ) public constant returns (uint _allowance);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}

contract TokenBase is ERC20, SafeMath {
  uint256 _supply;
  string public  _symbol;
  string public  _name;
  uint8 public _decimals = 0; // standard token precision. override to customize
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256))  _approvals;
    
  function totalSupply() public constant returns (uint256) {
    return _supply;
  }

  function balanceOf(address src) public constant returns (uint256) {
    return _balances[src];
  }

  function allowance(address src, address guy) public constant returns (uint256) {
    return _approvals[src][guy];
  }
    
  function transfer(address dst, uint wad) public returns (bool) {
    assert(_balances[msg.sender] >= wad);
    _balances[msg.sender] = sub(_balances[msg.sender], wad);
    _balances[dst] = add(_balances[dst], wad);
    emit Transfer(msg.sender, dst, wad);
    return true;
  }
    
  function transferFrom(address src, address dst, uint wad) public returns (bool) {
    assert(_balances[src] >= wad);
    assert(_approvals[src][msg.sender] >= wad);
    _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
    _balances[src] = sub(_balances[src], wad);
    _balances[dst] = add(_balances[dst], wad);
    emit Transfer(src, dst, wad);
    return true;
  }
    
  function approve(address guy, uint256 wad) public returns (bool) {
    _approvals[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

}

contract ServerBase is SafeMath, TokenBase {
  // admin
  address public _serverAdmin;
  uint256 _bonus = 0;
  uint256 _prebonus = 0;
  uint256 _usedbonus = 0;

  modifier onlyAdmin() {
    require(msg.sender == _serverAdmin);
    _;
  }
  // user
  uint256 _allScore;
  mapping (address => bool) _userRegister;
  mapping (address => uint32) _userScore;
  mapping (address => uint32) _userYan;
  mapping (address => bytes32) _userInfo;
  mapping (address => bytes32) _userLangAbility;
  mapping (address => bytes32) _userProjectExp;
  mapping (address => bytes32) _userEduExp;
  mapping (address => bytes32) _userCertificate;

  function getYanCoefficient(uint256 cbase, uint32 yan) 
      internal returns (uint256) {
    uint256 ret = 0;
    if (yan >= 0 && yan < 200) {
      ret = div(cbase, 2); // coe:0.5
    } else if (yan >= 200 && yan < 400) {
      ret = div(mul(cbase, 7), 10); // coe:0.7
    } else if (yan >= 400 && yan < 600) {
      ret = div(mul(cbase, 17), 20); // coe:0.85
    } else if (yan >= 600 && yan < 800) {
      ret = div(mul(cbase, 19), 20); // coe:0.95
    } else if (yan >= 800) {
      ret = cbase; // coe:1
    }
    return ret;
  }

  // read
  function getBonusPool(bool isFindPreRemainBonus) public view returns (uint256) {
    if (isFindPreRemainBonus) {
      return _prebonus;
    }
    return _bonus;
  }

  function getScoreTotal() public view returns (uint256) {
    return _allScore;
  }

  // write
  function setServerAdmin(address admin) public {
    _serverAdmin = admin;
  }

  function resetBonusPool(uint256 coinnum, uint8 percentOfWeekUsed) public returns (bool) {
    assert(percentOfWeekUsed <= 100);
    _prebonus = sub(add(_prebonus, _bonus), _usedbonus);
    _prebonus = add(_prebonus, div(mul(coinnum, sub(100, percentOfWeekUsed)), 100));
    _bonus = div(mul(coinnum, percentOfWeekUsed), 100);
    _usedbonus = 0;
    return true;
  }

  function dividendBonus(address userAddr, uint allScoreByWeek, uint userScoreByWeek) 
      public returns (bool) {
    uint256 c = add(mul(div(userScoreByWeek, allScoreByWeek), _bonus), mul(div(_userScore[userAddr], _allScore), _prebonus));
    uint256 r = getYanCoefficient(c, _userYan[userAddr]);
    assert(add(r, _usedbonus) <= add(_bonus, _prebonus));
    super.transfer(userAddr, r);
    _usedbonus = add(_usedbonus, r);
    return true;
  }

  function userAdd(address userAddr) public returns (bool) {
    _userRegister[userAddr] = true;
    return true;
  }

  function userDelete(address userAddr) public returns (bool) {
    // TODO 不存在会异常?
    delete _userRegister[userAddr];
    delete _userScore[userAddr];
    delete _userYan[userAddr];
    delete _userInfo[userAddr];
    delete _userLangAbility[userAddr];
    delete _userProjectExp[userAddr];
    delete _userEduExp[userAddr];
    delete _userCertificate[userAddr];
    return true;
  }

  modifier onlyRegisterUser() {
    require(_userRegister[msg.sender] == true);
    _;
  }

  function setUserScore(address userAddr, uint32 score) public returns (bool) {
    uint32 cur = _userScore[userAddr];
    if (cur < score) {
      _allScore = add(_allScore, sub(score, cur));
      _userScore[userAddr] = score;
    } else if (cur > score) {
      _allScore = sub(_allScore, sub(cur, score));
      _userScore[userAddr] = score;
    }
    return true;
  }

  function setUserYan(address userAddr, uint32 yan) public returns (bool) {
    _userYan[userAddr] = yan;
    return true;
  }

  function changeUserInfo(bytes32 newhash) public returns (bool) {
    _userInfo[msg.sender] = newhash;
    return true;
  }

  function changeUserLangAbility(bytes32 newhash) public returns (bool) {
    _userLangAbility[msg.sender] = newhash;
    return true;
  }

  function changeUserProjectExp(bytes32 newhash) public returns (bool) {
    _userProjectExp[msg.sender] = newhash;
    return true;
  }

  function changeUserEduExp(bytes32 newhash) public returns (bool) {
    _userEduExp[msg.sender] = newhash;
    return true;
  }

  function changeUserCertificate(bytes32 newhash) public returns (bool) {
    _userCertificate[msg.sender] = newhash;
    return true;
  }
}

contract LIC is RunManager(true), ServerBase {

  function LIC(uint256 supply, string symbol, string name, uint8 decimals) public {
    _balances[msg.sender] = supply;
    _supply = supply;
    _symbol = symbol;
    _name = name;
    _decimals = decimals;
  }

  function setName(string name) public onlyOwner {
    _name = name;
  }

  function setSymbol(string symbol) public onlyOwner {
    _symbol = symbol;
  }

  function transfer(address dst, uint wad) public isRunning returns (bool) {
    return super.transfer(dst, wad);
  }

  function transferFrom(address src, address dst, uint wad) public isRunning returns (bool) {
    return super.transferFrom(src, dst, wad);
  }

  function approve(address guy, uint wad) public isRunning returns (bool) {
    return super.approve(guy, wad);
  }

  function mint(uint128 wad) public onlyOwner isRunning {
    _balances[msg.sender] = add(_balances[msg.sender], wad);
    _supply = add(_supply, wad);
  }

  function burn(uint128 wad) public onlyOwner isRunning {
    _balances[msg.sender] = sub(_balances[msg.sender], wad);
    _supply = sub(_supply, wad);
  }

  //
  function setServerAdmin(address admin) public onlyOwner isRunning {
    super.setServerAdmin(admin);
  }

  function dividendBonus(address userAddr, uint allScoreByWeek, uint userScoreByWeek) 
      public onlyAdmin isRunning returns (bool) {
    return super.dividendBonus(userAddr, allScoreByWeek, userScoreByWeek);
  }

  function resetBonusPool(uint256 coinnum, uint8 percentOfWeekUsed) public onlyAdmin isRunning returns (bool) {
    return super.resetBonusPool(coinnum, percentOfWeekUsed);
  }

  function setUserScore(address userAddr, uint32 score) public onlyAdmin isRunning returns (bool) {
    return super.setUserScore(userAddr, score);
  }

  function setUserYan(address userAddr, uint32 yan) public onlyAdmin isRunning returns (bool) {
    return super.setUserYan(userAddr, yan);
  }

  function changeUserInfo(bytes32 newhash) public onlyRegisterUser isRunning returns (bool) {
    return super.changeUserInfo(newhash);
  }

  function changeUserLangAbility(bytes32 newhash) public onlyRegisterUser isRunning returns (bool) {
    return super.changeUserLangAbility(newhash);
  }

  function changeUserProjectExp(bytes32 newhash) public onlyRegisterUser isRunning returns (bool) {
    return super.changeUserProjectExp(newhash);
  }

  function changeUserEduExp(bytes32 newhash) public onlyRegisterUser isRunning returns (bool) {
    return super.changeUserEduExp(newhash);
  }

  function changeUserCertificate(bytes32 newhash) public onlyRegisterUser isRunning returns (bool) {
    return super.changeUserCertificate(newhash);
  }

  function userAdd(address userAddr) public onlyAdmin isRunning returns (bool) {
    return super.userAdd(userAddr);
  }

  function userDelete(address userAddr) public onlyAdmin isRunning returns (bool) {
    return super.userDelete(userAddr);
  }

}