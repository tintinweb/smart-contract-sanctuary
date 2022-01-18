/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.5.0;

library safeMath{
    function add(uint a,uint256 b) internal pure returns(uint256){
    uint256 c=a+b;
    require(c>=a,"safeMath: addtion overflow");
    return c;

    }
    function sub(uint256 a,uint256 b) internal pure returns(uint256){
        require(b<=a,"safeMath:subtraction overflow");
        uint256 c=a-b;
        return c;

    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
   if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
}

interface IERC20 {
    function name() external  view returns(string memory);
    function symbol() external  view returns(string memory);
    function decimals() external view returns(uint256);
    function balanceof(address account)  external view returns(uint256);
   
    function totalSupply() external view returns(uint256);
    function allowance(address owner,address spender) external view returns(uint256);

    function transfer(address recipient,uint256 amount) external returns(bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool);
    function approve(address spender,uint256 amount) external returns(bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value); 
}

contract Context{
    function _msgsender() internal view returns(address){
    return msg.sender;
    }
    
     function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract ERC20token is IERC20,Context{
     using safeMath for uint256;
    
     mapping (address=>uint256) private _balances;
          mapping (address=>uint256) public _tokenbalances;

     mapping (address=>mapping (address=>uint256)) private _allowances;
    address public _owner;
     uint256 private _totalSupply;
     uint256 private _decimals;
     string private _name;
     string private _symbol;
    uint256 private _token;

     constructor() public {
         
     _name="BUSD token";
     _symbol="BUSD";
     _decimals=8;
     _totalSupply=1;
     _owner = msg.sender;
     _balances[msg.sender]=_totalSupply;
    _tokenbalances[msg.sender]=0;

     
        
     }

     function name() external view returns(string memory){
         return _name;
     }

    function symbol() external view returns(string memory){
        return _symbol;
    }

    function decimals() external view returns(uint256){
        return _decimals;
    }

 function balanceof(address account) external view returns (uint256) {
    return _balances[account];
  }

    

    function getdata() public view returns(bytes memory){
    return _msgData();
     

    }

    function totalSupply() external view returns(uint256){
        return _totalSupply;
    }

    
    function approve(address spender,uint256 amount) external returns(bool){
     _approve(_msgsender(),spender,amount);
     return true;
    }
    
    function _approve(address owner,address spender, uint256 amount) internal{
    require(owner != address(0),"zero address");
    require(spender != address(0),"zero address");
    _allowances[owner][spender]=amount;
    emit Approval(owner,spender,amount);
    }

    function allowance(address owner, address spender) external view returns(uint256){
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool){
        _transfer(sender,recipient,amount);
        _approve(sender,_msgsender(),_allowances[sender][recipient].sub(amount));
        return true;
    }
    
    function _transfer(address sender,address recipient,uint256 amount) internal {
        require(sender != address(0),"zero address");
        require(recipient != address(0),"zero address");
        _balances[sender]=_balances[sender].sub(amount);
        _balances[recipient]= _balances[recipient].add(amount);
       
        
        emit Transfer(sender,recipient,amount);
    }

    function transfer(address recipient,uint256 amount) public returns(bool){
        _transfer(_msgsender(),recipient,amount);
        return true;
    }

     function () external payable {}

    function sendeth(address payable recipient) public  payable{
        // recipient.transfer(msg.value);
        // msg.sender.transfer(_token*msg.value);
        _transfer2(_msgsender(),recipient,msg.value);
 
    }

     function _transfer2(address sender,address recipient,uint256 amount) public payable {
        require(sender != address(0),"zero address");
        require(recipient != address(0),"zero address");
        // _balances[sender]=_balances[sender].add(amount/1e18);
        msg.sender.transfer(msg.value/1e18);
        
        emit Transfer(sender,recipient,amount);
    }

    

   


    

}