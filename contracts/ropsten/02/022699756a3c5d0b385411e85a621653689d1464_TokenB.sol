/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenB is IERC20 {
    using SafeMath for uint256;
    string public _name;
    string public _symbol;
    uint256 public _totalSupply;
    uint256 public  _decimal;
    address admin;
    mapping (address => uint256) public balances;
    mapping (address => mapping(address=>uint256)) public allowed; 
    
    constructor(string memory _Tname, string memory _Tsymbol, uint256 _TtotalSupply, uint256 _Tdecimal) {
        _name=_Tname;
        _symbol=_Tsymbol;
        _totalSupply=_TtotalSupply;
        _decimal=_Tdecimal;
        admin=msg.sender;
        balances[admin]=_totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint256) {
        return _decimal;
    }
    
    function totalSupply() public override view returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public override view returns(uint256) {
        return balances[_owner];
    }
    
    modifier NotAddressZero(address recipient) {
        require(recipient!=address(0),"Invalid Address");
        _;
    }
  
    function transfer(address recipient, uint256 _amount) public NotAddressZero(recipient) override returns(bool) {
        require(balances[msg.sender]>=_amount,"Balance is not enough");
        require(_amount>0,"Amount must be greater than zero");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[recipient] = balances[recipient].add(_amount);
        emit Transfer(msg.sender,recipient,_amount);
        return true;
    } 
    
    function transferFrom(address sender, address recipient, uint256 amount) public NotAddressZero(recipient) override returns(bool){
        require(sender!=address(0),"Invalid Address");
        require(amount>0,"Amount must be greater than zero");
        require(allowed[sender][msg.sender]>=amount,"You are not allowed to transfer");
        require(balances[sender]>=amount,"Insufficient Amount");
        balances[sender]=balances[sender].sub(amount);
        allowed[sender][msg.sender]=allowed[sender][msg.sender].sub(amount);
        balances[recipient]=balances[recipient].add(amount);
        emit Transfer(sender,recipient,amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public NotAddressZero(spender) override returns(bool) {
        require(amount>0,"amount must be greater than zero");
        require(msg.sender!=spender,"Approval to current owner");
        allowed[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) public override view returns(uint256) {
        require(_spender!=address(0),"Invalid Address");
        return allowed[_owner][_spender];
    }
    
    modifier onlyAdmin() {
        require(admin==msg.sender,"Only admin can access");
        _;
    }
    
    function mint(address _to, uint256 _amount) public onlyAdmin { //To mint TokenA
        require(_to!=address(0),"Mint address cannot be zero"); 
        require(_amount>0,"Amount can't be zero");
        balances[_to]=balances[_to].add(_amount);
        _totalSupply=_totalSupply.add(_amount);
        emit Transfer(address(0),_to,_amount);
    } 
    function burn(address _to, uint256 _amount) public onlyAdmin { //To burn TokenA
        require(_to!=address(0),"Burn address cannot be zero");
        require(_amount>0,"Amount can't be zero");
        balances[_to]=balances[_to].sub(_amount);
        _totalSupply=_totalSupply.sub(_amount);
        emit Transfer(_to,address(0),_amount);
    }
}