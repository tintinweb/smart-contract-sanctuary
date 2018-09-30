pragma solidity ^0.4.24;

contract ERC20Token { 
    function transfer(address receiver, uint amount) public{ receiver; amount; } 
    function balanceOf(address tokenOwner) public returns (uint balance);
    
} //transfer方法的接口说明


contract THPCTransfer{
    
    uint256  public decimals = 18;   //需要管理的代币的精度
    address  public owner;			 
    mapping (address => bool) public accessAllowed; //具有转账权限的地址
	
	address public contract_addr;
    
    //address contract_addr = 0x08958e4cf104b4A234A5F468B70CAB071A249945;  //本合约管理的token的合约地址
    
    ERC20Token public THPCToken;
    
	//构造函数，参数为待管理的token的合约地址
    constructor(address _addr) public{
	   contract_addr = _addr;
       THPCToken = ERC20Token(contract_addr); //实例化一个token
       owner = msg.sender;
       accessAllowed[msg.sender] = true;
    }
    
	//所有者函数修改器
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
	//访问者函数修改器
    modifier onlyAccess {
        require(accessAllowed[msg.sender] == true);
        _;
    }
    
	//更改所有者
    function changeOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
	//添加转账权限
    function addAccess(address _addr)  onlyOwner public{
        accessAllowed[_addr] = true;
    }
    
	//禁用转账权限
    function denyAccess(address _addr) onlyOwner public {
        accessAllowed[_addr] = false;
    }
    
	//单次转账
    function tokenTransfer(address _to, uint256 _amt) onlyAccess public{
        require (_to != 0x0); 
        require (_amt > 0);
        require (ERC20Token(contract_addr).balanceOf(address(this)) >= _amt);   //判断余额
        
        THPCToken.transfer(_to,_amt);
    }
    
	//批量转账
    function batchTransfer(address[] _addr, uint256[] _value) onlyAccess public{
        
        uint256 totalValue = 0;
        require (_addr.length == _value.length);
        
        for(uint256 i = 0; i < _value.length ; i++){
            totalValue += _value[i];
        }
        require (ERC20Token(contract_addr).balanceOf(address(this)) >= totalValue);
        
        for(uint256 j = 0; j < _addr.length ; j++){
            tokenTransfer(_addr[j],_value[j]);
        }
    }
    
}