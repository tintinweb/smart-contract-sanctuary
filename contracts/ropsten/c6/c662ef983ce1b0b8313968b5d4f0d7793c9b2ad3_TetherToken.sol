/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.4.17;
//首先写了个工具类，提供加减乘除方法，方法中加入断言，使得调用时可以大胆调用，例如减法a-b无需判断
// a >= b是否成立，如果不成立这里就会抛异常
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
//定义一个Ownable合约
contract Ownable {
    //定义一个合约拥有者地址变量
    address public owner;
    //构造方法 只会在部署合约时执行 初始化合约拥有者地址
    //构造方法有两种写法  等同于：
    //    constructor() public {
    //        owner = msg.sender;
    //    }
    function Ownable() public {
        owner = msg.sender;
    }
    //函数修改器 和断言有异曲同工之处 不过这个是用作权限验证
    //人话：把它当做拦截器，只有这里成立了函数才能执行
    modifier onlyOwner() {
        //只有拥有者才回满足修改器的条件
        require(msg.sender == owner);
        _;
    }
    //一个转移合约拥有者的函数 后面public onlyOwner 表示使用onlyOwner这个修改器
    //满足修改器的条件，才可以执行函数内的代码
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
//https://eips.ethereum.org/EIPS/eip-20这里可以先看一下
//erc20协议提供的基本核心函数 
//event函数
//合约代币的交易不过就是合约上的变量变化而已，后面看了mapping就懂了
//合约变量变化后没人知道，那外界就没办法监听数据，所以处理完要公开告诉大家合约做了什么（广播）
//变量变化之后需要调用event函数，才会被记录到EVM中，也就可以被监听到了
contract ERC20Basic {
    uint public _totalSupply;
    //查询合约上代币总数
    function totalSupply() public constant returns (uint);
    //查询指定地址代币余额
    function balanceOf(address who) public constant returns (uint);
    //代币交易
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}
//erc20协议的扩展函数(这样说可能不合适)  //其实写在一个contract内也可以 这只是分开条理清晰一些
//is 继承  继承了上面ERC20Basic合约
contract ERC20 is ERC20Basic {
    //查询owner授权给spender剩余的代币额度
    function allowance(address owner, address spender) public constant returns (uint);
    //代理交易 从from转代币给to 
    //这里不讲太详细，说多可能会觉得乱，对代理交易有兴趣看我另一篇实战的博客
    function transferFrom(address from, address to, uint value) public;
    //msg.sender授权给spender value的代币额度
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
//继承Ownable和ERC20Basic 
contract BasicToken is Ownable, ERC20Basic {
    //使用之前的工具类
    using SafeMath for uint;
    //账户及余额的mapping 其实就像一个map key是地址 value是余额
    mapping(address => uint) public balances;
    //定义 basisPointsRate 是合约燃料费比例 万分之?，如果大于0 
    //那么 交易时除以太币燃料费外还要扣你的代币，后面的实现是减少实际到账
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;//最大燃料费
    //修改器 防止短地址攻击(无需理解)
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    //重写了交易实现
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        //计算燃料费 basisPointsRate为0 这里没什么意义
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);//减去燃料费 同样没意义
        //交易 实际就是操作mipping数据而已
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(msg.sender, owner, fee);
        }
        //调用 event广播
        Transfer(msg.sender, _to, sendAmount);
    }
    //重写查询余额
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}
//继承BasicToken,ERC20 
contract StandardToken is BasicToken, ERC20 {
    
    //授权数据mapping 相当于map包map结构
    mapping (address => mapping (address => uint)) public allowed;
    //2**256就是2的256次方
    uint public constant MAX_UINT = 2**256 - 1;
    //重写代理交易
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        //授权额度不足抛异常 下面就是减授权额度  交易 广播
        // if (_value > _allowance) throw;
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(_from, owner, fee);
        }
        Transfer(_from, _to, sendAmount);
    }
    //重写授权
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        //如果已经有授权额度了 不能重新授权 必须先授权为0 再重新授权
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    //重写授权额度
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
//这个合约是用于合约更新时停止 启用合约 只有拥有者可以操作
//因为合约更新需要同步数据，所以更新时要停止数据变动，同步完在启用
//如果停止 将拒绝所有函数调用
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;//停止启用的变量
  //修改器 验证当前是没有停止的
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  //修改器 验证当前是停止的
  modifier whenPaused() {
    require(paused);
    _;
  }
  //停止合约 onlyOwner whenNotPaused 修改器验证操作者是拥有者并且合约当前是启用的
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  //启用合约 onlyOwner whenNotPaused 修改器验证操作者是拥有者并且合约当前是停止的
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
//黑名单合约
contract BlackList is Ownable, BasicToken {
    //查地址有没有被加入黑名单
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }
    //获取合约拥有者
    function getOwner() external constant returns (address) {
        return owner;
    }
    //黑名单mapping
    mapping (address => bool) public isBlackListed;
    
    //加入黑名单
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        AddedBlackList(_evilUser);
    }
    //取消黑名单
    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }
    //销毁黑名单账户 把它的代币清空
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}
//兼容老版本的合约函数  欢迎大佬补充 没太懂 没看到实现
contract UpgradedStandardToken is StandardToken{
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}
//前边都是准备工作  这里才是最终的
contract TetherToken is Pausable, StandardToken, BlackList {
    string public name;//代币名称
    string public symbol;//代币符号
    uint public decimals;// 代币小数点位数
    address public upgradedAddress;//停用后要使用哪个版本？？不确定
    bool public deprecated;//版本控制变量 为true表示弃用这个版本了
    //构造方法 发布合约时初始化代币信息 版本信息 拥有者信息
    function TetherToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }
    // 交易 如果是这个版本就用这个版本的函数 
    //whenNotPaused 验证当前是没有停止的
    function transfer(address _to, uint _value) public whenNotPaused {
        //过滤黑名单用户
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            //！！！！！！这里我也没看懂 感觉像是没有实现还是怎样 欢迎大佬补充
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }
    //代理交易
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }
    //查代币余额
    function balanceOf(address who) public constant returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }
    //授权
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }
    //查询授权
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }
    //弃用当前版本
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }
    //查代币总数
    function totalSupply() public constant returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }
    //发行代币 新发行的代币加到拥有者账户 onlyOwner 拥有者权限
    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        balances[owner] += amount;
        _totalSupply += amount;
        Issue(amount);
    }
    //销毁一定的代币 从拥有者账户减  onlyOwner 拥有者权限
    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);
        _totalSupply -= amount;
        balances[owner] -= amount;
        Redeem(amount);
    }
    //修改燃料费 比例和最大燃料费参数  onlyOwner 拥有者权限
    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);
        Params(basisPointsRate, maximumFee);
    }
    // Called when new token are issued
    event Issue(uint amount);
    // Called when tokens are redeemed
    event Redeem(uint amount);
    // Called when contract is deprecated
    event Deprecate(address newAddress);
    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
}