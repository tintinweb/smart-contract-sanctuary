/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
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

contract Ownable{
    //"拥有者"
    address public owner;
    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      * @dev 把创建合约的人作为初始的“拥有者”.
      */
    constructor() {
        owner = msg.sender;
    }
    
        modifier onlyOwner(){
        require(msg.sender == owner);
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
        require(newOwner != address(0));
        owner = newOwner;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Mytoken is IERC20,Ownable{
    using SafeMath for uint;
    uint public basisPointsRate = 0; //基本利率
    uint public maximunFee = 0; //最大利息金额
    uint public constant MAX_UINT = 2**256-1;
    string private _name ; 
    string private _symbol;
    uint8 private _decimal;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor(string memory name_, string memory symbol_,uint8 decimal_,uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        _totalSupply = totalSupply_;
        _balances[owner] = totalSupply_;
    }

        modifier onlyPayloadSize(uint size){
        //msg.data就是data域（calldata）中的内容，一般来说都是4（函数名）+32（转账地址）+32（转账金额）=68字节
        //短地址攻击简单来说就是转账地址后面为0但故意缺省，导致金额32字节前面的0被当做地址而后面自动补0导致转账金额激增。
        //参数size就是除函数名外的剩下字节数
        //解决方法：对后面的的字节数的长度限制要求
        require(!(msg.data.length < size+4), "Invalid short address");
        _;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view  returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimal;
    }
    function totalSupply() public virtual override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) public virtual override view returns (uint256 ){
         return _balances[_owner];
    }
    function transfer(address _to, uint256 _value) public virtual override onlyPayloadSize(2 * 32) returns (bool){
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
        _balances[msg.sender] = _balances[msg.sender].sub(sendAmount);
        //加钱
        _balances[_to] = _balances[_to].add(sendAmount);
        //利息去向->owner
        if (fee > 0){
            //因为继承于Ownable，所以可以拿到owner
            _balances[owner] = _balances[owner].add(fee);
            //继承于ERCBasic接口，其中申明了Transfer记录
            //记录利息去向
            emit Transfer(msg.sender, owner, fee);
        }
        //记录转账去向,注意记录的不是总金额而是去除交易费的金额
        emit Transfer(msg.sender, _to, sendAmount);
        return true;

    }
    ////调用allowance(A, B)可以查看B账户还能够调用A账户多少个token 
    function allowance(address _owner, address _spender) public virtual override view returns (uint256){
        return _allowances[_owner][_spender];
    }
    //登录A账户执行approve(b,100)方法结果为：结果：_allowed[A][B] = 100token
    function approve(address _spender, uint256 _value) public virtual override returns (bool){
        require(!(_value != 0 && _allowances[msg.sender][_spender] != 0), "You have only one chance to approve , you can only change it to 0 later");
        //1.改allowed
        _allowances[msg.sender][_spender] = _value;
        //2. 记录
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //在执行登录B账户执行transferFrom(A,C,100),这里的B就是委托账号发送者,gas从B扣,必须确保token数量小于_allowed[A][B]
    function transferFrom(address _from,address _to,uint256 _value) public virtual override  onlyPayloadSize(2 * 32)  returns (bool){
        //授权金额：授权者对于当前调用者授权其可使用的金额量
        uint _allowance = _allowances[_from][msg.sender];
        //在这里同样不需要检查授权金额是否足够,后面的sub函数这种情况会检测
        // require(_allowance >= _value);
        //1.先算利息
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximunFee) fee = maximunFee;
        //2.扣钱
        // 这里为什么要判断？
        if (_allowance < MAX_UINT){
            //注意这里扣去的是总金额，包括了利息都要从授权方的授权金额去除
            _allowances[_from][msg.sender] = _allowance.sub(_value);
        }
        _balances[_from] = _balances[_from].sub(_value);
        //3.加钱
        uint sendAmount = _value.sub(fee);
        _balances[_to] = _balances[_to].add(sendAmount);
        //4.利息去向
        if (fee > 0){
            _balances[owner] = _balances[owner].add(fee);
            emit Transfer(_from,owner,fee);
        }
        //5.记录
        emit Transfer(_from, _to, sendAmount);
        return true;
    }
}