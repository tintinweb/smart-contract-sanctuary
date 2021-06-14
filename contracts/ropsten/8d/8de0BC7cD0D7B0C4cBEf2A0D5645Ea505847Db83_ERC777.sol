pragma solidity >=0.6.0 <0.7.0;

import "./BaseERC777.sol";
import "./BaseERC20.sol";
import "./SafeMath.sol";

contract ERC777 is BaseERC777,BaseERC20{
    string  _name;
    string  _symbol;
    uint256  _totalSupply;
    
    //默认的操作者列表，这个属性用于展示
    address[] private _defaultOperatorsArray;
    //默认的操作者者map
    mapping(address => bool) private _defaultOperators;
    //对某一个地址的一系列操作者及其状态
    mapping(address => mapping(address => bool)) private _operators;
    //针对默认操作者列表，控制其权限范围
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;
    
    //余额地址
    mapping (address => uint256)  _balances;
    
    //授信地址
    mapping (address => mapping (address => uint256))  _allowances;
    
    //合约创建者，只有创建者有权增发货币
    address _creator;
    
    using SafeMath for uint256;
    
    //构造器，初始供应链2100万枚
    constructor (string memory name,string memory symbol, address[] memory defaultOperators) public{
        _name = name;
        _symbol = symbol;
        _totalSupply = 21000000*10**uint256(decimals());
        _balances[msg.sender] = 21000000*10**uint256(decimals());
        _creator = msg.sender;
        _defaultOperatorsArray = defaultOperators;
        for (uint256 i = 0; i < defaultOperators.length; i++) {
            _defaultOperators[defaultOperators[i]] = true;
        }
    }
    
    //名称
    function name() public view override(BaseERC20,BaseERC777) returns (string memory){
        return _name;
    }
    
    //简称
    function symbol() public view override(BaseERC20,BaseERC777) returns (string memory){
        return _symbol;
    }
    
    //小数位
    function decimals() public view override(BaseERC20) returns (uint8) {
        return 18;
    }
    
    //最小不可分割单位
    function granularity() public view override returns (uint256){
        return 1;
    }
    
    //总供应量
    function totalSupply() public view override(BaseERC20,BaseERC777) returns (uint256){
        return _totalSupply;
    }
    
    //查询账户余额
    function balanceOf(address payable me) public view override(BaseERC20,BaseERC777) returns (uint256){
        return _balances[me];
    }
    
    //转账
    function send(address payable recipient, uint256 amount, bytes calldata data) public override {
        if(isOperatorFor(msg.sender,recipient)){
              commonTransfer(msg.sender,recipient,amount);
            emit Sent(msg.sender, msg.sender, recipient, amount, data, "");
        }
    }
    
    //销毁
    function burn(uint256 amount, bytes calldata data) public override{
        require(msg.sender!=address(0));
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burned(msg.sender,msg.sender,amount,data,"");
    }
    
    //通用转账方法
    function commonTransfer(address payable _from,address payable _to,uint256 _value) private {
         require(_from!=address(0),"Don't use zero address to send!!");
         require(_to!=address(0),"Don't send tokens to zero address!!");
         uint256 senderBalance = _balances[_from];
         require(senderBalance>=_value,"You don't have enough tokens to support the transfer!!");
         _balances[_from] = senderBalance.sub(_value);
         _balances[_to] = _balances[_to].add(_value);
    }
    
    //返回是否是某个账户的操作人
    function isOperatorFor(address operator, address tokenHolder) public view  override returns (bool) {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }
    
    //向某个地址授予操作人权限
    function authorizeOperator(address operator) public override{
         require(msg.sender != operator, "No need to authorize yourself as operator");
         if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[msg.sender][operator];
            } else {
            _operators[msg.sender][operator] = true;
          }
         emit AuthorizedOperator(operator, msg.sender);
     }
     
     //取消某个地址对本地址的操作人权限
     function revokeOperator(address operator) public override  {
          require(msg.sender != operator, "can not revoke yourself");
          if(_defaultOperators[operator]){
              _revokedDefaultOperators[msg.sender][operator]=true;
          }else{
              delete _operators[msg.sender][operator];
          }
          emit RevokedOperator(operator,msg.sender);
     }
     
     //返回默认的操作人列表
     function defaultOperators() public view  override returns (address[] memory) {
        return _defaultOperatorsArray;
     }
    
     //操作人代理发送
     function operatorSend(
        address payable sender,
        address payable recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
     ) public override{
         require(msg.sender!=address(0));
         if(isOperatorFor(msg.sender,sender)){
             commonTransfer(sender,recipient,amount);
         }
         emit Sent(msg.sender, msg.sender, recipient, amount, data, operatorData);
     }
     
     //操作人代理销毁
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) public override{
        require(msg.sender!=address(0));
        if(isOperatorFor(msg.sender,account)){
            require(account!=address(0));
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            _totalSupply = _totalSupply.sub(amount);
            emit Burned(msg.sender,msg.sender,amount,data,operatorData);
        }
    }
    
    //合约创建人增发货币
    function mint(address account, uint256 amount) public creatorOnly{
        require(account!=address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Minted(msg.sender,account,amount,"","");
    }
    
    //合约创建人
    modifier creatorOnly{
        require(msg.sender==_creator);
        _;
    }
    
    function transfer(address payable _to, uint256 _value) public override returns (bool success){
        commonTransfer(msg.sender,_to,_value);
        return true;
    }
    
    //被动转账,转移支付
    function transferFrom(address payable _from, address payable _to, uint256 _value) public override returns (bool success){
         require(_from!=address(0),"Sender's address can not be zero!!");
         require(_to!=address(0),"Target address can not be zero!!");
         uint256 remaining =  _allowances[_from][msg.sender];
         require(remaining>=_value,"Your address have no enough allowances to support the transfer!!");
         commonTransfer(_from,_to,_value);
         _allowances[_from][msg.sender] = remaining.sub(_value);
         return true;
    }
    
    //授信
    function approve(address payable _spender, uint256 _value) public override returns (bool success){
        _allowances[msg.sender][_spender] =  _allowances[msg.sender][_spender].add(_value);
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    //查看授信金额
    function allowance(address payable _owner, address payable _spender) public override view returns (uint256 remaining){
        return _allowances[_owner][_spender];
    }
    event Approval(address payable indexed _owner, address payable indexed _spender, uint256 _value);
}