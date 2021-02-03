/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^ 0.5.0;

/**
 * @dev 检测数学运算错误
 */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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



//设置合约拥有者及转让
contract Ownable {
    
  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
            owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
  }
}

//使用并扩展ERC20接口
contract ERC20Interface {
  function totalSupply() public view returns(uint);
  function balanceOf(address tokenOwner) public view returns(uint balance);
  function allowance(address tokenOwner, address spender) public view returns(uint remaining);
  function transfer(address to, uint tokens) public returns(bool success);
  function approve(address spender, uint tokens) public returns(bool success);
  function transferFrom(address from, address to, uint tokens) public returns(bool success);
  uint public basisPointsRate = 0;
  uint public maximumFee = 0;
  uint public MAX_UINT = 2**256 - 1;
  modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//支付服务
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


//合约暂停服务功能
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev 使方法仅在合约未暂停时可用
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev 使方法仅在合约暂停时可用
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev 仅合约拥有者可使用：暂停功能
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev 仅合约拥有者可使用：开放功能
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

  //黑名单功能
contract UserLock is Ownable {
  mapping(address => bool) blacklist;
  modifier permissionCheck {
    require(!blacklist[msg.sender]);
    _;
  }
  
  //锁定帐户
  function lockUser(address who) public onlyOwner {
    blacklist[who] = true;
    emit LockUser(who);
  }
  //解锁帐户
  function unlockUser(address LockUser) public onlyOwner {
    blacklist[LockUser] = false;
    emit UnlockUser(LockUser);
  }
  
  
  //黑名单公告
  event LockUser(address indexed who);
  event UnlockUser(address indexed who);
}

 //合约发布
contract AYCToken is Pausable, ERC20Interface, UserLock {
    using SafeMath for uint;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) public allowed;
    constructor() public {
    name = "Activate Your Chain";//代币全称
    symbol = "AYC";//代币代号
    decimals = 6;//小数位数
    _totalSupply = 180000000000000;//发行总量1亿
    address order = 0xe938B46165B215962d85D27c02bBe5Ae0Ee61bee;
    balances[order] = _totalSupply;
    emit Transfer(address(0), order, _totalSupply);
    }

    //查询帐号余额
    function balanceOf(address who) public view returns (uint) {
        return balances[who];
    }

    //普通转帐交易
    function transfer(address _to, uint _value) public whenNotPaused onlyPayloadSize(2 * 32) returns(bool success){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }



    //担保交易
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) returns(bool success){
        /*allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;  */
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    // 代理交易
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns(bool success){
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;

    }
    
    // 显示所有代币总值
    function totalSupply() public view returns (uint) {
       return _totalSupply.sub(balances[address(0)]);
    }

  
    //销毁指定黑名单用户代币并从总量减去
    function redeemBLT (address LockUser) public onlyOwner {
        require(blacklist[LockUser]);
        uint dirtyFunds = balanceOf(LockUser);
        balances[LockUser] = 0;
        _totalSupply -= dirtyFunds;
        emit RedeemBLT(LockUser, dirtyFunds);
    }
    
    //错误转帐回调
    function () external payable {
    revert();
    }
  
  //owner地址支持接受其他ERC20代币
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    /* 公告合约行为 如新增、销毁、更新等 */
    event Issue(uint amount);

    event Redeem(uint amount);

    event Params(uint feeBasisPoints, uint maxFee);
    
    event RedeemBLT(address LockUser, uint dirtyFunds);
}