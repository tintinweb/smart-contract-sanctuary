/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity >0.4.17;

/**
 * @title SafeMath 数学安全函数
 * @dev Math operations with safety checks that throw on error.
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
        // 分母大于0在solidity合约中已经会自动判定了
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

/**
 * @title Ownable 代币的拥有者
 * @dev The Ownable contract has an owner address, and provides basic authorization control.
 * @dev functions, this simplifies the implementation of "user permissions".
 * @dev 这个合约主要是指明合约创建人为代币的创建者，还包括授权控制功能，简化“用户权限”.
 */

contract Ownable{
    //"拥有者"
    address public owner;
    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      * @dev 把创建合约的人作为初始的“拥有者”.
      */
    constructor() public{
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      * @dev 暂时未知, 应该是只能拥有者进行的操作.
      */
    modifier onlyOwner(){
        require(msg.sender == owner, "仅owner调用！");
        //这一行表示继承此合约中使用
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @dev 权力转移给新的拥有者
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner{
        //先确保新用户不是0x0地址
        require(newOwner != address(0), "不能给地址0转移owner");
        owner = newOwner;
    }
}

/**
 * @title ERC20Basic 基于REC20，不是直接继承，而是类似的代码
 * @dev Simpler version of ERC20 interface  对于ERC20标准接口的简化版本
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev 新版本的编译器0.6.1要求抽象合约前要加abstract，并且抽象函数要加上virtual
 */
contract ERC20Basic{
     //定义接口的一系列函数
     uint public _totalSupply;//总发行货币量
     function totalSupply() public view returns(uint);//查看总货币量函数
     function balanceOf(address who) public view returns(uint);//查某人余额
     function transfer(address to, uint value) public;//转账交易函数
     event Transfer(address indexed from, address indexed to, uint value);//定义转账记录事件
 }

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev 继承与上面的接口
 */
contract ERC20 is ERC20Basic{
    //拓展了第三方授权功能
    //授权给别人用自己的钱，返回钱数？
    function allowance(address owner, address spender) public view returns(uint);
    //借助谁（from）向谁（to）转币
    function transferFrom(address from, address to, uint value) public;
    //授权使用额度函数
    function approve(address spender, uint value) public;
    //记录授权
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token 基础代币
 * @dev Basic version of StandardToken, with no allowances.
 * @dev 仅实现代币基本功能（没有第三方授权）
 * 
 */
 contract BasicToken is Ownable, ERC20Basic{
    //使用安全数学函数
    using SafeMath for uint;
    mapping(address => uint) public balances;
    // additional variables for use if transaction fees ever became necessary
    // 如果有必要收取交易费用，可使用其他变量
    uint public basisPointsRate = 0; //基本利率
    uint public maximunFee = 0; //最大利息金额

    /**
    * @dev Fix for the ERC20 short address attack. 防止短地址攻击，具体可看博客ERC20文章
    * @dev 凡是涉及转账交易（合约调用）都需要加上这一限制
    */
    modifier onlyPayloadSize(uint size){
        //msg.data就是data域（calldata）中的内容，一般来说都是4（函数名）+32（转账地址）+32（转账金额）=68字节
        //短地址攻击简单来说就是转账地址后面为0但故意缺省，导致金额32字节前面的0被当做地址而后面自动补0导致转账金额激增。
        //参数size就是除函数名外的剩下字节数
        //解决方法：对后面的的字节数的长度限制要求
        require(!(msg.data.length < size+4), "Invalid short address");
        _;
    }

    /**
    * @dev transfer token for a specified address 转给一个符合规定（非短地址）的地址
    * @param _to The address to transfer to. 转账地址
    * @param _value The amount to be transferred. 转账金额
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32){
        //先算利息: （转账金额*基本利率)/10000  (ps:因为浮点会精度缺失，所以这样计算)
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        //判断是否超最大额
        if (fee > maximunFee) fee = maximunFee;
        //计算剩下的钱
        uint sendAmount = _value.sub(fee);
        //转账的钱要够   源码没加这个判断不知为何？
        //不需要检查，因为后面balances[msg.sender].sub(sendAmount)其中会检查，不够会报异常。
        //require(balances[msg.sender] >= _value);
        //有安全数学函数就不用判断溢出了
        //扣钱
        balances[msg.sender] = balances[msg.sender].sub(sendAmount);
        //加钱
        balances[_to] = balances[_to].add(sendAmount);
        //利息去向->owner
        if (fee > 0){
            //因为继承于Ownable，所以可以拿到owner
            balances[owner] = balances[owner].add(fee);
            //继承于ERCBasic接口，其中申明了Transfer记录
            //记录利息去向
            emit Transfer(msg.sender, owner, fee);
        }
        //记录转账去向,注意记录的不是总金额而是去除交易费的金额
        emit Transfer(msg.sender, _to, sendAmount);
    }

    /**
    * @dev Gets the balance of the specified address. 查余额函数
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns(uint balance){
        return balances[_owner];
    }

}
/**
 * @title Standard ERC20 token ERC20标准代币
 *
 * @dev Implementation of the basic standard token.  依据基本代币准则
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 * @dev 借鉴了firstblood代币
 * @dev 对代币基础功能的拓展-> 添加了第三方授权功能
 */
contract StandardToken is BasicToken, ERC20{
    //授权金额映射：某人对其他所有人授权的金额的映射
    mapping(address => mapping(address => uint)) public allowed;
    //uint最大值
    uint public constant MAX_UINT = 2**256-1;
    /**
    * @dev Transfer tokens from one address to another 授权转账：从一个账户转到另一个账户
    * @param _from address The address which you want to send tokens from 已得到授权的账户
    * @param _to address The address which you want to transfer to 转向的账户
    * @param _value uint the amount of tokens to be transferred 转账金额
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(2 * 32){
        //授权金额：授权者对于当前调用者授权其可使用的金额量
        uint _allowance = allowed[_from][msg.sender];
        //在这里同样不需要检查授权金额是否足够,后面的sub函数这种情况会检测
        // require(_allowance >= _value);
        //1.先算利息
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximunFee) fee = maximunFee;
        //2.扣钱
        // 这里为什么要判断？
        if (_allowance < MAX_UINT){
            //注意这里扣去的是总金额，包括了利息都要从授权方的授权金额去除
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        //3.加钱
        uint sendAmount = _value.sub(fee);
        balances[_to] = balances[_to].add(sendAmount);
        //4.利息去向
        if (fee > 0){
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        //5.记录
        emit Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @dev 调用者授权给他人可使用金额
    * @param _spender The address which will spend the funds. 被授权者
    * @param _value The amount of tokens to be spent. 金额
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32){
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        //这里的限定条件是：不能将已设置过的授权金额改动，除非改为0。
        //也就是说对他人的授权金额只能是从0改为value,这一次机会，再改就只能改回到0
        require(!(_value != 0 && allowed[msg.sender][_spender] != 0), "You have only one chance to approve , you can only change it to 0 later");
        //1.改allowed
        allowed[msg.sender][_spender] = _value;
        //2. 记录
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds. 地址拥有资金的地址。
    * @param _spender address The address which will spend the funds. 查看授权了多少钱
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns(uint remaining){
        return allowed[_owner][_spender];
    }
}


/**
 * @title Pausable 中断
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev 实现紧急停止机制
 */
contract Pausable is Ownable{
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    * @dev 限制条件：函数只能是在合约未停止情况下执行.
    */
    modifier whenNotPaused(){
        require(!paused, "Must be used without pausing");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    * @dev 函数只能在停止条件下执行
    */
    modifier whenPaused(){
        require(paused, "Must be used under pause");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    * @dev 只能由代币管理者进行停止
    *
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    * @dev 只能是代币管理者进行重开
    */
    function unpause() public onlyOwner whenPaused{
        paused = false;
        emit Unpause();
    }
}

/**
 * @dev 列黑名单
 */

contract BlackList is Ownable, BasicToken{
    //黑名单映射
    mapping(address => bool) isBlackListed;
    //事件
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);


    //Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether)
    //允许其他合约调用此黑名单(external)，查看此人是否被列入黑名单
    function getBlackListStatus(address _maker) external view returns(bool){
        return isBlackListed[_maker];
    }

    //获取当前代币的Owner
    function getOwner() external view returns(address){
        return owner;
    }
    //增加黑名单
    function addBlackList(address _evilUser) public onlyOwner{
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    //去除某人黑名单
    function removeBlackList(address _clearUser) public onlyOwner{
        isBlackListed[_clearUser] = false;
        emit RemovedBlackList(_clearUser);
    }

    //去除掉黑名单账户的钱
    function destroyBlackFunds(address _blackListUser) public onlyOwner{
        //1. 检查是否在黑名单
        require(isBlackListed[_blackListUser], "You can only clear the money of users in the blacklist");
        //2. 查看要清除的钱
        uint dirtyFunds = balanceOf(_blackListUser);
        //3. 扣除清零
        balances[_blackListUser] = 0;
        //4. 总代币发行量减少
        _totalSupply = _totalSupply.sub(dirtyFunds);
        //5. 记录
        emit DestroyedBlackFunds(_blackListUser, dirtyFunds);
    }
}


//标准代币拓展(为了适应不支持ERC20的情况或者是拓展)
contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    // 这些拓展方法都是来自遗留合同
    // 并且合约调用者必须是合约地址
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}


//主体代币
contract TetherToken is Pausable, StandardToken, BlackList{

    string public name;  //代币名
    string public symbol; //标志
    uint public decimals; //精度/小数点后几位
    address public upgradedAddress; //升级合约的地址（必须是合约地址）
    bool public deprecated; //弃用（支持ERC20与否）

    //  The contract can be initialized with a number of tokens 可初始化多个代币
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals

    constructor(
        uint _initialSupply,
        string _name,
        string _symbol,
        uint _decimals
    ) public {
        //总发行币都给owner
        _totalSupply = _initialSupply;
        balances[owner] = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        deprecated = false;
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    //如果不推荐使用ERC20方法，则将其转为升级的合同
    function transfer(address _to, uint _value) public whenNotPaused{
        //排除黑名单
        require(!isBlackListed[msg.sender], "The account you applied for is on the blacklist and cannot be transferred");
        //判断是否支持ERC20
        if(deprecated){
            //不支持的话就调用用upgradedAddress实例化的对象的transferByLegacy函数
            //不知道这里为什么要传msg.sender？
            //我猜测是重新升级适配函数的话调用此函数的人(msg.sender)也要转过去
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        }else{
            //支持的话就直接调用ERC20的转账
            //这里没有返回值，不知道为什么还要加return
            return super.transfer(_to, _value);
        }
    }

    //同理：
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused{
        require(!isBlackListed[_from], "The account you applied for is on the blacklist and cannot be transferred");
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    //注意这里查询余额在代币暂停的情况下也是可以使用的
    function balanceOf(address who) public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        }else{
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) public whenNotPaused{
        //这里不用检查了，如果是在黑名单中，那么授权再多也没用，transferFrom的时候就检测出来了
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        }else{
            return super.approve(_spender, _value);
        }

    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).allowance(_owner, _spender);
        }else{
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    //反对现行合同，改用新合同. upgradedAddress新合同地址
    function deprecate(address _upgradedAddress) public onlyOwner{
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        //记录
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    //反对现行合同，如果想换一个新合约,需要提前知道当前发行量
    function totalSupply() public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).totalSupply();
        }else{
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens 发行新数量的代币
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint _amount) public onlyOwner{
        //增加拥有者的量
        balances[owner] = balances[owner].add(_amount);
        //增加发行的总代币量
        _totalSupply = _totalSupply.add(_amount);
        //记录
        emit Issue(_amount);
    }

    // 调整利息率和最大利息限制
    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner{
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        //通过硬编码限制来确保透明度，超过这个限度就不能再增加费用了
        require(newBasisPoints < 20, "The new BasisPoints cannot exceed 20"); //0.002
        require(newMaxFee < 50, "The new MaxFee cannot exceed 50"); //5*10**(decimals+1)
        basisPointsRate = newBasisPoints;
        maximunFee = newMaxFee.mul(10**decimals);
        //记录
        emit Params(newBasisPoints, newMaxFee);
    }
}