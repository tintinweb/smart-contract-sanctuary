/**
 *Submitted for verification at Etherscan.io on 2021-07-08
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
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}


interface token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(uint256 _amount) external;
    function burn(uint256 _amount) external;
    
    event Transfer(address from, address to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract TokenA is token{
    using SafeMath for uint256;
    string public _name;
    string public _symbol;
    uint256 public _totalSuply;
    uint256 public _decimals;
    address public _admin;

    
    constructor(string memory name, string memory symbol, uint256 decimals) {
        _name=name;
        _symbol=symbol;
        _decimals=decimals;
        _admin=msg.sender;
    }
    mapping(address =>uint256) balances;
    mapping (address => mapping(address=>uint256)) public allowed;
    function balanceOf(address _account) public override view returns (uint256) {
        return balances[_account];
    }
    function transfer(address _to, uint256 _amount) public override returns(bool) {
        require(_amount>0,"Amount can't be zero");
        require(balances[msg.sender]>=_amount,"Not Enough Tokens for transfer");
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    modifier NotAddressZero(address recipient) {
        require(recipient!=address(0),"Invalid Address");
        _;
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
    modifier onlyAdmin {
        require(msg.sender==_admin,"Only admin is allowed to access");
        _;
    }
    function mint(uint256 _amount) public override onlyAdmin {
        require(_amount>0,"Amount can't be zero");
        balances[msg.sender]=balances[msg.sender].add(_amount);
        _totalSuply=_totalSuply.add(_amount);
        emit Transfer(address(0),_admin,_amount);
    } 
    function burn(uint256 _amount) public override onlyAdmin {
        require(_amount>0,"Amount can't be zero");
        balances[_admin]=balances[_admin].sub(_amount);
        _totalSuply=_totalSuply.sub(_amount);
        emit Transfer(_admin,address(0),_amount);
    }
}