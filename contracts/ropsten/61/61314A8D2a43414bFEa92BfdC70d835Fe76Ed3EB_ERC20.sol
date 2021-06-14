pragma solidity >=0.6.0 <0.7.0;


import "./BaseERC20.sol";
import "./SafeMath.sol";

contract ERC20 is BaseERC20{
    
    string  _name;
    string  _symbol;
    uint256  _totalSupply;
    //余额地址
    mapping (address => uint256)  _balances;
    //授信地址
    mapping (address => mapping (address => uint256))  _allowances;
    
    using SafeMath for uint256;

    constructor (string memory name,string memory symbol) public{
        _name = name;
        _symbol = symbol;
        _totalSupply = 21000000*10**uint256(decimals());
        _balances[msg.sender] = 21000000*10**uint256(decimals());
    }
    
    function name() public view override returns (string memory){
        return _name;
    }

    function symbol() public view override returns (string memory){
        return _symbol;
    }

    function decimals() public view override returns (uint8){
        return 18;
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address payable me) public view override returns (uint256){
        return _balances[me];
    }

    //主动转账
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
    
    function commonTransfer(address payable _from,address payable _to,uint256 _value) private {
         require(_from!=address(0),"Don't use zero address to send!!");
         require(_to!=address(0),"Don't send tokens to zero address!!");
         uint256 senderBalance = _balances[_from];
         require(senderBalance>=_value,"You don't have enough tokens to support the transfer!!");
         _balances[_from] = senderBalance.sub(_value);
         _balances[_to] = _balances[_to].add(_value);
         emit Transfer(_from,_to,_value);
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

    
}